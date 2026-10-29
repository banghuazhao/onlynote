import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/services/note_text_format.dart';

void main() {
  test('ordinary normalization leaves legacy notes deterministic and unchanged',
      () {
    const heading =
        NoteTextStyleRange(start: 0, end: 5, kind: NoteTextStyleKind.heading);
    expect(normalizeNoteTextStyles([heading], 'Title'), [heading]);
    expect(normalizeNoteTextStyles([heading], 'Title'), [heading]);
  });

  test('explicit anchor assignment gives each heading paragraph a stable ID',
      () {
    const text = 'One\nTwo\nbody';
    final anchored = ensureNoteHeadingAnchors([
      const NoteTextStyleRange(
          start: 0, end: 7, kind: NoteTextStyleKind.heading),
    ], text);
    expect(anchored, hasLength(2));
    expect(anchored.map((range) => range.anchorId).toSet(), hasLength(2));
    expect(
        anchored.every((range) => range.anchorId?.isNotEmpty == true), isTrue);
    expect(ensureNoteHeadingAnchors(anchored, text), anchored);
    expect(buildNoteOutline(text, anchored).map((entry) => entry.anchorId),
        anchored.map((range) => range.anchorId));
    expect(
        anchored.map((range) => NoteTextStyleRange.tryFromMap(range.toMap())),
        anchored);
  });

  test(
      'renaming and moving a linked heading preserves its destination identity',
      () {
    final original = ensureNoteHeadingAnchors([
      const NoteTextStyleRange(
          start: 0, end: 5, kind: NoteTextStyleKind.heading),
    ], 'Title\nbody');
    final id = original.single.anchorId;
    final controller =
        SimpleFormattingController(text: 'Title\nbody', styles: original);
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
        text: 'New title\nbody', selection: TextSelection.collapsed(offset: 9));
    expect(buildNoteOutline(controller.text, controller.styles).single.anchorId,
        id);
    controller.value = const TextEditingValue(
        text: 'Intro\nNew title\nbody',
        selection: TextSelection.collapsed(offset: 6));
    final outline = buildNoteOutline(controller.text, controller.styles);
    expect(outline.last.anchorId, id);
    expect(outline.last.text, 'New title');
    expect(outline.first.anchorId, isNull);
  });

  test('formatting a mixed heading selection keeps existing anchored targets',
      () {
    final original = ensureNoteHeadingAnchors([
      const NoteTextStyleRange(
          start: 0, end: 5, kind: NoteTextStyleKind.heading),
    ], 'Title\nbody');
    final controller =
        SimpleFormattingController(text: 'Title\nbody', styles: original);
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 10);
    controller.toggleHeading();
    final outline = buildNoteOutline(controller.text, controller.styles);
    expect(outline.first.anchorId, original.single.anchorId);
    expect(outline.last.anchorId, isNull);
    expect(outline.map((entry) => entry.text), ['Title', 'body']);
  });

  test(
      'multiline paste inside a heading keeps the anchor on original first text',
      () {
    final original = ensureNoteHeadingAnchors([
      const NoteTextStyleRange(
          start: 0, end: 5, kind: NoteTextStyleKind.heading),
    ], 'Title');
    final controller =
        SimpleFormattingController(text: 'Title', styles: original);
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
        text: 'TiMore\nNewtle', selection: TextSelection.collapsed(offset: 10));
    final outline = buildNoteOutline(controller.text, controller.styles);
    expect(outline.first.anchorId, original.single.anchorId);
    expect(outline.last.anchorId, isNull);
    controller.value = const TextEditingValue(
        text: 'Title', selection: TextSelection.collapsed(offset: 2));
    expect(buildNoteOutline(controller.text, controller.styles).single.anchorId,
        original.single.anchorId);
  });

  test('different anchors never merge and the saved ID survives range slicing',
      () {
    const first = NoteTextStyleRange(
        start: 0, end: 3, kind: NoteTextStyleKind.heading, anchorId: 'first');
    const second = NoteTextStyleRange(
        start: 3, end: 6, kind: NoteTextStyleKind.heading, anchorId: 'second');
    expect(normalizeNoteTextStyles([first, second], 'abcdef'), [first, second]);
    expect(
        removeNoteTextStyle([first], 1, 2, NoteTextStyleKind.heading)
            .map((range) => range.anchorId),
        ['first', 'first']);
  });
}
