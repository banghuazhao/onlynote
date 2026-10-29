import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_mutations.dart';

class NoteArchiveChange {
  const NoteArchiveChange({
    required this.noteId,
    required this.previousArchived,
    required this.archived,
  });
  final String noteId;
  final bool previousArchived;
  final bool archived;
}

/// Archive changes only library visibility. Content, reminders, pinning, and
/// folder ownership remain attached to the freshest stored note.
Future<NoteArchiveChange?> setNoteArchived(
        NoteRepository repository, String noteId, bool archived) =>
    NoteMutations.run(() async {
      final note = await repository.getNote(noteId);
      if (note.isDeleted) throw StateError('Deleted notes cannot be archived');
      if (note.isArchived == archived) return null;
      await repository.addUpdateNote(note.copyWith(isArchived: archived));
      return NoteArchiveChange(
          noteId: noteId,
          previousArchived: note.isArchived,
          archived: archived);
    });
