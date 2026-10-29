"""Run fake build executables as real children; no build, credentials or API."""

from contextlib import redirect_stdout
import io
import os
from pathlib import Path
import stat
import sys
import tempfile
import unittest
from unittest.mock import patch

from tool import build_ios_release as ios
from tool import build_macos_release as macos


@unittest.skipUnless(os.name == "posix", "Release child umasks require POSIX.")
class ReleaseBuildPermissionsTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        # Executable shims produce ordinary bundle/config files without chmod.
        # Their modes therefore expose the child's actual inherited umask.
        program = f"""#!{sys.executable}
from pathlib import Path
import sys

tool = Path(sys.argv[0]).name
if tool == 'xcrun':
    assert sys.argv[1] == 'xcodebuild'
else:
    assert sys.argv[1:5] == ['build', 'macos', '--release', '--config-only']
output = Path('child-output') / tool / 'Contents' / 'Resources'
output.mkdir(parents=True)
(output / 'generated.txt').write_text('fake build output')
print('TEST_ONLY_PRIVATE_VALUE')
"""
        for name in ("xcrun", "flutter"):
            executable = self.bin / name
            executable.write_text(program)
            executable.chmod(0o755)

    def assert_child_modes_and_private_parent(self, tool, invoke):
        previous_umask = os.umask(0o077)
        try:
            log_path = self.root / "private-build.log"
            with patch.object(ios, "REPO", self.root), \
                    patch.object(macos, "REPO", self.root), \
                    patch.dict(os.environ, {"PATH": str(self.bin) + os.pathsep + os.environ.get("PATH", "")}), \
                    redirect_stdout(io.StringIO()), log_path.open("w") as log:
                invoke(log)
            self.assertEqual(os.umask(0o077), 0o077, "Build launch changed the parent's private umask.")
            self.assertEqual(stat.S_IMODE(log_path.stat().st_mode), 0o600)
            self.assertNotIn("TEST_ONLY_PRIVATE_VALUE", log_path.read_text())
            self.assertIn("[REDACTED]", log_path.read_text())
            output = self.root / "child-output"
            for directory in (output, output / tool, output / tool / "Contents", output / tool / "Contents/Resources"):
                self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o755, str(directory.relative_to(self.root)))
            generated = output / tool / "Contents/Resources/generated.txt"
            self.assertEqual(generated.read_text(), "fake build output")
            self.assertEqual(stat.S_IMODE(generated.stat().st_mode), 0o644)
            # A later parent-created file must still be private too.
            later_private_file = self.root / "parent-private.txt"
            later_private_file.write_text("private parent output")
            self.assertEqual(stat.S_IMODE(later_private_file.stat().st_mode), 0o600)
        finally:
            os.umask(previous_umask)

    def test_ios_xcode_child_uses_public_bundle_modes_under_private_parent(self):
        def invoke(log):
            self.assertTrue(ios.run_xcode("Fake iOS archive", ["archive"], ("TEST_ONLY_PRIVATE_VALUE",), log))

        self.assert_child_modes_and_private_parent("xcrun", invoke)

    def test_macos_shared_xcode_child_uses_public_bundle_modes_under_private_parent(self):
        def invoke(log):
            self.assertTrue(macos.run_xcode("Fake Mac archive", ["archive"], ("TEST_ONLY_PRIVATE_VALUE",), log))

        self.assert_child_modes_and_private_parent("xcrun", invoke)

    def test_macos_flutter_child_uses_public_config_modes_under_private_parent(self):
        self.assert_child_modes_and_private_parent("flutter", lambda log:
            macos.flutter_config("1.13.0", "23", ("TEST_ONLY_PRIVATE_VALUE",), log))

    def test_repair_changes_only_app_entries_and_keeps_executables(self):
        app = self.root / "built/Onlynote.app"
        resources = app / "Contents/Resources"
        resources.mkdir(parents=True)
        executable = app / "Contents/MacOS/Onlynote"
        executable.parent.mkdir()
        data = resources / "document.dat"
        data.write_text("bundle resource")
        executable.write_text("fake executable")
        app_directories = (app, app / "Contents", resources, executable.parent)
        for directory in app_directories:
            directory.chmod(0o700)
        data.chmod(0o600)
        executable.chmod(0o700)
        already_public_executable = executable.parent / "helper"
        already_public_executable.write_text("fake helper")
        already_public_executable.chmod(0o755)
        private = self.root / "private.txt"
        private.write_text("private file")
        private.chmod(0o600)
        outside = self.root / "outside"
        outside.mkdir(mode=0o700)
        outside.chmod(0o700)
        outside_file = outside / "private.txt"
        outside_file.write_text("outside private file")
        outside_file.chmod(0o600)
        file_link = resources / "private-link"
        directory_link = resources / "outside-link"
        broken_link = resources / "missing-link"
        file_link.symlink_to(private)
        directory_link.symlink_to(outside, target_is_directory=True)
        broken_link.symlink_to(self.root / "missing")

        self.assertGreater(macos.normalize_bundle_permissions(app), 0)

        for directory in app_directories:
            self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o755)
        self.assertEqual(stat.S_IMODE(data.stat().st_mode), 0o644)
        self.assertEqual(stat.S_IMODE(executable.stat().st_mode), 0o755)
        self.assertEqual(stat.S_IMODE(already_public_executable.stat().st_mode), 0o755)
        self.assertEqual(stat.S_IMODE(private.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(outside.stat().st_mode), 0o700)
        self.assertEqual(stat.S_IMODE(outside_file.stat().st_mode), 0o600)
        for link in (file_link, directory_link, broken_link):
            self.assertTrue(link.is_symlink())
        self.assertEqual(file_link.readlink(), private)
        self.assertEqual(directory_link.readlink(), outside)
        self.assertEqual(broken_link.readlink(), self.root / "missing")
        macos.require_readable_bundle(app)

    def test_export_guard_rejects_owner_only_entries_then_accepts_repair(self):
        app = self.root / "Onlynote.app"
        resources = app / "Contents/Resources"
        resources.mkdir(parents=True)
        data = resources / "document.dat"
        data.write_text("bundle resource")
        executable = resources / "executable"
        executable.write_text("fake executable")
        for directory in (app, app / "Contents", resources):
            directory.chmod(0o755)
        data.chmod(0o644)
        executable.chmod(0o755)
        for entry, mode, expected in ((data, 0o600, 0o644),
                                      (resources, 0o700, 0o755),
                                      (executable, 0o700, 0o755)):
            with self.subTest(entry=entry.name):
                entry.chmod(mode)
                with self.assertRaisesRegex(macos.BuildError, "90255"):
                    macos.require_readable_bundle(app)
                macos.normalize_bundle_permissions(app)
                self.assertEqual(stat.S_IMODE(entry.stat().st_mode), expected)
                macos.require_readable_bundle(app)

    def test_repair_refuses_non_app_roots_and_symlink_app_roots(self):
        cache = self.root / "private-cache"
        cache.mkdir(mode=0o700)
        cache.chmod(0o700)
        with self.assertRaises(macos.BuildError):
            macos.normalize_bundle_permissions(cache)
        app = self.root / "Onlynote.app"
        app.mkdir(mode=0o700)
        app.chmod(0o700)
        linked_app = self.root / "Linked.app"
        linked_app.symlink_to(app, target_is_directory=True)
        with self.assertRaises(macos.BuildError):
            macos.normalize_bundle_permissions(linked_app)
        self.assertEqual(stat.S_IMODE(cache.stat().st_mode), 0o700)
        self.assertEqual(stat.S_IMODE(app.stat().st_mode), 0o700)


if __name__ == "__main__":
    unittest.main()
