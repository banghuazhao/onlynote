import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

/// Render only characters absent from bundled fonts (for example emoji) with
/// Flutter's platform font fallback. Ordinary PDF text stays selectable.
Future<Map<String, ui.Image>> renderMissingPdfGlyphs(
    String text, List<ByteData> fonts) async {
  final document = PdfDocument();
  final pdfFonts = fonts.map((data) => PdfTtfFont(document, data)).toList();
  final images = <String, ui.Image>{};
  try {
    for (final character in text.characters.toSet()) {
      if (character.trim().isEmpty ||
          character.runes
              .every((r) => pdfFonts.any((font) => font.isRuneSupported(r)))) {
        continue;
      }
      final painter = TextPainter(
          text: TextSpan(
              text: character,
              style: const TextStyle(fontSize: 48, color: Colors.black)),
          textDirection: TextDirection.ltr)
        ..layout();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, Offset.zero);
      final picture = recorder.endRecording();
      try {
        images[character] = await picture.toImage(
            painter.width.ceil().clamp(1, 1024),
            painter.height.ceil().clamp(1, 256));
      } finally {
        picture.dispose();
        painter.dispose();
      }
    }
    return images;
  } catch (_) {
    for (final image in images.values) {
      image.dispose();
    }
    rethrow;
  }
}
