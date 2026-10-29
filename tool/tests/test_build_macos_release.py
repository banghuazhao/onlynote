"""Release verification regressions; no signing tools or network are invoked."""

from contextlib import redirect_stderr, redirect_stdout
import io
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from tool import build_macos_release as release


class MacReleaseTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.app = self.root / "Onlynote.app"
        for target, (bundle, min_os) in release.TARGETS.items():
            path = self.app if target == "Onlynote" else self.app / "Contents/PlugIns/OnlynoteWidget.appex"
            (path / "Contents").mkdir(parents=True)
            info = {
                "CFBundleIdentifier": bundle, "CFBundleShortVersionString": "1.8.0",
                "CFBundleVersion": "18", "CFBundleExecutable": target,
                "LSMinimumSystemVersion": min_os, "OnlynoteWidgetAppGroup": release.GROUP,
            }
            if target == "Onlynote":
                info["LSApplicationCategoryType"] = "public.app-category.productivity"
            (path / "Contents/Info.plist").write_bytes(plistlib.dumps(info))
        self.entitlements = {
            "com.apple.security.app-sandbox": True,
            "com.apple.security.application-groups": [release.GROUP],
        }
        self.authority = "Apple Distribution"

    def signing_command(self, arguments):
        stdout, stderr = b"", b""
        if arguments[0] == "lipo":
            stdout = b"x86_64 arm64\n"
        elif "--verbose=4" in arguments:
            stderr = f"Authority={self.authority}: A Private Developer ({release.TEAM})\nTeamIdentifier={release.TEAM}\n".encode()
        elif "--entitlements" in arguments:
            stdout = plistlib.dumps(self.entitlements)
        return subprocess.CompletedProcess(arguments, 0, stdout, stderr)

    def test_export_must_never_upload_or_renumber(self):
        path = self.root / "ExportOptions.plist"
        base = {"destination": "export", "method": "app-store-connect", "teamID": release.TEAM,
                "manageAppVersionAndBuildNumber": False}
        for override in [{"destination": "upload"}, {"manageAppVersionAndBuildNumber": True}]:
            with self.subTest(override=override):
                path.write_bytes(plistlib.dumps({**base, **override}))
                with self.assertRaises(release.BuildError):
                    release.export_options(path)

    def test_dry_run_does_not_read_credentials_or_run_tools(self):
        (self.root / "pubspec.yaml").write_text("name: onlynote\nversion: 1.8.0+18\n")
        config = self.root / "macos/ExportOptions.plist"
        config.parent.mkdir()
        config.write_bytes((release.REPO / "macos/ExportOptions.plist").read_bytes())
        output = io.StringIO()
        with patch.object(release, "REPO", self.root), patch.object(release, "credentials") as credentials, \
                patch.object(release, "run_xcode") as xcode, patch.object(release.subprocess, "run") as command, \
                redirect_stdout(output):
            self.assertEqual(release.main(["--output-dir", str(self.root / "output")]), 0)
        credentials.assert_not_called()
        xcode.assert_not_called()
        command.assert_not_called()
        self.assertFalse((self.root / "output").exists())
        self.assertIn("1.8.0 (18)", output.getvalue())

    def test_store_signatures_and_unrestricted_group_need_no_profile(self):
        output = io.StringIO()
        with patch.object(release, "command", side_effect=self.signing_command), redirect_stdout(output):
            release.inspect_bundle(self.app, "1.8.0", "18", distribution=True)
        self.assertIn("OnlynoteWidget: 1.8.0 (18)", output.getvalue())
        self.assertNotIn("A Private Developer", output.getvalue())

    def test_export_rejects_development_signature(self):
        self.authority = "Apple Development"
        with patch.object(release, "command", side_effect=self.signing_command):
            with self.assertRaisesRegex(release.BuildError, "distribution signature"):
                release.inspect_bundle(self.app, "1.8.0", "18", distribution=True)

    def test_export_rejects_wrong_shared_group_even_when_code_signed(self):
        self.entitlements["com.apple.security.application-groups"] = ["OTHERTEAM.com.appsbay.onlynote"]
        with patch.object(release, "command", side_effect=self.signing_command):
            with self.assertRaisesRegex(release.BuildError, "shared widget group"):
                release.inspect_bundle(self.app, "1.8.0", "18", distribution=True)

    def test_export_rejects_widget_version_mismatch(self):
        path = self.app / "Contents/PlugIns/OnlynoteWidget.appex/Contents/Info.plist"
        info = plistlib.loads(path.read_bytes())
        info["CFBundleVersion"] = "17"
        path.write_bytes(plistlib.dumps(info))
        with patch.object(release, "command", side_effect=self.signing_command), redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(release.BuildError, "OnlynoteWidget bundle ID or version/build"):
                release.inspect_bundle(self.app, "1.8.0", "18", distribution=True)

    def test_skipped_flutter_configuration_must_match_requested_release(self):
        (self.root / "pubspec.yaml").write_text("version: 1.8.0+18\n")
        config = self.root / "macos/ExportOptions.plist"
        config.parent.mkdir()
        config.write_bytes((release.REPO / "macos/ExportOptions.plist").read_bytes())
        generated = self.root / "macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
        generated.parent.mkdir(parents=True)
        generated.write_text("FLUTTER_BUILD_NAME=1.7.0\nFLUTTER_BUILD_NUMBER=17\n")
        error = io.StringIO()
        with patch.object(release, "REPO", self.root), \
                patch.object(release, "credentials", return_value=("key", "issuer", self.root / "AuthKey.p8")), \
                patch.object(release, "signing_secrets", return_value=()), \
                patch.object(release, "run_xcode") as xcode, redirect_stdout(io.StringIO()), redirect_stderr(error):
            self.assertEqual(release.main(["--execute", "--skip-flutter-config", "--output-dir", str(self.root / "output")]), 1)
        xcode.assert_not_called()
        self.assertIn("config does not match", error.getvalue())

    def test_manual_export_uses_no_credentials_or_cloud_provisioning(self):
        (self.root / "pubspec.yaml").write_text("version: 1.8.0+18\n")
        config = self.root / "macos/ExportOptions.plist"
        config.parent.mkdir()
        config.write_bytes((release.REPO / "macos/ExportOptions.plist").read_bytes())
        output = self.root / "output"
        exported = output / "export"
        exported.mkdir(parents=True)
        (output / "Onlynote.xcarchive/Products/Applications/Onlynote.app").mkdir(parents=True)
        (exported / "Onlynote.pkg").touch()
        with patch.object(release, "REPO", self.root), patch.object(release, "credentials") as credentials, \
                patch.object(release, "signing_secrets", return_value=()), \
                patch.object(release, "inspect_bundle"), patch.object(release, "inspect_package"), \
                patch.object(release, "installed_manual_export_options", return_value=output / "ManualExportOptions.plist"), \
                patch.object(release, "run_xcode", return_value=True) as xcode, redirect_stdout(io.StringIO()):
            self.assertEqual(release.main(["--execute", "--export-only", "--manual-export", "--output-dir", str(output)]), 0)
        credentials.assert_not_called()
        arguments = xcode.call_args.args[1]
        self.assertIn("-exportArchive", arguments)
        self.assertNotIn("-allowProvisioningUpdates", arguments)
        self.assertNotIn("-authenticationKeyPath", arguments)


if __name__ == "__main__":
    unittest.main()
