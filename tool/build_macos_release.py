#!/usr/bin/env python3
"""Archive, export, and verify a Mac App Store package; never upload it.

Default invocation is a read-only dry run: no credentials are loaded, no Flutter
or Xcode command is executed, and no files are written. --execute performs the
local build/export and authorizes Xcode's automatic API provisioning as part of
the requested release. It does not submit an app, upload a package, or change
App Store listing metadata. The existing asc_token.py is parsed as constants
without executing it; private key contents are never read by this script.

First build the release app with Flutter, then run, for example:
  python3 tool/build_macos_release.py --execute --skip-flutter-config
Use --version/--build to override pubspec.yaml and --export-only to reuse an
already verified archive. --manual-export uses installed Mac App Store profiles
and certificates without Xcode cloud signing or API provisioning during export.
Logs redact authentication and signing account data.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import fnmatch
from pathlib import Path
import plistlib
import re
import stat
import subprocess
import sys
import tempfile

# Keep the read-only dry run free of imported-module cache writes too.
sys.dont_write_bytecode = True

try:
    from .build_ios_release import credentials, redact, run_xcode
except ImportError:
    from build_ios_release import credentials, redact, run_xcode


REPO = Path(__file__).resolve().parents[1]
TEAM = "F694X76A5X"
BUNDLE = "com.appsbay.onlynote"
GROUP = f"{TEAM}.{BUNDLE}"
TARGETS = {
    "Onlynote": (BUNDLE, "12.0"),
    "OnlynoteWidget": (f"{BUNDLE}.OnlynoteWidget", "14.0"),
}


class BuildError(Exception):
    pass


def release_version(version: str | None, build: str | None) -> tuple[str, str]:
    match = re.search(
        r"^version:\s*[\"']?(\d+\.\d+\.\d+)\+(\d+)[\"']?\s*(?:#.*)?$",
        (REPO / "pubspec.yaml").read_text(), re.MULTILINE,
    )
    if not match:
        raise BuildError("pubspec.yaml must contain a version and numeric build number.")
    version, build = version or match[1], build or match[2]
    if not re.fullmatch(r"\d+\.\d+\.\d+", version) or not re.fullmatch(r"\d+", build):
        raise BuildError("Version must be three numeric components; build must be numeric.")
    return version, build


def export_options(path: Path) -> dict:
    options = plistlib.loads(path.read_bytes())
    if options.get("destination") != "export":
        raise BuildError("Mac ExportOptions must use destination=export; upload is disabled.")
    if options.get("method") != "app-store-connect" or options.get("teamID") != TEAM:
        raise BuildError("Mac ExportOptions must use the expected App Store method and team.")
    if options.get("manageAppVersionAndBuildNumber") is not False:
        raise BuildError("Mac export must preserve the explicitly selected version/build.")
    return options


def command(arguments: list[str]) -> subprocess.CompletedProcess:
    """Capture tool output; callers only print validated summaries or redacted logs."""
    result = subprocess.run(arguments, cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise BuildError(f"{Path(arguments[0]).name} verification failed (exit {result.returncode}).")
    return result


def signing_secrets() -> tuple[str, ...]:
    """Collect public identity labels privately to redact account names in Xcode output."""
    output = command(["security", "find-identity", "-v", "-p", "basic"]).stdout.decode(errors="replace")
    result = []
    for fingerprint, label in re.findall(r'\b([A-F0-9]{40})\s+"([^"]+)"', output):
        result.extend((fingerprint, label))
        if ": " in label:
            account = label.split(": ", 1)[1].rsplit(" (", 1)[0]
            if account:
                result.append(account)
    return tuple(result)


def installed_manual_export_options(original: dict, output: Path) -> Path:
    """Use installed certificate hashes and matching Mac store profiles offline."""
    identities = command(["security", "find-identity", "-v", "-p", "basic"]).stdout.decode(errors="replace")
    labels = re.findall(r'\b([A-F0-9]{40})\s+"([^"]+)"', identities)
    signing = [digest for digest, label in labels if label.startswith("3rd Party Mac Developer Application:") and label.endswith(f"({TEAM})")]
    installer = [digest for digest, label in labels if label.startswith("3rd Party Mac Developer Installer:") and label.endswith(f"({TEAM})")]
    if len(signing) != 1 or len(installer) != 1:
        raise BuildError("Manual Mac export requires one installed app and installer distribution identity for this team.")
    import hashlib
    profiles: dict[str, tuple[datetime, str]] = {}
    roots = [Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
             Path.home() / "Library/MobileDevice/Provisioning Profiles"]
    for root in roots:
        for path in root.glob("*.provisionprofile"):
            raw = subprocess.run(["security", "cms", "-D", "-i", str(path)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if raw.returncode:
                continue
            try:
                profile = plist_from_output(raw.stdout)
                entitlements = profile.get("Entitlements", {})
                expiry = profile["ExpirationDate"].replace(tzinfo=timezone.utc)
            except (BuildError, KeyError, ValueError, AttributeError):
                continue
            certs = {hashlib.sha1(cert).hexdigest().upper() for cert in profile.get("DeveloperCertificates", [])}
            if ("OSX" not in profile.get("Platform", []) or TEAM not in profile.get("TeamIdentifier", []) or
                    expiry <= datetime.now(timezone.utc) or signing[0] not in certs or
                    profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices") or
                    entitlements.get("get-task-allow") or entitlements.get("com.apple.security.get-task-allow")):
                continue
            identifier = entitlements.get("com.apple.application-identifier", entitlements.get("application-identifier", ""))
            for bundle, _ in TARGETS.values():
                if identifier == f"{TEAM}.{bundle}" and (bundle not in profiles or expiry > profiles[bundle][0]):
                    profiles[bundle] = (expiry, profile["UUID"])
    if set(profiles) != {bundle for bundle, _ in TARGETS.values()}:
        raise BuildError("Installed Mac App Store profiles are missing for Runner or widget; fetch/create matching MAC_APP_STORE profiles first.")
    options = {**original, "signingStyle": "manual", "signingCertificate": signing[0],
               "installerSigningCertificate": installer[0],
               "provisioningProfiles": {bundle: value[1] for bundle, value in profiles.items()}}
    destination = output / "ManualExportOptions.plist"
    destination.touch(mode=0o600, exist_ok=True)
    destination.chmod(0o600)
    destination.write_bytes(plistlib.dumps(options))
    print("Manual export selected installed Mac app/installer certificates and both store profiles; cloud signing disabled.", flush=True)
    return destination


def plist_from_output(output: bytes) -> dict:
    start, end = output.find(b"<?xml"), output.find(b"</plist>")
    if start < 0 or end < start:
        raise BuildError("Signing tool returned no readable entitlement/profile plist.")
    return plistlib.loads(output[start:end + len(b"</plist>")])


def inspect_profile(path: Path, bundle: str) -> bool:
    if not path.is_file():
        # A team-prefixed macOS App Group is unrestricted. Its entitlement alone
        # does not require an embedded provisioning profile.
        return False
    profile = plist_from_output(command(["security", "cms", "-D", "-i", str(path)]).stdout)
    entitlements = profile.get("Entitlements", {})
    expiry = profile.get("ExpirationDate")
    if not isinstance(expiry, datetime) or expiry.replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
        raise BuildError("Embedded Mac provisioning profile is expired or has no expiration.")
    if (profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices") or
            entitlements.get("get-task-allow") or entitlements.get("com.apple.security.get-task-allow")):
        raise BuildError("Exported package contains a non-store provisioning profile.")
    identifier = entitlements.get("com.apple.application-identifier", entitlements.get("application-identifier", ""))
    if TEAM not in profile.get("TeamIdentifier", []) or not fnmatch.fnmatchcase(f"{TEAM}.{bundle}", identifier):
        raise BuildError("Embedded profile does not authorize the expected team/bundle.")
    return True


def inspect_bundle(app: Path, version: str, build: str, *, distribution: bool) -> None:
    command(["codesign", "--verify", "--deep", "--strict", str(app)])
    bundles = {
        "Onlynote": app,
        "OnlynoteWidget": app / "Contents/PlugIns/OnlynoteWidget.appex",
    }
    for target, bundle_path in bundles.items():
        info_path = bundle_path / "Contents/Info.plist"
        if not info_path.is_file():
            raise BuildError(f"{target} is missing from the Mac app package.")
        info = plistlib.loads(info_path.read_bytes())
        bundle, min_os = TARGETS[target]
        if (info.get("CFBundleIdentifier") != bundle or
                info.get("CFBundleShortVersionString") != version or str(info.get("CFBundleVersion")) != build):
            raise BuildError(f"{target} bundle ID or version/build does not match this release.")
        if info.get("LSMinimumSystemVersion") != min_os or info.get("OnlynoteWidgetAppGroup") != GROUP:
            raise BuildError(f"{target} minimum OS or shared App Group does not match the release config.")
        if target == "Onlynote" and info.get("LSApplicationCategoryType") != "public.app-category.productivity":
            raise BuildError("The Mac app category must be Productivity for this listing.")
        executable = bundle_path / "Contents/MacOS" / info["CFBundleExecutable"]
        architectures = command(["lipo", "-archs", str(executable)]).stdout.decode().split()
        if not {"arm64", "x86_64"}.issubset(architectures):
            raise BuildError(f"{target} must include both Apple Silicon and Intel architectures.")
        command(["codesign", "--verify", "--strict", str(bundle_path)])
        signature_result = command(["codesign", "--display", "--verbose=4", str(bundle_path)])
        signature = (signature_result.stdout + signature_result.stderr).decode(errors="replace")
        if f"TeamIdentifier={TEAM}" not in signature:
            raise BuildError(f"{target} is not signed by the expected developer team.")
        if distribution and not re.search(r"^Authority=(?:Apple Distribution|3rd Party Mac Developer Application):", signature, re.MULTILINE):
            raise BuildError(f"{target} does not have a Mac App Store distribution signature.")
        signed = command(["codesign", "--display", "--entitlements", ":-", str(bundle_path)])
        entitlements = plist_from_output(signed.stdout + signed.stderr)
        if entitlements.get("com.apple.security.app-sandbox") is not True or GROUP not in entitlements.get("com.apple.security.application-groups", []):
            raise BuildError(f"{target} signature does not authorize its sandbox and shared widget group.")
        if distribution and (entitlements.get("get-task-allow") or entitlements.get("com.apple.security.get-task-allow")):
            raise BuildError(f"{target} distribution signature permits debugging.")
        has_profile = inspect_profile(bundle_path / "Contents/embedded.provisionprofile", bundle) if distribution else False
        print(f"{target}: {version} ({build}), macOS {min_os}+, universal, signature/group verified; "
              f"store profile={'verified' if has_profile else 'not required for current Mac entitlements'}.", flush=True)


def bundle_permission_entries(app: Path):
    if app.is_symlink() or not app.is_dir() or app.suffix != ".app":
        raise BuildError("Expected a built application bundle for permission repair.")
    for path in (app, *app.rglob("*")):
        if not path.is_symlink():
            yield path, path.stat()


def normalize_bundle_permissions(app: Path) -> int:
    """Repair only the archived app payload; export signs it again afterward."""
    changed = 0
    for path, metadata in bundle_permission_entries(app):
        mode = stat.S_IMODE(metadata.st_mode)
        readable = mode | 0o444
        if stat.S_ISDIR(metadata.st_mode) or mode & 0o111:
            readable |= 0o111
        if readable != mode:
            path.chmod(readable)
            changed += 1
    return changed


def require_readable_bundle(app: Path) -> None:
    for _, metadata in bundle_permission_entries(app):
        mode = stat.S_IMODE(metadata.st_mode)
        if mode & 0o444 != 0o444 or (stat.S_ISDIR(metadata.st_mode) and mode & 0o111 != 0o111):
            raise BuildError("Exported app contains files unreadable by non-root users (Apple 90255).")


def inspect_package(path: Path, version: str, build: str) -> None:
    signed = command(["pkgutil", "--check-signature", str(path)])
    signature = (signed.stdout + signed.stderr).decode(errors="replace")
    if not re.search(r"(?:3rd Party Mac Developer Installer|Mac Installer Distribution):[^\n]+\(" + TEAM + r"\)", signature):
        raise BuildError("Package is not signed with the expected Mac App Store installer identity.")
    with tempfile.TemporaryDirectory(prefix="onlynote-mac-package-") as directory:
        expanded = Path(directory) / "expanded"
        command(["pkgutil", "--expand-full", str(path), str(expanded)])
        candidates = [candidate for candidate in expanded.rglob("Onlynote.app") if candidate.is_dir()]
        if len(candidates) != 1:
            raise BuildError("Exported package must contain exactly one Onlynote application.")
        require_readable_bundle(candidates[0])
        inspect_bundle(candidates[0], version, build, distribution=True)
    print(f"Package: {path}\nSize: {path.stat().st_size / 1024 / 1024:.1f} MiB\n"
          "Mac App Store installer signature verified. No upload was performed.", flush=True)


def flutter_config(version: str, build: str, secrets: tuple[str, ...], log) -> None:
    print("Generating Flutter release configuration.", flush=True)
    result = subprocess.run(
        ["flutter", "build", "macos", "--release", "--config-only", f"--build-name={version}", f"--build-number={build}"],
        cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors="replace",
        umask=0o022,
    )
    log.write(redact(result.stdout, secrets))
    log.flush()
    if result.returncode:
        raise BuildError("Flutter release configuration failed; see the redacted build log.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--execute", action="store_true", help="Perform the authorized local archive/export and automatic provisioning; never upload.")
    parser.add_argument("--version", help="Defaults to the pubspec.yaml version.")
    parser.add_argument("--build", help="Defaults to the pubspec.yaml build number.")
    parser.add_argument("--export-only", action="store_true", help="Verify and export the existing archive without rebuilding it.")
    parser.add_argument("--manual-export", action="store_true", help="Export with installed Mac store certificates/profiles, without cloud signing or API provisioning.")
    parser.add_argument("--skip-flutter-config", action="store_true", help="Reuse release configuration already generated by Flutter with this version/build.")
    parser.add_argument("--output-dir", type=Path, default=REPO / "build/macos-release")
    parser.add_argument("--credentials-helper", type=Path, default=Path.home() / "Development/secret/AppStoreConnect_API_keys/asc_token.py")
    args = parser.parse_args(argv)
    secrets: tuple[str, ...] = ()
    try:
        version, build = release_version(args.version, args.build)
        options_path = REPO / "macos/ExportOptions.plist"
        options = export_options(options_path)
        output = args.output_dir.resolve()
        archive = output / "Onlynote.xcarchive"
        exported = output / "export"
        print(f"Mac release: {version} ({build}); Runner and widget; local App Store package export.", flush=True)
        if not args.execute:
            print(f"Dry run: prepare Flutter config, archive to {archive}, export to {exported}, "
                  "verify package signatures, versions and widget App Group.\n"
                  "No credentials read, files written, provisioning, upload, or App Store changes. "
                  "Use --execute to build the requested release.", flush=True)
            return 0
        secrets = signing_secrets()
        authentication = []
        if not args.manual_export or not args.export_only:
            try:
                key_id, issuer, key_path = credentials(args.credentials_helper)
            except Exception:
                raise BuildError("Unable to parse the existing authentication helper/key; no credentials were printed.") from None
            secrets += (key_id, issuer, str(key_path), key_path.name, str(args.credentials_helper))
            authentication = [
                "-allowProvisioningUpdates", "-authenticationKeyPath", str(key_path),
                "-authenticationKeyID", key_id, "-authenticationKeyIssuerID", issuer,
            ]
        output.mkdir(parents=True, exist_ok=True)
        log_path = output / "release-build.log"
        log_path.touch(mode=0o600, exist_ok=True)
        log_path.chmod(0o600)
        with log_path.open("a") as log:
            if not args.export_only:
                if not args.skip_flutter_config:
                    flutter_config(version, build, secrets, log)
                generated = (REPO / "macos/Flutter/ephemeral/Flutter-Generated.xcconfig").read_text()
                values = dict(re.findall(r"^(FLUTTER_BUILD_(?:NAME|NUMBER))=(.*)$", generated, re.MULTILINE))
                if values.get("FLUTTER_BUILD_NAME") != version or values.get("FLUTTER_BUILD_NUMBER") != build:
                    raise BuildError("Generated Flutter config does not match the selected release version/build.")
                if not run_xcode("Mac archive", [
                    "-workspace", "macos/Runner.xcworkspace", "-scheme", "Runner",
                    "-configuration", "Release", "-destination", "generic/platform=macOS",
                    "-archivePath", str(archive), *authentication,
                    "ONLY_ACTIVE_ARCH=NO", f"ONLYNOTE_APP_BUNDLE_ID={BUNDLE}",
                    f"FLUTTER_BUILD_NAME={version}", f"FLUTTER_BUILD_NUMBER={build}", "archive",
                ], secrets, log):
                    return 1
            inspect_bundle(archive / "Products/Applications/Onlynote.app", version, build, distribution=False)
            repaired = normalize_bundle_permissions(archive / "Products/Applications/Onlynote.app")
            if repaired:
                print(f"Restored readable permissions on {repaired} archived app entries before export.", flush=True)
            if args.manual_export:
                options_path = installed_manual_export_options(options, output)
            if not run_xcode("Mac export", [
                "-exportArchive", "-archivePath", str(archive), "-exportOptionsPlist", str(options_path),
                "-exportPath", str(exported), *(authentication if not args.manual_export else []),
            ], secrets, log):
                return 1
        packages = sorted(exported.glob("*.pkg"), key=lambda path: path.stat().st_mtime)
        if not packages:
            raise BuildError("Xcode returned success without exporting a Mac App Store package.")
        inspect_package(packages[-1], version, build)
        print(f"Redacted build log: {log_path}", flush=True)
        return 0
    except Exception as error:
        print(redact(f"Mac release build failed: {type(error).__name__}: {error}", secrets), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
