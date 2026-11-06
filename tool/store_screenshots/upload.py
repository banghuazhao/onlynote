"""Upload Onlynote store assets without bundling or releasing application builds.

Credentials stay outside the repository; authentication headers are never logged.
Google Play upload and commit are intentionally separate operations.
"""

import argparse
import hashlib
import importlib.util
import json
import time
from pathlib import Path

import requests
from PIL import Image

APP_ID = '1616516732'
PACKAGE = 'com.appsbay.onlynote'
APPLE_BASE = 'https://api.appstoreconnect.apple.com/v1'
PLAY_BASE = f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits'
LEGACY_APPLE_DEVICES = {
    'iphone6_9': ('APP_IPHONE_67', (1320, 2868)),
    'iphone6_3': ('APP_IPHONE_61', (1206, 2622)),
    'ipad13': ('APP_IPAD_PRO_3GEN_129', (2064, 2752)),
}
# Duo uses Asset Library placements, not the deprecated ScreenshotDisplayType.
# Placement group identifiers are discovered from Apple's reference data.
APPLE_LIBRARY_DEVICES = {
    'iphone_duo_outer': ('IPHONE_DUO', (1398, 2034)),
    'iphone_duo_inner': ('IPHONE_DUO', (2007, 2853)),
}
APPLE_DEVICES = {**LEGACY_APPLE_DEVICES, **APPLE_LIBRARY_DEVICES}
PLAY_DEVICES = {
    'playphone': ('phoneScreenshots', (1080, 1920)),
    'play7inch': ('sevenInchScreenshots', (1200, 1920)),
    'play10inch': ('tenInchScreenshots', (1600, 2560)),
}
APPLE_LOCALES = {'en': 'en-US', 'zh-Hans': 'zh-Hans', 'zh-Hant': 'zh-Hant'}
PLAY_LOCALES = {'en': ['en-US'], 'zh-Hans': ['zh-CN'], 'zh-Hant': ['zh-TW', 'zh-HK']}
LEGACY_APPLE_DISPLAYS = {'APP_IPHONE_65', 'APP_IPHONE_55', 'APP_IPAD_PRO_129'}
DEFAULT_DEVICES = (*LEGACY_APPLE_DEVICES, *PLAY_DEVICES)


