"""Compose Google Play artwork from current, real Android app captures.

Phone screenshots use one short headline and a uniformly scaled app viewport.
Tablet screenshots export the responsive app capture directly. The feature
graphic is a separate 1024x500 SVG composition. No device hardware is drawn.
"""

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from compose_creative_assets import REPO, render_svg, text_svg, viewport_svg


DEFAULT_ROOT = Path('build/android-growth/2026-10-26')
SCREENS = ('home', 'checklist', 'foldersSearch', 'formattedNote', 'reminderAgenda', 'backup')
DEVICES = {
    'playphone': ('phoneScreenshots', [1080, 1920]),
    'play7inch_16_9': ('sevenInchScreenshots', [2304, 1296]),
    'play10inch_16_9': ('tenInchScreenshots', [3200, 1800]),
}
COPY = {
    'en-US': {
        'ui': 'en',
        'headlines': ['Your day,\nin notes.', 'Plans you can\ncheck off.', 'Find the note\nyou need.',
                      'Make room\nfor ideas.', 'Remember\nwhat matters.', 'Your notes.\nYour backup.'],
        'feature': 'Notes, lists,\nand little\nmoments.',
        'alt': ['Colorful notes organized in the Onlynote library.',
                'A weekend checklist with completed and upcoming tasks.',
                'Folder filtering and highlighted search results.',
                'A note with headings and highlighted text.',
                'The reminder agenda with upcoming notes.',
                'The backup and readable note export dashboard.'],
        'featureAlt': 'Onlynote notes and checklists on warm paper backgrounds.',
    },
    'zh-CN': {
        'ui': 'zh-Hans',
        'headlines': ['日常点滴，\n随手记下。', '把计划，\n一项项完成。', '想找的备忘，\n轻松找到。',
                      '留一点空间，\n记录灵感。', '重要的事，\n记得提醒。', '备份备忘，\n安心保存。'],
        'feature': '备忘、清单，\n记录生活\n小片刻。',
        'alt': ['Onlynote 备忘列表中的彩色备忘卡片。', '周末清单，显示已完成和待办事项。',
                '文件夹筛选与高亮显示的搜索结果。', '带有标题和高亮文字的备忘。',
                '提醒日程中的待办备忘。', '备份和可阅读格式导出界面。'],
        'featureAlt': '暖色纸张背景上的 Onlynote 备忘和清单。',
    },
    'zh-TW': {
        'ui': 'zh-Hant',
        'headlines': ['日常點滴，\n隨手記下。', '把計畫，\n一項項完成。', '想找的備忘，\n輕鬆找到。',
                      '留一點空間，\n記錄靈感。', '重要的事，\n記得提醒。', '備份備忘，\n安心保存。'],
        'feature': '備忘、清單，\n記錄生活\n小片刻。',
        'alt': ['Onlynote 備忘列表中的彩色備忘卡片。', '週末清單，顯示已完成和待辦事項。',
                '資料夾篩選與標示相符文字的搜尋結果。', '帶有標題和標示文字的備忘。',
                '提醒日程中的待辦備忘。', '備份和可閱讀格式匯出介面。'],
        'featureAlt': '暖色紙張背景上的 Onlynote 備忘和清單。',
    },
}
LOCALE_ALIASES = {'zh-HK': 'zh-TW'}


def capture_path(captures, device, ui_locale, screen):
    if device not in DEVICES:
        raise ValueError(f'Expected a real Android device capture, got {device}')
    matches = list((captures / device / ui_locale).glob(f'[0-9][0-9]-{screen}.png'))
    if len(matches) != 1:
        raise ValueError(f'Expected exactly one capture: {device}/{ui_locale}/{screen}')
    with Image.open(matches[0]) as image:
        if list(image.size) != DEVICES[device][1]:
            raise ValueError(f'Unexpected Android capture dimensions: {matches[0]} {image.size}')
    return matches[0]


def source_metadata(path):
    with Image.open(path) as image:
        size = list(image.size)
    return {'path': str(path.resolve()), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'size': size}


