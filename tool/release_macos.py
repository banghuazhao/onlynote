#!/usr/bin/env python3
"""Prepare and submit Onlynote's macOS release through App Store Connect.

Credentials remain outside the repository and are read without executing the
credential helper. API failures redact credentials, tokens, and upload URLs.
"""

from __future__ import annotations

import argparse
from contextlib import redirect_stderr, redirect_stdout
import io
import fcntl
import hashlib
import json
import logging
from pathlib import Path
import re
import subprocess
import sys
import time
from types import SimpleNamespace

import jwt
import requests
from PIL import Image

from build_ios_release import credentials
from submit_app_store_release import (
    AppleApi, EDITABLE, ReleaseError, collection, collection_response,
    linkage, patch, reconcile_created, reconcile_submitted_review, save_journal,
)


REPO = Path(__file__).resolve().parents[1]
APP_ID = "1616516732"
PLATFORM = "MAC_OS"
DEFAULT_HELPER = Path.home() / "Development/secret/AppStoreConnect_API_keys/asc_token.py"
OUTPUT = REPO / "build/macos-release"
JOURNAL = OUTPUT / "store-release.json"
METADATA = REPO / "fastlane/metadata_macos"
SCREENSHOT_ROOT = REPO / "build/store_screenshots/2026-10-14"

# Submission states that still belong to a release in flight. COMPLETE is not
# one of them: an approved, rejected or cancelled submission all end there.
LIVE_REVIEW_STATES = {"WAITING_FOR_REVIEW", "IN_REVIEW", "COMPLETING"}
FINISHED_REVIEW_STATES = {"COMPLETE", "CANCELED"}