def helper(name, file):
    spec = importlib.util.spec_from_file_location(name, file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class StoreApi:
    def __init__(self, credentials):
        self.credentials = credentials
        self.auth = {}
        self.tokens = {}
        self.session = requests.Session()

    def token(self, store):
        cached = self.tokens.get(store)
        if cached is None or time.monotonic() - cached[1] > 480:
            if store not in self.auth:
                filename = ('AppStoreConnect_API_keys/asc_token.py' if store == 'apple'
                            else 'GooglePlay_API/publish_play_release.py')
                self.auth[store] = helper(f'{store}_credentials', self.credentials / filename)
            value = self.auth[store].token()
            self.tokens[store] = value, time.monotonic()
        return self.tokens[store][0]

    def call(self, store, method, url, **kwargs):
        headers = dict(kwargs.pop('headers', {}))
        headers['Authorization'] = f'Bearer {self.token(store)}'
        response = self.session.request(method, url, headers=headers, timeout=55, **kwargs)
        if not response.ok:
            try:
                detail = response.json()
            except ValueError:
                detail = {'error': response.text[:600]}
            raise RuntimeError(f'{store} {method} failed ({response.status_code}): {json.dumps(detail)[:2000]}')
        return response.json() if response.content else {}


def save(file, value):
    file.write_text(json.dumps(value, indent=2, ensure_ascii=False))


def files(root, device, locale, size, count=8):
    values = sorted((root / device / locale).glob('[0-9][0-9]-*.jpg'))
    if len(values) != count:
        raise ValueError(f'{device}/{locale}: expected {count} JPEG files, found {len(values)}')
    for path in values:
        with Image.open(path) as image:
            if image.size != size or image.mode != 'RGB':
                raise ValueError(f'{path.name}: expected RGB {size}, got {image.mode} {image.size}')
        if path.stat().st_size > 8_000_000:
            raise ValueError(f'{path.name}: exceeds 8 MB')
    return values


def select_devices(value=None, store=None):
    available = APPLE_DEVICES if store == 'apple' else PLAY_DEVICES if store == 'play' else {**APPLE_DEVICES, **PLAY_DEVICES}
    selected = [name.strip() for name in value.split(',')] if value else [
        name for name in DEFAULT_DEVICES if name in available]
    unknown = set(selected) - available.keys()
    if unknown:
        raise ValueError(f'Unknown {store or "store"} devices: {sorted(unknown)}')
    return {name: available[name] for name in dict.fromkeys(selected)}


def select_locales(value=None):
    selected = [name.strip() for name in value.split(',')] if value else list(APPLE_LOCALES)
    unknown = set(selected) - APPLE_LOCALES.keys()
    if unknown:
        raise ValueError(f'Unknown locales: {sorted(unknown)}')
    return {name: APPLE_LOCALES[name] for name in dict.fromkeys(selected)}


def preflight(root, devices=None, locales=None, count=8):
    devices = select_devices() if devices is None else devices
    locales = APPLE_LOCALES if locales is None else locales
    total = 0
    for device, (_, size) in devices.items():
        for locale in locales:
            total += len(files(root, device, locale, size, count))
    print(f'Validated {total} opaque, correctly sized store images.', flush=True)


def apple_version(api, version_string, allow_create):
    versions = api.call('apple', 'GET', f'{APPLE_BASE}/apps/{APP_ID}/appStoreVersions',
                        params={'filter[platform]': 'IOS', 'limit': 200})['data']
    version = next((v for v in versions if v['attributes']['versionString'] == version_string), None)
    if version is None:
        if not allow_create:
            raise ValueError(f'No {version_string} version exists; pass --create-draft to create one.')
        version = api.call('apple', 'POST', f'{APPLE_BASE}/appStoreVersions', json={'data': {
            'type': 'appStoreVersions',
            'attributes': {'versionString': version_string, 'platform': 'IOS', 'releaseType': 'MANUAL'},
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}},
        }})['data']
    state = version['attributes']['appStoreState']
    if state not in {'PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED'}:
        raise ValueError(f'Version {version_string} is {state}; screenshots require an editable release.')
    return version


def screenshot_state(screenshot):
    return (screenshot['attributes'].get('assetDeliveryState') or {}).get('state')


def journal_apple(root, screenshot_id, set_id, path, checksum, size, state):
    with (root / 'apple-reservations.jsonl').open('a') as journal:
        journal.write(json.dumps({
            'id': screenshot_id, 'setId': set_id, 'file': str(path),
            'checksum': checksum, 'fileSize': size, 'state': state,
        }) + '\n')


def upload_apple_file(api, root, set_id, path):
    body = path.read_bytes()
    checksum = hashlib.md5(body).hexdigest()
    reserved = api.call('apple', 'POST', f'{APPLE_BASE}/appScreenshots', json={'data': {
        'type': 'appScreenshots', 'attributes': {'fileName': path.name, 'fileSize': len(body)},
        'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': set_id}}},
    }})['data']
    journal_apple(root, reserved['id'], set_id, path, checksum, len(body), 'RESERVED')
    for part in reserved['attributes']['uploadOperations']:
        headers = {entry['name']: entry['value'] for entry in part.get('requestHeaders', [])}
        start = part['offset']
        # Storage URLs carry their own authorization; never forward the Apple JWT.
        try:
            response = requests.request(part['method'], part['url'], headers=headers,
                                        data=body[start:start + part['length']], timeout=55)
        except requests.RequestException:
            raise RuntimeError('Screenshot part upload failed (transport error)') from None
        if not response.ok:
            raise RuntimeError(f'Screenshot part upload failed ({response.status_code})')
    uploaded = api.call('apple', 'PATCH', f"{APPLE_BASE}/appScreenshots/{reserved['id']}", json={'data': {
        'type': 'appScreenshots', 'id': reserved['id'],
        'attributes': {'uploaded': True, 'sourceFileChecksum': checksum},
    }})['data']
    journal_apple(root, reserved['id'], set_id, path, checksum, len(body), 'UPLOAD_COMPLETE')
    return uploaded


