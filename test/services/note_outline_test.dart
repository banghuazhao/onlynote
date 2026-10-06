import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_outline.dart';

void main() {
  test('only current heading paragraphs appear in document order', () {
    const body = '# Plain Markdown\nFirst heading\nBody\n第二章\nLast heading';
    final first = body.indexOf('First heading');
    final second = body.indexOf('第二章');
    final last = body.indexOf('Last heading');
    final outline = buildNoteOutline(body, [
      NoteTextStyleRange(
          start: last, end: body.length, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(
          start: first, end: first + 13, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(
          start: second, end: second + 3, kind: NoteTextStyleKind.bold),
    ]);
    expect(
        outline.map((entry) => entry.text), ['First heading', 'Last heading']);
    expect(outline.map((entry) => entry.start), [first, last]);
  });

  test('one saved range spanning paragraphs gives separate nonempty headings',
      () {
    const body = '  Alpha \r\n\n  \n👩🏽‍💻 Beta\n';
    final outline = buildNoteOutline(body, const [
      NoteTextStyleRange(start: 0, end: 1000, kind: NoteTextStyleKind.heading),
    ]);
    expect(outline.map((entry) => entry.text), ['Alpha', '👩🏽‍💻 Beta']);
    for (final entry in outline) {
      expect(body.substring(entry.start, entry.end), entry.text);
    }
    expect(outline.first.start, 2);
  });

  test('partial heading formatting identifies its paragraph once', () {
    const body = 'An important title\nText';
    final outline = buildNoteOutline(body, const [
      NoteTextStyleRange(start: 3, end: 6, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(start: 8, end: 12, kind: NoteTextStyleKind.heading),
    ]);
    expect(outline.single.text, 'An important title');
    expect(outline.single.start, 0);
    expect(outline.single.end, 18);
  });

  test('stale or empty formatting never creates phantom sections', () {
    expect(
        buildNoteOutline('', const [
          NoteTextStyleRange(
              start: 0, end: 20, kind: NoteTextStyleKind.heading),
        ]),
        isEmpty);
    expect(
        buildNoteOutline('Text', const [
          NoteTextStyleRange(
              start: 20, end: 30, kind: NoteTextStyleKind.heading),
          NoteTextStyleRange(start: 0, end: 0, kind: NoteTextStyleKind.heading),
        ]),
        isEmpty);
    expect(
        buildNoteOutline('  \n\n', const [
          NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.heading),
        ]),
        isEmpty);
  });

  test('outline is contextual to several sections or a long note', () {
    const one = [NoteOutlineEntry(text: 'One', start: 0, end: 3)];
    const two = [
      NoteOutlineEntry(text: 'One', start: 0, end: 3),
      NoteOutlineEntry(text: 'Two', start: 10, end: 13),
    ];
    expect(shouldShowNoteOutline('Short note', one), isFalse);
    expect(shouldShowNoteOutline('Short note', two), isTrue);
    expect(shouldShowNoteOutline('x' * 499, one), isFalse);
    expect(shouldShowNoteOutline('x' * 500, one), isTrue);
    expect(shouldShowNoteOutline('x' * 1000, const []), isFalse);
  });

  test('current section follows the caret until the next heading', () {
    const entries = [
      NoteOutlineEntry(text: 'One', start: 5, end: 8),
      NoteOutlineEntry(text: 'Two', start: 20, end: 23),
    ];
    expect(currentNoteOutlineEntry(entries, -1), isNull);
    expect(currentNoteOutlineEntry(entries, 0), isNull);
    expect(currentNoteOutlineEntry(entries, 5), same(entries.first));
    expect(currentNoteOutlineEntry(entries, 19), same(entries.first));
    expect(currentNoteOutlineEntry(entries, 20), same(entries.last));
    expect(currentNoteOutlineEntry(entries, 100), same(entries.last));
  });
}
