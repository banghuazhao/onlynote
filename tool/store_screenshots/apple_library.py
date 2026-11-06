"""Upload Duo screenshots through Apple's documented App Asset Library API.

Placement groups, dimensions, and limits are discovered at runtime. Existing
placements are replaced only after every new image has processed successfully.
Library images themselves are retained for reuse and rollback.
"""

import hashlib
import json
import time

import requests

from upload import APPLE_BASE, APP_ID, apple_version, files, save


READY_STATES = {
    'PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW', 'WAITING_FOR_REVIEW',
    'IN_REVIEW', 'ACCEPTED', 'APPROVED',
}
# The live API returns ACTIVE for attached placements in an editable draft;
# Apple's tutorial examples use PARENT_PREPARE_FOR_SUBMISSION. Neither state
# changes the independent image-processing and exact-order checks below.
READY_PLACEMENT_STATES = {'ACTIVE', 'PARENT_PREPARE_FOR_SUBMISSION'}


def pages(api, url, **kwargs):
    """Read all pages without silently ignoring placements or reusable images."""
    result = {'data': [], 'included': []}
    while url:
        response = api.call('apple', 'GET', url, **kwargs)
        result['data'].extend(response.get('data', []))
        result['included'].extend(response.get('included', []))
        url = response.get('links', {}).get('next')
        kwargs = {}
    return result


def screenshot_groups(reference, devices, count):
    """Resolve exact screenshot specs to valid Duo placement groups and caps."""
    groups = {}
    for device, (display_class, size) in devices.items():
        candidates = {}
        for resource in reference['data']:
            attributes = resource['attributes']
            specs = {
                spec['specId'] for spec in attributes.get('imageSpecs', [])
                if spec.get('dimensions') == {
                    'minWidth': size[0], 'maxWidth': size[0],
                    'minHeight': size[1], 'maxHeight': size[1],
                } and 'APP_SCREENSHOT' in spec.get('compatiblePlacementTypes', [])
                and '.jpg' in spec.get('fileExtensions', [])
            }
            profiles = {
                group['placementProfileGroupId']
                for group in attributes.get('placementProfileGroups', [])
                if group.get('displayClassId') == display_class
                and group.get('platform') == 'IPHONE_APP_STORE'
            }
            limits = {}
            for feature in attributes.get('features', []):
                if feature['featureId'] != 'APP_STORE_VERSIONS':
                    continue
                for policy in feature.get('placementPolicies', []):
                    if policy['placementType'] == 'APP_SCREENSHOT':
                        for limit in policy.get('groupLimits', []):
                            limits.update({group: limit['maxCount'] for group in limit['groupIds']})
            for placement in attributes.get('placementTypes', []):
                if placement['placementTypeId'] != 'APP_SCREENSHOT':
                    continue
                for mapping in placement.get('specMappings', []):
                    group = mapping['placementGroupId']
                    accepted = specs.intersection(mapping.get('specs', []))
                    if group in profiles and group in limits and accepted:
                        candidates[group] = {'specIds': sorted(accepted), 'maxCount': limits[group]}
        if len(candidates) != 1:
            raise ValueError(f'{device}: expected one Apple screenshot group for {size}; found {sorted(candidates)}')
        group, candidate = next(iter(candidates.items()))
        target = groups.setdefault(group, {'devices': [], 'maxCount': candidate['maxCount']})
        target['devices'].append({'device': device, 'size': size, 'specIds': candidate['specIds']})
    for group, target in groups.items():
        planned = len(target['devices']) * count
        if planned > target['maxCount']:
            raise ValueError(f'{group}: {planned} screenshots exceed Apple limit {target["maxCount"]}; '
                             'capture fewer screens per display and pass --count')
    return groups


def upload_image(api, root, library_id, path, reference_name):
    existing = pages(api, f'{APPLE_BASE}/appAssetLibraries/{library_id}/images', params={
        'filter[referenceName]': reference_name, 'limit': 200,
    })['data']
    image = next((item for item in existing if item['attributes'].get('referenceName') == reference_name
                  and item['attributes'].get('state') in READY_STATES | {'UPLOAD_COMPLETE'}), None)
    if image is not None:
        return image
    body = path.read_bytes()
    image = api.call('apple', 'POST', f'{APPLE_BASE}/appAssetLibraryImages', json={'data': {
        'type': 'appAssetLibraryImages',
        'attributes': {'fileName': f'{reference_name}.jpg', 'fileSize': len(body),
                       'category': 'APP_SCREENSHOTS_AND_PREVIEWS', 'referenceName': reference_name},
        'relationships': {'assetLibrary': {'data': {'type': 'appAssetLibraries', 'id': library_id}}},
    }})['data']
    with (root / 'apple-library-reservations.jsonl').open('a') as journal:
        journal.write(json.dumps({'id': image['id'], 'path': str(path), 'referenceName': reference_name,
                                  'sha256': hashlib.sha256(body).hexdigest(), 'state': 'RESERVED'}) + '\n')
    for part in image['attributes']['uploadOperations']:
        headers = {entry['name']: entry['value'] for entry in part.get('requestHeaders', [])}
        try:
            response = requests.request(part['method'], part['url'], headers=headers,
                                        data=body[part['offset']:part['offset'] + part['length']], timeout=55)
        except requests.RequestException:
            # Requests exceptions can contain the signed storage URL.
            raise RuntimeError('Asset Library image part upload failed (transport error)') from None
        if not response.ok:
            raise RuntimeError(f'Asset Library image part upload failed ({response.status_code})')
    # Unlike deprecated appScreenshots, the library commit accepts uploaded alone.
    return api.call('apple', 'PATCH', f'{APPLE_BASE}/appAssetLibraryImages/{image["id"]}', json={'data': {
        'type': 'appAssetLibraryImages', 'id': image['id'], 'attributes': {'uploaded': True},
    }})['data']


