"""Compose editable SVG artwork from real caption-free Flutter captures.

SVG supplies typography, paper surfaces, and rounded viewport cards. Production
screens remain embedded PNGs. Sharp's bundled librsvg/Pango renderer produces
the final image; Pillow is used only for font metrics and opaque RGB export.
"""

import argparse
import base64
from functools import lru_cache
import hashlib
import html
import json
import os
from pathlib import Path
import re
import subprocess

from fontTools.ttLib import TTCollection, TTFont
from PIL import Image, ImageDraw, ImageFont


REPO = Path(__file__).resolve().parents[2]
RUNTIME = Path.home() / '.cache/codex-runtimes/codex-primary-runtime/dependencies'
DEFAULT_CAPTURES = Path('build/store_assets/2026-10-26/raw-app')
DEFAULT_OUTPUT = Path('build/store_assets/2026-10-26-v2')
DEFAULT_LAYOUT = {
    'header': {
        'size': [3840, 1646], 'safe': [1097, 493, 1646, 661],
        'title': {'box': [1160, 540, 900, 380], 'size': 164, 'minimum': 144, 'lineHeight': 1.08},
        'subtitle': {'box': [1160, 940, 900, 180], 'size': 72, 'minimum': 64, 'lineHeight': 1.16},
        'viewports': [
            {'device': 'iphone_duo_outer', 'screen': 'checklist', 'box': [2940, 170, 1160, 1688], 'rotation': 6},
            {'device': 'iphone_duo_inner', 'screen': 'home', 'box': [2180, 390, 1100, 1564],
             'focal': [80, 300, 580, 100]},
        ],
    },
    'search': {
        'size': [3840, 2560], 'safe': [836, 765, 2168, 1030],
        'title': {'box': [900, 790, 1200, 800], 'size': 180, 'minimum': 142, 'lineHeight': 1.08},
        'subtitle': {'box': [900, 1608, 1150, 187], 'size': 78, 'minimum': 68, 'lineHeight': 1.16},
        'viewports': [
            {'device': 'iphone_duo_outer', 'screen': 'checklist', 'box': [3060, 360, 1160, 1688], 'rotation': 7},
            {'device': 'iphone_duo_inner', 'screen': 'home', 'box': [2300, 650, 1300, 1848],
             'focal': [80, 300, 580, 100]},
        ],
    },
}


def escaped(value):
    return html.escape(str(value), quote=True)


@lru_cache(maxsize=None)
def font_face(path, bold=False):
    path = Path(path)
    index = 0
    if path.suffix.lower() == '.ttc':
        collection = TTCollection(path, lazy=True)
        try:
            for number, font in enumerate(collection.fonts):
                style = font['name'].getDebugName(2) or ''
                matches_weight = 'Bold' in style if bold else style in {'Regular', 'W3'}
                if matches_weight:
                    index = number
                    break
        finally:
            collection.close()
    with TTFont(path, fontNumber=index, lazy=True) as font:
        family = font['name'].getDebugName(16) or font['name'].getDebugName(1)
        cmap = frozenset(font.getBestCmap())
    return str(path.resolve()), index, family, cmap


def selected_font(locale, bold):
    if locale.startswith('ja'):
        candidates = sorted(Path('/System/Library/Fonts').glob('* W6.ttc' if bold else '* W3.ttc'))
        if candidates:
            return font_face(str(candidates[0]), bold)
    if locale.startswith('ko'):
        return font_face('/System/Library/Fonts/AppleSDGothicNeo.ttc', bold)
    if locale.startswith('zh'):
        return font_face(str(REPO / 'assets/fonts/DroidSansFallback.ttf'), bold)
    return font_face(str(REPO / f'build/store_screenshots/fonts/Montserrat-{"Bold" if bold else "Regular"}.ttf'), bold)


class WordTooWide(ValueError):
    pass


