"""Offline regressions for shared/localized artwork and scoped draft placement."""

import copy
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'store_screenshots'))
import upload_creative_assets as creative


def reference_data():
    types = creative.PLACEMENTS
    specs = []
    for name, size in creative.DEFAULT_SIZES.items():
        specs.append({'specId': f'{name}-spec',
                      'dimensions': {'minWidth': size[0], 'maxWidth': size[0],
                                     'minHeight': size[1], 'maxHeight': size[1]},
                      'compatiblePlacementTypes': [types[name]],
                      'aspectRatio': '21:9' if name == 'header' else '3:2',
                      'fileExtensions': ['.png'], 'mimeTypes': ['image/png'], 'maxFileSize': 524288000})
    return {'data': [{'attributes': {
        'imageSpecs': specs,
        'placementProfileGroups': [{'placementProfileGroupId': 'live-default', 'platform': 'ANY'}],
        'features': [{'featureId': 'APP_STORE_VERSIONS', 'placementPolicies': [
            {'placementType': value, 'groupLimits': [{'groupIds': ['live-default'], 'maxCount': 1}]}
            for value in types.values()
        ]}],
        'placementTypes': [{'placementTypeId': value, 'acceptsAssetCategories': ['CREATIVE_ASSETS'],
                            'specMappings': [{'placementGroupId': 'live-default', 'specs': [f'{key}-spec']}]}
                           for key, value in types.items()],
    }}]}


def placement(identifier, placement_type, group, image=None, video=None):
    return {'id': identifier, 'type': 'appAssetLibraryPlacements',
            'attributes': {'placementType': placement_type, 'placementGroup': group,
                           'state': 'ACTIVE', 'stateDetails': None},
            'relationships': {
                'image': {'data': {'type': 'appAssetLibraryImages', 'id': image} if image else None},
                'video': {'data': {'type': 'appAssetLibraryVideos', 'id': video} if video else None},
            }}


class FakeApi:
    def __init__(self, placements=None):
        self.placements = placements or {}
        self.images = {}
        self.calls = []

    def call(self, store, method, url, **kwargs):
        self.calls.append((method, url, kwargs))
        if method == 'GET' and '/appAssetLibraries/' in url:
            reference = kwargs['params']['filter[referenceName]']
            return {'data': [copy.deepcopy(image) for image in self.images.values()
                             if image['attributes']['referenceName'] == reference]}
        if method == 'POST' and url.endswith('/appAssetLibraryImages'):
            attributes = copy.deepcopy(kwargs['json']['data']['attributes'])
            name = 'header' if '-header-' in attributes['referenceName'] else 'search'
            width, height = creative.DEFAULT_SIZES[name]
            attributes.update({'state': 'AWAITING_UPLOAD', 'stateDetails': None,
                               'imageAsset': {'width': width, 'height': height}, 'specId': f'{name}-spec',
                               'uploadOperations': [{'method': 'PUT', 'url': 'https://storage.example/signed',
                                                      'offset': 0, 'length': attributes['fileSize'],
                                                      'requestHeaders': [{'name': 'Content-Type', 'value': 'image/png'}]}]})
            image_id = f'image-{name}'
            if image_id in self.images:
                image_id += f'-{len(self.images)}'
            image = {'id': image_id, 'type': 'appAssetLibraryImages', 'attributes': attributes}
            self.images[image['id']] = image
            return {'data': copy.deepcopy(image)}
        if '/appAssetLibraryImages/' in url:
            image = self.images[url.rsplit('/', 1)[1]]
            if method == 'PATCH':
                if kwargs['json']['data']['attributes'] != {'uploaded': True}:
                    raise AssertionError('Creative image commits must use uploaded alone')
                image['attributes']['state'] = 'PREPARE_FOR_SUBMISSION'
            return {'data': copy.deepcopy(image)}
        if method == 'GET' and url.endswith('/placements'):
            locale = url.rsplit('/', 2)[1]
            values = self.placements.get(locale, [])
            params = kwargs['params']
            if 'filter[placementType]' in params:
                values = [item for item in values if item['attributes']['placementType'] == params['filter[placementType]']
                          and item['attributes']['placementGroup'] == params['filter[placementGroup]']]
            return {'data': copy.deepcopy(values), 'included': []}
        if method == 'POST' and url.endswith('/appAssetLibraryPlacements'):
            data = kwargs['json']['data']
            locale = data['relationships']['appStoreVersionLocalization']['data']['id']
            created = placement(f'new-{locale}-{data["attributes"]["placementType"]}',
                                data['attributes']['placementType'], data['attributes']['placementGroup'],
                                image=data['relationships']['image']['data']['id'])
            self.placements.setdefault(locale, []).append(created)
            return {'data': copy.deepcopy(created)}
        if method == 'DELETE' and '/appAssetLibraryPlacements/' in url:
            identifier = url.rsplit('/', 1)[1]
            for values in self.placements.values():
                values[:] = [item for item in values if item['id'] != identifier]
            return {}
        raise AssertionError(f'Unexpected remote operation: {method} {url}')


