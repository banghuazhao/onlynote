"""Inspect and attach Header/Search Results artwork to an existing iOS draft.

Use inspect to cache Apple's current specifications and placements, validate for
an offline artwork check, and upload --execute to attach the prepared images.
Use two shared images or a locale-to-file manifest. Existing library images are
retained. This tool never creates versions, uploads builds, or submits review.
"""

import argparse
import hashlib
import json
import time
from pathlib import Path

import requests
from PIL import Image

from apple_library import READY_PLACEMENT_STATES, READY_STATES, pages
from upload import APPLE_BASE, APP_ID, StoreApi, apple_version, save


CATEGORY = 'CREATIVE_ASSETS'
PLACEMENTS = {
    'header': 'PRODUCT_PAGE_HEADER_ASSET',
    'search': 'APP_STORE_SEARCH_RESULTS_ASSET',
}
DEFAULT_SIZES = {'header': (3840, 1646), 'search': (3840, 2560)}
DEFAULT_ROOT = Path('build/store_assets/2026-10-26')


def image_info(path):
    with Image.open(path) as image:
        if image.mode != 'RGB' or image.format not in {'PNG', 'JPEG'}:
            raise ValueError(f'{path}: expected an RGB PNG or JPEG without an alpha channel')
        extensions = {'.png'} if image.format == 'PNG' else {'.jpg', '.jpeg'}
        if path.suffix.lower() not in extensions:
            raise ValueError(f'{path}: file extension does not match its image format')
        mime = 'image/png' if image.format == 'PNG' else 'image/jpeg'
        size = image.size
    return {'path': str(path), 'size': size, 'extension': path.suffix.lower(), 'mimeType': mime,
            'fileSize': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def load_manifest(path):
    """Load {locales: {en-US: {header: path, search: path}}}; paths are manifest-relative."""
    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f'Duplicate manifest key: {key}')
            result[key] = value
        return result

    manifest = json.loads(path.read_text(), object_pairs_hook=unique_object)
    if (not isinstance(manifest, dict) or set(manifest) != {'locales'}
            or not isinstance(manifest['locales'], dict) or not manifest['locales']):
        raise ValueError('Manifest must contain one nonempty locales object')
    images = {}
    for locale, entries in manifest['locales'].items():
        if not isinstance(locale, str) or not locale or locale.strip() != locale:
            raise ValueError('Manifest locale keys must be nonempty locale identifiers')
        if not isinstance(entries, dict) or set(entries) != set(PLACEMENTS):
            raise ValueError(f'{locale}: manifest requires exactly header and search paths')
        images[locale] = {}
        for name, value in entries.items():
            if not isinstance(value, str) or not value.strip():
                raise ValueError(f'{locale}/{name}: expected a nonempty image path')
            image_path = Path(value).expanduser()
            if not image_path.is_absolute():
                image_path = path.parent / image_path
            images[locale][name] = image_info(image_path.resolve())
    return images


def select_manifest_images(images, selected='all', available=None):
    if available is not None and set(images) - set(available):
        raise ValueError(f'Manifest has unknown existing localizations: {sorted(set(images) - set(available))}')
    locales = (list(available if available is not None else images) if selected == 'all'
               else list(dict.fromkeys(value.strip() for value in selected.split(','))))
    missing = set(locales) - images.keys()
    if not locales or missing or '' in locales:
        raise ValueError(f'Manifest is missing selected localizations: {sorted(missing)}')
    if available is not None and set(locales) - set(available):
        raise ValueError(f'Unknown existing localizations: {sorted(set(locales) - set(available))}')
    return {locale: images[locale] for locale in locales}