def finish_apple_sets(api, root, report):
    deadline = time.monotonic() + 900
    pending = list(report['sets'])
    while pending:
        for item in list(pending):
            sid = item['setId']
            screenshots = api.call('apple', 'GET', f'{APPLE_BASE}/appScreenshotSets/{sid}/appScreenshots',
                                   params={'limit': 200})['data']
            by_id = {shot['id']: shot for shot in screenshots}
            complete = 0
            for screenshot_id in item['ids']:
                shot = by_id.get(screenshot_id)
                if shot is None:
                    raise RuntimeError(f'Apple queued screenshot {screenshot_id} disappeared from set {sid}')
                delivery = shot['attributes'].get('assetDeliveryState') or {}
                if delivery.get('state') in {'FAILED', 'ERROR'} or delivery.get('errors'):
                    raise RuntimeError(f'Apple {item["locale"]}/{item["device"]} processing failed: '
                                       f'{shot["attributes"]["fileName"]}: {json.dumps(delivery)}')
                complete += delivery.get('state') == 'COMPLETE'
            item['completeCount'] = complete
            if complete != len(item['ids']):
                print(f'Apple {item["locale"]}/{item["device"]}: {complete}/{len(item["ids"])} COMPLETE',
                      flush=True)
                continue
            # Processing succeeded for every replacement before old assets are removed.
            for old in screenshots:
                if old['id'] not in item['ids']:
                    api.call('apple', 'DELETE', f"{APPLE_BASE}/appScreenshots/{old['id']}")
            api.call('apple', 'PATCH', f'{APPLE_BASE}/appScreenshotSets/{sid}/relationships/appScreenshots',
                     json={'data': [{'type': 'appScreenshots', 'id': i} for i in item['ids']]})
            verified = api.call('apple', 'GET', f'{APPLE_BASE}/appScreenshotSets/{sid}/appScreenshots',
                                params={'limit': 200})['data']
            if ([shot['id'] for shot in verified] != item['ids']
                    or any(screenshot_state(shot) != 'COMPLETE' for shot in verified)):
                raise RuntimeError('Apple screenshot readback order or processing state did not match')
            item['state'] = 'VERIFIED'
            pending.remove(item)
            print(f'Apple {item["locale"]}/{item["device"]}: all screenshots VERIFIED', flush=True)
            save(root / 'apple-upload-report.json', report)
        save(root / 'apple-upload-report.json', report)
        if pending:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                unfinished = ', '.join(f'{item["locale"]}/{item["device"]}' for item in pending)
                raise TimeoutError(f'Apple screenshot processing exceeded 15 minutes: {unfinished}. '
                                   'Queued assets are preserved; rerun to resume.')
            time.sleep(min(10, remaining))


