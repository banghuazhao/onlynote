"""Convert opaque Flutter captures to store-compatible RGB JPEGs with macOS sips."""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image

from upload import preflight, select_devices, select_locales


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('build/store_screenshots/2026-10-08'))
    parser.add_argument('--devices', help='Comma-separated devices to export and validate; other captures are not required.')
    parser.add_argument('--locales', help='Comma-separated locales to export and validate; other captures are not required.')
    parser.add_argument('--count', type=int, default=8, help='Expected captures per device and locale (default: 8).')
    args = parser.parse_args()
    if not 1 <= args.count <= 10:
        parser.error('--count must be between 1 and 10')
    devices = select_devices(args.devices)
    locales = select_locales(args.locales)
    manifest_file = args.root / 'manifest.json'
    prior = json.loads(manifest_file.read_text()) if manifest_file.exists() else []
    manifest = [item for item in prior if item['device'] not in devices or item['locale'] not in locales]
    for device, (_, size) in devices.items():
        for locale in locales:
            folder = args.root / device / locale
            captures = sorted(folder.glob('[0-9][0-9]-*.png'))
            if len(captures) != args.count:
                raise ValueError(f'{device}/{locale}: expected {args.count} captures, found {len(captures)}')
            upload_folder = args.root / 'upload' / device / locale
            upload_folder.mkdir(parents=True, exist_ok=True)
            for source in captures:
                with Image.open(source) as image:
                    if image.size != size:
                        raise ValueError(f'{source}: unexpected size {image.size}')
                    if image.mode == 'RGBA' and image.getchannel('A').getextrema() != (255, 255):
                        raise ValueError(f'{source}: capture must be opaque before export')
                target = source.with_suffix('.jpg')
                subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '96',
                                str(source), '--out', str(target)], check=True, capture_output=True)
                (upload_folder / target.name).write_bytes(target.read_bytes())
                manifest.append({
                    'device': device, 'locale': locale, 'path': str(target.relative_to(args.root)),
                    'width': size[0], 'height': size[1], 'bytes': target.stat().st_size,
                    'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                })
            # A smaller or renamed capture sequence must not leave old numbered
            # JPEGs in either selected set. Keep unrelated files and other sets.
            capture_stems = {source.stem for source in captures}
            for output_folder in (folder, upload_folder):
                for extension in ('jpg', 'jpeg'):
                    for obsolete in output_folder.glob(f'[0-9][0-9]-*.{extension}'):
                        if obsolete.stem not in capture_stems:
                            obsolete.unlink()
    preflight(args.root, devices, locales, args.count)
    manifest_file.write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
    print(f'Prepared {len(manifest)} JPEGs and per-set upload folders.', flush=True)


if __name__ == '__main__':
    main()
