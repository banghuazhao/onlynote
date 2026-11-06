"""Check fidelity and Google Play geometry for Android-only compositions."""

import base64
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'store_screenshots'))
import compose_android_assets as android
import compose_creative_assets as vector


class AndroidCompositionTests(unittest.TestCase):
    def captures(self, root, device='playphone'):
        folder = root / device / 'en'
        folder.mkdir(parents=True)
        for index, screen in enumerate(android.SCREENS):
            Image.new('RGB', android.DEVICES[device][1], '#D3EDE4').save(folder / f'{index+1:02}-{screen}.png')
        return folder

    def test_phone_uses_android_capture_bytes_and_small_tagline_region(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = self.captures(root)
            svg, report = android.phone_svg(root, 'en-US', 'home')
            self.assertIn(base64.b64encode((folder / '01-home.png').read_bytes()).decode(), svg)
            self.assertEqual(report['size'], [1080, 1920])
            self.assertLessEqual(report['taglineFraction'], .20)
            self.assertEqual(report['title']['lines'], ['Your day,', 'in notes.'])
            self.assertEqual(report['viewport']['sourceSize'], [1080, 1920])
            _, _, width, height = report['viewport']['box']
            self.assertAlmostEqual(width / height, 9 / 16)

    def test_feature_is_dedicated_play_geometry_and_real_android_ui(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.captures(root)
            svg, report = android.feature_svg(root, 'en-US')
            self.assertIn('width="1024" height="500"', svg)
            self.assertEqual(report['size'], [1024, 500])
            self.assertEqual(len(report['viewports']), 2)
            self.assertTrue(all('/playphone/' in row['path'] for row in report['viewports']))
            self.assertNotIn('iphone', svg.lower())

    def test_tablet_export_keeps_responsive_pixels_and_has_no_extra_artwork(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = self.captures(root, 'play7inch_16_9')
            source = folder / '01-home.png'
            with Image.open(source) as image:
                original = image.convert('RGB').tobytes()
            target = root / 'tablet.png'
            android.export_tablet(source, target)
            with Image.open(target) as image:
                self.assertEqual(image.mode, 'RGB')
                self.assertEqual(image.size, (2304, 1296))
                self.assertEqual(image.tobytes(), original)

    def test_wrong_dimensions_or_apple_source_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = self.captures(root)
            with self.assertRaisesRegex(ValueError, 'real Android'):
                android.capture_path(root, 'iphone_duo_outer', 'en', 'home')
            Image.new('RGB', (1176, 2400)).save(folder / '01-home.png')
            with self.assertRaisesRegex(ValueError, 'dimensions'):
                android.capture_path(root, 'playphone', 'en', 'home')

    def test_preflight_missing_source_writes_no_partial_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = self.captures(root)
            (folder / '06-backup.png').unlink()
            output = root / 'output'
            with self.assertRaisesRegex(ValueError, 'exactly one capture'):
                android.compose(root, output, ['en-US'], ['playphone'])
            self.assertFalse((output / 'android-assets-manifest.json').exists())
            self.assertFalse(output.exists())

    def test_all_three_ui_languages_have_complete_six_screen_copy_and_alt_text(self):
        for locale, copy in android.COPY.items():
            self.assertEqual(len(copy['headlines']), len(android.SCREENS))
            self.assertEqual(len(copy['alt']), len(android.SCREENS))
            self.assertTrue(all(0 < len(text) <= 140 for text in copy['alt']))
            for title in copy['headlines']:
                _, metadata = vector.text_svg(title, locale,
                                             {'box': [80, 40, 920, 244], 'size': 96, 'minimum': 82, 'lineHeight': 1.05},
                                             [0, 0, 1080, 292], bold=True)
                self.assertEqual(len(metadata['lines']), 2)
                self.assertEqual(metadata['missingGlyphs'], [])

    def test_scoped_landscape_refresh_preserves_approved_phone_and_feature_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.captures(root, 'play7inch_16_9')
            output = root / 'output'
            folder = output / 'en-US'
            folder.mkdir(parents=True)
            phone, feature = folder / 'approved-phone.png', folder / 'approved-feature.png'
            Image.new('RGB', (1080, 1920), '#FFEABB').save(phone)
            Image.new('RGB', (1024, 500), '#DDE4C9').save(feature)
            originals = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in (phone, feature)}
            approved = {'phoneScreenshots': [{'path': 'en-US/approved-phone.png', 'screen': screen, 'altText': screen}
                                              for screen in android.SCREENS],
                        'featureGraphic': [{'path': 'en-US/approved-feature.png', 'altText': 'Approved artwork'}]}
            (output / 'android-assets-manifest.json').write_text(json.dumps({'packageName': 'com.appsbay.onlynote',
                                                                          'locales': {'en-US': approved}}))
            (output / 'composition-report.json').write_text(json.dumps({'compositions': {'en-US': {'phoneScreenshots': ['approved'],
                                                                                                'featureGraphic': 'approved'}}}))
            manifest, report = android.compose(root, output, ['en-US'], ['play7inch_16_9'])
            self.assertEqual(manifest['locales']['en-US']['phoneScreenshots'], approved['phoneScreenshots'])
            self.assertEqual(manifest['locales']['en-US']['featureGraphic'], approved['featureGraphic'])
            self.assertEqual(report['compositions']['en-US']['phoneScreenshots'], ['approved'])
            self.assertEqual(len(manifest['locales']['en-US']['sevenInchScreenshots']), 6)
            for path, digest in originals.items():
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), digest)


if __name__ == '__main__':
    unittest.main()