def background(width, height):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
            '<defs><filter id="shadow" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="10"/></filter></defs>',
            f'<rect width="{width}" height="{height}" fill="#F5EBD9"/>',
            f'<path d="M0 {height*.52} Q{width*.37} {height*.32} {width} {height*.72} V{height} H0Z" fill="#EBD9B6"/>',
            f'<path d="M{width*.84} 0 H{width} V{height} H{width*.60}Z" fill="#DDE4C9"/>']


def phone_svg(captures, locale, screen):
    copy = COPY[locale]
    source = capture_path(captures, 'playphone', copy['ui'], screen)
    parts = background(1080, 1920)
    # 292 px is 15.2% of canvas height. Headline and whitespace together remain
    # below Google's recommended 20%, with the real interface taking priority.
    title_style = {'box': [80, 40, 920, 244], 'size': 96, 'minimum': 82, 'lineHeight': 1.05}
    title, text_report = text_svg(copy['headlines'][SCREENS.index(screen)], locale, title_style,
                                  [0, 0, 1080, 292], bold=True)
    ui, ui_report = viewport_svg(captures, copy['ui'], {
        'device': 'playphone', 'screen': screen, 'box': [80, 292, 920, 920*16/9]},
        screen, [0, 0, 1080, 1920])
    parts.extend([title, ui, '</svg>'])
    return ''.join(parts), {'size': [1080, 1920], 'taglineFraction': 292/1920,
                            'title': text_report, 'viewport': ui_report, 'source': source_metadata(source)}


def feature_svg(captures, locale):
    copy = COPY[locale]
    # Focal content stays away from the graphic's outer edges. These are local
    # composition margins, not an invented Google safe-area specification.
    parts = background(1024, 500)
    back, back_report = viewport_svg(captures, copy['ui'], {
        'device': 'playphone', 'screen': 'checklist', 'box': [825, 104, 225, 400]},
        'feature-checklist', [0, 0, 1024, 500])
    fore, fore_report = viewport_svg(captures, copy['ui'], {
        'device': 'playphone', 'screen': 'home', 'box': [620, 46, 300, 300*16/9]},
        'feature-home', [0, 0, 1024, 500])
    title, title_report = text_svg(copy['feature'], locale,
                                  {'box': [82, 106, 510, 294], 'size': 58, 'minimum': 48, 'lineHeight': 1.08},
                                  [64, 50, 896, 400], bold=True)
    parts.extend([back, fore, title, '</svg>'])
    return ''.join(parts), {'size': [1024, 500], 'title': title_report,
                            'viewports': [back_report, fore_report]}


def export_tablet(source, destination):
    # Export opaque RGB without rescaling, cropping, frames, or marketing text.
    with Image.open(source) as image:
        image.convert('RGB').save(destination)
    return source_metadata(source)