def wait_for_images(api, root, report):
    pending = [image for group in report['groups'] for image in group['images']]
    deadline = time.monotonic() + 900
    while pending:
        for item in list(pending):
            image = api.call('apple', 'GET', f'{APPLE_BASE}/appAssetLibraryImages/{item["imageId"]}')['data']
            attributes = image['attributes']
            item['state'] = attributes['state']
            if item['state'] in {'FAILED', 'REJECTED', 'ARCHIVED'}:
                raise RuntimeError(f'{item["file"]}: {item["state"]}: {attributes.get("stateDetails")}')
            if item['state'] not in READY_STATES:
                continue
            asset = attributes.get('imageAsset') or {}
            if (attributes.get('specId') not in item['specIds']
                    or (asset.get('width'), asset.get('height')) != tuple(item['size'])):
                raise RuntimeError(f'{item["file"]}: Apple processed unexpected specification or dimensions')
            pending.remove(item)
        save(root / 'apple-library-upload-report.json', report)
        if pending:
            if time.monotonic() >= deadline:
                raise TimeoutError('Apple library processing exceeded 15 minutes; rerun to resume existing assets')
            print(f'Apple library: {len(pending)} images still processing.', flush=True)
            time.sleep(10)


def read_placements(api, localization_id, group):
    response = pages(api, f'{APPLE_BASE}/appStoreVersionLocalizations/{localization_id}/placements', params={
        'filter[placementType]': 'APP_SCREENSHOT', 'filter[placementGroup]': group,
        'sort': 'placementGroupPosition', 'include': 'image', 'limit': 200,
    })
    for placement in response['data']:
        attributes = placement['attributes']
        if attributes.get('placementType') != 'APP_SCREENSHOT' or attributes.get('placementGroup') != group:
            raise RuntimeError('Apple returned placements outside the requested screenshot group; refusing replacement')
        parent = placement.get('relationships', {}).get('appStoreVersionLocalization', {}).get('data')
        if parent and parent['id'] != localization_id:
            raise RuntimeError('Apple returned placements for a different localization; refusing replacement')
    return response


def backup_placements(root, version_string, locale, group, existing):
    folder = root / 'backup' / f'apple-library-{version_string}' / locale / group
    folder.mkdir(parents=True, exist_ok=True)
    backup = folder / 'placements.json'
    if not backup.exists():
        save(backup, existing)
    original = json.loads(backup.read_text())
    for image in original.get('included', []):
        asset = image.get('attributes', {}).get('imageAsset')
        if image['type'] != 'appAssetLibraryImages' or not asset:
            continue
        path = folder / f'{image["id"]}.png'
        if not path.exists():
            url = asset['templateUrl'].replace('{w}', str(asset['width'])).replace('{h}', str(asset['height'])).replace('{f}', 'png')
            response = requests.get(url, timeout=55)
            response.raise_for_status()
            path.write_bytes(response.content)


