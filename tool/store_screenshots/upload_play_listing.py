"""Scoped Onlynote Play listing updates, with offline validation and separate commit.

This tool never uploads a binary or changes a track, icon, video, or app detail.
Empty/omitted media arrays mean preserve. Only nonempty arrays are replaced.
API edits expire after about one hour; a staged edit is not a Console draft.
Console changes invalidate API edits. Review Publishing overview before staging
and before explicitly committing. Creating an edit invalidates another edit
opened by the same API user, so run only after coordinating with other writers.

Image altText/screen are retained for review; the Play Image API has no such
fields. See developers.google.com/android-publisher/api-ref/rest/v3/edits.images.
"""

import argparse
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from datetime import datetime, timezone
import fcntl
import hashlib
import io
import json
from pathlib import Path
import re
import sys
import time
from urllib.parse import urlparse

from PIL import Image
import requests

from upload import PACKAGE, PLAY_BASE, StoreApi

TYPES = ('phoneScreenshots', 'sevenInchScreenshots', 'tenInchScreenshots', 'featureGraphic')
ALL_TYPES = (*TYPES, 'icon', 'tvBanner', 'tvScreenshots', 'wearScreenshots')
FIELDS = {'title': 30, 'shortDescription': 80, 'fullDescription': 4000}
UPLOAD_BASE = PLAY_BASE.replace('/androidpublisher/', '/upload/androidpublisher/', 1)
JOURNAL = 'play-listing-journal.json'
BASELINE = 'play-listing-baseline.json'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def digest(value):
    return sha(json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode())


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')
    temporary.replace(path)


def read(path):
    return json.loads(path.read_text())


@contextmanager
def locked(root):
    root.mkdir(parents=True, exist_ok=True)
    with (root / '.play-listing.lock').open('a') as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError('Another listing command is using this journal directory') from None
        yield


def load_plan(metadata_path, assets_path, expected_version='21'):
    metadata_path, assets_path = metadata_path.resolve(), assets_path.resolve()
    metadata, assets = read(metadata_path), read(assets_path)
    if metadata.get('packageName') != PACKAGE or assets.get('packageName') != PACKAGE:
        raise ValueError(f'Both inputs must target {PACKAGE}')
    if set(assets) != {'packageName', 'locales'} or not isinstance(assets['locales'], dict):
        raise ValueError('Assets must contain exactly packageName and locales')
    if not isinstance(metadata.get('listings'), list) or not metadata['listings']:
        raise ValueError('metadata.listings must be a nonempty array')
    listings = {}
    for item in metadata['listings']:
        if not isinstance(item, dict) or set(item) != {'language', *FIELDS}:
            raise ValueError('Each listing must contain language and the three text fields only')
        locale = item['language']
        if not isinstance(locale, str) or not re.fullmatch(r'[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*', locale):
            raise ValueError('Invalid listing language')
        if locale in listings:
            raise ValueError(f'Duplicate listing language: {locale}')
        for field, limit in FIELDS.items():
            value = item[field]
            if not isinstance(value, str) or not value.strip() or len(value) > limit:
                raise ValueError(f'{locale}/{field}: requires 1..{limit} characters')
            if '\x00' in value or (field != 'fullDescription' and ('\n' in value or '\r' in value)):
                raise ValueError(f'{locale}/{field}: invalid control character or line break')
        listings[locale] = item
    media = {}
    for locale, groups in assets['locales'].items():
        if locale not in listings or not isinstance(groups, dict) or set(groups) - set(TYPES):
            raise ValueError(f'{locale}: media language/type is outside the metadata scope')
        for kind, entries in groups.items():
            if not isinstance(entries, list) or len(entries) > (1 if kind == 'featureGraphic' else 8):
                raise ValueError(f'{locale}/{kind}: invalid image count')
            if not entries:
                continue  # An empty placeholder is deliberately never a deletion request.
            if kind == 'phoneScreenshots' and len(entries) < 2:
                raise ValueError(f'{locale}/{kind}: Play requires at least two phone screenshots')
            values = []
            for entry in entries:
                if not isinstance(entry, dict) or set(entry) - {'path', 'screen', 'altText'} or 'path' not in entry:
                    raise ValueError(f'{locale}/{kind}: invalid image entry')
                if any(not isinstance(value, str) for value in entry.values()):
                    raise ValueError(f'{locale}/{kind}: image entry values must be text')
                relative = Path(entry['path'])
                path = (assets_path.parent / relative).resolve()
                if relative.is_absolute() or not path.is_relative_to(assets_path.parent):
                    raise ValueError(f'{locale}/{kind}: image paths must stay inside the manifest directory')
                body = path.read_bytes()
                with Image.open(path) as image:
                    image.load()
                    width, height = image.size
                    fmt = image.format
                    if fmt not in {'PNG', 'JPEG'} or image.mode != 'RGB':
                        raise ValueError(f'{locale}/{kind}: requires RGB PNG/JPEG without alpha')
                    if (kind == 'featureGraphic' and (width, height) != (1024, 500)) or (
                        kind != 'featureGraphic' and (min(width, height) < 320 or max(width, height) > 3840
                                                    or max(width, height) > 2 * min(width, height))):
                        raise ValueError(f'{locale}/{kind}: invalid image dimensions {width}x{height}')
                if not body or len(body) > 8_000_000:
                    raise ValueError(f'{locale}/{kind}: image exceeds 8 MB')
                values.append({**entry, 'path': str(path), 'sha256': sha(body), 'fileSize': len(body),
                               'width': width, 'height': height,
                               'mimeType': 'image/png' if fmt == 'PNG' else 'image/jpeg'})
            hashes = [value['sha256'] for value in values]
            if len(set(hashes)) != len(hashes):
                raise ValueError(f'{locale}/{kind}: duplicate images within one ordered set')
            media[f'{locale}/{kind}'] = values
    if not media:
        raise ValueError('At least one nonempty media array is required')
    plan = {'packageName': PACKAGE, 'expectedProductionVersionCode': str(expected_version),
            'metadataPath': str(metadata_path), 'assetsPath': str(assets_path),
            'metadataInputHash': sha(metadata_path.read_bytes()), 'assetsInputHash': sha(assets_path.read_bytes()),
            'listings': dict(sorted(listings.items())), 'media': dict(sorted(media.items()))}
    plan['planHash'] = digest(plan)
    return plan


