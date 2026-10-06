import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_text_format.dart';

NoteTextStyleRange bold(int start, int end) => NoteTextStyleRange(
      start: start,
      end: end,
      kind: NoteTextStyleKind.bold,
    );
NoteTextStyleRange heading(int start, int end) => NoteTextStyleRange(
      start: start,
      end: end,
      kind: NoteTextStyleKind.heading,
    );

void main() {
  test('range maps reject invalid types and unsupported style kinds', () {
    final range = bold(0, 3);
    expect(NoteTextStyleRange.tryFromMap(range.toMap()), range);
    expect(
        NoteTextStyleRange.tryFromMap({'start': 0, 'end': 2, 'kind': 'italic'}),
        isNull);
    expect(
        NoteTextStyleRange.tryFromMap({'start': 0.0, 'end': 2, 'kind': 'bold'}),
        isNull);
    expect(
        NoteTextStyleRange.tryFromMap({'start': -1, 'end': 2, 'kind': 'bold'}),
        isNull);
    expect(
        NoteTextStyleRange.tryFromMap({'start': 2, 'end': 2, 'kind': 'bold'}),
        isNull);
    expect(NoteTextStyleRange.tryFromMap([]), isNull);
  });

  test('normalization clamps stale data and merges only the same kind', () {
    final normalized = normalizeNoteTextStyles([
      bold(-4, 2),
      bold(1, 3),
      bold(3, 5),
      heading(0, 5),
      bold(20, 30),
      bold(3, 2),
    ], 'hello');
    expect(normalized, [bold(0, 5), heading(0, 5)]);
    expect(() => normalized.add(bold(0, 1)), throwsUnsupportedError);
    expect(normalizeNoteTextStyles([bold(0, 2)], ''), isEmpty);
  });

  test('emoji and combining characters stay whole on normalization', () {
    const text = '👩‍💻é中';
    expect(normalizeNoteTextStyles([bold(1, 4), heading(6, 7)], text),
        [bold(0, 5), heading(5, 7)]);
    expect(areValidNoteTextStyles([bold(1, 4)], text), isFalse);
    expect(areValidNoteTextStyles([bold(0, 5), heading(5, 7)], text), isTrue);
    expect(areValidNoteTextStyles([bold(0, 99)], text), isFalse);
  });

  test('typing insertion, deletion and plain pasted text rebase offsets', () {
    expect(rebaseNoteTextStyles('bold end', 'bold! end', [bold(0, 4)]),
        [bold(0, 5)]);
    expect(rebaseNoteTextStyles('abcde', 'ae', [bold(0, 5)]), [bold(0, 2)]);
    expect(
        rebaseNoteTextStyles('bold', 'boPLAINld', [bold(0, 4)],
            insertedBold: false),
        [bold(0, 2), bold(7, 9)]);
    expect(
        rebaseNoteTextStyles('plain', 'XXplain', [bold(2, 5)]), [bold(4, 7)]);
  });

  test('heading Return makes the remainder and next paragraph ordinary', () {
    expect(
        rebaseNoteTextStyles('Title', 'Ti\ntle', [heading(0, 5), bold(0, 5)]),
        [bold(0, 2), heading(0, 2)]);
    expect(rebaseNoteTextStyles('Title', 'Title\n', [heading(0, 5)]),
        [heading(0, 5)]);
    expect(rebaseNoteTextStyles('Title\n', 'Title\nbody', [heading(0, 5)]),
        [heading(0, 5)]);
    expect(rebaseNoteTextStyles('a\nTitle', 'a\nXTitle', [heading(2, 7)]),
        [heading(2, 8)]);
  });

  test('diff regions never split a surrogate or combining character', () {
    final emoji = noteTextChange('a😀z', 'a😃z');
    expect(emoji.start, 1);
    expect(emoji.oldEnd, 3);
    expect(emoji.inserted, '😃');
    final mark = noteTextChange('é!', 'è!');
    expect(mark.start, 0);
    expect(mark.oldEnd, 2);
    expect(mark.inserted, 'è');
  });

  test('display spans preserve all visible text and combine styles', () {
    final spans = buildNoteTextSpans(
      text: 'Title\nbody',
      styles: [heading(0, 5), bold(0, 2)],
      baseStyle:
          const TextStyle(fontSize: 17, fontFamily: 'Chosen', height: 1.4),
      composing: const TextRange(start: 7, end: 9),
    );
    expect(spans.map((span) => span.text).join(), 'Title\nbody');
    expect(spans.first.style?.fontSize, 19);
    expect(spans.first.style?.fontWeight, FontWeight.w700);
    expect(spans.first.style?.fontFamily, 'Chosen');
    expect(spans.first.style?.height, 1.4);
    expect(spans.singleWhere((span) => span.text == 'od').style?.decoration,
        TextDecoration.underline);
  });

  test('Markdown adds simple formatting and preserves literal old markup', () {
    expect(
        noteTextToMarkdown('Title\n• Milk\n**literal** &copy; #tag',
            [heading(0, 5), bold(8, 12)]),
        '## Title\n- **Milk**\n\\*\\*literal\\*\\* \\&copy; \\#tag');
    expect(noteTextToMarkdown('a(b)c', [bold(1, 4)]), 'a<strong>(b)</strong>c');
    expect(
        noteTextToMarkdown('x#tag', [bold(1, 5)]), 'x<strong>\\#tag</strong>');
    expect(noteTextToMarkdown(' important ', [bold(0, 11)]), ' **important** ');
    expect(noteTextToMarkdown('重要內容', [bold(0, 2)]), '**重要**內容');
  });
}