def wrap(text, font, width):
    result = []
    for paragraph in text.split('\n'):
        line = ''
        tokens = re.findall(r'[\w\u00C0-\u024F’\-]+[.,!?;:…、。！？]*|\s+|.', paragraph)
        for token in tokens:
            if font.getlength(line + token) <= width:
                line += token
            else:
                if line.strip():
                    result.append(line.rstrip())
                    line = ''
                if font.getlength(token.lstrip()) > width:
                    # Font fitting must reduce type or request shorter copy;
                    # splitting a Latin or Korean word is never acceptable.
                    raise WordTooWide(token)
                else:
                    line = token.lstrip()
        result.append(line.rstrip())
    return result


def contains(outer, inner, tolerance=1):
    x, y, width, height = inner
    a, b, w, h = outer
    return x >= a - tolerance and y >= b - tolerance and x + width <= a + w + tolerance and y + height <= b + h + tolerance


def text_svg(text, locale, style, safe, *, bold):
    path, index, family, cmap = selected_font(locale, bold)
    missing = sorted({character for character in text if not character.isspace() and ord(character) not in cmap})
    if missing:
        raise ValueError(f'{locale}: selected font {family} lacks glyphs {missing}')
    x, y, width, height = style['box']
    chosen = None
    for size in range(style['size'], style.get('minimum', style['size']) - 1, -2):
        font = ImageFont.truetype(path, size=size, index=index)
        if locale.startswith(('zh', 'ja')):
            # CJK captions have editorial line breaks. Fit each complete phrase
            # to avoid isolated punctuation, particles, and split kana words.
            lines = text.split('\n')
            if any(font.getlength(line) > width for line in lines):
                continue
        else:
            try:
                lines = wrap(text, font, width)
            except WordTooWide:
                continue
        ascent, descent = font.getmetrics()
        advance = size * style.get('lineHeight', 1.1)
        occupied = ascent + descent + (len(lines) - 1) * advance
        if occupied <= height:
            chosen = (size, lines, ascent, advance, occupied)
            break
    if chosen is None:
        raise ValueError(f'{locale}: text cannot fit at the minimum font size: {text!r}')
    size, lines, ascent, advance, occupied = chosen
    bounds = [x, y, max(font.getlength(line) for line in lines), occupied]
    if not contains(safe, bounds):
        raise ValueError(f'{locale}: critical text exceeds FIG safe area: {bounds}')
    weight = 700 if bold else 400
    if locale.startswith('ja'):
        weight = 600 if bold else 300
    spans = ''.join(f'<tspan x="{x}" y="{y + ascent + number * advance:.2f}">{escaped(line)}</tspan>'
                    for number, line in enumerate(lines))
    svg = (f'<text xml:lang="{escaped(locale)}" font-family="{escaped(family)}" '
           f'font-size="{size}" font-weight="{weight}" fill="{"#302A24" if bold else "#665B4B"}">{spans}</text>')
    return svg, {'text': text, 'lines': lines, 'fontPath': path, 'fontIndex': index,
                 'fontFamily': family, 'fontSize': size, 'bounds': bounds, 'missingGlyphs': []}


