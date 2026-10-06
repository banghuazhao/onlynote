import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_reader_sections.dart';

NoteTextStyleRange _heading(String text, String heading) => NoteTextStyleRange(
      start: text.indexOf(heading),
      end: text.indexOf(heading) + heading.length,
      kind: NoteTextStyleKind.heading,
    );

String _text(String text, Iterable<NoteDocumentPart> parts) => parts
    .whereType<NoteTextPart>()
    .map((part) => text.substring(part.start, part.end))
    .join();

List<String> _photos(Iterable<NoteDocumentPart> parts) =>
    parts.whereType<NoteImagePart>().map((part) => part.layout.path).toList();

void main() {
  test('only saved heading paragraphs create reader sections', () {
    const text =
        '# Plain Markdown\nIntro\n  First 👩🏽‍💻 \nBody\nSecond\nMore';
    final first = text.indexOf('First');
    final document = buildNoteReaderSections(text, [
      NoteTextStyleRange(
          start: first + 1, end: first + 3, kind: NoteTextStyleKind.heading),
      _heading(text, 'Second'),
    ], const []);
    expect(_text(text, document.introParts), '# Plain Markdown\nIntro\n');
    expect(document.sections.map((section) => section.heading.text),
        ['First 👩🏽‍💻', 'Second']);
    final section = document.sections.first;
    expect(text.substring(section.headingPart.start, section.headingPart.end),
        '  First 👩🏽‍💻 ');
    expect(_text(text, section.bodyParts), 'Body\n');
    expect(_text(text, document.sections.last.bodyParts), 'More');
    expect(
        section.containsOffset(text.indexOf('Body'), textLength: text.length),
        isTrue);
    expect(
        section.containsOffset(text.indexOf('Second'), textLength: text.length),
        isFalse);
    expect(
        document.sections.last
            .containsOffset(text.length, textLength: text.length),
        isTrue);
  });

  test('photos at heading boundaries stay before their heading', () {
    const text = 'Intro\nFirst\nBody\nSecond';
    final first = text.indexOf('First');
    final second = text.indexOf('Second');
    final document = buildNoteReaderSections(
      text,
      [_heading(text, 'First'), _heading(text, 'Second')],
      [
        const NoteImageLayout(path: 'cover', textOffset: 0),
        NoteImageLayout(path: 'intro', textOffset: first),
        NoteImageLayout(path: 'under-first', textOffset: text.indexOf('Body')),
        NoteImageLayout(path: 'before-second-a', textOffset: second),
        NoteImageLayout(path: 'before-second-b', textOffset: second),
        NoteImageLayout(path: 'trailing', textOffset: text.length),
      ],
    );
    expect(_photos(document.introParts), ['cover', 'intro']);
    expect(_photos(document.sections.first.bodyParts),
        ['under-first', 'before-second-a', 'before-second-b']);
    expect(_photos(document.sections.last.bodyParts), ['trailing']);
    expect(document.sections.last.canCollapse, isTrue);
  });

  test('consecutive and final headings without body have no fold action', () {
    const text = 'First\nSecond\nThird\n';
    final document = buildNoteReaderSections(
      text,
      const [
        NoteTextStyleRange(
            start: 0, end: 1000, kind: NoteTextStyleKind.heading),
      ],
      const [],
    );
    expect(document.sections, hasLength(3));
    expect(document.sections.every((section) => !section.canCollapse), isTrue);
    expect(document.sections.map((section) => section.start), [0, 6, 13]);
  });

  test('an image-only or unformatted note keeps the existing document parts',
      () {
    for (final text in ['', '# A heading\nText']) {
      final layouts = [NoteImageLayout(path: 'photo', textOffset: text.length)];
      final document = buildNoteReaderSections(text, const [], layouts);
      expect(document.sections, isEmpty);
      expect(document.introParts, noteDocumentParts(text, layouts));
    }
  });
}
