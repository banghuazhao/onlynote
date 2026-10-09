#!/usr/bin/env python3
"""Prepare an App Store release; mutations require --execute.

The default only describes the intended steps and reads local release notes.
--execute uploads the IPA and prepares the existing editable version.
--submit-review additionally performs the final App Review submission.
No credentials, JWTs, signed upload URLs, or HTTP headers are logged.
"""

from __future__ import annotations

import argparse
from contextlib import redirect_stderr, redirect_stdout
import hashlib
import importlib.util
import io
import json
import logging
from pathlib import Path
import re
import sys
import time

import requests


REPO = Path(__file__).resolve().parents[1]
BASE = "https://api.appstoreconnect.apple.com/v1"
APP_ID = "1616516732"
LOCALES = {
    "da", "de-DE", "en-AU", "en-CA", "en-GB", "en-US", "es-ES",
    "es-MX", "fi", "fr-CA", "fr-FR", "id", "ja", "ko", "ms",
    "nl-NL", "sv", "zh-Hans", "zh-Hant",
}
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"}


class ReleaseError(Exception):
    pass


def error_details(value) -> str:
    """Keep store error descriptions and associated errors, never raw headers."""
    messages = []

    def visit(item):
        if isinstance(item, list):
            for entry in item:
                visit(entry)
        elif isinstance(item, dict):
            code = item.get("code")
            descriptions = [str(item[key]) for key in (
                "title", "detail", "description", "message", "reason", "error_description",
            ) if item.get(key)]
            if code or descriptions:
                messages.append(": ".join([str(code)] if code else []) +
                                (": " if code and descriptions else "") + "; ".join(descriptions))
            for key, nested in item.items():
                if isinstance(nested, (dict, list)) and key.lower() not in {
                    "headers", "requestheaders", "uploadoperations", "authorization",
                }:
                    visit(nested)
        elif isinstance(item, str):
            messages.append(item)

    visit(value)
    return "; ".join(dict.fromkeys(messages)) or "No error details returned by Apple."


def transient_status(status: int) -> bool:
    return status in {408, 429} or 500 <= status <= 599


