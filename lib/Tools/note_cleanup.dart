import 'package:onlynote/Tools/image_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';

/// Best-effort cleanup of side effects owned by a note (images + reminders).
class NoteCleanup {
  NoteCleanup._();

  /// Cleans up [notes] that are about to be permanently deleted. [repository]
  /// is consulted so an image another note still points at survives — notes
  /// duplicated before images were copied per-note share files.
  static Future<void> cleanupNotes(
    Iterable<NoteDto> notes, {
    required NoteRepository repository,
  }) async {
    final ids = notes.map((note) => note.id).whereType<String>().toSet();
    for (final note in notes) {
      await cleanupNote(note, repository: repository, ignoreNoteIds: ids);
    }
  }

  static Future<void> cleanupNote(
    NoteDto note, {
    required NoteRepository repository,
    Set<String> ignoreNoteIds = const {},
  }) async {
    final noteId = note.id;

    await deleteUnreferencedImages(
      note.imagePaths ?? const <String>[],
      repository: repository,
      ignoreNoteIds: {...ignoreNoteIds, if (noteId != null) noteId},
    );

    if (noteId == null) return;

    final reminders = ReminderData.shared.reminders
        .where((reminder) => reminder.noteId == noteId)
        .toList();
    final notificationService = NotificationService();
    for (final reminder in reminders) {
      await notificationService.removeNotification(reminder);
      await ReminderData.shared.deleteReminder(reminder);
    }
  }

  /// Deletes the image files in [paths] that no *other* note still uses.
  /// [ignoreNoteIds] names the notes whose references don't count — the ones
  /// being deleted, or the one that just dropped these paths.
  static Future<void> deleteUnreferencedImages(
    Iterable<String> paths, {
    required NoteRepository repository,
    Set<String> ignoreNoteIds = const {},
  }) async {
    final candidates = paths.toSet();
    if (candidates.isEmpty) return;

    for (final other in repository.getAllNotes()) {
      final otherId = other.id;
      if (otherId != null && ignoreNoteIds.contains(otherId)) continue;
      candidates.removeAll(other.imagePaths ?? const <String>[]);
      if (candidates.isEmpty) return;
    }

    await ImageStorage.deleteImages(candidates.toList());
  }

  /// Startup housekeeping: drops image files nothing points at, e.g. a photo
  /// added in the editor and then abandoned without saving.
  static Future<void> pruneOrphanImages(NoteRepository repository) async {
    try {
      final referenced = <String>{};
      for (final note in repository.getAllNotes()) {
        for (final path in note.imagePaths ?? const <String>[]) {
          referenced.add(ImageStorage.resolvePath(path));
        }
      }
      if (Hive.isBoxOpen(draftDatabaseBox)) {
        for (final draft
            in Hive.box(draftDatabaseBox).values.whereType<NoteDto>()) {
          referenced
              .addAll((draft.imagePaths ?? []).map(ImageStorage.resolvePath));
        }
      }
      await ImageStorage.pruneOrphans(referenced);
    } catch (_) {
      // Runs unawaited at startup: never surface as an unhandled error, and
      // never delete anything when the note list can't be read.
    }
  }
}
