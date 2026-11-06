"""Offline regressions for staged Play listing updates; no credentials or network."""

import copy
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'store_screenshots'))
import upload_play_listing as play


class FakeApi:
    def __init__(self, root, plan):
        self.root, self.plan = root, plan
        self.calls = []
        self.edit = {'id': 'edit-42', 'expiryTimeSeconds': str(int(time.time()) + 3600)}
        self.listings = {locale: {**value, 'title': 'Old title', 'video': 'https://youtu.be/retained'}
                         for locale, value in plan['listings'].items()}
        self.tracks = {'tracks': [{'track': 'production', 'releases': [
            {'versionCodes': ['21'], 'status': 'completed', 'name': '1.11.0'}]},
                                 {'track': 'internal', 'releases': [{'versionCodes': ['20'], 'status': 'completed'}]}]}
        self.details = {'defaultLanguage': 'en-US', 'contactEmail': 'support@example.invalid'}
        self.images = {f'{locale}/{kind}': [] for locale in self.listings for kind in play.ALL_TYPES}
        self.blobs = {}
        for key in self.images:
            if key in plan['media'] or key.endswith('/icon') or key.endswith('/tvBanner'):
                encoded = io.BytesIO()
                Image.new('RGB', (8, 8), '#' + play.sha(key.encode())[:6]).save(encoded, format='PNG')
                body = encoded.getvalue()
                self.images[key] = [{'id': 'old-' + key.replace('/', '-'), 'sha256': play.sha(body),
                                     'url': 'https://play-lh.googleusercontent.com/' + key}]
                self.blobs[self.images[key][0]['url'] + '=s0'] = body
        self.upload_failure = None
        self.commit_failure = None
        self.counter = 0
        self.fail_download = False

    def download(self, url):
        self.calls.append(('DOWNLOAD', url, {}))
        if self.fail_download:
            raise play.ApiError('Backup failed')
        return self.blobs[url]

    def call(self, method, url, **kwargs):
        self.calls.append((method, url, kwargs))
        base = f'{play.PLAY_BASE}/{self.edit["id"]}'
        if method == 'POST' and url == play.PLAY_BASE:
            return copy.deepcopy(self.edit)
        if method == 'GET' and url == base:
            return copy.deepcopy(self.edit)
        if method == 'GET' and url == base + '/listings':
            return {'listings': copy.deepcopy(list(self.listings.values()))}
        if method == 'GET' and url == base + '/tracks':
            return copy.deepcopy(self.tracks)
        if method == 'GET' and url == base + '/details':
            return copy.deepcopy(self.details)
        if method == 'POST' and url == base + ':validate':
            return copy.deepcopy(self.edit)
        if method == 'POST' and url == base + ':commit':
            if self.commit_failure:
                raise self.commit_failure
            return copy.deepcopy(self.edit)
        if '/listings/' in url:
            key = url.split('/listings/')[1]
            if method == 'GET':
                return {'images': copy.deepcopy(self.images[key])}
            # Every listing/image mutation must have a complete byte backup first.
            journal = play.read(self.root / play.JOURNAL)
            baseline = play.read(self.root / play.BASELINE)
            if journal.get('baselineHash') != play.digest(baseline):
                raise AssertionError('Mutation before durable complete backup')
            for entry in baseline['imageByteBackups']:
                if play.sha((self.root / entry['path']).read_bytes()) != entry['downloadedSha256']:
                    raise AssertionError('Mutation before byte backups')
            if method == 'PUT':
                self.listings[key] = copy.deepcopy(kwargs['json'])
                return copy.deepcopy(self.listings[key])
            if method == 'DELETE':
                self.images[key] = []
                return {}
            if method == 'POST':
                failure, self.upload_failure = self.upload_failure, None
                if failure == 'before':
                    raise play.ApiError('Unknown transport outcome')
                self.counter += 1
                image = {'id': f'new-{self.counter}', 'sha256': play.sha(kwargs['data']),
                         'url': f'https://play-lh.googleusercontent.com/new-{self.counter}'}
                self.images[key].append(image)
                if failure == 'after':
                    raise play.ApiError('Unknown transport outcome')
                return {'image': copy.deepcopy(image)}
        raise AssertionError(f'Unexpected or prohibited operation: {method} {url}')


class PlayListingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.metadata = self.root / 'metadata.json'
        self.assets = self.root / 'assets.json'
        self.meta = {'packageName': play.PACKAGE, 'listings': [
            {'language': locale, 'title': 'Onlynote: Notes & Checklists',
             'shortDescription': 'Notes and lists', 'fullDescription': 'Write and organize your notes.'}
            for locale in ('en-US', 'zh-TW')]}
        self.manifest = {'packageName': play.PACKAGE, 'locales': {}}
        for locale in ('en-US', 'zh-TW'):
            entries = []
            for index, color in enumerate(('yellow', 'pink')):
                path = f'{locale}-{index}.png'
                Image.new('RGB', (320, 640), color).save(self.root / path)
                entries.append({'path': path, 'screen': f'screen-{index}', 'altText': 'A real notes screen'})
            self.manifest['locales'][locale] = {'phoneScreenshots': entries, 'sevenInchScreenshots': [],
                                               'tenInchScreenshots': [], 'featureGraphic': []}
        self.write_inputs()
        self.plan = play.load_plan(self.metadata, self.assets)
        self.api = FakeApi(self.root, self.plan)

    def write_inputs(self):
        play.save(self.metadata, self.meta)
        play.save(self.assets, self.manifest)

    def staged(self):
        return play.stage(self.api, self.root, self.plan)

    def test_offline_plan_tracks_exact_inputs_order_alt_text_and_cross_locale_reuse(self):
        self.assertEqual(len(self.plan['listings']), 2)
        self.assertEqual(len(self.plan['media']), 2)
        values = self.plan['media']['en-US/phoneScreenshots']
        self.assertEqual(values[0]['altText'], 'A real notes screen')
        old = self.plan['planHash']
        self.manifest['locales']['en-US']['phoneScreenshots'].reverse()
        self.write_inputs()
        self.assertNotEqual(play.load_plan(self.metadata, self.assets)['planHash'], old)

    def test_validation_rejects_wrong_package_locales_duplicate_text_and_bad_lengths(self):
        cases = []
        item = copy.deepcopy(self.meta)
        item['packageName'] = 'wrong.package'
        cases.append(item)
        item = copy.deepcopy(self.meta)
        item['listings'].append(copy.deepcopy(item['listings'][0]))
        cases.append(item)
        item = copy.deepcopy(self.meta)
        item['listings'][0]['title'] = 'x' * 31
        cases.append(item)
        item = copy.deepcopy(self.meta)
        item['listings'][0]['video'] = 'must-not-be-in-input'
        cases.append(item)
        for value in cases:
            with self.subTest(value=value):
                play.save(self.metadata, value)
                with self.assertRaises(ValueError):
                    play.load_plan(self.metadata, self.assets)

    def test_validation_rejects_alpha_wrong_dimensions_path_escape_and_duplicate_images(self):
        path = self.root / 'en-US-0.png'
        Image.new('RGBA', (320, 640)).save(path)
        with self.assertRaisesRegex(ValueError, 'without alpha'):
            play.load_plan(self.metadata, self.assets)
        Image.new('RGB', (319, 640)).save(path)
        with self.assertRaisesRegex(ValueError, 'dimensions'):
            play.load_plan(self.metadata, self.assets)
        Image.new('RGB', (320, 640), 'yellow').save(path)
        self.manifest['locales']['en-US']['phoneScreenshots'][1]['path'] = 'en-US-0.png'
        self.write_inputs()
        with self.assertRaisesRegex(ValueError, 'duplicate images'):
            play.load_plan(self.metadata, self.assets)
        self.manifest['locales']['en-US']['phoneScreenshots'][0]['path'] = '../outside.png'
        self.write_inputs()
        with self.assertRaisesRegex(ValueError, 'stay inside'):
            play.load_plan(self.metadata, self.assets)

    def test_feature_graphic_exact_dimensions_and_media_type_scope(self):
        Image.new('RGB', (1024, 500), 'blue').save(self.root / 'feature.png')
        self.manifest['locales']['en-US']['featureGraphic'] = [{'path': 'feature.png'}]
        self.write_inputs()
        self.assertIn('en-US/featureGraphic', play.load_plan(self.metadata, self.assets)['media'])
        self.manifest['locales']['en-US']['icon'] = [{'path': 'feature.png'}]
        self.write_inputs()
        with self.assertRaisesRegex(ValueError, 'outside'):
            play.load_plan(self.metadata, self.assets)

    def test_validate_and_missing_execute_never_create_api_client(self):
        args = ['--metadata', str(self.metadata), '--assets', str(self.assets), '--root', str(self.root)]
        with patch.object(play, 'PlayApi', side_effect=AssertionError('Network prohibited')):
            with redirect_stdout(io.StringIO()):
                self.assertEqual(play.main(['validate', *args]), 0)
            for action in ('stage', 'commit'):
                with self.assertRaisesRegex(ValueError, 'requires --execute'):
                    play.main([action, *args])
        self.assertFalse((self.root / play.JOURNAL).exists())

    def test_stage_backs_up_every_target_before_mutation_and_never_commits(self):
        old_images, old_tracks = copy.deepcopy(self.api.images), copy.deepcopy(self.api.tracks)
        result = self.staged()
        self.assertEqual(result['state'], 'STAGED')
        backup = play.read(self.root / play.BASELINE)
        self.assertEqual(len(backup['imageByteBackups']), 2)
        self.assertEqual(self.api.tracks, old_tracks)
        self.assertTrue(all(item['video'] == 'https://youtu.be/retained' for item in self.api.listings.values()))
        for key in old_images:
            if key not in self.plan['media']:
                self.assertEqual(self.api.images[key], old_images[key])
        self.assertFalse(any(url.endswith(':commit') for _, url, _ in self.api.calls))
        self.assertEqual([value['sha256'] for value in self.api.images['en-US/phoneScreenshots']],
                         [value['sha256'] for value in self.plan['media']['en-US/phoneScreenshots']])

    def test_backup_failure_stops_before_any_listing_or_media_write(self):
        self.api.fail_download = True
        with self.assertRaisesRegex(play.ApiError, 'Backup failed'):
            self.staged()
        self.assertFalse(any(method in {'PUT', 'DELETE'} or ('/upload/' in url and method == 'POST')
                             for method, url, _ in self.api.calls))

    def test_non_image_backup_response_stops_before_mutation(self):
        self.api.blobs = {key: b'<html>not an image</html>' for key in self.api.blobs}
        with self.assertRaisesRegex(ValueError, 'Invalid image byte backup'):
            self.staged()
        self.assertFalse(any(method in {'PUT', 'DELETE'} or ('/upload/' in url and method == 'POST')
                             for method, url, _ in self.api.calls))

    def test_stage_resumes_without_duplicate_uploads_or_new_edit(self):
        first = self.staged()
        count = self.api.counter
        self.assertEqual(play.stage(self.api, self.root, self.plan)['editId'], first['editId'])
        self.assertEqual(self.api.counter, count)
        self.assertEqual(sum(method == 'POST' and url == play.PLAY_BASE for method, url, _ in self.api.calls), 1)

    def test_ambiguous_applied_upload_is_reconciled_without_duplicate(self):
        self.api.upload_failure = 'after'
        self.assertEqual(self.staged()['state'], 'STAGED')
        self.assertEqual(self.api.counter, 4)
        uploads = [index for index, (method, url, _) in enumerate(self.api.calls)
                   if method == 'POST' and '/upload/' in url]
        for index in uploads:
            self.assertEqual(self.api.calls[index + 1][0], 'GET')

    def test_ambiguous_unapplied_upload_stops_and_rerun_reads_before_retry(self):
        self.api.upload_failure = 'before'
        with self.assertRaisesRegex(ValueError, 'not confirmed'):
            self.staged()
        self.assertEqual(self.api.counter, 0)
        self.assertEqual(sum(method == 'POST' and '/upload/' in url for method, url, _ in self.api.calls), 1)
        previous_count = len(self.api.calls)
        self.assertEqual(self.staged()['state'], 'STAGED')
        calls = self.api.calls[previous_count:]
        first_upload = next(index for index, (method, url, _) in enumerate(calls)
                            if method == 'POST' and '/upload/' in url)
        self.assertTrue(any(method == 'GET' and url.endswith('/en-US/phoneScreenshots')
                            for method, url, _ in calls[:first_upload]))
        self.assertEqual(self.api.counter, 4)

    def test_commit_is_separate_and_uses_error_if_in_review_only(self):
        self.staged()
        result = play.commit(self.api, self.root, self.plan)
        self.assertEqual(result['state'], 'COMMITTED')
        commits = [(method, url, kwargs) for method, url, kwargs in self.api.calls if url.endswith(':commit')]
        self.assertEqual(len(commits), 1)
        self.assertEqual(commits[0][2], {'params': {'changesInReviewBehavior': 'ERROR_IF_IN_REVIEW'}})
        with self.assertRaisesRegex(ValueError, 'successfully STAGED'):
            play.commit(self.api, self.root, self.plan)

    def test_commit_refuses_changed_inputs_backup_metadata_image_order_tracks_or_icons(self):
        self.staged()
        changed = copy.deepcopy(self.plan)
        changed['planHash'] = 'changed'
        with self.assertRaisesRegex(ValueError, 'exact'):
            play.commit(self.api, self.root, changed)
        mutations = [
            lambda: self.api.listings['en-US'].update({'video': 'different-video'}),
            lambda: self.api.listings['en-US'].update({'shortDescription': 'unexpected'}),
            lambda: self.api.images['en-US/phoneScreenshots'].reverse(),
            lambda: self.api.images['en-US/icon'][0].update({'id': 'changed-icon-id'}),
            lambda: self.api.tracks['tracks'][0]['releases'][0].update({'status': 'draft'}),
            lambda: self.api.details.update({'defaultLanguage': 'zh-TW'}),
        ]
        original = copy.deepcopy((self.api.listings, self.api.images, self.api.tracks, self.api.details))
        for mutation in mutations:
            mutation()
            with self.assertRaises(ValueError):
                play.commit(self.api, self.root, self.plan)
            self.api.listings, self.api.images, self.api.tracks, self.api.details = copy.deepcopy(original)
        self.assertFalse(any(url.endswith(':commit') for _, url, _ in self.api.calls))
        value = play.read(self.root / play.BASELINE)
        value['state']['details']['defaultLanguage'] = 'tampered'
        play.save(self.root / play.BASELINE, value)
        with self.assertRaisesRegex(ValueError, 'Baseline backup changed'):
            play.commit(self.api, self.root, self.plan)

    def test_review_rejection_retains_edit_and_does_not_relax_commit_behavior(self):
        self.staged()
        self.api.commit_failure = play.ApiError('In review', 400, 'CHANGES_ALREADY_IN_REVIEW')
        with self.assertRaises(play.ApiError):
            play.commit(self.api, self.root, self.plan)
        self.assertEqual(play.read(self.root / play.JOURNAL)['state'], 'STAGED')
        self.assertEqual(sum(url.endswith(':commit') for _, url, _ in self.api.calls), 1)

    def test_unknown_commit_outcome_cannot_be_retried(self):
        self.staged()
        self.api.commit_failure = play.ApiError('Transport timeout')
        with self.assertRaises(play.ApiError):
            play.commit(self.api, self.root, self.plan)
        self.assertEqual(play.read(self.root / play.JOURNAL)['state'], 'COMMIT_UNKNOWN')
        with self.assertRaisesRegex(ValueError, 'reconcile in Console'):
            play.commit(self.api, self.root, self.plan)
        self.assertEqual(sum(url.endswith(':commit') for _, url, _ in self.api.calls), 1)

    def test_unknown_create_response_is_durable_and_not_automatically_retried(self):
        original = self.api.call
        def uncertain(method, url, **kwargs):
            if method == 'POST' and url == play.PLAY_BASE:
                raise play.ApiError('Create response unknown')
            return original(method, url, **kwargs)
        self.api.call = uncertain
        with self.assertRaises(play.ApiError):
            self.staged()
        self.assertEqual(play.read(self.root / play.JOURNAL)['state'], 'CREATE_UNKNOWN')
        with self.assertRaisesRegex(ValueError, 'reconcile in Console'):
            self.staged()

    def test_changed_backup_bytes_and_unexpected_partial_order_prevent_retry(self):
        self.api.upload_failure = 'before'
        with self.assertRaises(ValueError):
            self.staged()
        self.api.images['en-US/phoneScreenshots'] = [{'id': 'unexpected', 'sha256': 'a' * 64}]
        with self.assertRaisesRegex(ValueError, 'ordered prefix'):
            self.staged()
        self.assertEqual(sum(method == 'POST' and '/upload/' in url for method, url, _ in self.api.calls), 1)
        record = play.read(self.root / play.BASELINE)['imageByteBackups'][0]
        (self.root / record['path']).write_bytes(b'tampered')
        with self.assertRaisesRegex(ValueError, 'byte backup'):
            self.staged()

    def test_expired_edit_and_unknown_create_are_not_replaced(self):
        self.staged()
        self.api.edit['expiryTimeSeconds'] = str(int(time.time()) - 1)
        with self.assertRaisesRegex(ValueError, 'expired'):
            self.staged()
        self.assertEqual(sum(method == 'POST' and url == play.PLAY_BASE for method, url, _ in self.api.calls), 1)
        journal = play.read(self.root / play.JOURNAL)
        journal['state'] = 'CREATE_UNKNOWN'
        play.save(self.root / play.JOURNAL, journal)
        with self.assertRaisesRegex(ValueError, 'reconcile in Console'):
            self.staged()

    def test_initial_version_or_locale_mismatch_prevents_writes(self):
        self.api.tracks['tracks'][0]['releases'][0]['versionCodes'] = ['22']
        with self.assertRaisesRegex(ValueError, 'Production version'):
            self.staged()
        self.assertFalse(any(method in {'PUT', 'DELETE'} for method, _, _ in self.api.calls))


if __name__ == '__main__':
    unittest.main()
