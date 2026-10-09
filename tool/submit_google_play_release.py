#!/usr/bin/env python3
"""Publish OnlyNote 1.6.0 (16) after approval; --dry-run is entirely offline.

One API commit submits both this production release and the saved Console
screenshot drafts. This script never writes images or store listings. Make no
Console changes while its API edit is active. Google rejection codes and
messages are retained with credentials redacted; raw responses are never logged.
"""

import argparse
import hashlib
import importlib.util
import io
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path


PACKAGE = "com.appsbay.onlynote"
VERSION_CODE = 16
VERSION_NAME = "1.6.0"
LOCALES = "da-DK,de-DE,en-AU,en-CA,en-GB,en-IN,en-SG,en-US,en-ZA,es-419,es-ES,es-US,fi-FI,fr-CA,fr-FR,id,ja-JP,ko-KR,ms,ms-MY,nl-NL,pt-BR,pt-PT,sv-SE,zh-CN,zh-HK,zh-TW".split(",")
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
UPLOAD_API = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"


class SafeFailure(Exception):
    pass


def log(phase, **fields):
    print(json.dumps({"phase": phase, **fields}), flush=True)


def redact_error_message(message, token):
    """Retain Google's message while removing credentials from its text."""
    if token:
        message = message.replace(token, "[redacted token]")
    message = re.sub(
        r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----",
        "[redacted private key]", message, flags=re.DOTALL)
    message = re.sub(r"\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*",
                     "[redacted JWT]", message)
    message = re.sub(r"\bya29\.[A-Za-z0-9_-]+", "[redacted token]", message)
    message = re.sub(r"\bAIza[A-Za-z0-9_-]{20,}", "[redacted API key]", message)
    message = re.sub(r"\b1//[A-Za-z0-9_-]+", "[redacted refresh token]", message)
    message = re.sub(r"(?i)\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+",
                     r"\1 [redacted credential]", message)
    credential_fields = (
        "access_token|refresh_token|id_token|client_secret|private_key|"
        "authorization|assertion|password|credential")
    quoted_field = re.compile(
        rf"(?i)([\"']?(?:{credential_fields})[\"']?\s*[:=]\s*)([\"'])(.*?)\2",
        flags=re.DOTALL)
    message = quoted_field.sub(lambda match: match[1] + match[2] + "[redacted]" + match[2], message)
    message = re.sub(
        rf"(?i)(\b(?:{credential_fields})\s*[:=]\s*)(?![\"'])[^\s,;]+",
        r"\1[redacted]", message)
    secret_parameters = {
        "access_token", "refresh_token", "id_token", "token", "auth", "authorization",
        "oauth_token", "client_secret", "assertion", "password", "key", "api_key",
        "signature", "credential", "code", "x-goog-signature", "x-goog-credential",
        "x-amz-signature", "x-amz-credential", "x-amz-security-token",
    }

    def redact_url(match):
        url = match[0]
        try:
            parsed = urllib.parse.urlsplit(url)
            query = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
            fragment = urllib.parse.parse_qsl(parsed.fragment, keep_blank_values=True)
            if parsed.username is not None or parsed.password is not None or any(
                    key.lower() in secret_parameters for key, _ in query + fragment):
                return "[redacted credential URL]"
        except ValueError:
            return "[redacted URL]"
        return url

    message = re.sub(r"https?://[^\s<>\"']+", redact_url, message)
    return re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", "", message)


def google_api_failure(error, token):
    """Extract selected Google error fields, never the raw error response."""
    try:
        payload = json.loads(error.read())
        details = payload.get("error", {}) if isinstance(payload, dict) else {}
        if not isinstance(details, dict):
            details = {}
    except (ValueError, UnicodeError, OSError):
        details = {}
    finally:
        error.close()
    fields = [f"HTTP {error.code}"]
    code = details.get("code")
    if isinstance(code, int) or isinstance(code, str) and code.isdigit():
        fields.append(f"code={code}")
    status = details.get("status")
    if isinstance(status, str) and re.fullmatch(r"[A-Z_]{1,120}", status):
        fields.append(f"status={status}")
    for detail in details.get("details", []) if isinstance(details.get("details"), list) else []:
        reason = detail.get("reason") if isinstance(detail, dict) else None
        if isinstance(reason, str) and re.fullmatch(r"[A-Z_]{1,120}", reason):
            fields.append(f"reason={reason}")
    message = details.get("message")
    if isinstance(message, str):
        fields.append("message=" + redact_error_message(message, token))
    return SafeFailure("Google Play API error: " + "; ".join(fields))