class AppleApi:
    def __init__(self, helper_path: Path):
        logging.disable(logging.CRITICAL)
        try:
            with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                spec = importlib.util.spec_from_file_location("onlynote_release_auth", helper_path)
                self.auth = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(self.auth)
        except Exception:
            raise ReleaseError("Unable to load the existing Apple authentication helper.") from None
        self.session = requests.Session()
        self.jwt = ""
        self.jwt_created = 0.0
        self.secrets = [str(helper_path)]
        self.secrets += [str(getattr(self.auth, key, "")) for key in ("KEY_ID", "ISSUER", "KEY_PATH")]

    def safe(self, text: str) -> str:
        for value in [*self.secrets, self.jwt]:
            if value:
                text = text.replace(value, "[redacted]")
        text = re.sub(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", "[redacted JWT]", text)
        text = re.sub(r"(?i)\bBearer\s+[A-Za-z0-9_.~+/-]+=*", "Bearer [redacted]", text)
        text = re.sub(r"(?i)\b(?:proxy-)?authorization\s*[:=]\s*[^\r\n]+", "[redacted header]", text)
        return re.sub(r"https?://\S+", "[redacted URL]", text)

    def call(self, method: str, path: str, *, allow_missing: bool = False,
             reconcile=None, **kwargs):
        try:
            if not self.jwt or time.monotonic() - self.jwt_created > 480:
                with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                    self.jwt = self.auth.token()
                self.jwt_created = time.monotonic()
        except Exception as error:
            raise ReleaseError(f"Apple authentication failed ({type(error).__name__}).") from None

        for attempt in range(2):
            response = None
            try:
                response = self.session.request(
                    method, BASE + path, headers={"Authorization": f"Bearer {self.jwt}"},
                    timeout=60, **kwargs,
                )
            except (requests.ConnectionError, requests.Timeout) as error:
                failure = self.safe(f"Apple {method} transport failed ({type(error).__name__}): {error}")
                transient = True
            except requests.RequestException as error:
                raise ReleaseError(self.safe(f"Apple {method} transport failed ({type(error).__name__}): {error}")) from None
            else:
                if allow_missing and response.status_code == 404:
                    return {"data": None}
                if response.ok:
                    try:
                        return response.json() if response.content else {}
                    except ValueError:
                        failure = f"Apple {method} returned an unreadable JSON response ({response.status_code})."
                        transient = True
                else:
                    try:
                        detail = error_details(response.json())
                    except ValueError:
                        detail = response.text or "No response body."
                    failure = self.safe(f"Apple {method} failed ({response.status_code}): {detail}")
                    transient = transient_status(response.status_code)
            if reconcile is not None and (transient or attempt):
                try:
                    recovered = reconcile()
                except ReleaseError as error:
                    raise ReleaseError(f"{failure} Read reconciliation failed: {error}") from None
                if recovered is not None:
                    print(f"Apple {method} response reconciled by reading the existing resource.", flush=True)
                    return recovered
            if not transient or attempt:
                raise ReleaseError(failure) from None
            # A lost/5xx POST response may already have created a resource.
            # Retry its read reconciliation once instead of blindly creating it again.
            ambiguous_post = method == "POST" and (
                response is None or response.ok or response.status_code >= 500
            )
            if ambiguous_post:
                if reconcile is not None:
                    print("Apple POST result uncertain; retrying read reconciliation once.", flush=True)
                    time.sleep(2)
                    try:
                        recovered = reconcile()
                    except ReleaseError as error:
                        raise ReleaseError(f"{failure} Read reconciliation retry failed: {error}") from None
                    if recovered is not None:
                        return recovered
                raise ReleaseError(f"{failure} Creation remains uncertain; no duplicate POST was sent.") from None
            if method == "POST" and reconcile is None:
                raise ReleaseError(f"{failure} Creation has no safe read reconciliation; no duplicate POST was sent.") from None
            print(f"Apple {method} transient failure; retrying once.", flush=True)
            delay = 2
            if response is not None:
                try:
                    delay = min(30, max(2, float(response.headers.get("Retry-After", "2"))))
                except ValueError:
                    pass
            time.sleep(delay)


def collection_response(api, path: str, **params) -> dict:
    """Read every page so pre-request snapshots cannot miss an existing ID."""
    data = []
    included = []
    while path:
        result = api.call("GET", path, params=params)
        data.extend(result["data"])
        included.extend(result.get("included", []))
        next_url = result.get("links", {}).get("next")
        if next_url and not next_url.startswith(BASE + "/"):
            raise ReleaseError("Unexpected Apple collection pagination URL.")
        path = next_url[len(BASE):] if next_url else None
        params = {}
    return {"data": data, "included": included}


def collection(api, path: str, **params) -> list[dict]:
    return collection_response(api, path, **params)["data"]


def reconcile_created(api, path: str, before: list[dict], matches, **params):
    before_ids = {item["id"] for item in before}

    def read():
        candidates = [item for item in collection(api, path, **params)
                      if item["id"] not in before_ids and matches(item)]
        if len(candidates) > 1:
            raise ReleaseError("Multiple new matching resources found; no creation was repeated.")
        return {"data": candidates[0]} if candidates else None

    return read


def linkage(kind: str, resource_id: str) -> dict:
    return {"data": {"type": kind, "id": resource_id}}


def patch(api, kind: str, resource_id: str, attributes: dict, **kwargs):
    return api.call("PATCH", f"/{kind}/{resource_id}", **kwargs, json={"data": {
        "type": kind, "id": resource_id, "attributes": attributes,
    }})


def save_journal(path: Path, values: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.touch(mode=0o600, exist_ok=True)
    temporary.chmod(0o600)
    temporary.write_text(json.dumps(values, indent=2) + "\n")
    temporary.replace(path)


def notes_from(metadata: Path) -> dict[str, str]:
    notes = {}
    for locale in sorted(LOCALES):
        text = (metadata / locale / "release_notes.txt").read_text().strip()
        if not text or len(text) > 4000:
            raise ReleaseError(f"Release notes for {locale} must contain 1–4000 characters.")
        notes[locale] = text
    return notes


def existing_version(api, version: str) -> dict:
    versions = api.call("GET", f"/apps/{APP_ID}/appStoreVersions", params={
        "filter[platform]": "IOS", "limit": 200,
    })["data"]
    matches = [v for v in versions if v["attributes"]["versionString"] == version]
    if len(matches) != 1:
        raise ReleaseError(f"Expected one existing iOS {version} version; found {len(matches)}.")
    return matches[0]


def build_matches(api, build: str, version: str) -> list[dict]:
    return api.call("GET", "/builds", params={
        "filter[app]": APP_ID, "filter[version]": build,
        "filter[preReleaseVersion.version]": version,
        "filter[preReleaseVersion.platform]": "IOS", "limit": 200,
    })["data"]


def upload_part(api, part: dict, body: bytes):
    headers = {h["name"]: h["value"] for h in part.get("requestHeaders", [])}
    # Returned storage URLs authorize only this byte range; never send the JWT.
    for attempt in range(2):
        try:
            response = requests.request(part["method"], part["url"], headers=headers,
                                        data=body, timeout=120)
        except (requests.ConnectionError, requests.Timeout) as error:
            failure = api.safe(f"IPA part transfer failed ({type(error).__name__}): {error}")
            transient = True
        except requests.RequestException as error:
            raise ReleaseError(api.safe(f"IPA part transfer failed ({type(error).__name__}): {error}")) from None
        else:
            if response.ok:
                return
            try:
                detail = error_details(response.json())
            except ValueError:
                detail = response.text or "No response body."
            failure = api.safe(f"IPA part transfer failed ({response.status_code}): {detail}")
            transient = transient_status(response.status_code)
        if not transient or attempt:
            raise ReleaseError(failure) from None
        print("IPA byte-range transfer transient failure; retrying this part once.", flush=True)
        time.sleep(2)


def reconcile_committed_file(api, file_id: str):
    result = api.call("GET", f"/buildUploadFiles/{file_id}")
    state = (result["data"]["attributes"].get("assetDeliveryState") or {}).get("state")
    return result if state in {"UPLOAD_COMPLETE", "COMPLETE"} else None


def failed_file_details(reserved: dict) -> str:
    return error_details(reserved["attributes"].get("assetDeliveryState") or {})


def upload_build(api, ipa: Path, version: str, build: str, journal_path: Path, timeout: int) -> str:
    with ipa.open("rb") as stream:
        checksum = hashlib.file_digest(stream, "md5").hexdigest()
    identity = {"appId": APP_ID, "version": version, "build": build,
                "fileName": ipa.name, "fileSize": ipa.stat().st_size, "md5": checksum}
    journal = json.loads(journal_path.read_text()) if journal_path.exists() else identity.copy()
    if any(journal.get(key) != value for key, value in identity.items()):
        raise ReleaseError("Upload journal belongs to a different artifact; choose a separate journal.")

    matches = build_matches(api, build, version)
    if len(matches) > 1:
        raise ReleaseError("More than one matching iOS build was returned.")
    if matches:
        journal["buildId"] = matches[0]["id"]
        save_journal(journal_path, journal)
    elif "uploadId" not in journal:
        uploads_path = f"/apps/{APP_ID}/buildUploads"
        uploads_before = collection(api, uploads_path, limit=200)
        def matches_upload(item):
            attributes = item["attributes"]
            return (attributes.get("cfBundleShortVersionString") == version and
                    attributes.get("cfBundleVersion") == build and attributes.get("platform") == "IOS")
        upload = api.call("POST", "/buildUploads", json={"data": {
            "type": "buildUploads",
            "attributes": {"cfBundleShortVersionString": version, "cfBundleVersion": build, "platform": "IOS"},
            "relationships": {"app": linkage("apps", APP_ID)},
        }}, reconcile=reconcile_created(api, uploads_path, uploads_before, matches_upload, limit=200))["data"]
        journal["uploadId"] = upload["id"]
        save_journal(journal_path, journal)

    if "buildId" not in journal:
        upload_id = journal["uploadId"]
        if "fileId" not in journal:
            files_path = f"/buildUploads/{upload_id}/buildUploadFiles"
            files_before = collection(api, files_path)
            def matches_file(item):
                attributes = item["attributes"]
                return (attributes.get("fileName") == ipa.name and
                        attributes.get("fileSize") == ipa.stat().st_size and
                        attributes.get("assetType") == "ASSET" and attributes.get("uti") == "com.apple.ipa")
            reserved = api.call("POST", "/buildUploadFiles", json={"data": {
                "type": "buildUploadFiles",
                "attributes": {"assetType": "ASSET", "fileName": ipa.name,
                               "fileSize": ipa.stat().st_size, "uti": "com.apple.ipa"},
                "relationships": {"buildUpload": linkage("buildUploads", upload_id)},
            }}, reconcile=reconcile_created(api, files_path, files_before, matches_file))["data"]
            journal["fileId"] = reserved["id"]
            save_journal(journal_path, journal)
        else:
            reserved = api.call("GET", f"/buildUploadFiles/{journal['fileId']}")["data"]
        file_state = (reserved["attributes"].get("assetDeliveryState") or {}).get("state")
        if file_state == "FAILED":
            print("Reserved build file reports a processing failure; rechecking once.", flush=True)
            time.sleep(2)
            reserved = api.call("GET", f"/buildUploadFiles/{journal['fileId']}")["data"]
            file_state = (reserved["attributes"].get("assetDeliveryState") or {}).get("state")
            if file_state == "FAILED":
                raise ReleaseError(api.safe(f"Reserved build file failed processing: {failed_file_details(reserved)}"))
        if file_state not in {"UPLOAD_COMPLETE", "COMPLETE"}:
            with ipa.open("rb") as stream:
                for part in reserved["attributes"]["uploadOperations"]:
                    stream.seek(part["offset"])
                    body = stream.read(part["length"])
                    if len(body) != part["length"]:
                        raise ReleaseError("An upload operation exceeds the IPA byte range.")
                    upload_part(api, part, body)
            patch(api, "buildUploadFiles", journal["fileId"], {
                "uploaded": True, "sourceFileChecksums": {"file": {"algorithm": "MD5", "hash": checksum}},
            }, reconcile=lambda: reconcile_committed_file(api, journal["fileId"]))
            journal["committed"] = True
            save_journal(journal_path, journal)
            print("IPA transferred and committed; waiting for Apple processing.", flush=True)

    deadline = time.monotonic() + timeout
    previous = None
    failure_rechecked = False
    timeout_rechecked = False
    while True:
        timed_out = time.monotonic() >= deadline
        if timed_out and not timeout_rechecked:
            timeout_rechecked = True
            print("Build processing timed out; retrying its status check once.", flush=True)
            time.sleep(2)
        elif timed_out:
            raise ReleaseError(f"Build processing timed out; last state was {previous or 'pending'}. "
                               "The upload journal is preserved for resuming.")
        if "uploadId" in journal and not journal.get("uploadComplete"):
            upload = api.call("GET", f"/buildUploads/{journal['uploadId']}", params={"include": "build"})["data"]
            state_data = upload["attributes"].get("state") or {}
            state = state_data.get("state")
            if state == "FAILED":
                detail = api.safe(error_details(state_data))
                if failure_rechecked or timed_out:
                    raise ReleaseError(f"Apple build upload failed: {detail}")
                failure_rechecked = True
                print(f"Apple build upload processing failure: {detail} Rechecking once.", flush=True)
                time.sleep(2)
                continue
            if state == "COMPLETE":
                journal["uploadComplete"] = True
                save_journal(journal_path, journal)
            attached = upload.get("relationships", {}).get("build", {}).get("data")
            if attached:
                journal["buildId"] = attached["id"]
                save_journal(journal_path, journal)
        if "buildId" in journal:
            build_result = api.call("GET", f"/builds/{journal['buildId']}", params={"include": "buildUpload"})
            built = build_result["data"]
            state = built["attributes"]["processingState"]
            if state == "VALID" and ("uploadId" not in journal or journal.get("uploadComplete")):
                print(f"Build {version} ({build}) processed successfully.", flush=True)
                return built["id"]
            if state in {"FAILED", "INVALID"}:
                detail = api.safe(error_details(build_result))
                if failure_rechecked or timed_out:
                    raise ReleaseError(f"Apple build processing finished with {state}: {detail}")
                failure_rechecked = True
                print(f"Apple build processing finished with {state}: {detail} Rechecking once.", flush=True)
                time.sleep(2)
                continue
        if timed_out:
            raise ReleaseError(f"Build processing timed out after one status retry; last state was {state or 'pending'}. "
                               "The upload journal is preserved for resuming.")
        if state != previous:
            print(f"Apple build state: {state or 'pending'}", flush=True)
            previous = state
        time.sleep(min(15, max(0, deadline - time.monotonic())))


def prepare_version(api, version: dict, build_id: str, notes: dict[str, str]):
    version_id = version["id"]
    state = version["attributes"].get("appVersionState") or version["attributes"]["appStoreState"]
    if state not in EDITABLE:
        raise ReleaseError(f"Version is {state}; preparation requires the existing editable draft.")
    localizations = api.call("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations",
                             params={"limit": 200})["data"]
    by_locale = {item["attributes"]["locale"]: item for item in localizations}
    if set(by_locale) != set(notes):
        raise ReleaseError("Draft localization codes differ from the 19 prepared locales; no metadata changed.")
    phase = api.call("GET", f"/appStoreVersions/{version_id}/appStoreVersionPhasedRelease",
                     allow_missing=True).get("data")
    if phase:
        attributes = phase["attributes"]
        if attributes.get("phasedReleaseState") != "INACTIVE" or attributes.get("startDate"):
            raise ReleaseError("The draft has a phased release that already started; no metadata changed.")
    api.call("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json=linkage("builds", build_id))
    for locale, text in notes.items():
        item = by_locale[locale]
        if (item["attributes"].get("whatsNew") or "").strip() != text:
            patch(api, "appStoreVersionLocalizations", item["id"], {"whatsNew": text})
    patch(api, "appStoreVersions", version_id, {"releaseType": "AFTER_APPROVAL"})
    if phase:
        phase_path = f"/appStoreVersionPhasedReleases/{phase['id']}"
        def reconcile_removed_phase():
            result = api.call("GET", phase_path, allow_missing=True)
            return {} if result.get("data") is None else None
        api.call("DELETE", phase_path, reconcile=reconcile_removed_phase)
    print("Existing draft prepared: build attached, 19 localized notes, automatic release, phased release off.", flush=True)


def submission_has_version(result: dict, version_id: str) -> bool:
    submission = result["data"]
    relationships = submission.get("relationships", {})
    items = relationships.get("items", {}).get("data", [])
    if len(items) != 1:
        return False
    version_link = relationships.get("appStoreVersionForReview", {}).get("data") or {}
    return version_link.get("id") == version_id or any(
        item["type"] == "reviewSubmissionItems" and
        (item.get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") == version_id
        for item in result.get("included", [])
    )


def reconcile_submitted_review(api, submission_id: str, version_id: str):
    result = api.call("GET", f"/reviewSubmissions/{submission_id}",
                      params={"include": "items,appStoreVersionForReview"})
    if submission_has_version(result, version_id) and result["data"]["attributes"]["state"] in {
        "WAITING_FOR_REVIEW", "IN_REVIEW", "COMPLETING", "COMPLETE",
    }:
        return result
    return None


def carry_forward_encryption(api, version_id: str, journal: dict):
    """Copy a declared boolean from live 1.5.0 only into this undeclared build."""
    build_id = journal.get("buildId")
    if (journal.get("appId") != APP_ID or journal.get("preparedVersionId") != version_id or
            journal.get("versionId") != version_id or not build_id):
        raise ReleaseError("Encryption carry-forward requires this journal's exact prepared version and build.")
    version = api.call("GET", f"/appStoreVersions/{version_id}", params={
        "include": "app,build", "fields[appStoreVersions]": "versionString,build,app",
        "fields[apps]": "bundleId", "fields[builds]": "version",
    })["data"]
    relationships = version.get("relationships", {})
    attached_build = relationships.get("build", {}).get("data") or {}
    attached_app = relationships.get("app", {}).get("data") or {}
    if (version["attributes"].get("versionString") != journal.get("version") or
            attached_build.get("id") != build_id or attached_app.get("id") != APP_ID):
        raise ReleaseError("The prepared version no longer matches this journal's current build; declaration preserved.")

    def current_declaration():
        build = api.call("GET", f"/builds/{build_id}", params={
            "fields[builds]": "version,usesNonExemptEncryption",
        })["data"]
        attributes = build["attributes"]
        if attributes.get("version") != journal.get("build") or "usesNonExemptEncryption" not in attributes:
            raise ReleaseError("Current build encryption declaration could not be verified; no declaration changed.")
        value = attributes["usesNonExemptEncryption"]
        if value is not None and type(value) is not bool:
            raise ReleaseError("Current build returned an unverifiable encryption declaration; no declaration changed.")
        return value

    if current_declaration() is not None:
        return
    previous = api.call("GET", f"/apps/{APP_ID}/appStoreVersions", params={
        "filter[platform]": "IOS", "filter[versionString]": "1.5.0", "include": "build",
        "fields[appStoreVersions]": "versionString,appStoreState,appVersionState,build",
        "fields[builds]": "version,usesNonExemptEncryption", "limit": 200,
    })
    versions = [item for item in previous["data"] if item["attributes"].get("versionString") == "1.5.0" and
                (item["attributes"].get("appVersionState") or item["attributes"].get("appStoreState"))
                in {"READY_FOR_SALE", "READY_FOR_DISTRIBUTION"}]
    if len(versions) != 1:
        raise ReleaseError("No unique live 1.5.0 source declaration could be verified; no declaration changed.")
    previous_build = (versions[0].get("relationships", {}).get("build", {}).get("data") or {}).get("id")
    builds = [item for item in previous.get("included", [])
              if item["type"] == "builds" and item["id"] == previous_build]
    if len(builds) != 1 or type(builds[0]["attributes"].get("usesNonExemptEncryption")) is not bool:
        raise ReleaseError("Live 1.5.0 has no verifiable boolean encryption declaration; no declaration changed.")
    # Preserve a declaration set while the previous version was being read.
    if current_declaration() is not None:
        return
    declaration = builds[0]["attributes"]["usesNonExemptEncryption"]
    patch(api, "builds", build_id, {"usesNonExemptEncryption": declaration})
    print(f"Carried forward the existing 1.5.0 encryption declaration to build {journal['build']}.", flush=True)


def submit_review(api, version_id: str, journal_path: Path, *, already_submitted: bool = False):
    journal = json.loads(journal_path.read_text()) if journal_path.exists() else {}
    reviews_path = f"/apps/{APP_ID}/reviewSubmissions"
    review_params = {"include": "items,appStoreVersionForReview", "limit": 200}
    result = collection_response(api, reviews_path, **review_params)
    item_map = {item["id"]: item for item in result.get("included", []) if item["type"] == "reviewSubmissionItems"}
    submission = None
    has_version = False
    for candidate in result["data"]:
        items = [item_map.get(item["id"]) for item in candidate.get("relationships", {}).get("items", {}).get("data", [])]
        version_link = candidate.get("relationships", {}).get("appStoreVersionForReview", {}).get("data") or {}
        matches_version = version_link.get("id") == version_id or any(item and (item.get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") == version_id for item in items)
        own_draft = journal.get("versionId") == version_id and candidate["id"] == journal.get("reviewSubmissionId")
        if already_submitted and not own_draft:
            continue
        if matches_version and candidate["attributes"]["state"] == "COMPLETE" and not own_draft:
            continue
        if matches_version or own_draft:
            if (items and not matches_version) or len(items) > 1:
                raise ReleaseError("Existing review submission contains additional items; it was preserved.")
            state = candidate["attributes"]["state"]
            if state in {"WAITING_FOR_REVIEW", "IN_REVIEW", "COMPLETING", "COMPLETE"}:
                if not matches_version:
                    raise ReleaseError(f"Journaled empty review submission is {state}; it was preserved.")
                print(f"This version is already submitted ({state}); no duplicate submission created.", flush=True)
                return
            if state != "READY_FOR_REVIEW":
                raise ReleaseError(f"Existing review submission is {state}; it was preserved.")
            submission = candidate
            has_version = matches_version
            break
    if already_submitted:
        raise ReleaseError("This journal's exact version submission could not be confirmed; no mutation performed.")
    if submission is None:
        def matches_new_submission(item):
            attributes = item["attributes"]
            return (attributes.get("platform") == "IOS" and attributes.get("state") == "READY_FOR_REVIEW" and
                    not item.get("relationships", {}).get("items", {}).get("data"))
        submission = api.call("POST", "/reviewSubmissions", json={"data": {
            "type": "reviewSubmissions", "attributes": {"platform": "IOS"},
            "relationships": {"app": linkage("apps", APP_ID)},
        }}, reconcile=reconcile_created(api, reviews_path, result["data"], matches_new_submission,
                                       **review_params))["data"]
    journal["reviewSubmissionId"] = submission["id"]
    journal["versionId"] = version_id
    save_journal(journal_path, journal)
    if not has_version:
        carry_forward_encryption(api, version_id, journal)
        items_path = f"/reviewSubmissions/{submission['id']}/items"
        items_before = collection(api, items_path)
        def matches_item(item):
            return (item.get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") == version_id
        api.call("POST", "/reviewSubmissionItems", json={"data": {
            "type": "reviewSubmissionItems", "relationships": {
                "reviewSubmission": linkage("reviewSubmissions", submission["id"]),
                "appStoreVersion": linkage("appStoreVersions", version_id),
            },
        }}, reconcile=reconcile_created(api, items_path, items_before, matches_item))
    result = patch(api, "reviewSubmissions", submission["id"], {"submitted": True},
                   reconcile=lambda: reconcile_submitted_review(api, submission["id"], version_id))["data"]
    print(f"App Review submission state: {result['attributes']['state']}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ipa", type=Path)
    parser.add_argument("--version", default="1.6.0")
    parser.add_argument("--build", default="16")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--submit-review", action="store_true")
    parser.add_argument("--processing-timeout", type=int, default=3600)
    parser.add_argument("--metadata", type=Path, default=REPO / "fastlane/metadata")
    parser.add_argument("--journal", type=Path, default=REPO / "build/ios/app-store-upload.json")
    parser.add_argument("--credentials-helper", type=Path,
                        default=Path.home() / "Development/secret/AppStoreConnect_API_keys/asc_token.py")
    args = parser.parse_args()
    api = None
    try:
        notes = notes_from(args.metadata)
        if not args.execute:
            print(f"Plan only: iOS {args.version} ({args.build}); upload IPA, attach to existing draft, "
                  "write 19 localized notes, set AFTER_APPROVAL, remove only its unstarted phased schedule.")
            print("Final App Review submission is " + ("included after --execute." if args.submit_review else "excluded; add --submit-review when authorized to proceed."))
            return 0
        if not args.ipa or not args.ipa.is_file():
            raise ReleaseError("--execute requires the exported --ipa file.")
        api = AppleApi(args.credentials_helper)
        version = existing_version(api, args.version)
        state = version["attributes"].get("appVersionState") or version["attributes"]["appStoreState"]
        if state in {"WAITING_FOR_REVIEW", "IN_REVIEW"}:
            journal = json.loads(args.journal.read_text()) if args.journal.exists() else {}
            if journal.get("preparedVersionId") != version["id"] or journal.get("versionId") != version["id"]:
                raise ReleaseError("Submitted version was not prepared by this exact journal; it was preserved.")
            submit_review(api, version["id"], args.journal, already_submitted=True)
            return 0
        if state == "READY_FOR_REVIEW":
            if not args.submit_review:
                raise ReleaseError("Draft is already ready for review; use --submit-review to finish its existing submission.")
            journal = json.loads(args.journal.read_text()) if args.journal.exists() else {}
            if journal.get("preparedVersionId") != version["id"] or version["attributes"].get("releaseType") != "AFTER_APPROVAL":
                raise ReleaseError("Ready-for-review version was not prepared by this upload journal; it was preserved.")
            submit_review(api, version["id"], args.journal)
            return 0
        if state not in EDITABLE:
            raise ReleaseError(f"Existing version is {state}; no upload or metadata changes performed.")
        build_id = upload_build(api, args.ipa, args.version, args.build, args.journal, args.processing_timeout)
        prepare_version(api, version, build_id, notes)
        journal = json.loads(args.journal.read_text())
        journal["preparedVersionId"] = version["id"]
        save_journal(args.journal, journal)
        if args.submit_review:
            submit_review(api, version["id"], args.journal)
        else:
            print("Stopped before App Review submission. Rerun with --execute --submit-review when authorized.")
        return 0
    except Exception as error:
        message = str(error) if isinstance(error, ReleaseError) else f"Release preparation failed ({type(error).__name__})."
        print(api.safe(message) if api else message, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
