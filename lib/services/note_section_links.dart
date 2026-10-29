import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/services/note_outline.dart';

const maxNoteSectionLinks = 100;

/// Preserve the user's order and one relationship per destination. Links to
/// headings in the same note are useful, so self references are retained.
List<NoteSectionLink> normalizeNoteSectionLinks(
    Iterable<NoteSectionLink> values) {
  final result = <NoteSectionLink>[];
  final seen = <(String, String)>{};
  for (final link in values) {
    if (NoteSectionLink.tryFromMap(link.toMap()) == null) {
      throw const FormatException('Invalid section link');
    }
    if (seen.add((link.noteId, link.headingId))) result.add(link);
    if (result.length > maxNoteSectionLinks) {
      throw const FormatException('Too many section links');
    }
  }
  return List.unmodifiable(result);
}

/// Strict parsing is shared by template and backup import. Local Hive loading
/// can ignore a malformed row without making an otherwise valid note unreadable.
List<NoteSectionLink> parseNoteSectionLinks(Object? value) {
  if (value is! List || value.length > maxNoteSectionLinks) {
    throw const FormatException('Invalid section links');
  }
  final links = <NoteSectionLink>[];
  for (final raw in value) {
    final link = NoteSectionLink.tryFromMap(raw);
    if (link == null) throw const FormatException('Invalid section link');
    links.add(link);
  }
  return normalizeNoteSectionLinks(links);
}

class ResolvedNoteSectionLink {
  const ResolvedNoteSectionLink({required this.note, required this.heading});
  final Note note;
  final NoteOutlineEntry heading;
}

/// Titles and offsets can change. A removed heading must stay unavailable
/// rather than accidentally navigating to another heading with the same title.
ResolvedNoteSectionLink? resolveNoteSectionLink(
    NoteSectionLink link, Iterable<Note> notes) {
  for (final note in notes) {
    if (note.id != link.noteId || note.isDeleted) continue;
    for (final heading
        in buildNoteOutline(note.description ?? '', note.textStyles)) {
      if (heading.anchorId == link.headingId) {
        return ResolvedNoteSectionLink(note: note, heading: heading);
      }
    }
    return null;
  }
  return null;
}