def offline_plan(args):
    repo = args.repo.resolve()
    aab = args.aab.resolve() if args.aab else repo / "build/app/outputs/bundle/release/app-release.aab"
    if not aab.is_file():
        raise SafeFailure("Release AAB is missing.")
    notes = []
    for locale in LOCALES:
        path = repo / "fastlane/metadata/android" / locale / "changelogs/16.txt"
        if not path.is_file():
            raise SafeFailure(f"Missing release notes for {locale}.")
        text = path.read_text(encoding="utf-8")
        if len(text) > 500 or len(text.encode("utf-16-le")) // 2 > 500:
            raise SafeFailure(f"Release notes exceed 500 characters for {locale}.")
        if len(text.splitlines()) != 4 or not all(line.startswith("- ") for line in text.splitlines()):
            raise SafeFailure(f"Expected four release-note bullets for {locale}.")
        notes.append({"language": locale, "text": text})
    report_path = repo / "build/store_screenshots/2026-10-08/play-console-upload-report.json"
    report = json.loads(report_path.read_text(encoding="utf-8"))
    sets = report.get("sets", [])
    if report.get("packageName") != PACKAGE or report.get("placements") != 96 or len(sets) != 12:
        raise SafeFailure("Screenshot verification report does not match the expected 96 placements.")
    if not all(item.get("count") == 8 and item.get("orderVerified") and item.get("verifiedAfterReload") for item in sets):
        raise SafeFailure("Screenshot verification report contains an unverified set.")
    if report.get("state") != "DRAFT_CHANGES" or report.get("reviewSubmitted") or report.get("published"):
        raise SafeFailure("Screenshot report does not describe the saved, unsubmitted Console drafts.")
    if report.get("managedPublishing") != "OFF_UNCHANGED":
        raise SafeFailure("Managed publishing report differs from the authorized automatic release plan.")
    sha256 = hashlib.sha256(aab.read_bytes()).hexdigest()
    log("offline-plan", package=PACKAGE, version=VERSION_NAME, versionCode=VERSION_CODE,
        track="production", status="completed", rolloutPercent=100, releaseNoteLocales=len(notes),
        savedConsoleScreenshotPlacements=96, bundleSha256=sha256, networkCalls=0)
    return aab, sha256, notes


def api_request(url, token, ssl_context, method="GET", body=None, raw_body=None):
    data = raw_body if raw_body is not None else json.dumps(body).encode() if body is not None else None
    headers = {"Authorization": f"Bearer {token}"}
    if raw_body is not None:
        headers["Content-Type"] = "application/octet-stream"
    elif body is not None:
        headers["Content-Type"] = "application/json"
    for attempt in range(2):
        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=1800, context=ssl_context) as response:
                payload = response.read()
            return json.loads(payload) if payload else {}
        except urllib.error.HTTPError as error:
            status = error.code
            if status in {408, 429, 500, 502, 503, 504} and attempt == 0:
                error.close()
                log("retry", operation=method, reason="transient-http", attempt=1)
                time.sleep(1)
                continue
            raise google_api_failure(error, token) from None
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            if attempt == 0:
                log("retry", operation=method, reason="transient-network", attempt=1)
                time.sleep(1)
                continue
            raise SafeFailure("Google Play API transport failed after one retry.") from None


