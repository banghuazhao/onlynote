import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/services/note_section_link_capture.dart';
import 'package:onlynote/services/note_section_links.dart';

void main() {
  test('legacy headings receive unique IDs without modifying text or metadata',
      () {
    final date = DateTime(2026, 10, 29, 9);
    final note = Note(
        id: 'note',
        title: 'Plan',
        description: '  First  \nBody\nSecond',
        dateTime: date,
        isArchived: true,
        tags: [
          'Work'
        ],
        textStyles: const [
          NoteTextStyleRange(start: 0, end: 9, kind: NoteTextStyleKind.heading),
          NoteTextStyleRange(
              start: 15, end: 21, kind: NoteTextStyleKind.heading),
        ]);
    final selected = buildNoteOutline(note.description!, note.textStyles).last;
    final capture = captureNoteSectionLink(note, selected)!;
    expect(capture.target.description, note.description);
    expect(capture.target.title, note.title);
    expect(capture.target.dateTime, date);
    expect(capture.target.tags, ['Work']);
    expect(capture.target.isArchived, isTrue);
    final headings = buildNoteOutline(
        capture.target.description!, capture.target.textStyles);
    expect(headings.map((h) => h.anchorId).toSet().length, 2);
    expect(headings.every((heading) => heading.anchorId != null), isTrue);
    expect(capture.link.headingText, 'Second');
    expect(capture.link.headingId, headings.last.anchorId);
    expect(resolveNoteSectionLink(capture.link, [capture.target])?.heading.text,
        'Second');
    expect(note.textStyles.every((style) => style.anchorId == null), isTrue);
  });

  test('an anchored selection follows its renamed and moved latest heading',
      () {
    const selected =
        NoteOutlineEntry(text: 'Before', start: 0, end: 6, anchorId: 'stable');
    final latest =
        Note(id: 'note', description: 'Intro\nAfter\nBody', textStyles: const [
      NoteTextStyleRange(
          start: 6,
          end: 11,
          kind: NoteTextStyleKind.heading,
          anchorId: 'stable')
    ]);
    final capture = captureNoteSectionLink(latest, selected)!;
    expect(capture.link.headingId, 'stable');
    expect(capture.link.headingText, 'After');
    expect(capture.target, latest);
    expect(
        resolveNoteSectionLink(capture.link, [capture.target])?.heading.start,
        6);
    expect(captureNoteSectionLink(capture.target, selected)!.target, latest);
  });

  test('stale legacy selections and missing or deleted targets reject capture',
      () {
    final note = Note(id: 'note', description: 'New title', textStyles: const [
      NoteTextStyleRange(start: 0, end: 9, kind: NoteTextStyleKind.heading)
    ]);
    const stale = NoteOutlineEntry(text: 'Old title', start: 0, end: 9);
    const removed = NoteOutlineEntry(
        text: 'New title', start: 0, end: 9, anchorId: 'removed');
    final current = buildNoteOutline(note.description!, note.textStyles).single;
    expect(captureNoteSectionLink(note, stale), isNull);
    expect(captureNoteSectionLink(note, removed), isNull);
    expect(captureNoteSectionLink(note.copyWith(id: null), current), isNull);
    expect(
        captureNoteSectionLink(
            note.copyWith(deletedAt: DateTime(2026)), current),
        isNull);
    expect(
        captureNoteSectionLink(note.copyWith(textStyles: []), current), isNull);
  });

  test('a multi-paragraph legacy heading range links the selected paragraph',
      () {
    final note = Note(
        id: 'note',
        description: 'Same\nSame\nThird',
        textStyles: const [
          NoteTextStyleRange(start: 0, end: 15, kind: NoteTextStyleKind.heading)
        ]);
    final selected = buildNoteOutline(note.description!, note.textStyles)[1];
    final captured = captureNoteSectionLink(note, selected)!;
    final target = resolveNoteSectionLink(captured.link, [captured.target]);
    expect(target?.heading.start, 5);
    expect(target?.heading.text, 'Same');
    final headings = buildNoteOutline(
        captured.target.description!, captured.target.textStyles);
    expect(headings.map((heading) => heading.anchorId).toSet().length, 3);
  });

  test('fallback labels stay bounded and do not split joined emoji', () {
    final text = '${'a' * 1020}👨‍👩‍👧‍👦';
    final note = Note(id: 'note', description: text, textStyles: [
      NoteTextStyleRange(
          start: 0, end: text.length, kind: NoteTextStyleKind.heading)
    ]);
    final capture = captureNoteSectionLink(
        note, buildNoteOutline(text, note.textStyles).single)!;
    expect(capture.link.headingText, 'a' * 1020);
    expect(NoteSectionLink.tryFromMap(capture.link.toMap()), capture.link);
    expect(capture.target.description, text);
  });

  test('an oversized single grapheme still produces a valid fallback label',
      () {
    final text = 'a${'\u0301' * 1100}';
    final note = Note(id: 'note', description: text, textStyles: [
      NoteTextStyleRange(
          start: 0, end: text.length, kind: NoteTextStyleKind.heading)
    ]);
    final capture = captureNoteSectionLink(
        note, buildNoteOutline(text, note.textStyles).single)!;
    expect(capture.link.headingText, isNotEmpty);
    expect(capture.link.headingText.length, lessThanOrEqualTo(1024));
    expect(NoteSectionLink.tryFromMap(capture.link.toMap()), capture.link);
    expect(capture.target.description, text);
  });
}
