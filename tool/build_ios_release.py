#!/usr/bin/env python3
"""Archive and export locally using existing App Store Connect credentials.

Reads the credential constants from the local asc_token.py helper without
executing it. Xcode output is redacted before being written to disk or stdout.
The export uses ios/ExportOptions.plist and never uploads the resulting IPA.
"""

from __future__ import annotations

import argparse
import ast
from collections import deque
from datetime import datetime, timezone
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import time
import zipfile


REPO = Path(__file__).resolve().parents[1]


def credentials(helper: Path) -> tuple[str, str, Path]:
    constants = {}
    for statement in ast.parse(helper.read_text()).body:
        if not isinstance(statement, ast.Assign):
            continue
        for target in statement.targets:
            if isinstance(target, ast.Name) and target.id in {
                "KEY_ID", "ISSUER", "KEY_PATH"
            }:
                constants[target.id] = ast.literal_eval(statement.value)
    key_id, issuer, key_path = (
        constants["KEY_ID"],
        constants["ISSUER"],
        Path(constants["KEY_PATH"]).expanduser(),
    )
    if not all(isinstance(value, str) and value for value in (key_id, issuer)):
        raise ValueError("Credential constants are unavailable")
    if not key_path.is_file():
        raise ValueError("Configured authentication key is unavailable")
    return key_id, issuer, key_path


