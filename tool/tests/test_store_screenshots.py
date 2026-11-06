"""Local contract checks for scoped captures and Duo Asset Library placement."""

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'store_screenshots'))
import apple_library
import prepare
import upload


def reference_data():
    return {'data': [{'attributes': {
        'imageSpecs': [{
            'specId': 'outer-spec',
            'dimensions': {'minWidth': 1398, 'maxWidth': 1398, 'minHeight': 2034, 'maxHeight': 2034},
            'compatiblePlacementTypes': ['APP_SCREENSHOT'], 'fileExtensions': ['.jpg'],
        }, {
            'specId': 'inner-spec',
            'dimensions': {'minWidth': 2007, 'maxWidth': 2007, 'minHeight': 2853, 'maxHeight': 2853},
            'compatiblePlacementTypes': ['APP_SCREENSHOT'], 'fileExtensions': ['.jpg'],
        }],
        'placementProfileGroups': [{'placementProfileGroupId': 'discovered-duo-group',
                                    'displayClassId': 'IPHONE_DUO', 'platform': 'IPHONE_APP_STORE'}],
        'features': [{'featureId': 'APP_STORE_VERSIONS', 'placementPolicies': [{
            'placementType': 'APP_SCREENSHOT',
            'groupLimits': [{'groupIds': ['discovered-duo-group'], 'maxCount': 10}],
        }]}],
        'placementTypes': [{'placementTypeId': 'APP_SCREENSHOT', 'specMappings': [{
            'placementGroupId': 'discovered-duo-group', 'specs': ['outer-spec', 'inner-spec'],
        }]}],
    }}]}