class ApiError(RuntimeError):
    def __init__(self, message, status=None, reason=None):
        super().__init__(message)
        self.status, self.reason = status, reason


class PlayApi(StoreApi):
    """Reuse existing credential loading without printing raw server/auth data."""
    def call(self, method, url, **kwargs):
        if urlparse(url).netloc != 'androidpublisher.googleapis.com':
            raise ValueError('Refusing to forward credentials outside the Play API')
        headers = dict(kwargs.pop('headers', {}))
        headers['Authorization'] = f'Bearer {self.token("play")}'
        try:
            response = self.session.request(method, url, headers=headers, timeout=55, **kwargs)
        except requests.RequestException:
            raise ApiError(f'Play {method}: transport response unknown') from None
        if not response.ok:
            reason = None
            try:
                details = response.json().get('error', {}).get('details', [])
                reason = next((d['reason'] for d in details if 'reason' in d), None)
            except (ValueError, TypeError, AttributeError):
                pass
            safe_reason = reason if isinstance(reason, str) and re.fullmatch(r'[A-Z_]+', reason) else None
            raise ApiError(f'Play {method}: HTTP {response.status_code}' +
                           (f' ({safe_reason})' if safe_reason else ''), response.status_code, safe_reason)
        return response.json() if response.content else {}

    def download(self, url):
        # Public preview URLs do not receive the Publisher bearer token.
        host = urlparse(url).hostname or ''
        if urlparse(url).scheme != 'https' or not any(host == h or host.endswith('.' + h)
                                                     for h in ('googleusercontent.com', 'ggpht.com')):
            raise ValueError('Unexpected image preview host; backup stopped before mutation')
        try:
            response = requests.get(url, timeout=55)
            response.raise_for_status()
            return response.content
        except requests.RequestException:
            raise ApiError('Image backup download failed; no authentication data logged') from None


def image_hashes(images):
    result = [image.get('sha256', '').lower() for image in images]
    if any(not re.fullmatch('[0-9a-f]{64}', value) for value in result):
        raise ValueError('Play returned a missing or malformed SHA256; refusing an unverifiable update')
    return result


def image_list(api, base, key):
    return api.call('GET', f'{base}/listings/{key}').get('images', [])