def viewport_svg(captures, locale, config, identifier, safe):
    matches = list((captures / config['device'] / locale).glob(f'[0-9][0-9]-{config["screen"]}.png'))
    if len(matches) != 1:
        raise ValueError(f'Expected exactly one real capture for {config["device"]}/{locale}/{config["screen"]}')
    path = matches[0]
    with Image.open(path) as image:
        source_width, source_height = image.size
    x, y, width, height = config['box']
    if abs(width / height - source_width / source_height) > .002:
        raise ValueError('Viewport boxes must preserve the production capture aspect ratio')
    # Use one uniform scale even when the requested box height was rounded.
    height = width * source_height / source_width
    angle = config.get('rotation', 0)
    transform = f'rotate({angle} {x + width / 2} {y + height / 2})'
    focal = None
    if 'focal' in config:
        if angle:
            raise ValueError('Critical focal rectangles currently require an unrotated foreground viewport')
        a, b, w, h = config['focal']
        if not contains([0, 0, source_width, source_height], config['focal']):
            raise ValueError('Critical focal rectangle extends outside the production capture')
        focal = [x + a * width / source_width, y + b * height / source_height,
                 w * width / source_width, h * height / source_height]
        if not contains(safe, focal):
            raise ValueError(f'Critical real UI heading exceeds FIG safe area: {focal}')
    encoded = base64.b64encode(path.read_bytes()).decode('ascii')
    svg = (f'<g transform="{transform}"><rect x="{x}" y="{y}" width="{width}" height="{height}" rx="44" '
           f'fill="#493A24" opacity=".13" transform="translate(0 24)" filter="url(#shadow)"/>'
           f'<clipPath id="clip-{identifier}"><rect x="{x}" y="{y}" width="{width}" height="{height}" rx="44"/></clipPath>'
           f'<image x="{x}" y="{y}" width="{width}" height="{height}" clip-path="url(#clip-{identifier})" '
           f'preserveAspectRatio="none" href="data:image/png;base64,{encoded}"/>'
           f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="44" fill="none" stroke="#D6C7AE" stroke-width="3"/></g>')
    return svg, {'path': str(path.resolve()), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                 'sourceSize': [source_width, source_height], 'box': [x, y, width, height], 'focalBounds': focal}


def compose_svg(captures, locale, copy, placement, layout):
    width, height = layout['size']
    safe = layout['safe']
    pieces = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
              '<defs><filter id="shadow" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="22"/></filter></defs>',
              f'<rect width="{width}" height="{height}" fill="#F5EBD9"/>',
              f'<path d="M-160 {height * .27} Q880 {height * .14} 1880 {height * .9} L1670 {height + 300} H-160Z" fill="#EBD9B6"/>',
              f'<rect x="-440" y="{height * .68}" width="2160" height="1200" rx="78" fill="#E0C69A" opacity=".42" transform="rotate(-14 350 {height * .8})"/>',
              f'<path d="M2600 -180 L4120 -180 L4120 {height + 60} L3070 {height + 200}Z" fill="#DDE4C9"/>']
    viewports = []
    for number, viewport in enumerate(layout['viewports']):
        element, metadata = viewport_svg(captures, copy['uiCaptureLocale'], viewport, number, safe)
        pieces.append(element)
        viewports.append(metadata)
    title, title_metadata = text_svg(copy[placement]['title'], locale, layout['title'], safe, bold=True)
    subtitle, subtitle_metadata = text_svg(copy[placement]['subtitle'], locale, layout['subtitle'], safe, bold=False)
    pieces.extend([title, subtitle, '</svg>'])
    return ''.join(pieces), {'size': layout['size'], 'safe': safe, 'uiCaptureLocale': copy['uiCaptureLocale'], 'title': title_metadata,
                            'subtitle': subtitle_metadata, 'viewports': viewports}


def render_svg(svg_path, png_path, output):
    fontconfig = output / 'fontconfig.xml'
    if not fontconfig.exists():
        directories = [REPO / 'build/store_screenshots/fonts', REPO / 'assets/fonts',
                       Path('/System/Library/Fonts'), Path('/System/Library/Fonts/Supplemental')]
        fontconfig.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig>'
                              + ''.join(f'<dir>{escaped(path)}</dir>' for path in directories)
                              + f'<cachedir>{escaped(output.resolve() / ".font-cache")}</cachedir></fontconfig>')
    node = RUNTIME / 'node/bin/node'
    sharp = RUNTIME / 'node/node_modules/sharp'
    script = 'const sharp=require(process.argv[1]); sharp(process.argv[2]).flatten({background:"#F5EBD9"}).removeAlpha().png().toFile(process.argv[3]).catch(e=>{console.error(e.message);process.exit(1)});'
    environment = {**os.environ, 'FONTCONFIG_FILE': str(fontconfig.resolve())}
    subprocess.run([str(node), '-e', script, str(sharp), str(svg_path), str(png_path)], check=True, env=environment,
                   capture_output=True, text=True)
    with Image.open(png_path) as image:
        if image.mode != 'RGB':
            raise ValueError('Vector renderer must export an opaque RGB PNG')


