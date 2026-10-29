import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/services/note_outline.dart';
import 'package:onlynote/services/note_text_format.dart';

class NoteSectionLinkCapture {
  const NoteSectionLinkCapture({required this.target, required this.link});
  final Note target;
  final NoteSectionLink link;
}

/// Revalidate a picker result against the latest note. Legacy headings acquire
/// their identity only when a link is created; their text and dates stay intact.
NoteSectionLinkCapture? captureNoteSectionLink(
    Note latest, NoteOutlineEntry selected) {
  if (latest.id == null || latest.isDeleted) return null;
  final text = latest.description ?? '';
  final headings = buildNoteOutline(text, latest.textStyles);
  final index = headings.indexWhere((heading) => selected.anchorId != null
      ? heading.anchorId == selected.anchorId
      : heading.start == selected.start && heading.text == selected.text);
  if (index < 0) return null;
  final styles = ensureNoteHeadingAnchors(latest.textStyles, text);
  final anchored = buildNoteOutline(text, styles)[index];
  final id = anchored.anchorId;
  if (id == null) return null;
  // A fallback label never cuts a UTF-16 surrogate pair.
  var label = anchored.text;
  if (label.length > 1024) {
    final buffer = StringBuffer();
    for (final character in label.characters) {
      if (buffer.length + character.length > 1024) break;
      buffer.write(character);
    }
    label = buffer.isEmpty ? '…' : buffer.toString();
  }
  return NoteSectionLinkCapture(
    target: latest.copyWith(textStyles: styles),
    link:
        NoteSectionLink(noteId: latest.id!, headingId: id, headingText: label),
  );
}