def upload_apple(api, root, version_string, allow_create, devices=None, locales=None, count=8):
    devices = LEGACY_APPLE_DEVICES if devices is None else devices
    locales = APPLE_LOCALES if locales is None else locales
    version = apple_version(api, version_string, allow_create)
    vid = version['id']
    localizations = api.call('apple', 'GET', f'{APPLE_BASE}/appStoreVersions/{vid}/appStoreVersionLocalizations',
                             params={'limit': 200})['data']
    before = {'version': version, 'localizations': []}
    for locale in localizations:
        sets = api.call('apple', 'GET', f"{APPLE_BASE}/appStoreVersionLocalizations/{locale['id']}/appScreenshotSets",
                        params={'include': 'appScreenshots', 'limit': 200})
        before['localizations'].append({'localization': locale, 'screenshots': sets})
    backup = root / f'apple-{version_string}-before.json'
    if not backup.exists():
        save(backup, before)
    original = json.loads(backup.read_text())
    # Preserve original image bytes, in addition to identifiers and ordering.
    for item in original['localizations']:
        store_locale = item['localization']['attributes']['locale']
        if store_locale not in APPLE_LOCALES.values():
            continue
        for shot in item['screenshots'].get('included', []):
            if shot['type'] != 'appScreenshots':
                continue
            asset = shot['attributes'].get('imageAsset')
            if not asset:
                continue
            folder = root / 'backup' / f'apple-{version_string}' / store_locale
            folder.mkdir(parents=True, exist_ok=True)
            target = folder / f"{shot['id']}.png"
            if target.exists():
                continue
            url = asset['templateUrl'].replace('{w}', str(asset['width'])).replace('{h}', str(asset['height'])).replace('{f}', 'png')
            response = requests.get(url, timeout=55)
            response.raise_for_status()
            target.write_bytes(response.content)
    report = {'version': version_string, 'versionId': vid, 'sets': []}
    legacy_sets = []
    print(f'Apple destination: {version_string}, {version["attributes"]["appStoreState"]}', flush=True)
    for source_locale, store_locale in locales.items():
        locale = next((l for l in localizations if l['attributes']['locale'] == store_locale), None)
        if locale is None:
            locale = api.call('apple', 'POST', f'{APPLE_BASE}/appStoreVersionLocalizations', json={'data': {
                'type': 'appStoreVersionLocalizations', 'attributes': {'locale': store_locale},
                'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': vid}}},
            }})['data']
        sets = api.call('apple', 'GET', f"{APPLE_BASE}/appStoreVersionLocalizations/{locale['id']}/appScreenshotSets",
                        params={'limit': 200})['data']
        for device, (display_type, size) in devices.items():
            shot_set = next((s for s in sets if s['attributes']['screenshotDisplayType'] == display_type), None)
            if shot_set is None:
                shot_set = api.call('apple', 'POST', f'{APPLE_BASE}/appScreenshotSets', json={'data': {
                    'type': 'appScreenshotSets', 'attributes': {'screenshotDisplayType': display_type},
                    'relationships': {'appStoreVersionLocalization': {'data': {
                        'type': 'appStoreVersionLocalizations', 'id': locale['id']}}},
                }})['data']
            sid = shot_set['id']
            existing = api.call('apple', 'GET', f'{APPLE_BASE}/appScreenshotSets/{sid}/appScreenshots',
                                params={'limit': 200})['data']
            desired = [(path, hashlib.md5(path.read_bytes()).hexdigest())
                       for path in files(root, device, source_locale, size, count)]
            matches = {}
            for path, checksum in desired:
                candidates = [s for s in existing if s['attributes']['fileName'] == path.name
                              and s['attributes'].get('sourceFileChecksum') == checksum
                              and screenshot_state(s) in {'COMPLETE', 'UPLOAD_COMPLETE'}]
                if candidates:
                    # Prefer a completed copy if an interrupted run left duplicates.
                    matches[path.name] = next((s for s in candidates if screenshot_state(s) == 'COMPLETE'),
                                              candidates[0])
            # Protect matches for the entire sequence, including later files.
            protected = {shot['id'] for shot in matches.values()}
            selected = []
            for path, checksum in desired:
                matched = matches.get(path.name)
                if matched is None:
                    # Empty/new modern sets fit all eight before removing prior assets.
                    if len(existing) >= 10:
                        removable = next((s for s in existing if s['id'] not in protected), None)
                        if removable is None:
                            raise RuntimeError('Apple screenshot set reached capacity')
                        api.call('apple', 'DELETE', f"{APPLE_BASE}/appScreenshots/{removable['id']}")
                        existing.remove(removable)
                    matched = upload_apple_file(api, root, sid, path)
                    existing.append(matched)
                    protected.add(matched['id'])
                selected.append(matched['id'])
                print(f'Apple {store_locale}/{device}: {path.name} {screenshot_state(matched) or "QUEUED"}',
                      flush=True)
            report['sets'].append({'locale': store_locale, 'device': device, 'setId': sid,
                                   'ids': selected, 'state': 'QUEUED'})
            save(root / 'apple-upload-report.json', report)
        for old_set in sets:
            if (set(devices) == set(LEGACY_APPLE_DEVICES)
                    and old_set['attributes']['screenshotDisplayType'] in LEGACY_APPLE_DISPLAYS):
                legacy_sets.append(old_set['id'])
    print(f'Apple queued: {sum(len(item["ids"]) for item in report["sets"])} screenshots; '
          'waiting for processing.', flush=True)
    finish_apple_sets(api, root, report)
    # Remove inherited legacy classes only after all replacement sets are verified.
    for sid in legacy_sets:
        old_shots = api.call('apple', 'GET', f'{APPLE_BASE}/appScreenshotSets/{sid}/appScreenshots',
                             params={'limit': 200})['data']
        for old in old_shots:
            api.call('apple', 'DELETE', f"{APPLE_BASE}/appScreenshots/{old['id']}")
    report['legacyCleanupComplete'] = True
    save(root / 'apple-upload-report.json', report)
    print(f'Apple verified: {len(report["sets"])} screenshot sets in editable version {version_string}.', flush=True)