def snapshot(api, base):
    listings = api.call('GET', f'{base}/listings').get('listings', [])
    if len({item['language'] for item in listings}) != len(listings):
        raise ValueError('Duplicate languages in Play listing response')
    state = {'listings': {item['language']: item for item in listings},
             'tracks': api.call('GET', f'{base}/tracks'), 'details': api.call('GET', f'{base}/details')}
    keys = [f'{locale}/{kind}' for locale in sorted(state['listings']) for kind in ALL_TYPES]
    with ThreadPoolExecutor(max_workers=6) as pool:
        images = list(pool.map(lambda key: image_list(api, base, key), keys))
    state['images'] = dict(zip(keys, images))
    for values in images:
        image_hashes(values)
    return state


def production_versions(state):
    return sorted({str(version) for track in state['tracks'].get('tracks', []) if track['track'] == 'production'
                   for release in track.get('releases', []) for version in release.get('versionCodes', [])})


def tracks_signature(state):
    # Track order is not semantic; release array order and all release fields are retained.
    return sorted(state['tracks'].get('tracks', []), key=lambda track: track['track'])


def check_baseline(state, plan):
    if set(state['listings']) != set(plan['listings']):
        raise ValueError('Live listing languages differ from the metadata manifest; no locales may be added/deleted')
    if production_versions(state) != [plan['expectedProductionVersionCode']]:
        raise ValueError('Production version does not match the explicitly expected version code')


def desired_listing(before, proposed):
    # Merge instead of clearing an existing YouTube video URL.
    return {**before, **proposed}


def verify(state, baseline, plan):
    check_baseline(state, plan)
    if tracks_signature(state) != tracks_signature(baseline) or state['details'] != baseline['details']:
        raise ValueError('Tracks or application details changed; refusing commit')
    for locale, item in state['listings'].items():
        if item != desired_listing(baseline['listings'][locale], plan['listings'][locale]):
            raise ValueError(f'{locale}: exact metadata/video readback did not match')
    for key, images in state['images'].items():
        expected = ([image['sha256'] for image in plan['media'][key]] if key in plan['media']
                    else image_hashes(baseline['images'][key]))
        if image_hashes(images) != expected:
            raise ValueError(f'{key}: ordered image hashes changed or did not match')
        if key not in plan['media'] and [i.get('id') for i in images] != [i.get('id') for i in baseline['images'][key]]:
            raise ValueError(f'{key}: preserved image identity changed')


def backup(api, root, state, plan):
    records = []
    for key in plan['media']:
        for index, image in enumerate(state['images'][key]):
            # Preview bytes may be encoded differently from the original upload.
            # Retain both hashes rather than misrepresenting preview bytes as originals.
            body = api.download(image['url'] + ('=s0' if '=' not in image['url'].rsplit('/', 1)[-1] else ''))
            if not body:
                raise ValueError('Empty image backup; no listing mutation performed')
            try:
                with Image.open(io.BytesIO(body)) as downloaded:
                    size, encoding = downloaded.size, downloaded.format
                    downloaded.verify()
            except (OSError, ValueError):
                raise ValueError('Invalid image byte backup; no listing mutation performed') from None
            path = root / 'backup-images' / key / f'{index + 1:02d}-{image["id"]}.image'
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(body)
            records.append({'key': key, 'id': image['id'], 'path': str(path.relative_to(root)),
                            'uploadedSha256': image['sha256'], 'downloadedSha256': sha(body), 'fileSize': len(body),
                            'downloadedSize': list(size), 'downloadedEncoding': encoding})
    value = {'state': state, 'imageByteBackups': records,
             'backupNote': 'Downloaded full-size preview bytes; uploaded hashes and source URLs are retained separately.'}
    save(root / BASELINE, value)
    return value


def check_backups(root, journal):
    value = read(root / BASELINE)
    if digest(value) != journal['baselineHash']:
        raise ValueError('Baseline backup changed')
    for entry in value['imageByteBackups']:
        if sha((root / entry['path']).read_bytes()) != entry['downloadedSha256']:
            raise ValueError('An image byte backup changed or disappeared')
    return value['state']


def expiry(edit, now=None):
    timestamp = int(edit.get('expiryTimeSeconds', 0))
    if timestamp <= (time.time() if now is None else now) + 60:
        raise ValueError('API edit expired or expires within 60 seconds; review Console and start with a new journal directory')
    return datetime.fromtimestamp(timestamp, timezone.utc).isoformat()


def edit_base(journal):
    return f'{PLAY_BASE}/{journal["editId"]}'


def load_journal(root, plan):
    journal = read(root / JOURNAL)
    if journal.get('schemaVersion') != 1 or journal.get('planHash') != plan['planHash']:
        raise ValueError('Journal does not match these exact metadata/artwork inputs')
    if journal.get('state') in {'CREATE_INTENT', 'CREATE_UNKNOWN', 'COMMITTING', 'COMMIT_UNKNOWN'}:
        raise ValueError('Previous create/commit response is unknown; reconcile in Console before another command')
    return journal


