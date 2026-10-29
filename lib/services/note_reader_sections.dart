import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_outline.dart';

/// A reader section is a saved heading paragraph and the content before the
/// next heading. All offsets still refer to the original UTF-16 note body.
class NoteReaderSection {
  const NoteReaderSection({
    required this.heading,
    required this.headingPart,
    required this.bodyStart,
    required this.end,
    required this.bodyParts,
  });

  final NoteOutlineEntry heading;
  final NoteTextPart headingPart;
  final int bodyStart;
  final int end;
  final List<NoteDocumentPart> bodyParts;

  int get start => headingPart.start;
  bool get canCollapse => bodyParts.isNotEmpty;

  /// The final section also owns the document's end caret position.
  bool containsOffset(int offset, {required int textLength}) =>
      offset >= start && (offset < end || (end == textLength && offset == end));
}

class NoteReaderDocument {
  const NoteReaderDocument({required this.introParts, required this.sections});

  final List<NoteDocumentPart> introParts;
  final List<NoteReaderSection> sections;
}

/// Groups the existing document parts without modifying the saved document.
/// A photo at a heading's start appears before that heading, so it stays with
/// the preceding section (or introductory content). Photos immediately after
/// a heading, including trailing photos, belong to that heading's body.
NoteReaderDocument buildNoteReaderSections(
  String text,
  Iterable<NoteTextStyleRange> styles,
  Iterable<NoteImageLayout> layouts,
) {
  final outline = buildNoteOutline(text, styles);
  final parts = noteDocumentParts(text, layouts, styles: styles);
  if (outline.isEmpty) {
    return NoteReaderDocument(introParts: parts, sections: const []);
  }

  final headings = <NoteTextPart>[];
  final bodyStarts = <int>[];
  for (final heading in outline) {
    final start =
        heading.start == 0 ? 0 : text.lastIndexOf('\n', heading.start - 1) + 1;
    final lineBreak = text.indexOf('\n', heading.end);
    final end = lineBreak < 0 ? text.length : lineBreak;
    headings.add(NoteTextPart(start: start, end: end));
    bodyStarts.add(lineBreak < 0 ? text.length : lineBreak + 1);
  }

  final intro = <NoteDocumentPart>[];
  final bodies = List.generate(outline.length, (_) => <NoteDocumentPart>[]);
  var textSection = -1;
  var imageSection = -1;
  for (final part in parts) {
    if (part is NoteImagePart) {
      // Strict inequality preserves a photo's position before a next heading.
      while (imageSection + 1 < headings.length &&
          headings[imageSection + 1].start < part.layout.textOffset) {
        imageSection++;
      }
      (imageSection < 0 ? intro : bodies[imageSection]).add(part);
    } else if (part is NoteDividerPart) {
      while (imageSection + 1 < headings.length &&
          headings[imageSection + 1].start < part.start) {
        imageSection++;
      }
      (imageSection < 0 ? intro : bodies[imageSection]).add(part);
    } else if (part is NoteTextPart) {
      var cursor = part.start;
      while (cursor < part.end) {
        while (textSection + 1 < headings.length &&
            headings[textSection + 1].start <= cursor) {
          textSection++;
        }
        if (textSection >= 0 && cursor < bodyStarts[textSection]) {
          // The header widget supplies its paragraph. Its separating newline
          // becomes the layout boundary between the header and its body.
          cursor = bodyStarts[textSection].clamp(cursor, part.end);
          continue;
        }
        final end = textSection + 1 < headings.length
            ? headings[textSection + 1].start.clamp(cursor, part.end)
            : part.end;
        (textSection < 0 ? intro : bodies[textSection])
            .add(NoteTextPart(start: cursor, end: end));
        cursor = end;
      }
    }
  }

  return NoteReaderDocument(
    introParts: List.unmodifiable(intro),
    sections: List.unmodifiable([
      for (var index = 0; index < outline.length; index++)
        NoteReaderSection(
          heading: outline[index],
          headingPart: headings[index],
          bodyStart: bodyStarts[index],
          end: index + 1 < headings.length
              ? headings[index + 1].start
              : text.length,
          bodyParts: List.unmodifiable(bodies[index]),
        ),
    ]),
  );
}
