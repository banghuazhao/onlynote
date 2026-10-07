import 'dart:async';

import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/premium_access.dart';

/// One queue for user-created notes, including autosave, templates and copies.
/// Recovery and backup restore keep their existing data-preservation paths.
class NoteCreationLimit {
  static Future<void>? _tail;

  static int count(NoteRepository repository) =>
      repository.getAllNotes().where((note) => !note.isDeleted).length;

  static bool canSave(NoteRepository repository, String? id,
      {PremiumAccess? access}) {
    final notes = repository.getAllNotes();
    return notes.any((note) => note.id == id) ||
        (access ?? PremiumAccess.instance).allows(PremiumFeature.notes,
            currentCount: notes.where((note) => !note.isDeleted).length);
  }

  static Future<void> save(NoteRepository repository, NoteDto note,
      {PremiumAccess? access}) async {
    final previous = _tail;
    final completion = Completer<void>();
    _tail = completion.future;
    try {
      if (previous != null) await previous;
      if (!canSave(repository, note.id, access: access)) {
        throw const PremiumRequired(PremiumFeature.notes);
      }
      await repository.addUpdateNote(note);
    } finally {
      if (identical(_tail, completion.future)) _tail = null;
      completion.complete();
    }
  }
}