def image_plan(reference, images=None, locale_images=None):
    """Resolve every image before upload, deduplicating matching bytes within each slot."""
    if bool(images) == bool(locale_images):
        raise ValueError('Supply shared images or localized manifest images, exclusively')
    if images:
        if set(images) != set(PLACEMENTS):
            raise ValueError('Both shared header and search images are required')
        return {'images': {name: {**target, 'assetKind': name}
                           for name, target in resolve_targets(reference, images).items()},
                'localizations': {}}
    unique = {}
    localizations = {}
    for locale, entries in locale_images.items():
        resolved = resolve_targets(reference, entries)
        if set(resolved) != set(PLACEMENTS):
            raise ValueError(f'{locale}: both creative image kinds are required')
        localizations[locale] = {}
        for name, target in resolved.items():
            key = f'{name}-{target["sha256"]}'
            unique.setdefault(key, {**target, 'assetKind': name})
            localizations[locale][name] = key
    return {'images': unique, 'localizations': localizations}


def spec_matches(spec, image):
    width, height = image['size']
    dimensions = spec.get('dimensions', {})
    if not (dimensions.get('minWidth', 0) <= width <= dimensions.get('maxWidth', -1)
            and dimensions.get('minHeight', 0) <= height <= dimensions.get('maxHeight', -1)
            and image['extension'] in spec.get('fileExtensions', [])
            and image['mimeType'] in spec.get('mimeTypes', [])
            and image['fileSize'] <= spec.get('maxFileSize', 0)):
        return False
    if spec.get('aspectRatio'):
        numerator, denominator = (float(value) for value in spec['aspectRatio'].split(':'))
        # Apple's exact header dimensions round 21:9 to a whole pixel.
        if abs(width * denominator - height * numerator) > max(numerator, denominator):
            return False
    return True


def resolve_targets(reference, images):
    targets = {}
    for name, image in images.items():
        placement_type = PLACEMENTS[name]
        candidates = {}
        for resource in reference['data']:
            attributes = resource['attributes']
            specs = {spec['specId'] for spec in attributes.get('imageSpecs', [])
                     if placement_type in spec.get('compatiblePlacementTypes', []) and spec_matches(spec, image)}
            profiles = {profile['placementProfileGroupId'] for profile in attributes.get('placementProfileGroups', [])
                        if profile.get('platform') in {'ANY', 'IPHONE_APP_STORE', 'IPAD_APP_STORE'}}
            limits = {}
            for feature in attributes.get('features', []):
                if feature['featureId'] == 'APP_STORE_VERSIONS':
                    for policy in feature.get('placementPolicies', []):
                        if policy['placementType'] == placement_type:
                            for limit in policy.get('groupLimits', []):
                                limits.update({group: limit['maxCount'] for group in limit['groupIds']})
            for placement in attributes.get('placementTypes', []):
                if (placement['placementTypeId'] != placement_type
                        or CATEGORY not in placement.get('acceptsAssetCategories', [])):
                    continue
                for mapping in placement.get('specMappings', []):
                    group = mapping['placementGroupId']
                    matching = specs.intersection(mapping.get('specs', []))
                    if group in profiles and limits.get(group) == 1 and matching:
                        candidates[group] = sorted(matching)
        if len(candidates) != 1:
            raise ValueError(f'{name}: expected one Apple creative placement group/spec for '
                             f'{image["size"]} {image["extension"]}; found {sorted(candidates)}')
        group, specs = next(iter(candidates.items()))
        targets[name] = {**image, 'placementType': placement_type, 'placementGroup': group,
                         'specIds': specs, 'category': CATEGORY, 'maxCount': 1}
    return targets


def select_localizations(localizations, selected):
    available = {item['attributes']['locale']: item for item in localizations}
    locales = list(available) if selected == 'all' else list(dict.fromkeys(value.strip() for value in selected.split(',')))
    if not locales or set(locales) - available.keys():
        raise ValueError(f'Unknown or empty existing localizations: {sorted(set(locales) - available.keys())}')
    return [available[locale] for locale in locales]


