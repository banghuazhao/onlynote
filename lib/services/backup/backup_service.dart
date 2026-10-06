import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:onlynote/services/daily_note.dart';
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
      required this.writeReminders,
      this.templateStore,
      this.history,
      this.savedViewStore});
  final Box notes;
  final Box? drafts;
  final Box folders;
  final Box journal;
  final Directory documents;
  final List<Reminder> Function() readReminders;
  final Future<void> Function(List<Reminder>) writeReminders;
  final CustomNoteTemplateStore? templateStore;
  final NoteHistory? history;
  final SavedNoteViewStore? savedViewStore;
  static const _uuid = Uuid();

  Future<Uint8List> export() async {
    await templateStore?.load();
    await savedViewStore?.load();
    final templates = templateStore?.templates.toList() ?? const [];
    final byId = {for (final n in notes.values.whereType<NoteDto>()) n.id: n};
    for (final draft in drafts?.values.whereType<NoteDto>() ?? <NoteDto>[]) {
      if (draft.validNote || byId.containsKey(draft.id)) byId[draft.id] = draft;
    }
    final snapshot = byId.values.toList();
    final folderSnapshot = folders.values.whereType<FolderDto>().toList();
    final folderIds = folderSnapshot.map((f) => f.id).toSet();
    final noteIds = snapshot.map((n) => n.id).toSet();
    final histories = {
      if (history != null)
        for (final note in snapshot)
          if (history!.versionsFor(note.id!).isNotEmpty)
            note.id!: history!.versionsFor(note.id!),
    };
    final historyNotes = [
      for (final versions in histories.values)
        for (final version in versions) version.note,
    ];
    final reminders = readReminders()
        .where((r) => noteIds.contains(r.noteId))
        .map((r) => BackupReminder(r.noteId, r.reminderDate, repeat: r.repeat))
        .toList();
    final photos = <String, BackupPhoto>{};
    final photoKeys = <String, String>{};
    final audio = <String, BackupAudio>{};
    final audioKeys = <String, String>{};
    var totalBytes = 0;
    for (final imagePaths in [
      for (final note in snapshot) note.imagePaths ?? <String>[],
      for (final template in templates) template.imagePaths,
      for (final note in historyNotes) note.imagePaths ?? <String>[],
    ]) {
      for (final path in imagePaths) {
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
    for (final memos in [
      for (final note in [...snapshot, ...historyNotes])
        _managedMemos(note.voiceMemos),
      for (final template in templates) template.voiceMemos,
    ]) {
      for (final memo in memos) {
        if (audioKeys.containsKey(memo.path)) continue;
        final file = File('${documents.path}/${memo.path}');
        final size = await file.length();
        totalBytes += size;
        if (size <= 0 ||
            size > maxBackupAudioBytes ||
            totalBytes > maxBackupBytes * .7) {
          throw const FormatException('Backup recording too large or empty');
        }
        final key = 'audio_${audio.length}';
        audioKeys[memo.path] = key;
        audio[key] = BackupAudio(await file.readAsBytes());
      }
    }
    NoteDto archiveNote(NoteDto note) => note.copyWith(
          imagePaths: [
            for (final path in note.imagePaths ?? <String>[]) photoKeys[path]!
          ],
          imageLayouts: _remapImageLayouts(note, photoKeys),
          voiceMemos: [
            for (final memo in _managedMemos(note.voiceMemos))
              memo.copyWith(path: audioKeys[memo.path]!).toMap()
          ],
          clearFolderId: !folderIds.contains(note.folderId),
        );
    final contents = BackupContents(
      createdAt: DateTime.now(),
      savedViews: [
        for (final view in savedViewStore?.views ?? <SavedNoteView>[])
          view.withAvailableFolders(folderIds.whereType<String>().toSet())
      ],
      folders: folderSnapshot,
      photos: photos,
      audio: audio,
      reminders: reminders,
      templates: [
        for (final template in templates)
          template.copyWith(imagePaths: [
            for (final path in template.imagePaths) photoKeys[path]!,
          ], voiceMemos: [
            for (final memo in template.voiceMemos)
              memo.copyWith(path: audioKeys[memo.path]!)
          ]),
      ],
      notes: [for (final note in snapshot) archiveNote(note)],
      histories: {
        for (final entry in histories.entries)
          entry.key: [
            for (final version in entry.value)
              NoteHistoryVersion(
                  id: version.id,
                  savedAt: version.savedAt,
                  note: archiveNote(version.note))
          ],
      },
    );
    return compute(encodeBackup, contents);
  }

  /// Restore only creates new IDs. The journal rolls back a partial import on
  /// I/O failure or on next launch, without ever deleting pre-existing data.
  Future<List<Reminder>> restore(BackupContents backup) async {
    // Validate even callers that construct contents directly, before any writes.
    backup = BackupContents.fromJson(backup.toJson());
    if (backup.templates.isNotEmpty && templateStore == null) {
      throw StateError('Template storage is unavailable');
    }
    if (backup.histories.isNotEmpty && history == null) {
      throw StateError('History storage is unavailable');
    }
    if (backup.savedViews.isNotEmpty && savedViewStore == null) {
      throw StateError('Saved view storage is unavailable');
    }
    await templateStore?.load();
    await savedViewStore?.load();
    if (journal.containsKey('pending')) await recoverInterruptedRestore();
    if ((savedViewStore?.views.length ?? 0) + backup.savedViews.length >
        SavedNoteViewStore.maxViews) {
      throw StateError('Saved view limit reached');
    }
    final noteIds = {for (final n in backup.notes) n.id!: _newId(notes)};
    final folderIds = {for (final f in backup.folders) f.id!: _newId(folders)};
    final templateIds = {
      for (final template in backup.templates) template.id: _uuid.v4(),
    };
    final restoredViews = [
      for (final view in backup.savedViews)
        SavedNoteView(
          id: _uuid.v4(),
          name: view.name,
          query: view.query,
          filters: view.filters,
          tags: view.tags,
          folderId: folderIds[view.folderId],
          archiveScope: view.archiveScope,
        ),
    ];
    final notePhotoKeys = {
      for (final note in backup.notes) ...note.imagePaths ?? <String>[],
      for (final versions in backup.histories.values)
        for (final version in versions)
          ...version.note.imagePaths ?? <String>[],
    };
    final templatePhotoKeys = {
      for (final template in backup.templates) ...template.imagePaths,
    };
    final paths = {
      for (final key in notePhotoKeys)
        key: 'note_images/${_uuid.v4()}.${backup.photos[key]!.extension}',
    };
    final templatePaths = {
      for (final key in templatePhotoKeys)
        key: 'template_images/${_uuid.v4()}.${backup.photos[key]!.extension}',
    };
    final noteAudioKeys = {
      for (final note in backup.notes)
        for (final memo in note.voiceMemos ?? const <Map>[])
          memo['path'] as String,
      for (final versions in backup.histories.values)
        for (final version in versions)
          for (final memo in version.note.voiceMemos ?? const <Map>[])
            memo['path'] as String,
    };
    final audioPaths = {
      for (final key in noteAudioKeys) key: 'note_audio/${_uuid.v4()}.m4a',
    };
    final templateAudioPaths = {
      for (final template in backup.templates)
        for (final memo in template.voiceMemos)
          memo.path: 'template_audio/${_uuid.v4()}.m4a',
    };
    final todoIds = <String, Map<String, String>>{};
    final memoIds = <String, Map<String, String>>{};
    // Imports keep their content as separate notes. Only one live note owns a
    // day: an existing association wins, then an active imported note wins over
    // an archived one, with a stable date/ID tie break.
    final importedDailyGroups = <String, List<NoteDto>>{};
    for (final note in backup.notes) {
      final key = note.dailyNoteDateKey;
      if (key == null) continue;
      (importedDailyGroups[key] ??= []).add(note);
    }
    Map<String, String?> resolveImportedDailyKeys() {
      final existingDays = {
        for (final note in notes.values.whereType<NoteDto>())
          if (!note.isDeleted && note.dailyNoteDateKey != null)
            note.dailyNoteDateKey!,
      };
      final keys = <String, String?>{};
      for (final entry in importedDailyGroups.entries) {
        final imported = existingDays.contains(entry.key)
            ? null
            : dailyNoteForDay(entry.value, entry.key);
        for (final note in entry.value) {
          keys[note.id!] =
              note.isDeleted || imported?.id == note.id ? entry.key : null;
        }
      }
      return keys;
    }

    final importedDailyKeys = resolveImportedDailyKeys();
    NoteDto restoreNote(NoteDto note) {
      final tasks = todoIds.putIfAbsent(note.id!, () => {});
      final memos = memoIds.putIfAbsent(note.id!, () => {});
      return note.copyWith(
        id: noteIds[note.id],
        dailyNoteDateKey: importedDailyKeys[note.id],
        clearDailyNoteDateKey: importedDailyKeys[note.id] == null,
        linkedNoteIds: [
          for (final id in note.linkedNoteIds ?? const <String>[])
            if (noteIds.containsKey(id) && id != note.id) noteIds[id]!
        ],
        folderId: folderIds[note.folderId],
        clearFolderId: !folderIds.containsKey(note.folderId),
        todoList: [
          for (final todo in note.todoList ?? const <TodoDto>[])
            TodoDto(
                id: todo.id == null
                    ? _uuid.v4()
                    : tasks.putIfAbsent(todo.id!, _uuid.v4),
                title: todo.title,
                completed: todo.completed)
        ],
        imagePaths: [
          for (final key in note.imagePaths ?? const <String>[]) paths[key]!
        ],
        imageLayouts: _remapImageLayouts(note, paths),
        voiceMemos: [
          for (final memo in note.voiceMemos ?? const <Map>[])
            {
              ...memo,
              'id': memos.putIfAbsent(
                  '${memo['id']}\u0000${memo['path']}', _uuid.v4),
              'path': audioPaths[memo['path']]!,
            }
        ],
      );
    }

    await journal.put('pending', {
      'notes': noteIds.values.toList(),
      'folders': folderIds.values.toList(),
      'templates': templateIds.values.toList(),
      'photos': [...paths.values, ...templatePaths.values],
      'audio': [...audioPaths.values, ...templateAudioPaths.values],
      'histories': [for (final id in backup.histories.keys) noteIds[id]!],
      'savedViews': restoredViews.map((view) => view.id).toList(),
    });
    await journal.flush();
    try {
      await Directory('${documents.path}/note_images').create(recursive: true);
      if (templatePaths.isNotEmpty) {
        await Directory('${documents.path}/template_images')
            .create(recursive: true);
      }
      for (final entry in paths.entries) {
        await File('${documents.path}/${entry.value}')
            .writeAsBytes(backup.photos[entry.key]!.bytes, flush: true);
      }
      for (final entry in templatePaths.entries) {
        await File('${documents.path}/${entry.value}')
            .writeAsBytes(backup.photos[entry.key]!.bytes, flush: true);
      }
      for (final group in [audioPaths, templateAudioPaths]) {
        for (final entry in group.entries) {
          final file = File('${documents.path}/${entry.value}');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(backup.audio[entry.key]!.bytes, flush: true);
        }
      }
      await folders.putAll({
        for (final f in backup.folders)
          folderIds[f.id]!: f.copyWith(id: folderIds[f.id])
      });
      // A daily note may have been created while media files were importing.
      // Recheck immediately before committing so that association stays primary.
      importedDailyKeys
        ..clear()
        ..addAll(resolveImportedDailyKeys());
      await notes.putAll(
          {for (final n in backup.notes) noteIds[n.id]!: restoreNote(n)});
      final restoredHistories = {
        for (final entry in backup.histories.entries)
          noteIds[entry.key]!: [
            for (final version in entry.value)
              NoteHistoryVersion(
                  id: _uuid.v4(),
                  savedAt: version.savedAt,
                  note: restoreNote(version.note))
          ],
      };
      if (backup.templates.isNotEmpty) {
        await templateStore!.importTemplates([
          for (final template in backup.templates)
            template.copyWith(
              id: templateIds[template.id],
              linkedNoteIds: [
                for (final id in template.linkedNoteIds)
                  if (noteIds.containsKey(id)) noteIds[id]!
              ],
              imagePaths: [
                for (final key in template.imagePaths) templatePaths[key]!,
              ],
              voiceMemos: [
                for (final memo in template.voiceMemos)
                  memo.copyWith(
                      id: _uuid.v4(), path: templateAudioPaths[memo.path]!)
              ],
            ),
        ]);
      }
      if (restoredHistories.isNotEmpty) {
        await history!.importVersions(restoredHistories);
      }
      if (restoredViews.isNotEmpty) {
        await savedViewStore!.importViews(restoredViews);
      }
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

  static List<VoiceMemo> _managedMemos(List<Map>? raw) {
    final memos = <VoiceMemo>[];
    for (final map in raw ?? const <Map>[]) {
      final memo = VoiceMemo.tryFromMap(map);
      if (memo == null || memo.durationMs <= 0) {
        throw const FormatException('Invalid source recording');
      }
      memos.add(memo);
    }
    return memos;
  }

  Future<void> recoverInterruptedRestore() async {
    final pending = journal.get('pending');
    if (pending == null) return;
    final viewIds =
        (pending['savedViews'] as List? ?? const []).cast<String>().toSet();
    if (viewIds.isNotEmpty) {
      if (savedViewStore == null) {
        throw StateError('Saved view recovery storage is unavailable');
      }
      await savedViewStore!.deleteViews(viewIds);
    }
    final historyIds =
        (pending['histories'] as List? ?? const []).cast<String>();
    if (historyIds.isNotEmpty) {
      if (history == null) {
        throw StateError('History recovery storage is unavailable');
      }
      await history!.purge(historyIds);
    }
    final templateIds =
        (pending['templates'] as List? ?? const []).cast<String>().toSet();
    if (templateIds.isNotEmpty) {
      if (templateStore == null) {
        throw StateError('Template recovery storage is unavailable');
      }
      await templateStore!.deleteTemplates(templateIds);
    }
    final ids = (pending['notes'] as List).cast<String>();
    await writeReminders(
        readReminders().where((r) => !ids.contains(r.noteId)).toList());
    await notes.deleteAll(ids);
    await folders.deleteAll((pending['folders'] as List).cast<String>());
    for (final path in (pending['photos'] as List).cast<String>()) {
      // Recovery paths must remain inside the managed image directory.
      if (!RegExp(
              r'^(note_images|template_images)/[a-zA-Z0-9-]+\.[a-zA-Z0-9]+$')
          .hasMatch(path)) {
        continue;
      }
      final file = File('${documents.path}/$path');
      if (await file.exists()) await file.delete();
    }
    for (final path in (pending['audio'] as List? ?? const []).cast<String>()) {
      if (!VoiceMemo.isManagedPath(path)) continue;
      final file = File('${documents.path}/$path');
      if (await file.exists()) await file.delete();
    }
    await notes.flush();
    await folders.flush();
    await journal.delete('pending');
    await journal.flush();
  }
}

List<Map<String, dynamic>> _remapImageLayouts(
        NoteDto note, Map<String, String> paths) =>
    [
      for (final layout in normalizeNoteImageLayouts([
        for (final raw in note.imageLayouts ?? const <Map>[])
          if (NoteImageLayout.tryFromMap(raw) case final layout?) layout,
      ], note.imagePaths ?? const [], note.description ?? ''))
        layout.copyWith(path: paths[layout.path]!).toMap(),
    ];
