import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:uuid/uuid.dart';

import 'backup_contents.dart';

const backupRecoveryBox = 'backup_restore_recovery';

class BackupService {
  BackupService(
      {required this.notes,
      this.drafts,
      required this.folders,
      required this.journal,
      required this.documents,
      required this.readReminders,
      required this.writeReminders});
  final Box notes;
  final Box? drafts;
  final Box folders;
  final Box journal;
  final Directory documents;
  final List<Reminder> Function() readReminders;
  final Future<void> Function(List<Reminder>) writeReminders;
  static const _uuid = Uuid();

  Future<Uint8List> export() async {
    final byId = {for (final n in notes.values.whereType<NoteDto>()) n.id: n};
    for (final draft in drafts?.values.whereType<NoteDto>() ?? <NoteDto>[]) {
      if (draft.validNote || byId.containsKey(draft.id)) byId[draft.id] = draft;
    }
    final snapshot = byId.values.toList();
    final folderSnapshot = folders.values.whereType<FolderDto>().toList();
    final folderIds = folderSnapshot.map((f) => f.id).toSet();
    final noteIds = snapshot.map((n) => n.id).toSet();
    final reminders = readReminders()
        .where((r) => noteIds.contains(r.noteId))
        .map((r) => BackupReminder(r.noteId, r.reminderDate, repeat: r.repeat))
        .toList();
    final photos = <String, BackupPhoto>{};
    final photoKeys = <String, String>{};
    var totalBytes = 0;
    for (final note in snapshot) {
      for (final path in note.imagePaths ?? <String>[]) {
        if (photoKeys.containsKey(path)) continue;
        final resolved = path.startsWith('/')
            ? ImageStorage.resolvePath(path)
            : '${documents.path}/$path';
        final file = File(resolved);
        totalBytes += await file.length();
        // Base64 adds roughly one third; reserve room for note content.
        if (totalBytes > maxBackupBytes * .7) {
          throw const FormatException('Backup too large');
        }
        final bytes = await file.readAsBytes();
        final suffix = path.split('.').last.toLowerCase();
        final extension =
            RegExp(r'^[a-z0-9]{1,10}$').hasMatch(suffix) ? suffix : 'jpg';
        final key = 'photo_${photos.length}';
        photoKeys[path] = key;
        photos[key] = BackupPhoto(extension, bytes);
      }
    }
    final contents = BackupContents(
      createdAt: DateTime.now(),
      folders: folderSnapshot,
      photos: photos,
      reminders: reminders,
      notes: [
        for (final note in snapshot)
          note.copyWith(
            imagePaths: [
              for (final path in note.imagePaths ?? <String>[]) photoKeys[path]!
            ],
            clearFolderId: !folderIds.contains(note.folderId),
          )
      ],
    );
    return compute(encodeBackup, contents);
  }

  /// Restore only creates new IDs. The journal rolls back a partial import on
  /// I/O failure or on next launch, without ever deleting pre-existing data.
  Future<List<Reminder>> restore(BackupContents backup) async {
    if (journal.containsKey('pending')) await recoverInterruptedRestore();
    final noteIds = {for (final n in backup.notes) n.id!: _newId(notes)};
    final folderIds = {for (final f in backup.folders) f.id!: _newId(folders)};
    final paths = {
      for (final entry in backup.photos.entries)
        entry.key: 'note_images/${_uuid.v4()}.${entry.value.extension}'
    };
    await journal.put('pending', {
      'notes': noteIds.values.toList(),
      'folders': folderIds.values.toList(),
      'photos': paths.values.toList(),
    });
    await journal.flush();
    try {
      await Directory('${documents.path}/note_images').create(recursive: true);
      for (final entry in backup.photos.entries) {
        await File('${documents.path}/${paths[entry.key]}')
            .writeAsBytes(entry.value.bytes, flush: true);
      }
      await folders.putAll({
        for (final f in backup.folders)
          folderIds[f.id]!: f.copyWith(id: folderIds[f.id])
      });
      await notes.putAll({
        for (final n in backup.notes)
          noteIds[n.id]!: n.copyWith(
            id: noteIds[n.id],
            folderId: folderIds[n.folderId],
            clearFolderId: n.folderId == null,
            imagePaths: [
              for (final key in n.imagePaths ?? <String>[]) paths[key]!
            ],
          )
      });
      final existing = List<Reminder>.of(readReminders());
      final usedIds = existing.map((r) => r.reminderId).toSet();
      final restored = <Reminder>[];
      for (final reminder in backup.reminders) {
        var id = _uuid.v4().hashCode & 0x7fffffff;
        while (!usedIds.add(id)) {
          id = (id + 1) & 0x7fffffff;
        }
        restored.add(Reminder(
            noteId: noteIds[reminder.noteId]!,
            reminderId: id,
            reminderDate: reminder.date,
            repeat: reminder.repeat));
      }
      await writeReminders([...existing, ...restored]);
      await notes.flush();
      await folders.flush();
      await journal.delete('pending');
      await journal.flush();
      return restored;
    } catch (_) {
      await recoverInterruptedRestore();
      rethrow;
    }
  }

  static String _newId(Box box) {
    var id = _uuid.v4();
    while (box.containsKey(id)) {
      id = _uuid.v4();
    }
    return id;
  }

  Future<void> recoverInterruptedRestore() async {
    final pending = journal.get('pending');
    if (pending == null) return;
    final ids = (pending['notes'] as List).cast<String>();
    await writeReminders(
        readReminders().where((r) => !ids.contains(r.noteId)).toList());
    await notes.deleteAll(ids);
    await folders.deleteAll((pending['folders'] as List).cast<String>());
    for (final path in (pending['photos'] as List).cast<String>()) {
      // Recovery paths must remain inside the managed image directory.
      if (!RegExp(r'^note_images/[a-zA-Z0-9-]+\.[a-zA-Z0-9]+$')
          .hasMatch(path)) {
        continue;
      }
      final file = File('${documents.path}/$path');
      if (await file.exists()) await file.delete();
    }
    await journal.delete('pending');
  }
}