def read_placements(api, localization_id, target=None):
    # Apple exposes display order only through this sort key, not an attribute:
    # https://developer.apple.com/documentation/appstoreconnectapi/placing-assets-on-your-app-store-surfaces
    params = {'include': 'image,video', 'sort': 'placementGroupPosition', 'limit': 200}
    if target:
        params.update({'filter[placementType]': target['placementType'],
                       'filter[placementGroup]': target['placementGroup']})
    result = pages(api, f'{APPLE_BASE}/appStoreVersionLocalizations/{localization_id}/placements', params=params)
    for placement in result['data']:
        parent = placement.get('relationships', {}).get('appStoreVersionLocalization', {}).get('data')
        if parent and parent['id'] != localization_id:
            raise RuntimeError('Apple returned placements for a different localization')
        if target and any(placement['attributes'].get(key) != target[key]
                          for key in ('placementType', 'placementGroup')):
            raise RuntimeError('Apple returned placements outside the selected creative slot')
    return result


def version_guard(api, version_id):
    version = api.call('apple', 'GET', f'{APPLE_BASE}/appStoreVersions/{version_id}',
                       params={'include': 'build'})['data']
    build = version.get('relationships', {}).get('build', {})
    if 'data' not in build:
        build = api.call('apple', 'GET', f'{APPLE_BASE}/appStoreVersions/{version_id}/relationships/build')
    keys = ('platform', 'versionString', 'appStoreState', 'appVersionState', 'releaseType', 'earliestReleaseDate')
    return {'attributes': {key: version['attributes'].get(key) for key in keys}, 'build': build.get('data')}


def inspect(api, root, version_string, selected='all', targets=None):
    root.mkdir(parents=True, exist_ok=True)
    reference = api.call('apple', 'GET', f'{APPLE_BASE}/appAssetLibraryRefData',
                         params={'filter[features]': 'APP_STORE_VERSIONS'})
    save(root / 'apple-creative-reference.json', reference)
    if targets is None:
        targets = resolve_targets(reference, {name: {'size': size, 'extension': '.png',
                                                    'mimeType': 'image/png', 'fileSize': 0}
                                               for name, size in DEFAULT_SIZES.items()})
    version = apple_version(api, version_string, False)
    localizations = select_localizations(pages(api, f'{APPLE_BASE}/appStoreVersions/{version["id"]}/appStoreVersionLocalizations',
                                               params={'limit': 200})['data'], selected)
    library = api.call('apple', 'GET', f'{APPLE_BASE}/apps/{APP_ID}/assetLibrary')['data']
    result = {'version': version_string, 'versionId': version['id'], 'libraryId': library['id'],
              'versionGuard': version_guard(api, version['id']), 'targets': targets, 'localizations': []}
    for locale in localizations:
        existing = read_placements(api, locale['id'])
        entry = {'id': locale['id'], 'locale': locale['attributes']['locale'], 'placements': existing}
        result['localizations'].append(entry)
        creative_count = sum(item['attributes'].get('placementType') in PLACEMENTS.values() for item in existing['data'])
        print(f'Inspect {entry["locale"]}: {creative_count} creative placements; {len(existing["data"])} total.', flush=True)
    save(root / 'apple-creative-inspection.json', result)
    print(f'Inspected editable iOS {version_string}: {len(localizations)} localizations.', flush=True)
    return result, reference