def upload_play(api, root, commit, devices=None, locales=None, count=8):
    devices = PLAY_DEVICES if devices is None else devices
    locales = PLAY_LOCALES if locales is None else {name: PLAY_LOCALES[name] for name in locales}
    existing_report = root / 'play-upload-report.json'
    if existing_report.exists():
        prior = json.loads(existing_report.read_text())
        expiry = int(prior.get('edit', {}).get('expiryTimeSeconds', 0))
        if not prior.get('committed') and expiry > time.time():
            raise ValueError('An uncommitted Play edit is still pending. Use play-commit to commit its validated assets, or explicitly discard it first.')
    edit = api.call('play', 'POST', PLAY_BASE, json={})
    eid = edit['id']
    base = f'{PLAY_BASE}/{eid}'
    tracks = api.call('play', 'GET', f'{base}/tracks')
    listing_languages = {l['language'] for l in api.call('play', 'GET', f'{base}/listings').get('listings', [])}
    report = {'edit': edit, 'committed': False, 'tracksBefore': tracks, 'sets': []}
    save(root / 'play-upload-report.json', report)
    for source_locale, store_locales in locales.items():
        for locale in store_locales:
            if locale not in listing_languages:
                raise ValueError(f'Google Play localization {locale} does not exist')
            for device, (image_type, size) in devices.items():
                target = f'{base}/listings/{locale}/{image_type}'
                old = api.call('play', 'GET', target)
                backup_dir = root / 'backup/play' / locale / image_type
                backup_dir.mkdir(parents=True, exist_ok=True)
                save(backup_dir / 'metadata.json', old)
                for index, image in enumerate(old.get('images', [])):
                    response = requests.get(image['url'] + '=s0', timeout=55)
                    response.raise_for_status()
                    (backup_dir / f'{index + 1:02d}.png').write_bytes(response.content)
                api.call('play', 'DELETE', target)
                uploaded = []
                for path in files(root, device, source_locale, size, count):
                    upload_url = f'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}/edits/{eid}/listings/{locale}/{image_type}'
                    value = api.call('play', 'POST', upload_url, params={'uploadType': 'media'},
                                     headers={'Content-Type': 'image/jpeg'}, data=path.read_bytes())['image']
                    uploaded.append(value)
                    print(f'Play {locale}/{device}: {path.name} uploaded', flush=True)
                verified = api.call('play', 'GET', target).get('images', [])
                if [i['sha256'] for i in verified] != [i['sha256'] for i in uploaded]:
                    raise RuntimeError('Play screenshot readback order or hashes did not match')
                report['sets'].append({'locale': locale, 'device': device, 'images': uploaded})
                save(root / 'play-upload-report.json', report)
    if api.call('play', 'GET', f'{base}/tracks') != tracks:
        raise RuntimeError('Google Play release tracks unexpectedly changed during screenshot upload')
    api.call('play', 'POST', f'{base}:validate')
    report['validated'] = True
    save(root / 'play-upload-report.json', report)
    if commit:
        report['commit'] = api.call('play', 'POST', f'{base}:commit', params={
            'changesNotSentForReview': 'true', 'changesInReviewBehavior': 'ERROR_IF_IN_REVIEW'})
        report['committed'] = True
        save(root / 'play-upload-report.json', report)
        print('Play screenshot edit committed. Check Console publishing status before claiming it is live.', flush=True)
    else:
        print(f'Play edit {eid} validated, UNCOMMITTED; expires at {edit.get("expiryTimeSeconds")}.', flush=True)