def authenticated_helper(path):
    if not path.is_file():
        raise SafeFailure("Publishing authentication helper is missing.")
    spec = importlib.util.spec_from_file_location("onlynote_existing_play_helper", path)
    helper = importlib.util.module_from_spec(spec)
    with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
        spec.loader.exec_module(helper)
    from google.auth.exceptions import TransportError
    for attempt in range(2):
        try:
            with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                token = helper.token()
            return helper, token
        except TransportError:
            if attempt == 0:
                log("retry", operation="authentication", reason="transient-network", attempt=1)
                time.sleep(1)
                continue
            raise SafeFailure("Authentication transport failed after one retry.") from None
        except Exception:
            raise SafeFailure("Google Play authentication failed; no credential details logged.") from None


def execute(args, aab, expected_hash, notes):
    helper, token = authenticated_helper(args.helper.expanduser().resolve())
    base = f"{API}/{PACKAGE}"
    call = lambda url, **kwargs: api_request(url, token, helper.SSL_CTX, **kwargs)
    edit = call(f"{base}/edits", method="POST", body={})
    edit_id = edit.get("id")
    if not isinstance(edit_id, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", edit_id):
        raise SafeFailure("Google Play returned an invalid edit identifier.")
    log("edit-created", editId=edit_id)
    edit_base = f"{base}/edits/{edit_id}"

    def matching_bundle():
        bundles = call(f"{edit_base}/bundles").get("bundles", [])
        return next((item for item in bundles if item.get("versionCode") == VERSION_CODE), None)

    bundle = matching_bundle()
    if bundle is None:
        try:
            bundle = call(f"{UPLOAD_API}/{PACKAGE}/edits/{edit_id}/bundles?uploadType=media",
                          method="POST", raw_body=aab.read_bytes())
        except SafeFailure as upload_error:
            # A response may be lost after the upload succeeds. Check the same
            # edit before allowing another run to upload the version again.
            try:
                bundle = matching_bundle()
            except SafeFailure:
                raise upload_error from None
            if bundle is None:
                raise upload_error from None
    if bundle.get("versionCode") != VERSION_CODE or bundle.get("sha256", "").lower() != expected_hash:
        raise SafeFailure("Uploaded bundle version or hash differs from the prepared AAB; edit remains uncommitted.")
    log("bundle-verified", versionCode=VERSION_CODE)
    release = {"name": VERSION_NAME, "versionCodes": [str(VERSION_CODE)], "status": "completed", "releaseNotes": notes}
    call(f"{edit_base}/tracks/production", method="PUT", body={"track": "production", "releases": [release]})
    track = call(f"{edit_base}/tracks/production")
    saved = track.get("releases", [])
    if len(saved) != 1 or saved[0].get("versionCodes") != [str(VERSION_CODE)] or saved[0].get("status") != "completed":
        raise SafeFailure("Production release verification failed; edit remains uncommitted.")
    if sorted(item.get("language") for item in saved[0].get("releaseNotes", [])) != sorted(LOCALES):
        raise SafeFailure("Localized release-note verification failed; edit remains uncommitted.")
    log("release-verified", track="production", status="completed", releaseNoteLocales=27)
    call(f"{edit_base}:validate", method="POST")
    log("edit-validated", editId=edit_id)
    try:
        call(f"{edit_base}:commit?changesInReviewBehavior=ERROR_IF_IN_REVIEW", method="POST")
    except SafeFailure as error:
        raise SafeFailure(f"{error} Commit did not return success; inspect Console before creating another edit or retrying submission.") from None
    log("committed", versionCode=VERSION_CODE, track="production", rolloutPercent=100,
        includesSavedConsoleDraftChanges=True, reviewStatus="verify-in-console", publication="after-review-approval")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--aab", type=Path)
    parser.add_argument("--helper", type=Path, default=Path.home() / "Development/secret/GooglePlay_API/publish_play_release.py")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Offline verification only; never authenticate or contact Google.")
    mode.add_argument("--execute", action="store_true", help="Only after user go: upload and submit production plus saved Console drafts.")
    args = parser.parse_args()
    try:
        plan = offline_plan(args)
        if args.execute:
            execute(args, *plan)
        else:
            log("offline-complete", storeWrites=0, authenticationCalls=0)
    except SafeFailure as error:
        print(str(error), file=sys.stderr)
        return 1
    except Exception:
        print("Release workflow failed; detailed exception suppressed to protect credentials.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
