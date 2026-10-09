"""Convert opaque Flutter captures to store-compatible RGB JPEGs with macOS sips."""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image

from upload import APPLE_DEVICES, APPLE_LOCALES, PLAY_DEVICES, preflight


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('build/store_screenshots/2026-10-08'))
    parser.add_argument('--devices', help='Comma-separated devices to re-export; other JPEGs remain unchanged.')
    parser.add_argument('--locales', help='Comma-separated locales to re-export; other JPEGs remain unchanged.')
    args = parser.parse_args()
    devices = {**APPLE_DEVICES, **PLAY_DEVICES}
    selected = set(args.devices.split(',')) if args.devices else set(devices)
    if selected - devices.keys():
        raise ValueError(f'Unknown devices: {sorted(selected - devices.keys())}')
    selected_locales = set(args.locales.split(',')) if args.locales else set(APPLE_LOCALES)
    if selected_locales - APPLE_LOCALES.keys():
        raise ValueError(f'Unknown locales: {sorted(selected_locales - APPLE_LOCALES.keys())}')
    manifest = []
    for device, (_, size) in devices.items():
        for locale in APPLE_LOCALES:
            folder = args.root / device / locale
            captures = sorted(folder.glob('[0-9][0-9]-*.png'))
            if len(captures) != 8:
                raise ValueError(f'{device}/{locale}: expected 8 captures, found {len(captures)}')
            upload_folder = args.root / 'upload' / device / locale
            upload_folder.mkdir(parents=True, exist_ok=True)
            for source in captures:
                with Image.open(source) as image:
                    if image.size != size:
                        raise ValueError(f'{source}: unexpected size {image.size}')
                    if image.mode == 'RGBA' and image.getchannel('A').getextrema() != (255, 255):
                        raise ValueError(f'{source}: capture must be opaque before export')
                target = source.with_suffix('.jpg')
                if device in selected and locale in selected_locales:
                    subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '96',
                                    str(source), '--out', str(target)], check=True, capture_output=True)
                    (upload_folder / target.name).write_bytes(target.read_bytes())
                manifest.append({
                    'device': device, 'locale': locale, 'path': str(target.relative_to(args.root)),
                    'width': size[0], 'height': size[1], 'bytes': target.stat().st_size,
                    'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                })
    preflight(args.root)
    (args.root / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
    print(f'Prepared {len(manifest)} JPEGs and per-set upload folders.', flush=True)


if __name__ == '__main__':
    main()
