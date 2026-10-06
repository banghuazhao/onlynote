import 'package:onlynote/Tools/image_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';
import 'package:onlynote/services/note_photo_recovery.dart';
import 'package:onlynote/services/shared_note_import.dart';

/// Best-effort cleanup of a note's images, recordings, and reminders.
class NoteCleanup {
  NoteCleanup._();

  /// Cleans up [notes] after permanent deletion. References held by another
  /// note, a template, history, or pending recovery keep shared media alive.
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

    await deleteUnreferencedAudio(
      (note.voiceMemos ?? const <Map>[])
          .map((memo) => memo['path'])
          .whereType<String>(),
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

    try {
      candidates.removeAll(
          await referencedImages(repository, ignoreNoteIds: ignoreNoteIds));
    } catch (_) {
      return; // Missing ownership data must preserve photos, not fail a save.
    }
    if (candidates.isEmpty) return;

    await ImageStorage.deleteImages(candidates.toList());
  }

  static Future<Set<String>> referencedImages(
    NoteRepository repository, {
    Set<String> ignoreNoteIds = const {},
    CustomNoteTemplateStore? templateStore,
  }) async {
    final store = templateStore ?? CustomNoteTemplateStore.instance;
    await store.load();
    final keep = <String>{
      for (final note in repository.getAllNotes())
        if (!ignoreNoteIds.contains(note.id)) ...note.imagePaths ?? const [],
      ...NoteHistory.initializedInstance?.referencedImages ?? const [],
      for (final template in store.templates) ...template.imagePaths,
    };
    for (final record in _journalValues()) {
      if (record is NoteDto && !ignoreNoteIds.contains(record.id)) {
        keep.addAll(record.imagePaths ?? const []);
      } else if (record is Map) {
        for (final key in ['note', 'seed']) {
          final note = record[key];
          if (note is NoteDto) keep.addAll(note.imagePaths ?? const []);
        }
        final saved = record['saved'];
        if (saved is List) keep.addAll(saved.whereType<String>());
      }
    }
    return keep;
  }

  static Future<Set<String>> referencedAudio(
    NoteRepository repository, {
    Set<String> ignoreNoteIds = const {},
    CustomNoteTemplateStore? templateStore,
  }) async {
    final store = templateStore ?? CustomNoteTemplateStore.instance;
    await store.load();
    final keep = <String>{
      for (final note in repository.getAllNotes())
        if (!ignoreNoteIds.contains(note.id)) ..._audioPaths(note),
      ...NoteHistory.initializedInstance?.referencedAudio ?? const [],
      ...VoiceMemoDrafts.initializedInstance?.referencedAudio ?? const [],
      for (final template in store.templates)
        for (final memo in template.voiceMemos) memo.path,
    };
    for (final record in _journalValues()) {
      if (record is NoteDto && !ignoreNoteIds.contains(record.id)) {
        keep.addAll(_audioPaths(record));
      } else if (record is Map) {
        for (final key in ['note', 'seed']) {
          final note = record[key];
          if (note is NoteDto) keep.addAll(_audioPaths(note));
        }
        final memo = record['memo'];
        if (memo is Map && memo['path'] is String) {
          keep.add(memo['path'] as String);
        }
      }
    }
    return keep;
  }

  static Iterable<String> _audioPaths(NoteDto note) =>
      (note.voiceMemos ?? const <Map>[])
          .map((memo) => memo['path'])
          .whereType<String>();

  static Iterable<dynamic> _journalValues() => Hive.isBoxOpen(draftDatabaseBox)
      ? Hive.box(draftDatabaseBox).values
      : const [];

  static bool get hasPendingMediaRecovery =>
      Hive.isBoxOpen(draftDatabaseBox) &&
      Hive.box(draftDatabaseBox).keys.whereType<String>().any((key) =>
          key.startsWith(NotePhotoRecovery.recordKey) ||
          key.startsWith(SharedNoteImport.journalPrefix) ||
          key.startsWith(VoiceMemoDrafts.prefix) ||
          key.startsWith('_note_delete_pending_v1.'));

  static Future<void> deleteUnreferencedAudio(
    Iterable<String> paths, {
    required NoteRepository repository,
    Set<String> ignoreNoteIds = const {},
    CustomNoteTemplateStore? templateStore,
    AudioStorage? audio,
  }) async {
    final candidates = paths.toSet();
    if (candidates.isEmpty) return;
    try {
      candidates.removeAll(await referencedAudio(repository,
          ignoreNoteIds: ignoreNoteIds, templateStore: templateStore));
    } catch (_) {
      return; // Missing ownership data must preserve audio, not fail a save.
    }
    await (audio ?? AudioStorage.instance).deletePaths(candidates);
  }

  /// Prune only after recovery; unresolved captures still own managed files.
  static Future<void> pruneOrphanImages(NoteRepository repository,
      {CustomNoteTemplateStore? templateStore}) async {
    if (hasPendingMediaRecovery) return;
    try {
      final keep =
          await referencedImages(repository, templateStore: templateStore);
      await ImageStorage.pruneOrphans(
          keep.map(ImageStorage.resolvePath).toSet());
    } catch (_) {
      // Never delete media when any owner's references cannot be read.
    }
  }

  static Future<void> pruneOrphanAudio(NoteRepository repository,
      {CustomNoteTemplateStore? templateStore, AudioStorage? audio}) async {
    if (hasPendingMediaRecovery) return;
    try {
      final keep =
          await referencedAudio(repository, templateStore: templateStore);
      await (audio ?? AudioStorage.instance).prune(keep);
    } catch (_) {
      // Never delete media when any owner's references cannot be read.
    }
  }
}
