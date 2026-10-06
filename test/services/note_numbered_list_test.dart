import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_numbered_list.dart';
import 'package:onlynote/services/note_text_format.dart';

void main() {
  test('list markers require a paragraph-start integer period and space', () {
    expect(noteNumberedListMarker('1. Tea')?.nextPrefix, '2. ');
    expect(noteNumberedListMarker('9. 九')?.nextPrefix, '10. ');
    for (final literal in [
      '1.5 litres',
      '1.5. litres',
      '1.Tea',
      '1.',
      '0. Tea',
      '01. Tea',
      ' 1. Tea',
      '-1. Tea',
      'Plan 1. Tea',
      '١. Tea',
      '1000000000. Tea',
    ]) {
      expect(noteNumberedListMarker(literal), isNull, reason: literal);
    }
  });

  test('Markdown preserves ordered markers and styles only their content', () {
    const text = '1. Tea\n2. <Milk>\n3. 😀';
    expect(
      noteTextToMarkdown(text, const [
        NoteTextStyleRange(start: 0, end: 6, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(
            start: 7, end: 16, kind: NoteTextStyleKind.highlight),
      ]),
      '1. **Tea**\n2. <mark>\\<Milk\\></mark>\n3. 😀',
    );
    expect(noteTextToMarkdown('1.5 litres\n01. literal\nPlan 1. literal', []),
        '1\\.5 litres\n01\\. literal\nPlan 1\\. literal');
  });

  test('numbered Return exits heading and keeps the split tail marked', () {
    const before = '1. Milkbread';
    const after = '1. Milk\n2. bread';
    expect(
      rebaseNoteTextStyles(before, after, const [
        NoteTextStyleRange(start: 0, end: 12, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(start: 0, end: 12, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(
            start: 3, end: 12, kind: NoteTextStyleKind.highlight),
      ]),
      const [
        NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(start: 3, end: 7, kind: NoteTextStyleKind.highlight),
        NoteTextStyleRange(
            start: 11, end: 16, kind: NoteTextStyleKind.highlight),
      ],
    );
  });
}