class CreativeAssetTests(unittest.TestCase):
    def test_live_reference_controls_format_category_group_and_dimensions(self):
        images = {name: {'size': size, 'extension': '.png', 'mimeType': 'image/png', 'fileSize': 100}
                  for name, size in creative.DEFAULT_SIZES.items()}
        result = creative.resolve_targets(reference_data(), images)
        self.assertEqual(result['header']['placementType'], 'PRODUCT_PAGE_HEADER_ASSET')
        self.assertEqual(result['search']['placementType'], 'APP_STORE_SEARCH_RESULTS_ASSET')
        self.assertEqual(result['header']['placementGroup'], 'live-default')
        self.assertEqual(result['header']['category'], 'CREATIVE_ASSETS')
        images['header'].update({'extension': '.jpg', 'mimeType': 'image/jpeg'})
        with self.assertRaisesRegex(ValueError, 'header: expected one Apple creative'):
            creative.resolve_targets(reference_data(), images)

    def test_artwork_rejects_alpha_and_misnamed_formats(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'transparent.png'
            Image.new('RGBA', (4, 4), (255, 255, 255, 255)).save(path)
            with self.assertRaisesRegex(ValueError, 'without an alpha channel'):
                creative.image_info(path)
            path = Path(directory) / 'misnamed.jpg'
            Image.new('RGB', (4, 4), 'white').save(path, format='PNG')
            with self.assertRaisesRegex(ValueError, 'extension does not match'):
                creative.image_info(path)

    def test_all_existing_localizations_are_selected_without_creation(self):
        localizations = [{'id': f'locale-{i}', 'attributes': {'locale': f'language-{i}'}} for i in range(19)]
        self.assertEqual(creative.select_localizations(localizations, 'all'), localizations)
        with self.assertRaisesRegex(ValueError, 'Unknown'):
            creative.select_localizations(localizations, 'missing')

    def test_screenshot_guard_preserves_order_within_groups_without_assuming_group_order(self):
        first = placement('first', 'APP_SCREENSHOT', 'phone', image='one')
        second = placement('second', 'APP_SCREENSHOT', 'phone', image='two')
        tablet = placement('tablet', 'APP_SCREENSHOT', 'tablet', image='three')
        before = creative.untouched_signature([first, tablet, second])
        self.assertEqual(before, creative.untouched_signature([tablet, first, second]))
        self.assertNotEqual(before, creative.untouched_signature([second, tablet, first]))
        api = FakeApi({'locale': [first, tablet, second]})
        creative.read_placements(api, 'locale')
        self.assertEqual(api.calls[-1][2]['params']['sort'], 'placementGroupPosition')

    def test_manifest_resolves_relative_paths_and_rejects_incomplete_or_duplicate_entries(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'en-US').mkdir()
            for kind in creative.PLACEMENTS:
                Image.new('RGB', (4, 4), 'white').save(root / 'en-US' / f'{kind}.png')
            manifest = root / 'manifest.json'
            manifest.write_text(json.dumps({'locales': {'en-US': {
                'header': 'en-US/header.png', 'search': str(root / 'en-US/search.png')}}}))
            images = creative.load_manifest(manifest)
            self.assertEqual(images['en-US']['header']['path'], str((root / 'en-US/header.png').resolve()))
            self.assertEqual(images['en-US']['search']['path'], str((root / 'en-US/search.png').resolve()))
            manifest.write_text('{"locales":{"en-US":{"header":"en-US/header.png"}}}')
            with self.assertRaisesRegex(ValueError, 'exactly header and search'):
                creative.load_manifest(manifest)
            manifest.write_text('{"locales":{"en-US":{},"en-US":{}}}')
            with self.assertRaisesRegex(ValueError, 'Duplicate manifest key'):
                creative.load_manifest(manifest)

    def test_manifest_requires_selected_existing_locales_and_deduplicates_identical_files(self):
        locales = {'en-US': {}, 'fr-FR': {}}
        with self.assertRaisesRegex(ValueError, 'missing selected'):
            creative.select_manifest_images({'en-US': {}}, 'all', ['en-US', 'fr-FR'])
        with self.assertRaisesRegex(ValueError, 'unknown existing'):
            creative.select_manifest_images({**locales, 'typo': {}}, 'en-US', list(locales))
        self.assertEqual(list(creative.select_manifest_images(locales, 'fr-FR', list(locales))), ['fr-FR'])
        images = {name: {'size': size, 'extension': '.png', 'mimeType': 'image/png',
                         'fileSize': 100, 'sha256': name}
                  for name, size in creative.DEFAULT_SIZES.items()}
        plan = creative.image_plan(reference_data(), locale_images={'en-US': images, 'fr-FR': images})
        self.assertEqual(len(plan['images']), 2)
        self.assertEqual(plan['localizations']['en-US'], plan['localizations']['fr-FR'])

    def test_38_localized_assets_replace_only_creatives_after_global_backup_and_processing(self):
        reference = reference_data()
        original = {}
        for i in range(19):
            original[f'locale-{i}'] = [
                placement(f'old-header-{i}', creative.PLACEMENTS['header'], 'live-default', image='old-header'),
                placement(f'old-search-{i}', creative.PLACEMENTS['search'], 'live-default', image='old-search'),
                *[placement(f'screenshot-{i}-{j}', 'APP_SCREENSHOT', 'IPHONE_DUO_PROFILE',
                            image=f'screenshot-image-{i}-{j}') for j in range(34 if i < 3 else 0)],
            ]
        guard = {'attributes': {'platform': 'IOS', 'versionString': '1.12.0',
                                'appStoreState': 'PREPARE_FOR_SUBMISSION', 'releaseType': 'MANUAL'},
                 'build': {'type': 'builds', 'id': 'build-22'}}
        context = {'versionId': 'version', 'libraryId': 'library', 'versionGuard': guard,
                   'localizations': [{'id': key, 'locale': f'language-{i}',
                                      'placements': {'data': copy.deepcopy(values)}}
                                     for i, (key, values) in enumerate(original.items())]}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            testcase = self

            class GuardedApi(FakeApi):
                def call(self, store, method, url, **kwargs):
                    if method == 'DELETE':
                        testcase.assertEqual(len(list((root / 'backup').rglob('*.json'))), 38)
                        testcase.assertEqual(len(self.images), 40)
                        testcase.assertTrue(all(image['attributes']['state'] in creative.READY_STATES
                                                for image in self.images.values()))
                    return super().call(store, method, url, **kwargs)

            api = GuardedApi(copy.deepcopy(original))
            for name in creative.PLACEMENTS:
                api.images[f'old-{name}'] = {'id': f'old-{name}', 'attributes': {
                    'referenceName': f'old-{name}', 'state': 'PREPARE_FOR_SUBMISSION'}}
            images = {}
            for i in range(19):
                images[f'language-{i}'] = {}
                for name, size in creative.DEFAULT_SIZES.items():
                    path = root / f'{i}-{name}.png'
                    Image.new('RGB', size, (i + 1, 20 if name == 'header' else 40, 100)).save(path)
                    images[f'language-{i}'][name] = creative.image_info(path)
            with patch.object(creative, 'inspect', return_value=(context, reference)), \
                    patch.object(creative, 'version_guard', return_value=guard), \
                    patch.object(creative.requests, 'request') as transfer, redirect_stdout(io.StringIO()):
                transfer.return_value.ok = True
                creative.upload(api, root, '1.12.0', locale_images=images)
                # A new inspection on resume sees the newly installed placement IDs.
                resumed = copy.deepcopy(context)
                for locale in resumed['localizations']:
                    locale['placements']['data'] = copy.deepcopy(api.placements[locale['id']])
                with patch.object(creative, 'inspect', return_value=(resumed, reference)):
                    creative.upload(api, root, '1.12.0', locale_images=images)
                self.assertEqual(transfer.call_count, 38)
            report = json.loads((root / 'apple-creative-upload-report.json').read_text())
            self.assertEqual(report['state'], 'VERIFIED')
            self.assertEqual(len(report['images']), 38)
            self.assertEqual(len(report['placements']), 38)
            self.assertEqual(report['screenshotCountPreserved'], 102)
            self.assertTrue(report['mappedImagesVerified'])
            self.assertTrue(report['screenshotOrderingPreserved'])
            self.assertTrue(report['versionAndBuildUnchanged'])
            for locale in report['placements']:
                kind = next(name for name, value in creative.PLACEMENTS.items() if value == locale['placementType'])
                self.assertEqual(locale['sha256'], images[locale['locale']][kind]['sha256'])
                remote = next(p for p in api.placements[locale['localizationId']] if p['id'] == locale['placementId'])
                self.assertEqual(creative.image_relation(remote), locale['imageId'])
            backups = list((root / 'backup').rglob('*.json'))
            self.assertEqual(len(backups), 38)
            self.assertTrue(all(json.loads(path.read_text())['data'][0]['id'].startswith('old-') for path in backups))
            self.assertEqual(len(api.images), 40)
        writes = [(method, url) for method, url, _ in api.calls if method != 'GET']
        self.assertEqual(sum(method == 'DELETE' for method, _ in writes), 38)
        self.assertEqual(sum(method == 'POST' and url.endswith('/appAssetLibraryImages') for method, url in writes), 38)
        self.assertFalse(any('/appStoreVersions/' in url or '/appAssetLibraryImages/' in url
                             for method, url in writes if method == 'DELETE'))
        self.assertEqual(sum(p['attributes']['placementType'] == 'APP_SCREENSHOT'
                             for values in api.placements.values() for p in values), 102)

    def test_failed_image_processing_keeps_every_original_placement(self):
        original = [placement('old-header', creative.PLACEMENTS['header'], 'live-default', image='old-image')]

        class FailedImageApi(FakeApi):
            def call(self, store, method, url, **kwargs):
                result = super().call(store, method, url, **kwargs)
                if method == 'GET' and url.endswith('/appAssetLibraryImages/image-search'):
                    result['data']['attributes']['state'] = 'FAILED'
                return result

        api = FailedImageApi({'locale': copy.deepcopy(original)})
        guard = {'build': 'build-22'}
        context = {'versionId': 'version', 'libraryId': 'library', 'versionGuard': guard,
                   'localizations': [{'id': 'locale', 'locale': 'en-US', 'placements': {'data': original}}]}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            images = {}
            for name, size in creative.DEFAULT_SIZES.items():
                path = root / f'{name}.png'
                Image.new('RGB', size, 'white').save(path)
                images[name] = creative.image_info(path)
            with patch.object(creative, 'inspect', return_value=(context, reference_data())), \
                    patch.object(creative.requests, 'request') as transfer, redirect_stdout(io.StringIO()):
                transfer.return_value.ok = True
                with self.assertRaisesRegex(RuntimeError, 'processing failed'):
                    creative.upload(api, root, '1.12.0', locale_images={'en-US': images})
        self.assertEqual(api.placements['locale'], original)
        self.assertFalse(any(method == 'DELETE' for method, _, _ in api.calls))

    def test_two_images_cover_19_localizations_and_resume_without_duplicates(self):
        reference = reference_data()
        api = FakeApi({f'locale-{i}': [placement(f'screenshot-{i}', 'APP_SCREENSHOT', 'IPHONE_DUO_PROFILE',
                                               image=f'screenshot-image-{i}')] for i in range(19)})
        context = {'versionId': 'version', 'libraryId': 'library', 'versionGuard': {'build': 'existing-build'},
                   'localizations': [{'id': f'locale-{i}', 'locale': f'language-{i}',
                                      'placements': {'data': copy.deepcopy(api.placements[f'locale-{i}'])}}
                                     for i in range(19)]}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            images = {}
            for name, size in creative.DEFAULT_SIZES.items():
                path = root / f'{name}.png'
                Image.new('RGB', size, 'white').save(path)
                images[name] = creative.image_info(path)
            with patch.object(creative, 'inspect', return_value=(context, reference)), \
                    patch.object(creative, 'version_guard', return_value=context['versionGuard']), \
                    patch.object(creative.requests, 'request') as transfer, redirect_stdout(io.StringIO()):
                transfer.return_value.ok = True
                creative.upload(api, root, '1.12.0', images)
                resumed = copy.deepcopy(context)
                for locale in resumed['localizations']:
                    locale['placements']['data'] = copy.deepcopy(api.placements[locale['id']])
                with patch.object(creative, 'inspect', return_value=(resumed, reference)):
                    creative.upload(api, root, '1.12.0', images)
                self.assertEqual(transfer.call_count, 2)
                for call in transfer.call_args_list:
                    self.assertEqual(call.kwargs['headers'], {'Content-Type': 'image/png'})
            report = json.loads((root / 'apple-creative-upload-report.json').read_text())
            self.assertEqual(report['state'], 'VERIFIED')
            self.assertEqual(len(report['images']), 2)
            self.assertEqual(len(report['placements']), 38)
            self.assertTrue(report['unrelatedPlacementsUnchanged'])
            self.assertTrue(report['versionAndBuildUnchanged'])
            self.assertTrue((root / 'apple-creative-1.12.0-before.json').exists())
            self.assertEqual(len(list((root / 'backup').rglob('*.json'))), 38)
        writes = [(method, url) for method, url, _ in api.calls if method != 'GET']
        self.assertEqual(sum(method == 'POST' and url.endswith('/appAssetLibraryImages') for method, url in writes), 2)
        self.assertEqual(sum(method == 'POST' and url.endswith('/appAssetLibraryPlacements') for method, url in writes), 38)
        self.assertFalse(any(method == 'DELETE' for method, _ in writes))
        self.assertEqual(len(api.images), 2)
        self.assertEqual(sum(item['attributes']['placementType'] == 'APP_SCREENSHOT'
                             for values in api.placements.values() for item in values), 19)

    def test_video_header_replacement_preserves_search_and_screenshot_assets(self):
        original = [placement('old-header', creative.PLACEMENTS['header'], 'live-default', video='old-video'),
                    placement('keep-search', creative.PLACEMENTS['search'], 'live-default', video='search-video'),
                    placement('keep-screenshot', 'APP_SCREENSHOT', 'IPHONE_DUO_PROFILE', image='screenshot-image')]
        api = FakeApi({'locale': copy.deepcopy(original)})
        target = {'placementType': creative.PLACEMENTS['header'], 'placementGroup': 'live-default', 'imageId': 'new-header'}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = creative.attach(api, root, '1.12.0', {'id': 'locale', 'locale': 'en-US'}, target)
            backup = json.loads(next((root / 'backup').rglob('*.json')).read_text())
            self.assertEqual(backup['data'][0]['relationships']['video']['data']['id'], 'old-video')
        self.assertEqual(result['state'], 'VERIFIED')
        deleted = [url.rsplit('/', 1)[1] for method, url, _ in api.calls if method == 'DELETE']
        self.assertEqual(deleted, ['old-header'])
        self.assertTrue(all(item in api.placements['locale'] for item in original[1:]))
        self.assertFalse(any('/appAssetLibraryVideos/' in url or '/appAssetLibraryImages/' in url
                             for method, url, _ in api.calls if method == 'DELETE'))

    def test_interrupted_reservation_resumes_without_exposing_signed_url(self):
        api = FakeApi()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'header.png'
            Image.new('RGB', (4, 4), 'white').save(path)
            target = creative.image_info(path)
            with patch.object(creative.requests, 'request', side_effect=creative.requests.RequestException(
                    'secret signed URL https://storage.example/?signature=sensitive')):
                with self.assertRaisesRegex(RuntimeError, 'transport error') as failure:
                    creative.upload_image(api, root, 'library', 'header', target, '1.12.0')
                self.assertNotIn('signature', str(failure.exception))
            self.assertEqual(len(api.images), 1)
            self.assertEqual(api.images['image-header']['attributes']['state'], 'AWAITING_UPLOAD')
            with patch.object(creative.requests, 'request') as transfer:
                transfer.return_value.ok = True
                resumed = creative.upload_image(api, root, 'library', 'header', target, '1.12.0')
            self.assertEqual(resumed['id'], 'image-header')
            self.assertEqual(resumed['attributes']['state'], 'PREPARE_FOR_SUBMISSION')
        reservations = [url for method, url, _ in api.calls if method == 'POST' and url.endswith('/appAssetLibraryImages')]
        self.assertEqual(len(reservations), 1)

    def test_scope_guard_refuses_wrong_slot_before_deletion(self):
        class WrongSlotApi:
            def call(self, store, method, url, **kwargs):
                if method != 'GET':
                    raise AssertionError('No mutations permitted after a scope mismatch')
                return {'data': [placement('wrong', 'APP_SCREENSHOT', 'IPHONE_DUO_PROFILE', image='old')]}

        with tempfile.TemporaryDirectory() as directory, self.assertRaisesRegex(RuntimeError, 'outside the selected creative slot'):
            creative.attach(WrongSlotApi(), Path(directory), '1.12.0', {'id': 'locale', 'locale': 'en-US'},
                            {'placementType': creative.PLACEMENTS['header'], 'placementGroup': 'live-default', 'imageId': 'new'})


if __name__ == '__main__':
    unittest.main()