class ScopedCaptureTests(unittest.TestCase):
    def test_store_defaults_and_explicit_scope(self):
        self.assertEqual(set(upload.select_devices(store='apple')), set(upload.LEGACY_APPLE_DEVICES))
        self.assertEqual(set(upload.select_devices(' iphone_duo_outer , iphone_duo_inner ', 'apple')),
                         set(upload.APPLE_LIBRARY_DEVICES))
        with self.assertRaisesRegex(ValueError, 'Unknown apple devices'):
            upload.select_devices('playphone', 'apple')

    def test_prepare_requires_only_selected_sets_and_preserves_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root / 'iphone_duo_outer' / 'en'
            folder.mkdir(parents=True)
            Image.new('RGBA', (1398, 2034), (255, 255, 255, 255)).save(folder / '01-home.png')
            prior = [{'device': 'playphone', 'locale': 'zh-Hant', 'path': 'old.jpg'}]
            (root / 'manifest.json').write_text(json.dumps(prior))

            def convert(command, **kwargs):
                with Image.open(command[-3]) as image:
                    image.convert('RGB').save(command[-1])

            with patch.object(sys, 'argv', ['prepare.py', '--root', str(root), '--devices',
                                           'iphone_duo_outer', '--locales', 'en', '--count', '1']), \
                    patch.object(prepare.subprocess, 'run', side_effect=convert):
                prepare.main()
            manifest = json.loads((root / 'manifest.json').read_text())
            self.assertEqual(manifest[0], prior[0])
            self.assertEqual(manifest[1]['device'], 'iphone_duo_outer')
            self.assertTrue((root / 'upload/iphone_duo_outer/en/01-home.jpg').exists())

    def test_prepare_shrinks_and_renames_only_selected_jpeg_sets(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            selected = root / 'iphone_duo_outer/en'
            selected_upload = root / 'upload/iphone_duo_outer/en'
            for folder in (selected, selected_upload):
                folder.mkdir(parents=True)
                for name in ('01-old-name.jpg', '02-removed.jpg', '03-removed.jpeg', 'reference.jpg'):
                    (folder / name).write_bytes(b'old image')
            unselected = [root / 'iphone_duo_outer/zh-Hans/02-keep.jpg',
                          root / 'upload/iphone_duo_outer/zh-Hans/02-keep.jpg',
                          root / 'iphone_duo_inner/en/02-keep.jpg',
                          root / 'upload/iphone_duo_inner/en/02-keep.jpg']
            for path in unselected:
                path.parent.mkdir(parents=True)
                path.write_bytes(b'unselected image')
            Image.new('RGB', (1398, 2034), 'white').save(selected / '01-new-name.png')

            def convert(command, **kwargs):
                with Image.open(command[-3]) as image:
                    image.convert('RGB').save(command[-1])

            with patch.object(sys, 'argv', ['prepare.py', '--root', str(root), '--devices',
                                           'iphone_duo_outer', '--locales', 'en', '--count', '1']), \
                    patch.object(prepare.subprocess, 'run', side_effect=convert):
                prepare.main()
            for folder in (selected, selected_upload):
                self.assertEqual(sorted(path.name for path in folder.glob('*.jpg')),
                                 ['01-new-name.jpg', 'reference.jpg'])
                self.assertFalse((folder / '03-removed.jpeg').exists())
            for path in unselected:
                self.assertEqual(path.read_bytes(), b'unselected image')
            manifest = json.loads((root / 'manifest.json').read_text())
            self.assertEqual([item['path'] for item in manifest], ['iphone_duo_outer/en/01-new-name.jpg'])


class LibraryTests(unittest.TestCase):
    def test_discovers_group_and_shared_limit(self):
        groups = apple_library.screenshot_groups(reference_data(), upload.APPLE_LIBRARY_DEVICES, 5)
        self.assertEqual(list(groups), ['discovered-duo-group'])
        self.assertEqual(len(groups['discovered-duo-group']['devices']), 2)
        with self.assertRaisesRegex(ValueError, '16 screenshots exceed Apple limit 10'):
            apple_library.screenshot_groups(reference_data(), upload.APPLE_LIBRARY_DEVICES, 8)

    def test_library_commit_uses_uploaded_without_legacy_checksum(self):
        class Api:
            calls = []

            def call(self, store, method, url, **kwargs):
                self.calls.append((method, url, kwargs))
                if method == 'GET':
                    return {'data': []}
                if method == 'POST':
                    return {'data': {'id': 'new-image', 'attributes': {'uploadOperations': [{
                        'method': 'PUT', 'url': 'https://storage.example/upload', 'offset': 0,
                        'length': 3, 'requestHeaders': [{'name': 'Content-Type', 'value': 'image/jpeg'}],
                    }]}}}
                return {'data': {'id': 'new-image', 'attributes': {'state': 'UPLOAD_COMPLETE'}}}

        api = Api()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'sample.jpg'
            path.write_bytes(b'jpg')
            with patch.object(apple_library.requests, 'request') as request:
                request.return_value.ok = True
                apple_library.upload_image(api, root, 'library', path, 'content-hash-reference')
                self.assertEqual(request.call_args.kwargs['headers'], {'Content-Type': 'image/jpeg'})
                self.assertEqual(request.call_args.kwargs['data'], b'jpg')
        self.assertEqual(api.calls[-1][2]['json']['data']['attributes'], {'uploaded': True})
        self.assertEqual(api.calls[1][2]['json']['data']['relationships']['assetLibrary']['data']['id'], 'library')

    def test_completed_content_hash_asset_is_reused(self):
        class Api:
            def call(self, store, method, url, **kwargs):
                self.asserted = method == 'GET'
                return {'data': [{'id': 'existing', 'attributes': {
                    'referenceName': 'content-hash-reference', 'state': 'PREPARE_FOR_SUBMISSION',
                }}]}

        api = Api()
        image = apple_library.upload_image(api, Path('/unused'), 'library', Path('/unused'),
                                           'content-hash-reference')
        self.assertEqual(image['id'], 'existing')
        self.assertTrue(api.asserted)

    def test_scoped_outer_replacement_preserves_inner_placements(self):
        def placement(identifier, image):
            return {'id': identifier, 'type': 'appAssetLibraryPlacements',
                    'attributes': {'state': 'PARENT_PREPARE_FOR_SUBMISSION',
                                   'placementType': 'APP_SCREENSHOT', 'placementGroup': 'group'},
                    'relationships': {'image': {'data': {'id': image, 'type': 'appAssetLibraryImages'}}}}

        class Api:
            def __init__(self):
                self.placements = [placement('old-outer', 'old-outer-image'),
                                   placement('old-inner', 'old-inner-image')]
                self.deleted = []

            def call(self, store, method, url, **kwargs):
                if method == 'GET':
                    return {'data': copy.deepcopy(self.placements), 'included': [{
                        'id': 'old-outer-image', 'type': 'appAssetLibraryImages', 'attributes': {'specId': 'outer-spec'},
                    }, {'id': 'old-inner-image', 'type': 'appAssetLibraryImages', 'attributes': {'specId': 'inner-spec'}}]}
                if method == 'DELETE':
                    identifier = url.rsplit('/', 1)[1]
                    self.deleted.append(identifier)
                    self.placements = [item for item in self.placements if item['id'] != identifier]
                    return {}
                if url.endswith('/appAssetLibraryPlacements'):
                    image_id = kwargs['json']['data']['relationships']['image']['data']['id']
                    created = placement('new-outer-placement', image_id)
                    self.placements.append(created)
                    return {'data': created}
                ids = [item['id'] for item in kwargs['json']['data']['relationships']['orderedPlacements']['data']]
                self.placements.sort(key=lambda item: ids.index(item['id']))
                return {'data': {'id': 'ordering'}}

        api = Api()
        item = {'locale': 'en-US', 'localizationId': 'locale', 'placementGroup': 'group', 'maxCount': 10,
                'images': [{'imageId': 'new-outer-image', 'specIds': ['outer-spec']}]}
        with tempfile.TemporaryDirectory() as directory:
            apple_library.place_group(api, Path(directory), '1.12.0', item)
        self.assertEqual(api.deleted, ['old-outer'])
        self.assertEqual([placement['id'] for placement in api.placements], ['new-outer-placement', 'old-inner'])
        self.assertEqual(item['state'], 'VERIFIED')

    def test_resume_verifies_live_active_placements_without_recreating_images(self):
        existing = {'id': 'existing-placement', 'type': 'appAssetLibraryPlacements',
                    'attributes': {'state': 'ACTIVE', 'stateDetails': None,
                                   'placementType': 'APP_SCREENSHOT', 'mediaType': 'IMAGE',
                                   'placementGroup': 'IPHONE_DUO_PROFILE'},
                    'relationships': {'image': {'data': {
                        'type': 'appAssetLibraryImages', 'id': 'processed-image'}}}}

        class Api:
            def __init__(self):
                self.calls = []

            def call(self, store, method, url, **kwargs):
                self.calls.append((method, url))
                if method == 'GET':
                    return {'data': [copy.deepcopy(existing)]}
                if method == 'POST' and url.endswith('/appAssetLibraryPlacementOrderingRequests'):
                    return {'data': {'id': 'ordering'}}
                raise AssertionError('Resume must only read existing placements and apply ordering')

        for state in ('ACTIVE', 'ASSET_PROCESSING', 'FAILED', 'UNKNOWN'):
            with self.subTest(state=state), tempfile.TemporaryDirectory() as directory:
                existing['attributes']['state'] = state
                api = Api()
                item = {'locale': 'en-US', 'localizationId': 'locale',
                        'placementGroup': 'IPHONE_DUO_PROFILE', 'maxCount': 10,
                        'images': [{'imageId': 'processed-image', 'specIds': ['outer-spec']}]}
                if state == 'ACTIVE':
                    apple_library.place_group(api, Path(directory), '1.12.0', item)
                    self.assertEqual(item['state'], 'VERIFIED')
                else:
                    with self.assertRaisesRegex(RuntimeError, 'order, images, or processing state'):
                        apple_library.place_group(api, Path(directory), '1.12.0', item)
                self.assertEqual([method for method, _ in api.calls], ['GET', 'POST', 'GET'])

    def test_scope_guard_rejects_other_groups_and_localizations(self):
        class Api:
            def call(self, store, method, url, **kwargs):
                return {'data': [{'attributes': {'placementType': 'APP_SCREENSHOT',
                                                'placementGroup': 'OTHER_GROUP'}}]}

        with self.assertRaisesRegex(RuntimeError, 'outside the requested screenshot group'):
            apple_library.read_placements(Api(), 'locale', 'IPHONE_DUO_PROFILE')


if __name__ == '__main__':
    unittest.main()
