"""Offline geometry and fidelity checks for vector creative artwork."""

import base64
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'store_screenshots'))
import compose_creative_assets as compose


class CompositionTests(unittest.TestCase):
    def test_raw_production_pixels_are_embedded_and_uniformly_scaled(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root / 'device/en'
            folder.mkdir(parents=True)
            source = folder / '01-home.png'
            Image.new('RGB', (40, 60), '#f0e0d0').save(source)
            config = {'device': 'device', 'screen': 'home', 'box': [100, 100, 100, 150],
                      'focal': [2, 4, 12, 8]}
            svg, metadata = compose.viewport_svg(root, 'en', config, 0, [100, 100, 50, 50])
            self.assertIn(base64.b64encode(source.read_bytes()).decode('ascii'), svg)
            self.assertEqual(metadata['sha256'], hashlib.sha256(source.read_bytes()).hexdigest())
            self.assertEqual(metadata['focalBounds'], [105, 110, 30, 20])
            self.assertEqual(metadata['box'], [100, 100, 100, 150])
            # The viewport bottom extends beyond safe bounds; only its focal
            # heading is constrained, matching the supplied Apple template.
            self.assertFalse(compose.contains([100, 100, 50, 50], metadata['box']))

    def test_critical_ui_heading_outside_safe_area_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root / 'device/en'
            folder.mkdir(parents=True)
            Image.new('RGB', (40, 60), 'white').save(folder / '01-home.png')
            config = {'device': 'device', 'screen': 'home', 'box': [100, 100, 100, 150],
                      'focal': [20, 40, 15, 10]}
            with self.assertRaisesRegex(ValueError, 'heading exceeds FIG safe area'):
                compose.viewport_svg(root, 'en', config, 0, [100, 100, 50, 50])

    def test_vector_text_keeps_copy_editable_and_checks_glyph_coverage(self):
        face = compose.font_face(str(compose.REPO / 'assets/fonts/Roboto-Regular.ttf'))
        style = {'box': [10, 10, 500, 180], 'size': 48, 'minimum': 40, 'lineHeight': 1.1}
        with patch.object(compose, 'selected_font', return_value=face):
            svg, metadata = compose.text_svg('Ideas & plans.\nYour notes.', 'en-US', style, [0, 0, 600, 240], bold=False)
            self.assertIn('<text ', svg)
            self.assertIn('<tspan ', svg)
            self.assertIn('Ideas &amp; plans.', svg)
            self.assertEqual(metadata['missingGlyphs'], [])
            with self.assertRaisesRegex(ValueError, 'lacks glyphs'):
                compose.text_svg('A missing glyph 🦄', 'en-US', style, [0, 0, 600, 240], bold=False)

    def test_wrap_preserves_explicit_lines_and_respects_available_width(self):
        font = ImageFont.truetype(str(compose.REPO / 'assets/fonts/Roboto-Regular.ttf'), 30)
        lines = compose.wrap('Notes and lists.\nBeautifully simple.', font, 180)
        self.assertGreater(len(lines), 2)
        self.assertTrue(all(font.getlength(line) <= 180 for line in lines))
        self.assertEqual(' '.join(lines), 'Notes and lists. Beautifully simple.')

    def test_compound_words_are_never_split_to_force_a_larger_font(self):
        font = ImageFont.truetype(str(compose.REPO / 'assets/fonts/Roboto-Regular.ttf'), 60)
        with self.assertRaises(compose.WordTooWide):
            compose.wrap('Anteckningar', font, 180)
        face = compose.font_face(str(compose.REPO / 'assets/fonts/Roboto-Regular.ttf'))
        with patch.object(compose, 'selected_font', return_value=face):
            _, metadata = compose.text_svg('Anteckningar\noch listor.', 'sv',
                                           {'box': [0, 0, 180, 150], 'size': 60, 'minimum': 20},
                                           [0, 0, 200, 180], bold=False)
        self.assertIn('Anteckningar', metadata['lines'])
        self.assertLess(metadata['fontSize'], 60)

    def test_cjk_editorial_phrases_remain_intact_without_punctuation_orphans(self):
        face = compose.font_face(str(compose.REPO / 'assets/fonts/DroidSansFallback.ttf'))
        with patch.object(compose, 'selected_font', return_value=face):
            _, metadata = compose.text_svg('备忘与清单，\n简约而美。', 'zh-Hans',
                                           {'box': [0, 0, 260, 180], 'size': 60, 'minimum': 40},
                                           [0, 0, 280, 200], bold=False)
        self.assertEqual(metadata['lines'], ['备忘与清单，', '简约而美。'])

    def test_critical_text_box_must_stay_inside_safe_area(self):
        face = compose.font_face(str(compose.REPO / 'assets/fonts/Roboto-Regular.ttf'))
        with patch.object(compose, 'selected_font', return_value=face), self.assertRaisesRegex(ValueError, 'critical text exceeds'):
            compose.text_svg('Real notes.', 'en-US', {'box': [500, 40, 350, 100], 'size': 40},
                             [0, 0, 550, 180], bold=False)


if __name__ == '__main__':
    unittest.main()