def upload_image(api, root, library_id, name, target, version_string):
    body = Path(target['path']).read_bytes()
    if hashlib.sha256(body).hexdigest() != target['sha256']:
        raise RuntimeError('Creative artwork changed after validation; refusing upload')
    reference_name = f'Onlynote-{version_string}-creative-{name}-{target["sha256"][:24]}'
    existing = pages(api, f'{APPLE_BASE}/appAssetLibraries/{library_id}/images', params={
        'filter[referenceName]': reference_name, 'filter[category]': CATEGORY, 'limit': 200,
    })['data']
    candidates = [item for item in existing if item['attributes'].get('referenceName') == reference_name
                  and item['attributes'].get('category') == CATEGORY]
    image = next((item for item in candidates if item['attributes'].get('state') in READY_STATES | {'UPLOAD_COMPLETE'}), None)
    if image:
        return image
    image = next((item for item in candidates if item['attributes'].get('state') == 'AWAITING_UPLOAD'), None)
    if image:
        image = api.call('apple', 'GET', f'{APPLE_BASE}/appAssetLibraryImages/{image["id"]}')['data']
        if image['attributes']['state'] in READY_STATES | {'UPLOAD_COMPLETE'}:
            return image
        if image['attributes']['state'] != 'AWAITING_UPLOAD':
            image = None
    if image is None:
        image = api.call('apple', 'POST', f'{APPLE_BASE}/appAssetLibraryImages', json={'data': {
            'type': 'appAssetLibraryImages', 'attributes': {
                'fileName': f'{reference_name}{target["extension"]}', 'fileSize': target['fileSize'],
                'category': CATEGORY, 'referenceName': reference_name,
            }, 'relationships': {'assetLibrary': {'data': {'type': 'appAssetLibraries', 'id': library_id}}},
        }})['data']
    with (root / 'apple-creative-reservations.jsonl').open('a') as journal:
        journal.write(json.dumps({'id': image['id'], 'path': target['path'], 'sha256': target['sha256'],
                                  'referenceName': reference_name, 'state': 'RESERVED'}) + '\n')
    for operation in image['attributes']['uploadOperations']:
        headers = {item['name']: item['value'] for item in operation.get('requestHeaders', [])}
        start = operation['offset']
        try:
            response = requests.request(operation['method'], operation['url'], headers=headers,
                                        data=body[start:start + operation['length']], timeout=55)
        except requests.RequestException:
            raise RuntimeError('Creative image transfer failed (transport error)') from None
        if not response.ok:
            raise RuntimeError(f'Creative image transfer failed ({response.status_code})')
    return api.call('apple', 'PATCH', f'{APPLE_BASE}/appAssetLibraryImages/{image["id"]}', json={'data': {
        'type': 'appAssetLibraryImages', 'id': image['id'], 'attributes': {'uploaded': True},
    }})['data']


def wait_for_images(api, root, report):
    pending = list(report['images'])
    deadline = time.monotonic() + 900
    while pending:
        for name in list(pending):
            item = report['images'][name]
            image = api.call('apple', 'GET', f'{APPLE_BASE}/appAssetLibraryImages/{item["imageId"]}')['data']
            attributes = image['attributes']
            item['state'] = attributes['state']
            if item['state'] in {'FAILED', 'REJECTED', 'ARCHIVED'}:
                raise RuntimeError(f'{name}: Apple image processing failed ({item["state"]})')
            if item['state'] not in READY_STATES:
                continue
            asset = attributes.get('imageAsset') or {}
            if (attributes.get('category') != CATEGORY or attributes.get('specId') not in item['specIds']
                    or (asset.get('width'), asset.get('height')) != tuple(item['size'])
                    or attributes.get('fileSize') != item['fileSize'] or attributes.get('stateDetails')):
                raise RuntimeError(f'{name}: Apple processed an unexpected creative asset specification')
            pending.remove(name)
        save(root / 'apple-creative-upload-report.json', report)
        if pending:
            if time.monotonic() >= deadline:
                raise TimeoutError('Creative images still processing after 15 minutes; rerun to resume')
            print(f'Apple creative assets: {len(pending)} images still processing.', flush=True)
            time.sleep(10)


def image_relation(placement):
    return (placement.get('relationships', {}).get('image', {}).get('data') or {}).get('id')


def backup_slot(root, version_string, locale, target, existing):
    backup = root / 'backup' / f'creative-{version_string}' / locale['locale']
    backup.mkdir(parents=True, exist_ok=True)
    snapshot = backup / f'{target["placementType"]}.json'
    if not snapshot.exists():
        save(snapshot, existing)


def slot_placements(placements, target):
    return {'data': [item for item in placements['data']
                     if all(item['attributes'].get(key) == target[key]
                            for key in ('placementType', 'placementGroup'))],
            'included': placements.get('included', [])}


def slot_signature(placements):
    return sorted((item['id'], json.dumps(item.get('relationships', {}), sort_keys=True))
                  for item in placements['data'])