def replace_set(api, root, journal, baseline, key, values):
    base = edit_base(journal)
    target = [value['sha256'] for value in values]
    current = image_hashes(image_list(api, base, key))
    progress = journal.setdefault('mediaProgress', {}).setdefault(key, {})
    if current == target:
        progress.update({'state': 'VERIFIED', 'hashes': current})
        save(root / JOURNAL, journal)
        return
    if not progress:
        if current != image_hashes(baseline['images'][key]):
            raise ValueError(f'{key}: image set changed before replacement')
        progress['state'] = 'RESET_INTENT'
        save(root / JOURNAL, journal)
    if progress['state'] == 'RESET_INTENT':
        if current == image_hashes(baseline['images'][key]):
            # DELETE is idempotent; after an ambiguous response rerun re-reads first.
            api.call('DELETE', f'{base}/listings/{key}')
            current = image_hashes(image_list(api, base, key))
        if current:
            raise ValueError(f'{key}: reset did not leave an empty set')
        progress['state'] = 'UPLOADING'
        save(root / JOURNAL, journal)
    if current != target[:len(current)] or len(current) > len(target):
        raise ValueError(f'{key}: remote images are not the planned ordered prefix; refusing retry')
    for value in values[len(current):]:
        body = Path(value['path']).read_bytes()
        if sha(body) != value['sha256']:
            raise ValueError('Artwork bytes changed after validation')
        progress.update({'state': 'UPLOAD_INTENT', 'beforeHashes': current, 'pendingSha256': value['sha256']})
        save(root / JOURNAL, journal)
        error = None
        try:
            api.call('POST', f'{UPLOAD_BASE}/{journal["editId"]}/listings/{key}',
                     params={'uploadType': 'media'}, headers={'Content-Type': value['mimeType']}, data=body)
        except (ApiError, requests.RequestException) as failure:
            error = failure
        # Always reconcile with GET, including timeouts/5xx, before any further upload.
        observed = image_hashes(image_list(api, base, key))
        if observed != current + [value['sha256']]:
            progress['state'] = 'UPLOAD_UNKNOWN' if error else 'READBACK_MISMATCH'
            save(root / JOURNAL, journal)
            raise ValueError(f'{key}: upload readback is not confirmed; rerun reconciles before retrying') from None
        current = observed
        progress.update({'state': 'UPLOADING', 'hashes': current})
        save(root / JOURNAL, journal)
    progress.update({'state': 'VERIFIED', 'hashes': current})
    save(root / JOURNAL, journal)


def stage(api, root, plan):
    if (root / JOURNAL).exists():
        journal = load_journal(root, plan)
        if journal['state'] not in {'CREATED', 'BACKED_UP', 'STAGING', 'STAGED'}:
            raise ValueError(f'Cannot stage journal in state {journal["state"]}')
        expiry(api.call('GET', edit_base(journal)))
    else:
        journal = {'schemaVersion': 1, 'planHash': plan['planHash'], 'plan': plan, 'state': 'CREATE_INTENT'}
        save(root / JOURNAL, journal)
        try:
            edit = api.call('POST', PLAY_BASE, json={})
        except Exception:
            journal['state'] = 'CREATE_UNKNOWN'
            save(root / JOURNAL, journal)
            raise
        journal.update({'editId': edit['id'], 'expiryTimeSeconds': edit['expiryTimeSeconds'], 'state': 'CREATED',
                        'expiresAtUtc': datetime.fromtimestamp(int(edit['expiryTimeSeconds']), timezone.utc).isoformat(),
                        'editLifetime': 'About 1 hour; staged changes are not a persistent Console draft.'})
        save(root / JOURNAL, journal)
        expiry(edit)
    base = edit_base(journal)
    if 'baselineHash' not in journal:
        state = snapshot(api, base)
        check_baseline(state, plan)
        value = backup(api, root, state, plan)
        journal.update({'baselineHash': digest(value), 'state': 'BACKED_UP'})
        save(root / JOURNAL, journal)
    baseline = check_backups(root, journal)
    # No listing/image mutation occurs before every selected original is backed up.
    journal['state'] = 'STAGING'
    save(root / JOURNAL, journal)
    current = api.call('GET', f'{base}/listings').get('listings', [])
    current = {item['language']: item for item in current}
    if set(current) != set(baseline['listings']):
        raise ValueError('Listing locale set changed during staging')
    for locale, proposed in plan['listings'].items():
        desired = desired_listing(baseline['listings'][locale], proposed)
        if current[locale] == desired:
            continue
        if current[locale] != baseline['listings'][locale]:
            raise ValueError(f'{locale}: unexpected metadata changed before staging')
        api.call('PUT', f'{base}/listings/{locale}', json=desired)
    for key, values in plan['media'].items():
        replace_set(api, root, journal, baseline, key, values)
    verify(snapshot(api, base), baseline, plan)
    validated = api.call('POST', f'{base}:validate')
    if validated.get('id', journal['editId']) != journal['editId']:
        raise ValueError('Validate returned a different edit identifier')
    journal.update({'state': 'STAGED', 'verifiedAt': datetime.now(timezone.utc).isoformat()})
    save(root / JOURNAL, journal)
    return journal


