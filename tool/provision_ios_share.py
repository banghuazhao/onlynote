#!/usr/bin/env python3
"""Install a missing Onlynote signing profile after Portal group linking.

Uses the existing API key and an already installed signing identity. It
creates no certificates and changes no project configuration. The installed
profile must include the existing App Group before it is accepted.
"""

from __future__ import annotations

import argparse
import base64
from datetime import datetime, timezone
import hashlib
import importlib.util
from pathlib import Path
import plistlib
import re
import subprocess
import sys

import requests

from build_ios_release import credentials, redact


TARGETS = {
    "share": ("com.appsbay.onlynote.OnlynoteShare", "Onlynote Share"),
    "app": ("com.appsbay.onlynote", "Onlynote"),
    "widget": ("com.appsbay.onlynote.OnlynoteWidget", "Onlynote Widget"),
}
APP_GROUP = "group.com.appsbay.onlynote"


def profile_plist(raw: bytes) -> dict:
    start = raw.find(b"<?xml")
    end = raw.find(b"</plist>", start)
    if start < 0 or end < 0:
        raise ValueError("Signing profile has no readable property list")
    return plistlib.loads(raw[start:end + len(b"</plist>")])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--app-group-linked", action="store_true", required=True,
        help="Confirm the existing App Group was associated with OnlynoteShare in Developer Portal.",
    )
    parser.add_argument(
        "--development", action="store_true",
        help="Install a development profile for the existing automatic archive signing.",
    )
    parser.add_argument("--target", choices=TARGETS, default="share")
    args = parser.parse_args()
    if not args.app_group_linked:
        return 1
    bundle_id, label = TARGETS[args.target]
    certificate_type = "DEVELOPMENT" if args.development else "DISTRIBUTION"
    profile_type = "IOS_APP_DEVELOPMENT" if args.development else "IOS_APP_STORE"
    profile_name = label + (" Development" if args.development else " App Store")
    helper = Path.home() / "Development/secret/AppStoreConnect_API_keys/asc_token.py"
    secrets: tuple[str, ...] = ()
    try:
        key_id, issuer, key_path = credentials(helper)
        secrets = (key_id, issuer, str(key_path), key_path.name)
        spec = importlib.util.spec_from_file_location("local_asc_auth", helper)
        auth = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(auth)

        def request(method: str, path: str, body=None) -> dict:
            response = requests.request(
                method,
                "https://api.appstoreconnect.apple.com/v1/" + path,
                headers={"Authorization": "Bearer " + auth.token()},
                json=body,
                timeout=45,
            )
            data = response.json()
            if response.status_code >= 300:
                errors = "; ".join(
                    f"{error.get('code')}: {error.get('detail', error.get('title'))}"
                    for error in data.get("errors", [])
                )
                raise ValueError(f"Signing API HTTP {response.status_code}: {errors}")
            return data

        bundles = request("GET", f"bundleIds?filter%5Bidentifier%5D={bundle_id}")["data"]
        bundles = [bundle for bundle in bundles if bundle["attributes"].get("identifier") == bundle_id]
        if len(bundles) != 1:
            raise ValueError("The target identifier is not registered")
        bundle = bundles[0]
        identities = subprocess.run(
            ["security", "find-identity", "-v", "-p", "codesigning"],
            capture_output=True, text=True, check=True,
        ).stdout
        fingerprints = set(re.findall(r"\b[0-9A-F]{40}\b", identities))
        certificates = request("GET", f"certificates?filter%5BcertificateType%5D={certificate_type}&limit=200")["data"]
        usable = [
            certificate for certificate in certificates
            if hashlib.sha1(base64.b64decode(certificate["attributes"]["certificateContent"])).hexdigest().upper()
            in fingerprints
        ]
        if not usable:
            raise ValueError("No existing signing identity matches the team's certificate")
        certificate = usable[0]

        def acceptable(profile: dict) -> bool:
            attributes = profile["attributes"]
            if attributes.get("profileState") != "ACTIVE":
                return False
            raw = base64.b64decode(attributes["profileContent"])
            data = profile_plist(raw)
            entitlements = data.get("Entitlements", {})
            return (
                data.get("ExpirationDate", datetime.min).replace(tzinfo=timezone.utc)
                > datetime.now(timezone.utc)
                and not data.get("IsXcodeManaged", False)
                and entitlements.get("application-identifier", "").endswith("." + bundle_id)
                and APP_GROUP in entitlements.get("com.apple.security.application-groups", [])
                and bool(entitlements.get("get-task-allow", False)) == args.development
                and any(
                    hashlib.sha1(cert).hexdigest().upper() in fingerprints
                    for cert in data.get("DeveloperCertificates", [])
                )
            )

        profiles = request(
            "GET", f"bundleIds/{bundle['id']}/profiles?limit=200"
        )["data"]
        matches = [
            profile for profile in profiles
            if profile["attributes"].get("profileType") == profile_type and acceptable(profile)
        ]
        if matches:
            profile = matches[0]
            print(f"Reusing an existing valid {label} signing profile.", flush=True)
        else:
            relationships = {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                "certificates": {"data": [{"type": "certificates", "id": certificate["id"]}]},
            }
            if args.development:
                devices = request("GET", "devices?filter%5Bplatform%5D=IOS&filter%5Bstatus%5D=ENABLED&limit=200")["data"]
                if not devices:
                    raise ValueError("The team has no existing enabled iOS devices for a development profile")
                relationships["devices"] = {
                    "data": [{"type": "devices", "id": device["id"]} for device in devices]
                }
            profile = request("POST", "profiles", {"data": {
                "type": "profiles",
                "attributes": {"name": profile_name, "profileType": profile_type},
                "relationships": relationships,
            }})["data"]
            print(f"Created the {label} signing profile with the existing certificate.", flush=True)
        if not acceptable(profile):
            raise ValueError("The profile still lacks the required App Group or valid signing identity; it was not installed")
        raw = base64.b64decode(profile["attributes"]["profileContent"])
        data = profile_plist(raw)
        destination = Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"
        destination.mkdir(parents=True, exist_ok=True)
        path = destination / f"{data['UUID']}.mobileprovision"
        path.write_bytes(raw)
        path.chmod(0o600)
        print(f"Installed the valid {label} signing profile in Xcode's profile directory.", flush=True)
        print(f"Verified: {bundle_id}; App Group: {APP_GROUP}; development={args.development}", flush=True)
        return 0
    except Exception as error:
        print(redact(f"Profile provisioning failed: {type(error).__name__}: {error}", secrets), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