def attach(api, root, version_string, locale, target, expected=None):
    existing = read_placements(api, locale['id'], target)
    if expected is not None and slot_signature(existing) != slot_signature(expected):
        raise RuntimeError(f'{locale["locale"]}: creative slot changed since inspection; refusing replacement')
    backup_slot(root, version_string, locale, target, existing)
    matching = next((item for item in existing['data'] if image_relation(item) == target['imageId']), None)
    for placement in existing['data']:
        if matching is None or placement['id'] != matching['id']:
            api.call('apple', 'DELETE', f'{APPLE_BASE}/appAssetLibraryPlacements/{placement["id"]}')
    if matching is None:
        matching = api.call('apple', 'POST', f'{APPLE_BASE}/appAssetLibraryPlacements', json={'data': {
            'type': 'appAssetLibraryPlacements',
            'attributes': {key: target[key] for key in ('placementType', 'placementGroup')},
            'relationships': {
                'image': {'data': {'type': 'appAssetLibraryImages', 'id': target['imageId']}},
                'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': locale['id']}},
            },
        }})['data']
    verified = read_placements(api, locale['id'], target)
    if (len(verified['data']) != 1 or verified['data'][0]['id'] != matching['id']
            or image_relation(verified['data'][0]) != target['imageId']
            or verified['data'][0]['attributes'].get('state') not in READY_PLACEMENT_STATES
            or verified['data'][0]['attributes'].get('stateDetails')):
        raise RuntimeError(f'{locale["locale"]}: creative placement readback did not match')
    return {'locale': locale['locale'], 'localizationId': locale['id'], 'imageId': target['imageId'],
            'placementId': matching['id'], 'placementType': target['placementType'],
            'placementGroup': target['placementGroup'], 'sha256': target.get('sha256'), 'state': 'VERIFIED'}


def untouched_signature(placements):
    # Preserve each group's ordered sequence. The server can interleave groups
    # differently without changing the order in which any screenshots display.
    groups = {}
    for item in placements:
        attributes = item['attributes']
        if attributes.get('placementType') in PLACEMENTS.values():
            continue
        group = (attributes.get('placementType'), attributes.get('placementGroup'))
        groups.setdefault(group, []).append((item['id'], json.dumps(item.get('relationships', {}), sort_keys=True)))
    return sorted(groups.items())