def contacts(output, manifest):
    font = ImageFont.truetype(str(REPO / 'assets/fonts/Roboto-Bold.ttf'), 24)
    for locale, assets in manifest['locales'].items():
        if locale in LOCALE_ALIASES:
            continue
        for kind in ('phoneScreenshots', 'sevenInchScreenshots', 'tenInchScreenshots'):
            rows = assets.get(kind, [])
            if not rows:
                continue
            columns, cell_width, cell_height = (3, 360, 690) if kind == 'phoneScreenshots' else (2, 640, 410)
            sheet = Image.new('RGB', (cell_width*columns, cell_height*((len(rows)+columns-1)//columns)), '#EEE8DD')
            draw = ImageDraw.Draw(sheet)
            for index, row in enumerate(rows):
                x, y = index % columns * cell_width, index // columns * cell_height
                draw.text((x+12, y+8), f'{index+1} · {row["screen"]}', font=font, fill='#302A24')
                with Image.open(output / row['path']) as image:
                    image.thumbnail((cell_width-12, cell_height-60), Image.Resampling.LANCZOS)
                    sheet.paste(image, (x+(cell_width-image.width)//2, y+48))
            sheet.save(output / locale / f'{kind}-contact.jpg', quality=93)


def compose(captures, output, locales, devices):
    if any(locale not in COPY for locale in locales):
        raise ValueError('Only actual English, Simplified Chinese, and Traditional Chinese UI captures are supported')
    if any(device not in DEVICES for device in devices):
        raise ValueError('Choose Android device profiles only')
    manifest_path, report_path = output / 'android-assets-manifest.json', output / 'composition-report.json'
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {'packageName': 'com.appsbay.onlynote', 'locales': {}}
    report = json.loads(report_path.read_text()) if report_path.exists() else {'source': 'Real Android production widgets with deterministic sample notes; no native widget mockups.',
                                                                           'screenOrder': list(SCREENS), 'compositions': {}}
    # Validate all selected sources/copy before writing replacements. A scoped
    # tablet refresh preserves approved phone and feature-graphic bytes.
    prepared = {}
    for locale in locales:
        for device in devices:
            for screen in SCREENS:
                source = capture_path(captures, device, COPY[locale]['ui'], screen)
                prepared[locale, device, screen] = phone_svg(captures, locale, screen) if device == 'playphone' else source
        if 'playphone' in devices or 'featureGraphic' not in manifest['locales'].get(locale, {}):
            prepared[locale, 'feature'] = feature_svg(captures, locale)
    output.mkdir(parents=True, exist_ok=True)
    for locale in locales:
        folder = output / locale
        folder.mkdir(exist_ok=True)
        assets = dict(manifest['locales'].get(locale, {}))
        details = dict(report['compositions'].get(locale, {}))
        for device in devices:
            kind = DEVICES[device][0]
            target = folder / kind
            target.mkdir(exist_ok=True)
            assets[kind], details[kind] = [], []
            for index, screen in enumerate(SCREENS):
                png = target / f'{index+1:02}-{screen}.png'
                if device == 'playphone':
                    svg, metadata = prepared[locale, device, screen]
                    svg_path = png.with_suffix('.svg')
                    svg_path.write_text(svg)
                    render_svg(svg_path, png, output)
                else:
                    metadata = {'size': DEVICES[device][1], 'source': export_tablet(prepared[locale, device, screen], png)}
                assets[kind].append({'path': str(png.relative_to(output)), 'screen': screen, 'altText': COPY[locale]['alt'][index]})
                details[kind].append(metadata)
            print(f'Composed {locale}/{kind}: {len(SCREENS)} current Android screens.', flush=True)
        if (locale, 'feature') in prepared:
            svg, metadata = prepared[locale, 'feature']
            svg_path, png = folder / 'featureGraphic.svg', folder / 'featureGraphic.png'
            svg_path.write_text(svg)
            render_svg(svg_path, png, output)
            assets['featureGraphic'] = [{'path': str(png.relative_to(output)), 'altText': COPY[locale]['featureAlt']}]
            details['featureGraphic'] = metadata
        manifest['locales'][locale], report['compositions'][locale] = assets, details
    # The app has one Traditional Chinese interface. Explicit localized
    # placements for Hong Kong reuse Taiwan's exact files and ordered alt text.
    for locale, source in LOCALE_ALIASES.items():
        if source in manifest['locales']:
            manifest['locales'][locale] = manifest['locales'][source]
    report['localeAliases'] = {locale: source for locale, source in LOCALE_ALIASES.items()
                               if source in manifest['locales']}
    (output / 'android-assets-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    (output / 'composition-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2))
    contacts(output, manifest)
    return manifest, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--captures', type=Path, default=DEFAULT_ROOT / 'raw-app')
    parser.add_argument('--output', type=Path, default=DEFAULT_ROOT / 'assets')
    parser.add_argument('--locales', default='en-US', help='Comma-separated en-US,zh-CN,zh-TW, or all')
    parser.add_argument('--devices', default=','.join(DEVICES), help='Comma-separated Android capture profiles')
    args = parser.parse_args()
    requested = list(COPY) if args.locales == 'all' else args.locales.split(',')
    locales = list(dict.fromkeys(LOCALE_ALIASES.get(locale, locale) for locale in requested))
    compose(args.captures, args.output, locales, args.devices.split(','))


if __name__ == '__main__':
    main()