def commit(api, root, plan):
    journal = load_journal(root, plan)
    if journal['state'] != 'STAGED':
        raise ValueError('Commit requires the exact successfully STAGED journal')
    base = edit_base(journal)
    expiry(api.call('GET', base))
    baseline = check_backups(root, journal)
    verify(snapshot(api, base), baseline, plan)
    api.call('POST', f'{base}:validate')
    journal['state'] = 'COMMITTING'
    save(root / JOURNAL, journal)
    try:
        result = api.call('POST', f'{base}:commit', params={'changesInReviewBehavior': 'ERROR_IF_IN_REVIEW'})
    except Exception as error:
        # A definitive 4xx did not commit; unknown transport/5xx is never retried.
        journal['state'] = ('STAGED' if isinstance(error, ApiError) and error.status is not None
                            and 400 <= error.status < 500 and error.status != 408 else 'COMMIT_UNKNOWN')
        save(root / JOURNAL, journal)
        raise
    if result.get('id') != journal['editId']:
        journal['state'] = 'COMMIT_UNKNOWN'
        save(root / JOURNAL, journal)
        raise ValueError('Commit response identifier mismatch; verify Publishing overview before proceeding')
    journal.update({'state': 'COMMITTED', 'committedAt': datetime.now(timezone.utc).isoformat()})
    save(root / JOURNAL, journal)
    return journal


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('action', choices=('validate', 'stage', 'commit'))
    parser.add_argument('--metadata', required=True, type=Path)
    parser.add_argument('--assets', required=True, type=Path)
    parser.add_argument('--root', required=True, type=Path, help='Dedicated journal/backup/report directory')
    parser.add_argument('--expected-production-version-code', default='21')
    parser.add_argument('--credentials', type=Path, default=Path.home() / 'Development/secret')
    parser.add_argument('--execute', action='store_true', help='Required for either stage or commit API mutations')
    args = parser.parse_args(argv)
    plan = load_plan(args.metadata, args.assets, args.expected_production_version_code)
    with locked(args.root):
        report = {'planHash': plan['planHash'], 'packageName': PACKAGE, 'metadataLocales': len(plan['listings']),
                  'mediaSets': len(plan['media']), 'imagePlacements': sum(map(len, plan['media'].values())),
                  'mediaLocales': sorted({key.split('/')[0] for key in plan['media']}),
                  'altText': 'Retained locally; unsupported by the Play images API',
                  'emptyMediaArrays': 'Preserved; never deleted', 'plan': plan}
        save(args.root / 'play-listing-offline-report.json', report)
        if args.action != 'validate':
            if not args.execute:
                raise ValueError(f'{args.action} requires --execute; offline report saved, no API request made')
            api = PlayApi(args.credentials)
            journal = stage(api, args.root, plan) if args.action == 'stage' else commit(api, args.root, plan)
            report.update({'state': journal['state'], 'editId': journal['editId'],
                           'expiryTimeSeconds': journal['expiryTimeSeconds'],
                           'expiresAtUtc': datetime.fromtimestamp(int(journal['expiryTimeSeconds']), timezone.utc).isoformat(),
                           'editLifetime': 'About 1 hour. Console changes invalidate it; staged is not published.'})
            save(args.root / f'play-listing-{args.action}-report.json', report)
        print(json.dumps({key: value for key, value in report.items() if key != 'plan'}, indent=2))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, ApiError, OSError) as error:
        print(f'Listing operation stopped: {error}', file=sys.stderr)
        sys.exit(1)
