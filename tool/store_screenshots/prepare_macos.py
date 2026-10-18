"""Validate and export genuine Mac captures as App Store RGB JPEGs.

The Mac capture harness renders production Flutter screens and, for image 09,
production SwiftUI widgets. This script only converts and indexes those captures.
"""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = (2880, 1800)
LOCALES = {"en": "en-US", "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant"}
SCREENS = [
    "01-home", "02-formattedNote", "03-checklist", "04-cardStyle",
    "05-starterTemplates", "06-foldersSearch", "07-reminderAgenda",
    "08-voiceMemo", "09-desktopWidgets",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path,
                        default=Path("build/store_screenshots/2026-10-14"))
    parser.add_argument("--locales", default=",".join(LOCALES))
    args = parser.parse_args()
    selected = args.locales.split(",")
    if set(selected) - LOCALES.keys():
        raise ValueError("Supported capture locales: en, zh-Hans, zh-Hant")
    manifest = {"platform": "MAC_OS", "displayType": "APP_DESKTOP",
                "width": SIZE[0], "height": SIZE[1], "sets": []}
    for locale in selected:
        capture_folder = args.root / "macos" / locale
        captures = sorted(capture_folder.glob("[0-9][0-9]-*.png"))
        if [file.stem for file in captures] != SCREENS:
            raise ValueError(f"{locale}: expected exactly these nine captures: {SCREENS}")
        upload_folder = args.root / "upload" / "macos" / locale
        upload_folder.mkdir(parents=True, exist_ok=True)
        files = []
        contact = Image.new("RGB", (1728, 1152), "#F4E9D6")
        contact_draw = ImageDraw.Draw(contact)
        for index, source in enumerate(captures):
            with Image.open(source) as image:
                if image.size != SIZE:
                    raise ValueError(f"{source}: expected {SIZE}, found {image.size}")
                if image.mode not in {"RGB", "RGBA"}:
                    raise ValueError(f"{source}: expected RGB/RGBA capture")
                if image.mode == "RGBA" and image.getchannel("A").getextrema() != (255, 255):
                    raise ValueError(f"{source}: transparent pixels are not accepted")
                thumbnail = image.convert("RGB").resize((576, 360), Image.Resampling.LANCZOS)
                x, y = (index % 3) * 576, (index // 3) * 384
                contact.paste(thumbnail, (x, y))
                contact_draw.text((x + 12, y + 363), source.stem, fill="#302D27")
            target = upload_folder / f"macos-{locale}-{source.stem}.jpg"
            subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "96",
                            str(source), "--out", str(target)],
                           check=True, capture_output=True)
            with Image.open(target) as exported:
                if exported.size != SIZE or exported.mode != "RGB":
                    raise ValueError(f"{target}: export must be RGB {SIZE}")
            if target.stat().st_size > 8_000_000:
                raise ValueError(f"{target}: exceeds 8 MB")
            files.append({"path": str(target.relative_to(args.root)),
                          "bytes": target.stat().st_size,
                          "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})
        contact.save(args.root / f"macos-{locale}-contact.png")
        manifest["sets"].append({"locale": locale, "appleLocale": LOCALES[locale],
                                 "screenshots": files})
    (args.root / "macos-manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f"Prepared {len(selected) * len(SCREENS)} Mac screenshots at {SIZE[0]} × {SIZE[1]}.")


if __name__ == "__main__":
    main()
