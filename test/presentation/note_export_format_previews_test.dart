import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/note_export_format_previews.dart';
import 'package:onlynote/presentation/components/note_export_section.dart';
import 'package:onlynote/services/note_bulk_export.dart';

void main() {
  testWidgets('restored format controls fit and remain interactive in previews',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size, format, saveToFile) in [
      (
        rememberedPlainTextExportPreview,
        const Size(390, 500),
        NoteBulkExportFormat.plainText,
        false,
      ),
      (
        rememberedPdfExportPreview,
        const Size(640, 420),
        NoteBulkExportFormat.pdf,
        true,
      ),
      (
        rememberedExportChinesePreview,
        const Size(280, 900),
        NoteBulkExportFormat.markdown,
        false,
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      final section =
          tester.widget<NoteExportSection>(find.byType(NoteExportSection));
      expect(section.format, format);
      expect(section.saveToFile, saveToFile);
      final alternate = format == NoteBulkExportFormat.pdf
          ? NoteBulkExportFormat.plainText
          : NoteBulkExportFormat.pdf;
      final chip = find.byKey(ValueKey('note-export-format-${alternate.name}'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