def commit_play(api, root):
    report = json.loads((root / 'play-upload-report.json').read_text())
    if report.get('committed'):
        raise ValueError('Play screenshot edit has already been committed')
    if not report.get('validated'):
        raise ValueError('Play screenshot edit must be fully uploaded and validated first')
    eid = report['edit']['id']
    base = f'{PLAY_BASE}/{eid}'
    if api.call('play', 'GET', f'{base}/tracks') != report['tracksBefore']:
        raise RuntimeError('Play release tracks changed after screenshot validation')
    for item in report['sets']:
        image_type = PLAY_DEVICES[item['device']][0]
        target = f"{base}/listings/{item['locale']}/{image_type}"
        verified = api.call('play', 'GET', target).get('images', [])
        if [i['sha256'] for i in verified] != [i['sha256'] for i in item['images']]:
            raise RuntimeError('Previously validated Play screenshots have changed')
    api.call('play', 'POST', f'{base}:validate')
    report['commit'] = api.call('play', 'POST', f'{base}:commit', params={
        'changesNotSentForReview': 'true', 'changesInReviewBehavior': 'ERROR_IF_IN_REVIEW'})
    report['committed'] = True
    save(root / 'play-upload-report.json', report)
    print('Existing Play screenshot edit committed; check Console publishing status.', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['validate', 'apple', 'play', 'play-commit'])
    parser.add_argument('--root', type=Path, default=Path('build/store_screenshots/2026-10-08'))
    parser.add_argument('--credentials', type=Path, default=Path.home() / 'Development/secret')
    parser.add_argument('--version', default='1.6.0')
    parser.add_argument('--devices', help='Comma-separated devices to validate/upload; defaults to the original devices for the chosen store.')
    parser.add_argument('--locales', help='Comma-separated source locales to validate/upload.')
    parser.add_argument('--count', type=int, default=8, help='Expected screenshots per device and locale (default: 8).')
    parser.add_argument('--create-draft', action='store_true')
    parser.add_argument('--commit-play', action='store_true', help='Commit may send the listing changes for review/publishing.')
    args = parser.parse_args()
    if not 1 <= args.count <= 10:
        parser.error('--count must be between 1 and 10')
    store = args.action if args.action in {'apple', 'play'} else None
    devices = select_devices(args.devices, store)
    locales = select_locales(args.locales)
    if args.action != 'play-commit':
        preflight(args.root, devices, locales, args.count)
    if args.action == 'validate':
        return
    api = StoreApi(args.credentials)
    if args.action == 'apple':
        legacy = {name: definition for name, definition in devices.items() if name in LEGACY_APPLE_DEVICES}
        library = {name: definition for name, definition in devices.items() if name in APPLE_LIBRARY_DEVICES}
        if legacy:
            upload_apple(api, args.root, args.version, args.create_draft, legacy, locales, args.count)
        if library:
            from apple_library import upload_apple_library
            upload_apple_library(api, args.root, args.version, args.create_draft, library, locales, args.count)
    elif args.action == 'play-commit':
        commit_play(api, args.root)
    else:
        upload_play(api, args.root, args.commit_play, devices, locales, args.count)


if __name__ == '__main__':
    main()
