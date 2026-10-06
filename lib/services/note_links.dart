import 'package:onlynote/domain/model/note.dart';

const maxLinkedNotes = 100;

/// Stable note identities, kept separately from the user's written text.
List<String> normalizeLinkedNoteIds(Iterable<String> values, {String? noteId}) {
  final ids = <String>{};
  for (final id in values) {
    if (id.isEmpty || id.length > 512) {
      throw const FormatException('Invalid linked note ID');
    }
    if (id != noteId) ids.add(id);
    if (ids.length > maxLinkedNotes) {
      throw const FormatException('Too many linked notes');
    }
  }
  return List.unmodifiable(ids);
}

List<Note> noteBacklinks(Note target, Iterable<Note> notes) => [
      if (target.id != null)
        for (final note in notes)
          if (!note.isDeleted &&
              note.id != target.id &&
              note.linkedNoteIds.contains(target.id))
            note,
    ];

Note? availableLinkedNote(String id, Iterable<Note> notes) {
  for (final note in notes) {
    if (note.id == id && !note.isDeleted) return note;
  }
  return null;
}
