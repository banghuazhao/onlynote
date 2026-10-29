import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_export.dart';
import 'package:onlynote/services/note_reader_sections.dart';
import 'package:onlynote/services/note_text_format.dart';

void main() {
  test('explicit divider splits writing without interpreting ordinary glyphs',
      () {
    final controller = SimpleFormattingController(text: 'BeforeAfter');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 6);
    expect(controller.insertDivider(), isTrue);
    expect(controller.text, 'Before\n─\nAfter');
    expect(controller.selection.extentOffset, 9);
    final range = controller.styles.single;
    expect(range.kind, NoteTextStyleKind.divider);
    expect(range.start, 7);
    expect(range.end, 8);
    expect(NoteTextStyleRange.tryFromMap(range.toMap()), range);
    expect(noteDocumentParts(controller.text, [], styles: controller.styles), [
      const NoteTextPart(start: 0, end: 7),
      const NoteDividerPart(start: 7, end: 8),
      const NoteTextPart(start: 9, end: 14),
    ]);
    expect(noteDocumentParts('Before\n─\nAfter', []),
        [const NoteTextPart(start: 0, end: 14)]);
    expect(noteDocumentParts('Before\n---\nAfter', []),
        [const NoteTextPart(start: 0, end: 16)]);
  });

  test('divider insertion preserves emoji and following photo placement', () {
    final controller = SimpleFormattingController(text: '😀\nEnd');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 3);
    final before = controller.text;
    expect(controller.insertDivider(), isTrue);
    final layouts = rebaseNoteImageLayouts(before, controller.text,
        [const NoteImageLayout(path: 'photo', textOffset: 3)], ['photo']);
    expect(layouts.single.textOffset, 5);
    final parts =
        noteDocumentParts(controller.text, layouts, styles: controller.styles);
    expect(parts.whereType<NoteDividerPart>().single.start, 3);
    expect(parts.whereType<NoteImagePart>().single.layout.textOffset, 5);
  });

  test('a divider can be removed and restored through native text undo', () {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 7);
    controller.insertDivider();
    final divided = controller.value;
    final saved = controller.styles;
    expect(controller.removeDivider(7), isTrue);
    expect(controller.text, 'Before\nAfter');
    expect(controller.styles, isEmpty);
    controller.value = divided;
    expect(controller.styles, saved);
    controller.value = const TextEditingValue(
        text: 'Before\nAfter', selection: TextSelection.collapsed(offset: 7));
    expect(controller.styles, isEmpty);
  });

  test('typing before a divider shifts it without inheriting block formatting',
      () {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 7);
    controller.insertDivider();
    controller.value = const TextEditingValue(
        text: 'New Before\n─\nAfter',
        selection: TextSelection.collapsed(offset: 4));
    expect(controller.styles.single.start, 11);
    expect(controller.styles.single.kind, NoteTextStyleKind.divider);
    expect(
        isNoteDividerRange(controller.styles.single, controller.text), isTrue);
  });

  test('divider exports are portable rules and malformed block ranges rejected',
      () {
    final note = Note(
        title: 'Plan',
        description: 'Before\n─\nAfter',
        textStyles: [
          const NoteTextStyleRange(
              start: 7, end: 8, kind: NoteTextStyleKind.divider)
        ]);
    expect(NoteExport.plainText(note), 'Plan\n\nBefore\n---\nAfter');
    expect(NoteExport.markdown(note), '# Plan\n\nBefore\n\n\n---\n\nAfter');
    expect(
        normalizeNoteTextStyles(note.textStyles, 'Before\nX\nAfter'), isEmpty);
    expect(
        areValidNoteTextStyles(note.textStyles, 'Before\nX\nAfter'), isFalse);
    expect(areValidNoteTextStyles(note.textStyles, note.description!), isTrue);
  });

  test('dividers belong to the surrounding collapsible heading section', () {
    const text = 'Heading\nBefore\n─\nAfter\nNext\nMore';
    final document = buildNoteReaderSections(text, [
      const NoteTextStyleRange(
          start: 0, end: 7, kind: NoteTextStyleKind.heading),
      const NoteTextStyleRange(
          start: 15, end: 16, kind: NoteTextStyleKind.divider),
      const NoteTextStyleRange(
          start: 23, end: 27, kind: NoteTextStyleKind.heading),
    ], []);
    expect(document.sections.first.bodyParts.whereType<NoteDividerPart>(),
        hasLength(1));
    expect(
        document.sections.last.bodyParts.whereType<NoteDividerPart>(), isEmpty);
  });

  test('IME composition prevents insertion or deletion of divider blocks', () {
    final controller = SimpleFormattingController(text: 'text');
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
        text: 'text',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4));
    expect(controller.insertDivider(), isFalse);
    expect(controller.text, 'text');
  });
}