def qa_previews(output, manifest, layout):
    """Build separate guide images and contact sheets; final assets stay clean."""
    if 'en-US' in manifest['locales']:
        for placement in ('header', 'search'):
            source = output / 'en-US' / f'{placement}.svg'
            x, y, width, height = layout[placement]['safe']
            overlay = (f'<rect x="{x}" y="{y}" width="{width}" height="{height}" '
                       'fill="#FFFFFF" fill-opacity=".10" stroke="#FF176B" stroke-width="8" stroke-dasharray="28 16"/>')
            guide = output / f'{placement}-safe-area-preview.svg'
            guide.write_text(source.read_text().replace('</svg>', overlay + '</svg>'))
            render_svg(guide, output / f'{placement}-safe-area-preview.png', output)
    # QA thumbnails preserve exported artwork exactly; they never paint app UI.
    for placement in ('header', 'search'):
        columns = 4
        thumbnail_width = 768
        thumbnail_height = round(thumbnail_width * layout[placement]['size'][1] / layout[placement]['size'][0])
        row_height = thumbnail_height + 54
        locales = list(manifest['locales'])
        rows = (len(locales) + columns - 1) // columns
        sheet = Image.new('RGB', (columns * thumbnail_width, rows * row_height), '#FFFFFF')
        draw = ImageDraw.Draw(sheet)
        font = ImageFont.truetype(str(REPO / 'assets/fonts/Roboto-Bold.ttf'), 26)
        for number, locale in enumerate(locales):
            x = number % columns * thumbnail_width
            y = number // columns * row_height
            draw.text((x + 14, y + 10), locale, fill='#302A24', font=font)
            with Image.open(output / manifest['locales'][locale][placement]) as image:
                image = image.resize((thumbnail_width, thumbnail_height), Image.Resampling.LANCZOS)
                sheet.paste(image, (x, y + 48))
        sheet.save(output / f'{placement}-contact-sheet.jpg', quality=93)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--copy', type=Path, default=Path(__file__).with_name('creative_copy.json'))
    parser.add_argument('--captures', type=Path, default=DEFAULT_CAPTURES)
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--layout', type=Path, help='Optional editable layout JSON replacing the default FIG-guided layout.')
    parser.add_argument('--locales', default='en-US', help='Comma-separated copy locales, or all. English preview is the default.')
    args = parser.parse_args()
    copy = json.loads(args.copy.read_text())['locales']
    locales = list(copy) if args.locales == 'all' else args.locales.split(',')
    layout = json.loads(args.layout.read_text()) if args.layout else DEFAULT_LAYOUT
    args.output.mkdir(parents=True, exist_ok=True)
    prepared = {}
    # Validate every locale's copy, glyphs, raw captures, and focal geometry
    # before writing any replacement artwork or a partially complete manifest.
    for locale in locales:
        if locale not in copy:
            raise ValueError(f'No localized copy for {locale}')
        for placement in ('header', 'search'):
            prepared[locale, placement] = compose_svg(args.captures, locale, copy[locale], placement, layout[placement])
    manifest = {'locales': {}}
    report = {'compositions': {}}
    for locale in locales:
        folder = args.output / locale
        folder.mkdir(parents=True, exist_ok=True)
        manifest['locales'][locale] = {}
        report['compositions'][locale] = {}
        for placement in ('header', 'search'):
            svg, metadata = prepared[locale, placement]
            svg_path = folder / f'{placement}.svg'
            png_path = folder / f'{placement}.png'
            svg_path.write_text(svg)
            render_svg(svg_path, png_path, args.output)
            manifest['locales'][locale][placement] = str(png_path.relative_to(args.output))
            report['compositions'][locale][placement] = metadata
            print(f'Composed {locale}/{placement}: {metadata["size"]}; all critical content inside FIG safe area.', flush=True)
    (args.output / 'creative-manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
    (args.output / 'composition-report.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
    qa_previews(args.output, manifest, layout)


if __name__ == '__main__':
    main()