class MacAppleApi(AppleApi):
    def __init__(self, helper_path: Path):
        logging.disable(logging.CRITICAL)
        key_id, issuer, key_path = credentials(helper_path)
        self._key_id, self._issuer, self._key_path = key_id, issuer, key_path
        self.auth = SimpleNamespace(token=self._token)
        self.session = requests.Session()
        self.jwt = ""
        self.jwt_created = 0.0
        self.secrets = [str(helper_path), key_id, issuer, str(key_path)]

    def _token(self):
        now = int(time.time())
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            return jwt.encode(
                {"iss": self._issuer, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
                self._key_path.read_text(), algorithm="ES256",
                headers={"kid": self._key_id, "typ": "JWT"},
            )

    def safe(self, value):
        return re.sub(r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
                      "<redacted-email>", super().safe(value))


def inspect(api: MacAppleApi):
    app = api.call("GET", f"/apps/{APP_ID}")["data"]
    versions = collection(api, f"/apps/{APP_ID}/appStoreVersions", limit=200)
    infos = collection(api, f"/apps/{APP_ID}/appInfos", limit=200)
    result = {"app": app, "versions": versions, "appInfos": infos,
              "macLocalizations": {}, "infoLocalizations": {}, "macBuilds": []}
    for version in versions:
        attributes = version["attributes"]
        if attributes["platform"] == PLATFORM:
            result["macLocalizations"][version["id"]] = collection(
                api, f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations", limit=200)
    for info in infos:
        result["infoLocalizations"][info["id"]] = collection(
            api, f"/appInfos/{info['id']}/appInfoLocalizations", limit=200)
    result["macBuilds"] = collection(api, "/builds", **{
        "filter[app]": APP_ID, "filter[preReleaseVersion.platform]": PLATFORM,
        "include": "preReleaseVersion", "limit": 200})
    OUTPUT.mkdir(parents=True, exist_ok=True)
    save_journal(OUTPUT / "store-before.json", result)
    print(json.dumps({
        "app": {key: app["attributes"].get(key) for key in ("name", "bundleId", "primaryLocale")},
        "versions": [{"id": v["id"], **{key: v["attributes"].get(key) for key in
            ("platform", "versionString", "appStoreState", "appVersionState", "releaseType")}} for v in versions],
        "macLocalizations": {vid: [{"id": item["id"], "locale": item["attributes"]["locale"],
            "hasDescription": bool(item["attributes"].get("description")),
            "supportUrl": item["attributes"].get("supportUrl")} for item in values]
            for vid, values in result["macLocalizations"].items()},
        "infoLocalizations": {iid: [{key: item["attributes"].get(key) for key in
            ("locale", "name", "subtitle", "privacyPolicyUrl")} for item in values]
            for iid, values in result["infoLocalizations"].items()},
        "macBuilds": [{"id": b["id"], "version": b["attributes"].get("version"),
            "processingState": b["attributes"].get("processingState"),
            "uploadedDate": b["attributes"].get("uploadedDate")} for b in result["macBuilds"]],
    }, indent=2, ensure_ascii=False))


def journal(version: str, build: str) -> dict:
    values = json.loads(JOURNAL.read_text()) if JOURNAL.exists() else {}
    identity = {"appId": APP_ID, "platform": PLATFORM, "version": version, "build": build}
    if any(values.get(key, value) != value for key, value in identity.items()):
        raise ReleaseError("The Mac release journal belongs to a different release.")
    values.update(identity)
    return values


def record(version: str, build: str, **fields):
    """Merge only this stage's fields so simultaneous asset/build work is safe."""
    JOURNAL.parent.mkdir(parents=True, exist_ok=True)
    with JOURNAL.with_suffix(".lock").open("a") as lock:
        JOURNAL.with_suffix(".lock").chmod(0o600)
        fcntl.flock(lock, fcntl.LOCK_EX)
        values = journal(version, build)
        values.update(fields)
        save_journal(JOURNAL, values)
    return values


def mac_versions(api):
    versions = collection(api, f"/apps/{APP_ID}/appStoreVersions", **{
        "filter[platform]": PLATFORM, "limit": 200})
    if any(item["attributes"].get("platform") != PLATFORM for item in versions):
        raise ReleaseError("Apple returned a different platform for the Mac version request.")
    return versions


def version_for(api, version: str, *, editable=False):
    matches = [item for item in mac_versions(api) if item["attributes"]["versionString"] == version]
    if len(matches) != 1:
        raise ReleaseError(f"Expected one Mac {version} version; found {len(matches)}.")
    result = matches[0]
    if editable and (result["attributes"].get("appVersionState") or result["attributes"]["appStoreState"]) not in EDITABLE:
        raise ReleaseError("The Mac version is no longer editable.")
    return result


def metadata_from(folder: Path):
    values = {}
    mapping = {"description.txt": "description", "keywords.txt": "keywords",
               "promotional_text.txt": "promotionalText"}
    for directory in sorted(folder.iterdir()):
        if not directory.is_dir():
            continue
        fields = {key: (directory / filename).read_text().strip() for filename, key in mapping.items()}
        if (not fields["description"] or len(fields["description"]) > 4000 or
                not fields["keywords"] or len(fields["keywords"].encode("utf-8")) > 100 or
                len(fields["promotionalText"]) > 170):
            raise ReleaseError(f"Mac listing fields for {directory.name} exceed Apple's limits.")
        values[directory.name] = fields
    return values


def prepare_listing(api, version: str, build: str):
    metadata = metadata_from(METADATA)
    versions = mac_versions(api)
    exact = [item for item in versions if item["attributes"]["versionString"] == version]
    if exact:
        destination = version_for(api, version, editable=True)
    else:
        editable = [item for item in versions if (item["attributes"].get("appVersionState") or
                    item["attributes"]["appStoreState"]) in EDITABLE]
        if len(editable) != 1:
            raise ReleaseError("Expected exactly one existing editable Mac draft to update.")
        destination = editable[0]
    vid = destination["id"]
    locales = collection(api, f"/appStoreVersions/{vid}/appStoreVersionLocalizations", limit=200)
    if {item["attributes"]["locale"] for item in locales} != set(metadata):
        raise ReleaseError("Prepared Mac listing locales do not match the existing draft.")
    values = journal(version, build)
    values["versionId"] = vid
    record(version, build, versionId=vid)
    patch(api, "appStoreVersions", vid, {"versionString": version, "releaseType": "AFTER_APPROVAL"})
    for item in locales:
        locale = item["attributes"]["locale"]
        desired = metadata[locale]
        if any((item["attributes"].get(key) or "").strip() != text for key, text in desired.items()):
            patch(api, "appStoreVersionLocalizations", item["id"], desired)
        print(f"Mac listing: {locale} updated.", flush=True)
    # What's New is unavailable for this platform's first release. Keep local
    # release_notes.txt for future versions, without sending an invalid field.
    values["listingPrepared"] = True
    record(version, build, listingPrepared=True)
    readback = collection(api, f"/appStoreVersions/{vid}/appStoreVersionLocalizations", limit=200)
    for item in readback:
        desired = metadata[item["attributes"]["locale"]]
        if any(item["attributes"].get(key) != value for key, value in desired.items()):
            raise ReleaseError("Mac listing readback did not match the prepared text.")
    print(f"Mac {version}: {len(readback)} localized listings verified; automatic release after approval.")


def screenshot_manifest():
    manifest = json.loads((SCREENSHOT_ROOT / "macos-manifest.json").read_text())
    if manifest.get("platform") != PLATFORM or manifest.get("displayType") != "APP_DESKTOP":
        raise ReleaseError("Screenshot manifest is not a Mac desktop set.")
    if {item["appleLocale"] for item in manifest["sets"]} != {"en-US", "zh-Hans", "zh-Hant"}:
        raise ReleaseError("Expected the three prepared Mac screenshot locales.")
    for item in manifest["sets"]:
        if not 1 <= len(item["screenshots"]) <= 10:
            raise ReleaseError("A Mac screenshot set must contain 1–10 images.")
        for shot in item["screenshots"]:
            path = (SCREENSHOT_ROOT / shot["path"]).resolve()
            if not path.is_relative_to(SCREENSHOT_ROOT.resolve()) or not path.is_file():
                raise ReleaseError("Screenshot path escapes its prepared directory or is missing.")
            if hashlib.sha256(path.read_bytes()).hexdigest() != shot["sha256"]:
                raise ReleaseError("Screenshot content changed after preparation.")
            with Image.open(path) as image:
                if image.size != (2880, 1800) or image.mode != "RGB":
                    raise ReleaseError("Mac screenshots must be opaque RGB 2880×1800.")
    return manifest


def shot_state(shot):
    return (shot["attributes"].get("assetDeliveryState") or {}).get("state")


def upload_screenshot(api, set_id: str, path: Path, reserved_callback=None):
    body = path.read_bytes()
    checksum = hashlib.md5(body).hexdigest()
    shots_path = f"/appScreenshotSets/{set_id}/appScreenshots"
    before = collection(api, shots_path, limit=200)
    matches = [item for item in before if item["attributes"].get("fileName") == path.name and
               item["attributes"].get("sourceFileChecksum") == checksum and
               shot_state(item) in {"COMPLETE", "UPLOAD_COMPLETE"}]
    if matches:
        return next((item for item in matches if shot_state(item) == "COMPLETE"), matches[0])
    pending = [item for item in before if item["attributes"].get("fileName") == path.name and
               item["attributes"].get("fileSize") == len(body) and
               shot_state(item) in {"AWAITING_UPLOAD", "UPLOADING"}]
    if len(pending) > 1:
        raise ReleaseError("Multiple pending reservations match this screenshot; preserved for inspection.")
    if pending:
        reserved = api.call("GET", f"/appScreenshots/{pending[0]['id']}")["data"]
    else:
        if len(before) >= 10:
            raise ReleaseError("Mac screenshot set capacity reached; existing images were preserved.")
        reserved = api.call("POST", "/appScreenshots", json={"data": {
            "type": "appScreenshots", "attributes": {"fileName": path.name, "fileSize": len(body)},
            "relationships": {"appScreenshotSet": linkage("appScreenshotSets", set_id)},
        }}, reconcile=reconcile_created(api, shots_path, before, lambda item:
            item["attributes"].get("fileName") == path.name and
            item["attributes"].get("fileSize") == len(body), limit=200))["data"]
    if reserved_callback:
        reserved_callback(reserved["id"])
    if not reserved["attributes"].get("uploadOperations"):
        raise ReleaseError("The pending screenshot has no upload operations; reservation preserved.")
    for operation in reserved["attributes"].get("uploadOperations", []):
        headers = {item["name"]: item["value"] for item in operation.get("requestHeaders", [])}
        offset, length = operation["offset"], operation["length"]
        response = requests.request(operation["method"], operation["url"], headers=headers,
            data=body[offset:offset + length], timeout=55)
        if not response.ok:
            raise ReleaseError(f"Screenshot byte transfer failed ({response.status_code}).")
    return patch(api, "appScreenshots", reserved["id"], {
        "uploaded": True, "sourceFileChecksum": checksum})["data"]


def upload_screenshots(api, version: str, build: str):
    manifest = screenshot_manifest()
    destination = version_for(api, version, editable=True)
    locales = collection(api, f"/appStoreVersions/{destination['id']}/appStoreVersionLocalizations", limit=200)
    by_locale = {item["attributes"]["locale"]: item for item in locales}
    values = journal(version, build)
    values.setdefault("screenshotSets", {})
    for item in manifest["sets"]:
        locale = item["appleLocale"]
        local_id = by_locale[locale]["id"]
        sets_path = f"/appStoreVersionLocalizations/{local_id}/appScreenshotSets"
        existing = collection(api, sets_path, limit=200)
        desktop = [s for s in existing if s["attributes"]["screenshotDisplayType"] == "APP_DESKTOP"]
        if len(desktop) > 1:
            raise ReleaseError("Multiple Mac desktop screenshot sets found; preserved for inspection.")
        if desktop:
            screenshot_set = desktop[0]
        else:
            screenshot_set = api.call("POST", "/appScreenshotSets", json={"data": {
                "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": "APP_DESKTOP"},
                "relationships": {"appStoreVersionLocalization": linkage("appStoreVersionLocalizations", local_id)},
            }}, reconcile=reconcile_created(api, sets_path, existing,
                lambda entry: entry["attributes"]["screenshotDisplayType"] == "APP_DESKTOP", limit=200))["data"]
        sid = screenshot_set["id"]
        ids = []
        for shot in item["screenshots"]:
            path = SCREENSHOT_ROOT / shot["path"]
            def record_reservation(resource_id):
                values["screenshotSets"][locale] = {"id": sid, "screenshots": [*ids, resource_id], "complete": False}
                record(version, build, screenshotSets=values["screenshotSets"])
            uploaded = upload_screenshot(api, sid, path, record_reservation)
            ids.append(uploaded["id"])
            values["screenshotSets"][locale] = {"id": sid, "screenshots": ids, "complete": False}
            record(version, build, screenshotSets=values["screenshotSets"])
            print(f"Mac screenshot: {locale} {path.name} transferred.", flush=True)
        deadline = time.monotonic() + 900
        while True:
            stored = collection(api, f"/appScreenshotSets/{sid}/appScreenshots", limit=200)
            chosen = {entry["id"]: entry for entry in stored if entry["id"] in ids}
            if len(chosen) != len(ids):
                raise ReleaseError("Reserved Mac screenshot disappeared during processing.")
            if any(shot_state(entry) in {"FAILED", "ERROR"} for entry in chosen.values()):
                raise ReleaseError("Apple rejected a Mac screenshot during processing.")
            if all(shot_state(entry) == "COMPLETE" for entry in chosen.values()):
                break
            if time.monotonic() >= deadline:
                raise ReleaseError("Mac screenshot processing timed out; reservations preserved for resuming.")
            time.sleep(10)
        if any(entry["id"] not in ids for entry in stored):
            raise ReleaseError("Existing Mac screenshots remain; no unrequested deletion was performed.")
        api.call("PATCH", f"/appScreenshotSets/{sid}/relationships/appScreenshots", json={
            "data": [{"type": "appScreenshots", "id": resource_id} for resource_id in ids]})
        readback = collection(api, f"/appScreenshotSets/{sid}/appScreenshots", limit=200)
        if [entry["id"] for entry in readback] != ids or any(shot_state(entry) != "COMPLETE" for entry in readback):
            raise ReleaseError("Mac screenshot order or completion state failed verification.")
        values["screenshotSets"][locale]["complete"] = True
        record(version, build, screenshotSets=values["screenshotSets"])
        print(f"Mac screenshots: {locale}, {len(ids)} ordered images verified.", flush=True)


def package_action(api, helper: Path, package: Path, action: str, version: str, build: str):
    if not package.is_file() or package.suffix != ".pkg":
        raise ReleaseError("The Mac upload requires a verified .pkg file.")
    values = journal(version, build)
    digest = hashlib.sha256(package.read_bytes()).hexdigest()
    if action == "upload-package":
        if not values.get("packageValidated") or values.get("packageSha256") != digest:
            raise ReleaseError("Validate this exact package with Apple before uploading it.")
        if values.get("packageUploaded"):
            print("This exact Mac package was already uploaded; checking its build status is the next step.")
            return
    from build_macos_release import inspect_package
    inspect_package(package, version, build)
    key_id, issuer, key_path = credentials(helper)
    arguments = ["xcrun", "altool", "--validate-app" if action == "validate-package" else "--upload-package",
        str(package), "--api-key", key_id, "--api-issuer", issuer,
        "--p8-file-path", str(key_path), "--output-format", "json"]
    print(f"Apple Mac package {'validation' if action == 'validate-package' else 'upload'} started.", flush=True)
    result = subprocess.run(arguments, cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace")
    safe = api.safe(result.stdout)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    log_path = OUTPUT / f"{action}.log"
    log_path.write_text(safe)
    log_path.chmod(0o600)
    if result.returncode:
        print(safe[-8000:], file=sys.stderr)
        raise ReleaseError(f"Apple package operation failed ({result.returncode}).")
    values = journal(version, build)
    values["packagePath"] = str(package)
    values["packageSha256"] = digest
    values["packageValidated" if action == "validate-package" else "packageUploaded"] = True
    record(version, build, packagePath=str(package), packageSha256=digest,
           **{"packageValidated" if action == "validate-package" else "packageUploaded": True})
    print(f"Mac package {'validated' if action == 'validate-package' else 'uploaded'} successfully.", flush=True)


def status(api, version: str, build: str):
    versions = mac_versions(api)
    matches = collection(api, "/builds", **{
        "filter[app]": APP_ID, "filter[version]": build,
        "filter[preReleaseVersion.version]": version,
        "filter[preReleaseVersion.platform]": PLATFORM, "limit": 200})
    print(json.dumps({"versions": [{"id": item["id"], "version": item["attributes"]["versionString"],
        "state": item["attributes"].get("appVersionState") or item["attributes"]["appStoreState"]}
        for item in versions], "builds": [{"id": item["id"], "state": item["attributes"]["processingState"],
        "build": item["attributes"]["version"], "usesNonExemptEncryption": item["attributes"].get("usesNonExemptEncryption")}
        for item in matches]}, indent=2))
    return matches


def verified_build(api, version: str, build: str):
    result = collection_response(api, "/builds", **{
        "filter[app]": APP_ID, "filter[version]": build,
        "filter[preReleaseVersion.version]": version,
        "filter[preReleaseVersion.platform]": PLATFORM,
        "include": "app,preReleaseVersion", "limit": 200})
    if len(result["data"]) != 1:
        raise ReleaseError(f"Expected one processed Mac {version} ({build}) build; found {len(result['data'])}.")
    item = result["data"][0]
    prereleases = {entry["id"]: entry for entry in result.get("included", [])
                   if entry["type"] == "preReleaseVersions"}
    relationships = item.get("relationships", {})
    prerelease = prereleases.get((relationships.get("preReleaseVersion", {}).get("data") or {}).get("id"))
    if (item["attributes"].get("version") != build or
            (relationships.get("app", {}).get("data") or {}).get("id") != APP_ID or
            not prerelease or prerelease["attributes"].get("platform") != PLATFORM or
            prerelease["attributes"].get("version") != version):
        raise ReleaseError("The selected build does not match the exact Mac app/version/build.")
    if item["attributes"].get("processingState") != "VALID" or item["attributes"].get("expired"):
        raise ReleaseError(f"Mac build is not ready ({item['attributes'].get('processingState')}).")
    return item


def verify_screenshots(api, values: dict):
    expected = screenshot_manifest()
    saved = values.get("screenshotSets", {})
    for item in expected["sets"]:
        locale = item["appleLocale"]
        screenshot_set = saved.get(locale, {})
        if not screenshot_set.get("complete") or len(screenshot_set.get("screenshots", [])) != len(item["screenshots"]):
            raise ReleaseError(f"Mac screenshots for {locale} have not finished preparation.")
        shots = collection(api, f"/appScreenshotSets/{screenshot_set['id']}/appScreenshots", limit=200)
        if [shot["id"] for shot in shots] != screenshot_set["screenshots"]:
            raise ReleaseError("Mac screenshot order changed after preparation.")
        for shot, local in zip(shots, item["screenshots"]):
            checksum = hashlib.md5((SCREENSHOT_ROOT / local["path"]).read_bytes()).hexdigest()
            if shot_state(shot) != "COMPLETE" or shot["attributes"].get("sourceFileChecksum") != checksum:
                raise ReleaseError("Mac screenshot content or completion state changed after preparation.")


REVIEW_NOTES = """macOS 1.8.0 review notes:
Build 19 responds to the Guideline 2.1(a) and Guideline 4 findings in submission 02b846f6-c1db-46bf-821d-e522aa66c859. Closing the main window now quits Onlynote through macOS's standard termination. The previous build asked the Flutter engine whether it could exit and then terminated from inside that reply, which started a second overlapping exit request and could leave the app running with no window. Onlynote is a single-window app, so closing its window quits it and there is no window left to reopen. The wait for unsaved notes during quit is now bounded as well, so a save that cannot finish can no longer hold the quit open.

This is Onlynote's first native Mac release under the existing universal purchase app record. No account or sign-in is required. The app supports macOS 12 or later; its native desktop widgets require macOS 14 or later.

To test widgets, launch Onlynote once, create a note or checklist, then add Onlynote's Note or Overview widget from Edit Widgets. Select a note through Edit Widget, or use the default note. Checklist items can be toggled in the widget. Widget links open the selected note in Onlynote.

The Mac app is ad-free. The existing non-consumable Premium product com.appsbay.onlynote.remove_ads unlocks unlimited notes, folders and templates, voice transcription, and additional card styles. Purchases can be restored. The free version supports 10 notes, 3 folders and 3 templates.

Libraries are local to each device. Settings provides .onlynote backup export/import for transferring notes. There is no automatic cross-device sync. Image text recognition uses Apple's Vision framework. Voice transcription requests on-device recognition where supported by the selected language. Microphone, speech and notification permissions are requested only for the corresponding feature.
"""


def prepare_review(api, version: str, build: str):
    destination = version_for(api, version, editable=True)
    values = journal(version, build)
    if values.get("versionId") != destination["id"] or not values.get("listingPrepared"):
        raise ReleaseError("Prepare this exact Mac listing before attaching a build.")
    metadata = metadata_from(METADATA)
    locales = collection(api, f"/appStoreVersions/{destination['id']}/appStoreVersionLocalizations", limit=200)
    if {entry["attributes"]["locale"] for entry in locales} != set(metadata):
        raise ReleaseError("Mac listing locales changed before review preparation.")
    for entry in locales:
        if any(entry["attributes"].get(key) != text for key, text in metadata[entry["attributes"]["locale"]].items()):
            raise ReleaseError("Mac listing content changed before review preparation.")
    verify_screenshots(api, values)
    selected = verified_build(api, version, build)
    if selected["attributes"].get("usesNonExemptEncryption") is not False:
        raise ReleaseError("The uploaded Mac build's encryption declaration does not match its Info.plist.")
    detail = api.call("GET", f"/appStoreVersions/{destination['id']}/appStoreReviewDetail")["data"]
    required = ("contactFirstName", "contactLastName", "contactPhone", "contactEmail")
    if not detail or any(not detail["attributes"].get(key) for key in required):
        raise ReleaseError("The Mac review contact details are incomplete.")
    if detail["attributes"].get("demoAccountRequired"):
        raise ReleaseError("The existing Mac review details require a demo account; inspect before changing them.")
    # This draft inherited iOS tracking-permission instructions. Replace only
    # the Mac version's notes with the actual native Mac review flow.
    notes = REVIEW_NOTES.strip()
    if len(notes) > 4000:
        raise ReleaseError("Existing and prepared Mac review notes exceed Apple's limit.")
    patch(api, "appStoreReviewDetails", detail["id"], {"notes": notes})
    api.call("PATCH", f"/appStoreVersions/{destination['id']}/relationships/build",
             json=linkage("builds", selected["id"]))
    patch(api, "appStoreVersions", destination["id"], {"releaseType": "AFTER_APPROVAL"})
    attached = api.call("GET", f"/appStoreVersions/{destination['id']}/build")["data"]
    if attached["id"] != selected["id"]:
        raise ReleaseError("The exact Mac build attachment failed verification.")
    values["buildId"] = selected["id"]
    values["reviewPrepared"] = True
    record(version, build, buildId=selected["id"], reviewPrepared=True)
    print(f"Mac {version} ({build}): exact build attached, reviewer notes and all listing assets verified.", flush=True)


def submit_mac_review(api, version: str, build: str):
    destination = version_for(api, version)
    version_id = destination["id"]
    values = journal(version, build)
    if values.get("versionId") != version_id or not values.get("reviewPrepared"):
        raise ReleaseError("Prepare this exact Mac release for review first.")
    if destination["attributes"].get("releaseType") != "AFTER_APPROVAL":
        raise ReleaseError("This Mac version is not configured for automatic release after approval.")
    selected = verified_build(api, version, build)
    attached = api.call("GET", f"/appStoreVersions/{version_id}/build")["data"]
    if selected["id"] != values.get("buildId") or attached["id"] != selected["id"]:
        raise ReleaseError("The Mac release's build attachment changed before submission.")
    verify_screenshots(api, values)
    reviews_path = f"/apps/{APP_ID}/reviewSubmissions"
    params = {"include": "items,appStoreVersionForReview", "limit": 200}
    result = collection_response(api, reviews_path, **params)
    item_map = {item["id"]: item for item in result.get("included", []) if item["type"] == "reviewSubmissionItems"}
    submission, has_version = None, False
    for candidate in result["data"]:
        if candidate["attributes"].get("platform") != PLATFORM:
            continue
        state = candidate["attributes"]["state"]
        # A finished submission is this version's history, not this release.
        # A rejected or cancelled one ends as COMPLETE keeping its original
        # submitted date, and Apple stops returning its items' relationships,
        # so neither its contents nor its date say anything about the build
        # being released now. Reading one as an existing submission reported a
        # resubmission as already submitted without sending anything.
        if state in FINISHED_REVIEW_STATES:
            continue
        items = [item_map.get(link["id"]) for link in candidate.get("relationships", {}).get("items", {}).get("data", [])]
        version_link = (candidate.get("relationships", {}).get("appStoreVersionForReview", {}).get("data") or {}).get("id")
        matches = version_link == version_id or any(item and
            (item.get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") == version_id for item in items)
        owned = candidate["id"] == values.get("reviewSubmissionId")
        if not matches and not owned:
            continue
        if state in LIVE_REVIEW_STATES and matches:
            values.update(reviewSubmissionId=candidate["id"], reviewSubmitted=True, reviewState=state)
            record(version, build, reviewSubmissionId=candidate["id"], reviewSubmitted=True, reviewState=state)
            print(f"Mac release already submitted ({state}); no duplicate submission created.", flush=True)
            return
        # What a submission is doing decides what to say about it; only the one
        # about to carry this release is inspected for its contents. Checking
        # items first described a rejection as unexpected items.
        if state != "READY_FOR_REVIEW":
            raise ReleaseError(f"Existing Mac review submission is {state}; preserved for inspection.")
        if items and (len(items) != 1 or not items[0] or
                (items[0].get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") != version_id):
            raise ReleaseError("The matching Mac review submission contains different or additional items.")
        submission, has_version = candidate, matches
        break
    state = destination["attributes"].get("appVersionState") or destination["attributes"]["appStoreState"]
    if state not in EDITABLE and not (state == "READY_FOR_REVIEW" and submission and has_version):
        raise ReleaseError(f"Mac version is {state}; a matching active submission could not be verified.")
    if submission is None:
        submission = api.call("POST", "/reviewSubmissions", json={"data": {
            "type": "reviewSubmissions", "attributes": {"platform": PLATFORM},
            "relationships": {"app": linkage("apps", APP_ID)},
        }}, reconcile=reconcile_created(api, reviews_path, result["data"], lambda item:
            item["attributes"].get("platform") == PLATFORM and item["attributes"].get("state") == "READY_FOR_REVIEW" and
            not item.get("relationships", {}).get("items", {}).get("data"), **params))["data"]
    values["reviewSubmissionId"] = submission["id"]
    record(version, build, reviewSubmissionId=submission["id"])
    if not has_version:
        items_path = f"/reviewSubmissions/{submission['id']}/items"
        before = collection(api, items_path, limit=200)
        if before:
            raise ReleaseError("The Mac submission gained another item; no items changed.")
        api.call("POST", "/reviewSubmissionItems", json={"data": {
            "type": "reviewSubmissionItems", "relationships": {
                "reviewSubmission": linkage("reviewSubmissions", submission["id"]),
                "appStoreVersion": linkage("appStoreVersions", version_id),
            },
        }}, reconcile=reconcile_created(api, items_path, before, lambda item:
            (item.get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") == version_id, limit=200))
    current = collection(api, f"/reviewSubmissions/{submission['id']}/items", include="appStoreVersion", limit=200)
    if len(current) != 1 or (current[0].get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id") != version_id:
        raise ReleaseError("The Mac review submission's exact single item changed; no submission performed.")
    submitted = patch(api, "reviewSubmissions", submission["id"], {"submitted": True},
        reconcile=lambda: reconcile_submitted_review(api, submission["id"], version_id))["data"]
    values.update(reviewSubmitted=True, reviewState=submitted["attributes"]["state"])
    record(version, build, reviewSubmitted=True, reviewState=submitted["attributes"]["state"])
    print(f"Mac App Review submission state: {submitted['attributes']['state']}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["inspect", "prepare-listing", "upload-screenshots",
        "validate-package", "upload-package", "prepare-review", "submit-review", "status"])
    parser.add_argument("--version", default="1.8.0")
    parser.add_argument("--build", default="18")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--package", type=Path)
    parser.add_argument("--credentials-helper", type=Path, default=DEFAULT_HELPER)
    args = parser.parse_args()
    api = None
    try:
        if args.action not in {"inspect", "status"} and not args.execute:
            print(f"Plan only: Mac {args.version} ({args.build}) {args.action}. Pass --execute for the authorized release action.")
            return 0
        api = MacAppleApi(args.credentials_helper)
        if args.action == "inspect":
            inspect(api)
        elif args.action == "status":
            status(api, args.version, args.build)
        elif args.action == "prepare-listing":
            prepare_listing(api, args.version, args.build)
        elif args.action == "upload-screenshots":
            upload_screenshots(api, args.version, args.build)
        elif args.action == "prepare-review":
            prepare_review(api, args.version, args.build)
        elif args.action == "submit-review":
            submit_mac_review(api, args.version, args.build)
        elif args.action in {"validate-package", "upload-package"}:
            if args.package is None:
                raise ReleaseError("Package validation/upload requires --package.")
            package_action(api, args.credentials_helper, args.package.resolve(), args.action, args.version, args.build)
        return 0
    except Exception as error:
        message = str(error) if isinstance(error, ReleaseError) else f"Mac release failed ({type(error).__name__})."
        print(api.safe(message) if api else message, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
