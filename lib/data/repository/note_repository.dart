import 'package:injectable/injectable.dart';
import 'package:onlynote/common/exception.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_photo_recovery.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

@LazySingleton(as: NoteRepository)
class NoteRepositoryImplementation implements NoteRepository {
  NoteRepositoryImplementation(this._database);

  final Database _database;
  static const deletionPrefix = '_note_delete_pending_v1.';

  @override
  Future addUpdateNote(NoteDto note) async {
    try {
      final id = note.id!;
      final previous = _database.box.get(id) as NoteDto?;
      if (previous != null) {
        await NoteHistory.initializedInstance?.recordBeforeSave(previous, note);
        final current = _database.box.get(id) as NoteDto?;
        if (current == null ||
            (!previous.isDeleted && current.isDeleted && !note.isDeleted)) {
          throw StateError('Note became unavailable while saving');
        }
      }
      await _database.addUpdate(id, note);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future deleteNote(String id) async {
    await _delete({id}, () => _database.delete(id));
  }

  @override
  Future deleteMultiNotes(List<String> ids) async {
    await _delete(ids.toSet(), () => _database.deleteAll(ids));
  }

  Future<void> _delete(Set<String> ids, Future Function() commit) async {
    final drafts =
        Hive.isBoxOpen(draftDatabaseBox) ? Hive.box(draftDatabaseBox) : null;
    final key = '$deletionPrefix${const Uuid().v4()}';
    if (drafts != null) {
      await drafts.put(key, {'version': 1, 'ids': ids.toList()});
      await drafts.flush();
    }
    // The durable intent remains if either deletion or recovery cleanup fails.
    // Startup checks the database so partially failed deletes keep live drafts.
    await commit();
    try {
      await _purgeDeletedState(ids);
      if (drafts != null) {
        await drafts.delete(key);
        await drafts.flush();
      }
    } catch (error) {
      // A committed deletion is complete for the caller. Its durable intent
      // prevents recovery drafts from resurrecting it when cleanup retries.
      debugPrint('Permanent deletion cleanup deferred: $error');
    }
  }

  Future<bool> recoverPendingDeletions() async {
    if (!Hive.isBoxOpen(draftDatabaseBox)) return true;
    final drafts = Hive.box(draftDatabaseBox);
    var complete = true;
    for (final key in drafts.keys.whereType<String>().toList()) {
      if (!key.startsWith(deletionPrefix)) continue;
      final record = drafts.get(key);
      if (record is! Map || record['version'] != 1 || record['ids'] is! List) {
        continue;
      }
      final ids = (record['ids'] as List).whereType<String>().toSet();
      final existing = getAllNotes().map((note) => note.id).toSet();
      try {
        await _purgeDeletedState(ids.difference(existing));
        await drafts.delete(key);
        await drafts.flush();
      } catch (error) {
        complete = false;
        debugPrint('Permanent deletion recovery deferred: $error');
      }
    }
    return complete;
  }

  Future<void> _purgeDeletedState(Set<String> ids) async {
    final documentScans = DocumentScanCapture.initializedInstance;
    if (documentScans != null) {
      await documentScans.purgeNotes(ids);
    } else if (Hive.isBoxOpen(draftDatabaseBox)) {
      // Pending native UI still owns this record until its terminal result.
      // Mark its seed abandoned so recovery cannot recreate a deleted note.
      await DocumentScanCapture(
        journalBox: Hive.box(draftDatabaseBox),
        repository: this,
      ).purgeNotes(ids);
    }
    if (Hive.isBoxOpen(draftDatabaseBox)) {
      final drafts = Hive.box(draftDatabaseBox);
      for (final id in ids) {
        if (drafts.get(id) is NoteDto) await drafts.delete(id);
      }
      // Camera recovery can also retain an unsaved origin seed. Permanent
      // deletion must clear it even when its original `existed` flag was false.
      for (final key in drafts.keys.whereType<String>().toList()) {
        if (!key.startsWith(NotePhotoRecovery.recordKey)) continue;
        final record = drafts.get(key);
        if (record is Map) {
          final note = record['note'];
          if (note is NoteDto && ids.contains(note.id)) {
            await drafts.delete(key);
          }
        }
      }
      await drafts.flush();
    }
    final voiceDrafts = VoiceMemoDrafts.initializedInstance;
    if (voiceDrafts != null) {
      await voiceDrafts.purgeNotes(ids);
    } else if (Hive.isBoxOpen(draftDatabaseBox)) {
      final drafts = Hive.box(draftDatabaseBox);
      for (final key in drafts.keys.whereType<String>().toList()) {
        if (!key.startsWith(VoiceMemoDrafts.prefix)) continue;
        final record = drafts.get(key);
        if (record is Map && ids.contains(record['noteId'])) {
          await drafts.delete(key);
        }
      }
      await drafts.flush();
    }
    await NoteHistory.initializedInstance?.purge(ids);
  }

  @override
  List<NoteDto> getAllNotes() {
    try {
      final notesDto =
          _database.getAll().map((note) => note as NoteDto).toList();
      return notesDto;
    } on NoRecordsException {
      return [];
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<NoteDto> getNote(String id) async {
    try {
      final noteDto = await _database.get(id) as NoteDto;
      return noteDto;
    } catch (_) {
      rethrow;
    }
  }
}