def upload(api, root, version_string, images=None, selected='all', locale_images=None):
    context, reference = inspect(api, root, version_string, 'all' if locale_images else selected)
    if locale_images:
        available = [locale['locale'] for locale in context['localizations']]
        locale_images = select_manifest_images(locale_images, selected, available)
        context['localizations'] = [locale for locale in context['localizations'] if locale['locale'] in locale_images]
    plan = image_plan(reference, images, locale_images)
    bindings = plan['localizations'] or {
        locale['locale']: {name: name for name in PLACEMENTS} for locale in context['localizations']}
    save(root / 'apple-creative-plan.json', {**plan, 'localizations': bindings})
    original = root / f'apple-creative-{version_string}-before.json'
    if not original.exists():
        save(original, context)
    # Save every original creative slot before the first replacement, not just
    # the next locale being changed. Keep prior snapshots on interrupted reruns.
    for locale in context['localizations']:
        for key in bindings[locale['locale']].values():
            target = plan['images'][key]
            backup_slot(root, version_string, locale, target, slot_placements(locale['placements'], target))
    report = {'version': version_string, 'versionId': context['versionId'], 'libraryId': context['libraryId'],
              'localizations': bindings, 'images': {}, 'placements': [], 'state': 'UPLOADING'}
    for key, target in plan['images'].items():
        image = upload_image(api, root, context['libraryId'], target['assetKind'], target, version_string)
        report['images'][key] = {**target, 'imageId': image['id'], 'state': image['attributes']['state']}
        save(root / 'apple-creative-upload-report.json', report)
    wait_for_images(api, root, report)
    if version_guard(api, context['versionId']) != context['versionGuard']:
        raise RuntimeError('The draft build, version metadata, or review state changed before creative replacement')
    for locale in context['localizations']:
        for name, key in bindings[locale['locale']].items():
            target = report['images'][key]
            report['placements'].append(attach(api, root, version_string, locale, target,
                                               expected=slot_placements(locale['placements'], target)))
            save(root / 'apple-creative-upload-report.json', report)
            print(f'Apple {locale["locale"]}/{name}: VERIFIED.', flush=True)
    screenshot_count = 0
    for locale in context['localizations']:
        after = read_placements(api, locale['id'])
        if untouched_signature(after['data']) != untouched_signature(locale['placements']['data']):
            raise RuntimeError('An unrelated screenshot or other placement changed during creative upload')
        screenshot_count += sum(item['attributes'].get('placementType') == 'APP_SCREENSHOT'
                                for item in after['data'])
        for name, key in bindings[locale['locale']].items():
            target = report['images'][key]
            actual = slot_placements(after, target)['data']
            if (len(actual) != 1 or image_relation(actual[0]) != target['imageId']
                    or actual[0]['attributes'].get('state') not in READY_PLACEMENT_STATES
                    or actual[0]['attributes'].get('stateDetails')):
                raise RuntimeError(f'{locale["locale"]}/{name}: final mapped-image readback did not match')
    if version_guard(api, context['versionId']) != context['versionGuard']:
        raise RuntimeError('The draft build, version metadata, or review state changed during creative upload')
    report.update({'state': 'VERIFIED', 'unrelatedPlacementsUnchanged': True, 'versionAndBuildUnchanged': True,
                   'screenshotCountPreserved': screenshot_count, 'mappedImagesVerified': True,
                   'screenshotOrderingPreserved': True, 'libraryImagesRetained': True})
    save(root / 'apple-creative-upload-report.json', report)
    print(f'Verified {len(report["images"])} creative images in {len(report["placements"])} placements '
          f'on editable iOS {version_string}.', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['inspect', 'validate', 'upload'])
    parser.add_argument('--root', type=Path, default=DEFAULT_ROOT)
    parser.add_argument('--version', default='1.12.0')
    parser.add_argument('--header', type=Path)
    parser.add_argument('--search', type=Path)
    parser.add_argument('--manifest', type=Path,
                        help='JSON {locales: {en-US: {header: path, search: path}}}; paths relative to manifest.')
    parser.add_argument('--reference', type=Path, help='Cached Apple reference JSON for offline validation.')
    parser.add_argument('--locales', default='all', help='Existing App Store locales, comma-separated; default all.')
    parser.add_argument('--credentials', type=Path, default=Path.home() / 'Development/secret')
    parser.add_argument('--execute', action='store_true', help='Required for uploading and attaching creative assets.')
    args = parser.parse_args()
    args.root.mkdir(parents=True, exist_ok=True)
    if args.action == 'inspect':
        inspect(StoreApi(args.credentials), args.root, args.version, args.locales)
        return
    if args.manifest and (args.header or args.search):
        parser.error('--manifest is mutually exclusive with --header/--search')
    if not args.manifest and (not args.header or not args.search):
        parser.error('--manifest or both --header and --search are required for validate/upload')
    locale_images = load_manifest(args.manifest) if args.manifest else None
    images = None if args.manifest else {'header': image_info(args.header), 'search': image_info(args.search)}
    if args.action == 'validate':
        reference = json.loads((args.reference or args.root / 'apple-creative-reference.json').read_text())
        plan = image_plan(reference, images,
                          select_manifest_images(locale_images, args.locales) if locale_images else None)
        save(args.root / 'apple-creative-plan.json', plan if locale_images else plan['images'])
        summary = {name: {key: target[key] for key in
                         ('size', 'placementType', 'placementGroup', 'specIds', 'sha256')}
                   for name, target in plan['images'].items()}
        print(json.dumps({'images': summary, 'localizations': plan['localizations']}
                         if locale_images else summary, indent=2))
    elif not args.execute:
        parser.error('upload requires --execute; use validate to check the artwork without remote changes')
    else:
        upload(StoreApi(args.credentials), args.root, args.version, images, args.locales, locale_images)


if __name__ == '__main__':
    main()