def place_group(api, root, version_string, item):
    group = item['placementGroup']
    localization_id = item['localizationId']
    existing = read_placements(api, localization_id, group)
    backup_placements(root, version_string, item['locale'], group, existing)
    desired_images = {image['imageId'] for image in item['images']}
    selected_specs = {spec for image in item['images'] for spec in image['specIds']}
    included = {image['id']: image for image in existing.get('included', [])
                if image['type'] == 'appAssetLibraryImages'}
    by_image = {}
    preserved = []
    for placement in existing['data']:
        relation = placement.get('relationships', {}).get('image', {}).get('data')
        if relation and relation['id'] in desired_images and relation['id'] not in by_image:
            by_image[relation['id']] = placement
        elif relation and relation['id'] not in desired_images:
            spec_id = included.get(relation['id'], {}).get('attributes', {}).get('specId')
            if not spec_id:
                raise RuntimeError('Existing screenshot specification is missing; cannot safely scope replacement')
            if spec_id not in selected_specs:
                preserved.append(placement)
    if len(item['images']) + len(preserved) > item['maxCount']:
        raise ValueError(f'{group}: selected images plus preserved display screenshots exceed Apple group limit')
    # Every replacement image has already finished processing. Preserve the old
    # library images and the full original placement metadata for rollback.
    kept = {placement['id'] for placement in [*by_image.values(), *preserved]}
    for placement in existing['data']:
        if placement['id'] not in kept:
            api.call('apple', 'DELETE', f'{APPLE_BASE}/appAssetLibraryPlacements/{placement["id"]}')
    ordered = []
    for image in item['images']:
        placement = by_image.get(image['imageId'])
        if placement is None:
            placement = api.call('apple', 'POST', f'{APPLE_BASE}/appAssetLibraryPlacements', json={'data': {
                'type': 'appAssetLibraryPlacements',
                'attributes': {'placementType': 'APP_SCREENSHOT', 'placementGroup': group},
                'relationships': {
                    'image': {'data': {'type': 'appAssetLibraryImages', 'id': image['imageId']}},
                    'appStoreVersionLocalization': {'data': {
                        'type': 'appStoreVersionLocalizations', 'id': localization_id}},
                },
            }})['data']
        image['placementId'] = placement['id']
        ordered.append({'type': 'appAssetLibraryPlacements', 'id': placement['id']})
    ordered.extend({'type': 'appAssetLibraryPlacements', 'id': placement['id']} for placement in preserved)
    ordered_images = [image['imageId'] for image in item['images']] + [
        placement['relationships']['image']['data']['id'] for placement in preserved]
    api.call('apple', 'POST', f'{APPLE_BASE}/appAssetLibraryPlacementOrderingRequests', json={'data': {
        'type': 'appAssetLibraryPlacementOrderingRequests', 'attributes': {'placementGroup': group},
        'relationships': {
            'orderedPlacements': {'data': ordered},
            'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': localization_id}},
        },
    }})
    verified = read_placements(api, localization_id, group)
    if ([placement['id'] for placement in verified['data']] != [item['id'] for item in ordered]
            or [placement.get('relationships', {}).get('image', {}).get('data', {}).get('id')
                for placement in verified['data']] != ordered_images
            or any(placement['attributes'].get('state') not in READY_PLACEMENT_STATES
                   or placement['attributes'].get('stateDetails')
                   for placement in verified['data'])):
        raise RuntimeError(f'{item["locale"]}/{group}: Apple placement order, images, or processing state did not match')
    item['state'] = 'VERIFIED'
    item['verifiedPlacements'] = verified
    print(f'Apple {item["locale"]}/{group}: {len(ordered)} placements VERIFIED.', flush=True)


def upload_apple_library(api, root, version_string, allow_create, devices, locales, count=8):
    reference = api.call('apple', 'GET', f'{APPLE_BASE}/appAssetLibraryRefData', params={
        'filter[features]': 'APP_STORE_VERSIONS', 'filter[placementTypes]': 'APP_SCREENSHOT',
    })
    save(root / 'apple-asset-reference.json', reference)
    targets = screenshot_groups(reference, devices, count)
    library = api.call('apple', 'GET', f'{APPLE_BASE}/apps/{APP_ID}/assetLibrary')['data']
    version = apple_version(api, version_string, allow_create)
    localizations = pages(api, f'{APPLE_BASE}/appStoreVersions/{version["id"]}/appStoreVersionLocalizations',
                          params={'limit': 200})['data']
    report = {'version': version_string, 'versionId': version['id'], 'libraryId': library['id'], 'groups': []}
    for source_locale, store_locale in locales.items():
        localization = next((item for item in localizations if item['attributes']['locale'] == store_locale), None)
        if localization is None:
            localization = api.call('apple', 'POST', f'{APPLE_BASE}/appStoreVersionLocalizations', json={'data': {
                'type': 'appStoreVersionLocalizations', 'attributes': {'locale': store_locale},
                'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version['id']}}},
            }})['data']
        for group, target in targets.items():
            item = {'locale': store_locale, 'localizationId': localization['id'], 'placementGroup': group,
                    'maxCount': target['maxCount'], 'images': [], 'state': 'QUEUED'}
            report['groups'].append(item)
            for device in target['devices']:
                for path in files(root, device['device'], source_locale, device['size'], count):
                    checksum = hashlib.sha256(path.read_bytes()).hexdigest()
                    reference_name = f'Onlynote-{version_string}-{device["device"]}-{source_locale}-{path.stem}-{checksum[:16]}'
                    image = upload_image(api, root, library['id'], path, reference_name)
                    item['images'].append({'imageId': image['id'], 'file': str(path.relative_to(root)),
                                           'sha256': checksum, 'size': device['size'], 'specIds': device['specIds'],
                                           'state': image['attributes']['state']})
                    save(root / 'apple-library-upload-report.json', report)
                    print(f'Apple library {store_locale}/{device["device"]}: {path.name} queued.', flush=True)
    wait_for_images(api, root, report)
    for item in report['groups']:
        place_group(api, root, version_string, item)
        save(root / 'apple-library-upload-report.json', report)
    report['state'] = 'VERIFIED'
    save(root / 'apple-library-upload-report.json', report)
    print(f'Apple library: {sum(len(item["images"]) for item in report["groups"])} screenshots attached '
          f'and verified in editable version {version_string}.', flush=True)