def redact(value: str, secrets: tuple[str, ...]) -> str:
    for secret in sorted(secrets, key=len, reverse=True):
        if secret:
            value = value.replace(secret, "[REDACTED]")
    value = re.sub(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", "[REDACTED JWT]", value)
    value = re.sub(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", "[REDACTED ACCOUNT]", value)
    return value


def installed_signing_profiles() -> tuple[dict[str, str], dict[str, str]]:
    """Select the installed store profiles only for the three application targets."""
    targets = {
        "Runner": "com.appsbay.onlynote",
        "OnlynoteShare": "com.appsbay.onlynote.OnlynoteShare",
        "OnlynoteWidget": "com.appsbay.onlynote.OnlynoteWidget",
    }
    profiles = {}
    roots = [
        Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
        Path.home() / "Library/MobileDevice/Provisioning Profiles",
    ]
    for root in roots:
        for path in root.glob("*.mobileprovision"):
            raw = path.read_bytes()
            start, end = raw.find(b"<?xml"), raw.find(b"</plist>")
            if start < 0 or end < 0:
                continue
            profile = plistlib.loads(raw[start:end + len(b"</plist>")])
            entitlements = profile.get("Entitlements", {})
            if profile.get("IsXcodeManaged", False):
                continue
            if entitlements.get("get-task-allow", False) or profile.get("ProvisionedDevices"):
                continue
            if profile.get("ExpirationDate", datetime.min).replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
                continue
            if "group.com.appsbay.onlynote" not in entitlements.get("com.apple.security.application-groups", []):
                continue
            identifier = entitlements.get("application-identifier", "")
            for target, bundle_id in targets.items():
                if identifier == "F694X76A5X." + bundle_id:
                    profiles[target] = profile["UUID"]
    if set(profiles) != set(targets):
        raise ValueError("Installed App Store profiles are missing for " + ", ".join(set(targets) - set(profiles)))
    return targets, profiles


def installed_signing_overlay() -> Path:
    targets, profiles = installed_signing_profiles()
    lines = [
        "// Local build overlay; repository signing configuration is unchanged.",
        "DEVELOPMENT_TEAM = F694X76A5X",
        "CODE_SIGN_STYLE = Manual",
        "CODE_SIGN_IDENTITY = Apple Distribution",
        "CODE_SIGNING_ALLOWED = $(ONLYNOTE_SIGNING_ALLOWED_$(TARGET_NAME):default=NO)",
        "PROVISIONING_PROFILE_SPECIFIER = $(ONLYNOTE_PROFILE_$(TARGET_NAME))",
    ]
    for target in targets:
        lines.extend([
            f"ONLYNOTE_SIGNING_ALLOWED_{target} = YES",
            f"ONLYNOTE_PROFILE_{target} = {profiles[target]}",
        ])
    destination = REPO / "build/ios/offline-signing.xcconfig"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(lines) + "\n")
    print("Selected installed App Store profiles for Runner, OnlynoteShare, and OnlynoteWidget.", flush=True)
    return destination


def manual_export_options(original: dict) -> Path:
    targets, profiles = installed_signing_profiles()
    options = dict(original)
    options.update({
        "destination": "export",
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "manageAppVersionAndBuildNumber": False,
        "provisioningProfiles": {
            bundle_id: profiles[target] for target, bundle_id in targets.items()
        },
    })
    destination = REPO / "build/ios/ManualExportOptions.plist"
    with destination.open("wb") as output:
        plistlib.dump(options, output)
    print("Prepared local manual export mapping for the three installed profiles.", flush=True)
    return destination


def run_xcode(stage: str, arguments: list[str], secrets: tuple[str, ...], log) -> bool:
    print(f"{stage} started.", flush=True)
    log.write(f"\n{stage}\n")
    started = time.monotonic()
    tail: deque[str] = deque(maxlen=35)
    process = subprocess.Popen(
        ["xcrun", "xcodebuild", *arguments],
        cwd=REPO,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
        # Distribution payloads must remain readable to installed-app users,
        # even when a credential-safe caller uses a private parent umask.
        umask=0o022,
    )
    assert process.stdout is not None
    for line in process.stdout:
        safe = redact(line, secrets)
        log.write(safe)
        log.flush()
        tail.append(safe.rstrip())
        if any(marker in safe for marker in ("error:", "** ARCHIVE", "** EXPORT", "EXPORT SUCCEEDED")):
            print(safe.rstrip(), flush=True)
    status = process.wait()
    print(f"{stage} finished in {time.monotonic() - started:.0f}s (exit {status}).", flush=True)
    if status:
        print("Recent redacted Xcode output:", flush=True)
        for line in tail:
            print(line, flush=True)
    return status == 0


def inspect_ipa(path: Path) -> None:
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        app_info = next(
            name for name in names
            if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", name)
        )
        info = plistlib.loads(archive.read(app_info))
        print(
            f"IPA: {path}\n"
            f"Size: {path.stat().st_size / 1024 / 1024:.1f} MiB\n"
            f"Version: {info.get('CFBundleShortVersionString')} "
            f"({info.get('CFBundleVersion')})\n"
            f"Bundle: {info.get('CFBundleIdentifier')}",
            flush=True,
        )
        for name in names:
            if not name.endswith("/embedded.mobileprovision"):
                continue
            raw = archive.read(name)
            start = raw.find(b"<?xml")
            end = raw.find(b"</plist>", start)
            profile = plistlib.loads(raw[start:end + len(b"</plist>")])
            entitlements = profile.get("Entitlements", {})
            print(
                f"Profile: {entitlements.get('application-identifier')}; "
                f"distribution={not entitlements.get('get-task-allow', False)}; "
                f"App Group={'group.com.appsbay.onlynote' in entitlements.get('com.apple.security.application-groups', [])}",
                flush=True,
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--credentials-helper", type=Path,
        default=Path.home() / "Development/secret/AppStoreConnect_API_keys/asc_token.py",
    )
    parser.add_argument("--export-only", action="store_true")
    parser.add_argument(
        "--manual-export", action="store_true",
        help="Use a local copy of ExportOptions with explicit installed profile mappings.",
    )
    parser.add_argument(
        "--installed-signing-assets", action="store_true",
        help="Use installed signing profiles and certificates, without Xcode API provisioning.",
    )
    args = parser.parse_args()
    export_options_path = REPO / "ios/ExportOptions.plist"
    with export_options_path.open("rb") as source:
        export_options = plistlib.load(source)
    if export_options.get("destination", "export") != "export":
        print("ExportOptions must use the local export destination; upload is disabled.", file=sys.stderr)
        return 1
    print("Export destination verified: local export (no upload).", flush=True)
    try:
        key_id, issuer, key_path = credentials(args.credentials_helper)
    except Exception:
        print("Unable to read the existing authentication helper/key. No credentials were printed.", file=sys.stderr)
        return 1

    secrets = (key_id, issuer, str(key_path), key_path.name)
    authentication = [
        "-allowProvisioningUpdates",
        "-authenticationKeyPath", str(key_path),
        "-authenticationKeyID", key_id,
        "-authenticationKeyIssuerID", issuer,
    ]
    archive_overrides = []
    if args.installed_signing_assets:
        authentication = []
        archive_overrides = ["-xcconfig", str(installed_signing_overlay())]
    if args.manual_export:
        export_options_path = manual_export_options(export_options)
    archive_path = REPO / "build/ios/archive/Runner.xcarchive"
    export_path = REPO / "build/ios/ipa"
    log_path = REPO / "build/ios/release-build.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.touch(mode=0o600, exist_ok=True)
    log_path.chmod(0o600)
    try:
        with log_path.open("a") as log:
            if not args.export_only and not run_xcode(
                "Archive",
                [
                    "-workspace", "ios/Runner.xcworkspace",
                    "-scheme", "Runner",
                    "-configuration", "Release",
                    "-destination", "generic/platform=iOS",
                    "-archivePath", str(archive_path),
                    *authentication,
                    *archive_overrides,
                    "archive",
                ],
                secrets, log,
            ):
                return 1
            if not run_xcode(
                "Export",
                [
                    "-exportArchive",
                    "-archivePath", str(archive_path),
                    "-exportOptionsPlist", str(export_options_path),
                    "-exportPath", str(export_path),
                    *authentication,
                ],
                secrets, log,
            ):
                return 1
        ipas = sorted(export_path.glob("*.ipa"), key=lambda path: path.stat().st_mtime)
        if not ipas:
            print("Xcode returned success but no exported IPA was found.", file=sys.stderr)
            return 1
        inspect_ipa(ipas[-1])
        print(f"Redacted build log: {log_path}", flush=True)
        return 0
    except Exception as error:
        print(redact(f"Release build failed: {type(error).__name__}: {error}", secrets), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
