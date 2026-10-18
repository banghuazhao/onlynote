"""Offline Mac release regressions; Apple, key files, and altool are never used."""

from contextlib import redirect_stderr, redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_macos_release
import release_macos as release


class MacStoreReleaseTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.package = self.root / "Onlynote.pkg"
        self.package.write_bytes(b"verified Mac release package")
        self.digest = hashlib.sha256(self.package.read_bytes()).hexdigest()
        self.output = self.root / "output"
        for attribute, value in [("REPO", self.root), ("OUTPUT", self.output),
                                 ("JOURNAL", self.output / "store-release.json")]:
            patcher = patch.object(release, attribute, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        credentials = patch.object(release, "credentials", side_effect=AssertionError("Real credentials must not be read."))
        self.credentials = credentials.start()
        self.addCleanup(credentials.stop)
        runner = patch.object(release.subprocess, "run", side_effect=AssertionError("A real command must not run."))
        self.runner = runner.start()
        self.addCleanup(runner.stop)
        inspect = patch.object(build_macos_release, "inspect_package")
        self.inspect = inspect.start()
        self.addCleanup(inspect.stop)
        network = patch.object(release.requests.sessions.Session, "request", side_effect=AssertionError("Apple/network access is prohibited."))
        network.start()
        self.addCleanup(network.stop)
        self.api = MagicMock()
        self.api.call.side_effect = AssertionError("Apple API must not be contacted.")
        self.api.safe.side_effect = lambda text: text.replace("PRIVATE_TEST_TOKEN", "[redacted]")

    def journal_with(self, **fields):
        values = release.journal("1.8.0", "18")
        values.update(fields)
        release.save_journal(release.JOURNAL, values)

    def package_action(self, action):
        return release.package_action(self.api, self.root / "unused-helper.py", self.package,
                                      action, "1.8.0", "18")

    def permit_fake_altool(self, status=0):
        self.credentials.side_effect = None
        self.credentials.return_value = ("fake-key", "fake-issuer", self.root / "unused-key.p8")
        self.runner.side_effect = None
        self.runner.return_value = subprocess.CompletedProcess([], status, "PRIVATE_TEST_TOKEN result", "")

    def test_upload_requires_successful_validation_of_exact_package(self):
        for fields in [{}, {"packageValidated": False, "packageSha256": self.digest},
                       {"packageValidated": True, "packageSha256": "different-package"}]:
            with self.subTest(fields=fields):
                if release.JOURNAL.exists():
                    release.JOURNAL.unlink()
                self.journal_with(**fields)
                with self.assertRaisesRegex(release.ReleaseError, "exact package"):
                    self.package_action("upload-package")
        self.inspect.assert_not_called()
        self.credentials.assert_not_called()
        self.runner.assert_not_called()

    def test_package_changed_after_validation_cannot_be_uploaded(self):
        self.journal_with(packageValidated=True, packageSha256=self.digest)
        self.package.write_bytes(b"rebuilt package with the same file name")
        with self.assertRaisesRegex(release.ReleaseError, "exact package"):
            self.package_action("upload-package")
        self.runner.assert_not_called()

    def test_already_uploaded_exact_package_does_not_upload_again(self):
        self.journal_with(packageValidated=True, packageSha256=self.digest, packageUploaded=True)
        with redirect_stdout(io.StringIO()):
            self.package_action("upload-package")
        self.inspect.assert_not_called()
        self.credentials.assert_not_called()
        self.runner.assert_not_called()

    def test_successful_validation_records_checksum_and_sanitized_log(self):
        self.permit_fake_altool()
        with redirect_stdout(io.StringIO()):
            self.package_action("validate-package")
        values = json.loads(release.JOURNAL.read_text())
        self.assertTrue(values["packageValidated"])
        self.assertEqual(values["packageSha256"], self.digest)
        self.assertNotIn("packageUploaded", values)
        self.assertIn("--validate-app", self.runner.call_args.args[0])
        self.assertNotIn("PRIVATE_TEST_TOKEN", (self.output / "validate-package.log").read_text())
        self.inspect.assert_called_once_with(self.package, "1.8.0", "18")

    def test_failed_validation_never_sets_validated_flag(self):
        self.permit_fake_altool(status=1)
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            with self.assertRaisesRegex(release.ReleaseError, "operation failed"):
                self.package_action("validate-package")
        self.assertFalse(release.JOURNAL.exists())

    def test_successful_upload_retry_is_idempotent(self):
        self.journal_with(packageValidated=True, packageSha256=self.digest)
        self.permit_fake_altool()
        with redirect_stdout(io.StringIO()):
            self.package_action("upload-package")
            self.package_action("upload-package")
        self.runner.assert_called_once()
        self.assertIn("--upload-package", self.runner.call_args.args[0])
        self.assertTrue(json.loads(release.JOURNAL.read_text())["packageUploaded"])

    def test_release_journal_cannot_be_reused_for_ios(self):
        self.journal_with(platform="IOS")
        with self.assertRaisesRegex(release.ReleaseError, "different release"):
            release.journal("1.8.0", "18")

    def test_distinct_stage_records_preserve_package_and_screenshot_fields(self):
        # The screenshot stage holds its own older snapshot while package work
        # finishes. Committing only its fields must preserve the newer flags.
        screenshot_stage = release.record("1.8.0", "18", screenshotSets={
            "en-US": {"id": "desktop-set", "screenshots": ["shot"], "complete": False}})
        release.record("1.8.0", "18", packageValidated=True, packageSha256=self.digest)
        screenshot_stage["screenshotSets"]["en-US"]["complete"] = True
        release.record("1.8.0", "18", screenshotSets=screenshot_stage["screenshotSets"])
        release.record("1.8.0", "18", packageUploaded=True)
        stored = json.loads(release.JOURNAL.read_text())
        self.assertTrue(stored["packageValidated"])
        self.assertTrue(stored["packageUploaded"])
        self.assertEqual(stored["packageSha256"], self.digest)
        self.assertTrue(stored["screenshotSets"]["en-US"]["complete"])
        self.assertEqual(stored["platform"], "MAC_OS")

    @staticmethod
    def version(platform, identifier="version"):
        return {"id": identifier, "attributes": {"platform": platform, "versionString": "1.8.0",
                "appStoreState": "PREPARE_FOR_SUBMISSION"}}

    def test_version_selection_rejects_accidental_ios_api_result(self):
        with patch.object(release, "collection", return_value=[self.version("IOS")]):
            with self.assertRaisesRegex(release.ReleaseError, "different platform"):
                release.version_for(self.api, "1.8.0", editable=True)

    def test_version_selection_rejects_mixed_platform_api_results(self):
        mac = self.version("MAC_OS", "mac-version")
        with patch.object(release, "collection", return_value=[self.version("IOS", "ios-version"), mac]):
            with self.assertRaisesRegex(release.ReleaseError, "different platform"):
                release.version_for(self.api, "1.8.0", editable=True)

    def test_version_selection_rejects_noneditable_mac_version(self):
        mac = self.version("MAC_OS")
        mac["attributes"]["appStoreState"] = "WAITING_FOR_REVIEW"
        with patch.object(release, "mac_versions", return_value=[mac]):
            with self.assertRaisesRegex(release.ReleaseError, "no longer editable"):
                release.version_for(self.api, "1.8.0", editable=True)

    @staticmethod
    def build_response(platform="MAC_OS", app_id=release.APP_ID, version="1.8.0", build="18",
                       state="VALID", expired=False):
        item = {"id": "mac-build", "type": "builds", "attributes": {
            "version": build, "processingState": state, "expired": expired, "usesNonExemptEncryption": False},
            "relationships": {"app": {"data": {"id": app_id, "type": "apps"}},
                              "preReleaseVersion": {"data": {"id": "prerelease", "type": "preReleaseVersions"}}}}
        prerelease = {"id": "prerelease", "type": "preReleaseVersions",
                      "attributes": {"platform": platform, "version": version}}
        return {"data": [item], "included": [prerelease]}

    def test_verified_build_rejects_wrong_platform_app_or_version_even_with_server_filter(self):
        for changes in [{"platform": "IOS"}, {"app_id": "another-app"},
                        {"version": "1.7.0"}, {"build": "17"}]:
            with self.subTest(changes=changes), patch.object(
                    release, "collection_response", return_value=self.build_response(**changes)) as request:
                with self.assertRaisesRegex(release.ReleaseError, "exact Mac app/version/build"):
                    release.verified_build(self.api, "1.8.0", "18")
                self.assertEqual(request.call_args.kwargs["filter[preReleaseVersion.platform]"], "MAC_OS")
        self.api.call.assert_not_called()

    def test_verified_build_requires_successful_processing_and_unexpired_build(self):
        for changes in [{"state": "PROCESSING"}, {"state": "FAILED"}, {"expired": True}]:
            with self.subTest(changes=changes), patch.object(
                    release, "collection_response", return_value=self.build_response(**changes)):
                with self.assertRaisesRegex(release.ReleaseError, "not ready"):
                    release.verified_build(self.api, "1.8.0", "18")

    def test_review_preparation_never_mutates_accidental_ios_version(self):
        with patch.object(release, "collection", return_value=[self.version("IOS")]), \
                patch.object(release, "patch") as mutation:
            with self.assertRaisesRegex(release.ReleaseError, "different platform"):
                release.prepare_review(self.api, "1.8.0", "18")
        mutation.assert_not_called()
        self.api.call.assert_not_called()
        self.assertFalse(release.JOURNAL.exists())

    def test_review_preparation_never_mutates_wrong_platform_or_build(self):
        self.journal_with(versionId="mac-version", listingPrepared=True)
        metadata = {"en-US": {"description": "Mac notes", "keywords": "notes", "promotionalText": "For Mac"}}
        locale = {"id": "localization", "attributes": {"locale": "en-US", **metadata["en-US"]}}

        def collection(api, path, **kwargs):
            if path.endswith("/appStoreVersions"):
                return [self.version("MAC_OS", "mac-version")]
            if path.endswith("/appStoreVersionLocalizations"):
                return [locale]
            raise AssertionError(f"Unexpected offline collection: {path}")

        for changes in [{"platform": "IOS"}, {"build": "17"}]:
            with self.subTest(changes=changes), patch.object(release, "collection", side_effect=collection), \
                    patch.object(release, "metadata_from", return_value=metadata), \
                    patch.object(release, "verify_screenshots"), \
                    patch.object(release, "collection_response", return_value=self.build_response(**changes)), \
                    patch.object(release, "patch") as mutation:
                with self.assertRaisesRegex(release.ReleaseError, "exact Mac app/version/build"):
                    release.prepare_review(self.api, "1.8.0", "18")
                mutation.assert_not_called()
        self.api.call.assert_not_called()
        self.assertNotIn("reviewPrepared", json.loads(release.JOURNAL.read_text()))

    @staticmethod
    def submission(platform, identifier, state="WAITING_FOR_REVIEW"):
        return {"id": identifier, "type": "reviewSubmissions",
                "attributes": {"platform": platform, "state": state},
                "relationships": {"items": {"data": []},
                                  "appStoreVersionForReview": {"data": {"id": "mac-version", "type": "appStoreVersions"}}}}

    def submitted_release(self):
        self.journal_with(versionId="mac-version", buildId="mac-build", reviewPrepared=True)
        mac = self.version("MAC_OS", "mac-version")
        mac["attributes"]["releaseType"] = "AFTER_APPROVAL"
        return mac, self.build_response()["data"][0]

    def test_matching_mac_review_ignores_ios_and_prevents_duplicate_submission(self):
        mac, build = self.submitted_release()
        self.api.call.side_effect = lambda method, path, **kwargs: {"data": build} if (
            method == "GET" and path == "/appStoreVersions/mac-version/build") else self.fail("Unexpected API mutation.")
        reviews = {"data": [self.submission("IOS", "ios-review"), self.submission("MAC_OS", "mac-review")],
                   "included": []}
        with patch.object(release, "collection", return_value=[mac]), \
                patch.object(release, "verified_build", return_value=build), \
                patch.object(release, "verify_screenshots"), \
                patch.object(release, "collection_response", return_value=reviews), \
                patch.object(release, "patch") as mutation, redirect_stdout(io.StringIO()):
            release.submit_mac_review(self.api, "1.8.0", "18")
            release.submit_mac_review(self.api, "1.8.0", "18")
        mutation.assert_not_called()
        self.assertTrue(all(call.args[0] == "GET" for call in self.api.call.call_args_list))
        saved = json.loads(release.JOURNAL.read_text())
        self.assertTrue(saved["reviewSubmitted"])
        self.assertEqual(saved["reviewSubmissionId"], "mac-review")

    def test_finished_submission_is_not_reported_as_an_already_submitted_release(self):
        # A rejected or cancelled submission ends as COMPLETE for this same
        # version. Reading it as this release's submission reported success
        # without sending anything, which is how a resubmission went nowhere.
        mac, build = self.submitted_release()
        created = {"id": "fresh-review", "type": "reviewSubmissions",
                   "attributes": {"platform": "MAC_OS", "state": "READY_FOR_REVIEW"},
                   "relationships": {"items": {"data": []}}}
        item = {"id": "fresh-item", "relationships": {
            "appStoreVersion": {"data": {"id": "mac-version", "type": "appStoreVersions"}}}}
        calls = []

        def call(method, path, **kwargs):
            calls.append((method, path))
            if method == "GET" and path == "/appStoreVersions/mac-version/build":
                return {"data": build}
            if method == "POST" and path == "/reviewSubmissions":
                return {"data": created}
            if method == "POST" and path == "/reviewSubmissionItems":
                return {"data": item}
            raise AssertionError(f"Unexpected call: {method} {path}")

        self.api.call.side_effect = call
        stale = self.submission("MAC_OS", "old-review", state="COMPLETE")
        stale["relationships"]["items"]["data"] = [{"id": "old-item", "type": "reviewSubmissionItems"}]
        reviews = {"data": [stale], "included": []}
        def collection(api, path, **kwargs):
            if "appStoreVersions" in path:
                return [mac]
            # The items of the submission being built: empty before the item
            # is created, exactly this version's on the re-read before sending.
            return [item] if kwargs.get("include") == "appStoreVersion" else []

        with patch.object(release, "collection", side_effect=collection), \
                patch.object(release, "verified_build", return_value=build), \
                patch.object(release, "verify_screenshots"), \
                patch.object(release, "collection_response", return_value=reviews), \
                patch.object(release, "patch", return_value={"data": {"id": "fresh-review", "attributes": {
                    "state": "WAITING_FOR_REVIEW"}}}) as mutation, redirect_stdout(io.StringIO()):
            release.submit_mac_review(self.api, "1.8.0", "18")
        self.assertIn(("POST", "/reviewSubmissions"), calls)
        self.assertIn(("POST", "/reviewSubmissionItems"), calls)
        self.assertEqual(mutation.call_args.args[1:], ("reviewSubmissions", "fresh-review", {"submitted": True}))
        saved = json.loads(release.JOURNAL.read_text())
        self.assertEqual(saved["reviewSubmissionId"], "fresh-review")
        self.assertEqual(saved["reviewState"], "WAITING_FOR_REVIEW")

    def test_unresolved_submission_is_named_rather_than_blamed_on_its_items(self):
        # Apple stops returning a finished submission's item relationships, so
        # inspecting contents first described a rejection as unexpected items.
        mac, build = self.submitted_release()
        self.api.call.side_effect = lambda method, path, **kwargs: {"data": build} if (
            method == "GET" and path == "/appStoreVersions/mac-version/build") else self.fail(
                "Unexpected API mutation.")
        rejected = self.submission("MAC_OS", "old-review", state="UNRESOLVED_ISSUES")
        rejected["relationships"]["items"]["data"] = [{"id": "old-item", "type": "reviewSubmissionItems"}]
        with patch.object(release, "collection", return_value=[mac]), \
                patch.object(release, "verified_build", return_value=build), \
                patch.object(release, "verify_screenshots"), \
                patch.object(release, "collection_response",
                             return_value={"data": [rejected], "included": []}), \
                patch.object(release, "patch") as mutation:
            with self.assertRaisesRegex(release.ReleaseError, "UNRESOLVED_ISSUES; preserved"):
                release.submit_mac_review(self.api, "1.8.0", "18")
        mutation.assert_not_called()
        self.assertNotIn("reviewSubmitted", json.loads(release.JOURNAL.read_text()))

    def test_review_submission_rejects_changed_build_before_any_mutation(self):
        mac, build = self.submitted_release()
        self.api.call.side_effect = None
        self.api.call.return_value = {"data": {**build, "id": "another-build"}}
        with patch.object(release, "collection", return_value=[mac]), \
                patch.object(release, "verified_build", return_value=build), \
                patch.object(release, "patch") as mutation:
            with self.assertRaisesRegex(release.ReleaseError, "attachment changed"):
                release.submit_mac_review(self.api, "1.8.0", "18")
        mutation.assert_not_called()
        self.assertTrue(all(call.args[0] == "GET" for call in self.api.call.call_args_list))
        self.assertNotIn("reviewSubmitted", json.loads(release.JOURNAL.read_text()))

    def test_final_review_item_reread_blocks_changed_or_additional_items(self):
        mac, build = self.submitted_release()
        reviews = {"data": [self.submission("MAC_OS", "mac-review", state="READY_FOR_REVIEW")],
                   "included": []}
        self.api.call.side_effect = lambda method, path, **kwargs: {"data": build} if (
            method == "GET" and path == "/appStoreVersions/mac-version/build") else self.fail("Unexpected API mutation.")

        def item(identifier, version_id):
            return {"id": identifier, "type": "reviewSubmissionItems", "relationships": {
                "appStoreVersion": {"data": {"id": version_id, "type": "appStoreVersions"}}}}

        for current in [[], [item("changed-item", "different-version")],
                        [item("intended-item", "mac-version"), item("additional-item", "different-version")]]:
            def collection(api, path, **kwargs):
                if path.endswith("/appStoreVersions"):
                    return [mac]
                if path == "/reviewSubmissions/mac-review/items":
                    self.assertEqual(kwargs.get("include"), "appStoreVersion")
                    return current
                raise AssertionError(f"Unexpected offline collection: {path}")

            with self.subTest(current=current), patch.object(release, "collection", side_effect=collection), \
                    patch.object(release, "verified_build", return_value=build), \
                    patch.object(release, "verify_screenshots"), \
                    patch.object(release, "collection_response", return_value=reviews), \
                    patch.object(release, "patch") as mutation:
                with self.assertRaisesRegex(release.ReleaseError, "exact single item changed"):
                    release.submit_mac_review(self.api, "1.8.0", "18")
                mutation.assert_not_called()
        self.assertTrue(all(call.args[0] == "GET" for call in self.api.call.call_args_list))
        self.assertNotIn("reviewSubmitted", json.loads(release.JOURNAL.read_text()))


if __name__ == "__main__":
    unittest.main()
