import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/note_history.dart';

/// Retains a recording and the note it belongs to until the foreground editor
/// has durably saved it. A completed file survives an interrupted save/close.
class VoiceMemoDrafts {
  static VoiceMemoDrafts? initializedInstance;
  static void configure(VoiceMemoDrafts drafts) => initializedInstance = drafts;
  VoiceMemoDrafts(
      {required this.journal,
      required this.notes,
      AudioStorage? audio,
      required this.readDuration})
      : audio = audio ?? AudioStorage.instance;

  static const prefix = '_voice_memo_pending_v1.';
  final Box journal;
  final NoteRepository notes;
  final AudioStorage audio;
  final Future<int> Function(String absolutePath) readDuration;

  String _key(String id) => '$prefix$id';
  bool get hasPending =>
      journal.keys.whereType<String>().any((key) => key.startsWith(prefix));

  Set<String> get referencedAudio => {
        for (final key in journal.keys.whereType<String>())
          if (key.startsWith(prefix))
            if (journal.get(key) case final Map record)
              if (VoiceMemo.tryFromMap(record['memo'])
                  case final VoiceMemo memo)
                memo.path,
      };

  Future<VoiceMemo> prepare(Note note) async {
    if (note.id == null || note.isDeleted) throw StateError('Unavailable note');
    final memo = await audio.createMemo();
    await journal.put(_key(memo.id), {
      'version': 1,
      'noteId': note.id,
      'existed': notes.getAllNotes().any((saved) => saved.id == note.id),
      'seed': NoteDto.fromNote(note),
      'memo': memo.toMap(),
    });
    await journal.flush();
    return memo;
  }

  Future<void> retain(VoiceMemo memo) async {
    final old = journal.get(_key(memo.id));
    if (old is! Map || old['version'] != 1) {
      throw StateError('Recording ownership is missing');
    }
    final previous = VoiceMemo.tryFromMap(old['memo']);
    if (previous?.path != memo.path || memo.durationMs <= 0) {
      throw const FormatException('Invalid recording');
    }
    await audio.flush(memo);
    await journal.put(_key(memo.id), {...old, 'memo': memo.toMap()});
    await journal.flush();
  }

  Future<void> complete(VoiceMemo memo) async {
    final record = journal.get(_key(memo.id));
    if (record is Map) {
      await journal.put(_key(memo.id), {...record, 'committed': true});
      await journal.flush();
    }
    await journal.delete(_key(memo.id));
    await journal.flush();
  }

  Future<void> discard(VoiceMemo memo) async {
    final noteRefs = notes
        .getAllNotes()
        .expand((note) => note.voiceMemos ?? [])
        .map((entry) => entry['path'])
        .toSet();
    final draftRefs = journal.values
        .whereType<NoteDto>()
        .expand((note) => note.voiceMemos ?? [])
        .map((entry) => entry['path'])
        .toSet();
    final pendingRefs = <String>{
      for (final key in journal.keys.whereType<String>())
        if (key.startsWith(prefix) && key != _key(memo.id))
          if (journal.get(key) case final Map record)
            if (VoiceMemo.tryFromMap(record['memo']) case final VoiceMemo other)
              other.path,
    };
    if (!noteRefs.contains(memo.path) &&
        !draftRefs.contains(memo.path) &&
        !pendingRefs.contains(memo.path) &&
        !(NoteHistory.initializedInstance?.referencedAudio
                .contains(memo.path) ??
            false)) {
      await audio.deletePaths([memo.path]);
    }
    await journal.delete(_key(memo.id));
    await journal.flush();
  }

  Future<void> purgeNotes(Set<String> ids) async {
    for (final key in journal.keys.whereType<String>().toList()) {
      if (!key.startsWith(prefix)) continue;
      final record = journal.get(key);
      if (record is! Map || !ids.contains(record['noteId'])) continue;
      final memo = VoiceMemo.tryFromMap(record['memo']);
      if (memo != null) {
        await discard(memo);
      } else {
        await journal.delete(key);
      }
    }
    await journal.flush();
  }

  Future<void> recover() async {
    for (final key in journal.keys.whereType<String>().toList()) {
      if (!key.startsWith(prefix)) continue;
      try {
        final record = journal.get(key);
        if (record is! Map || record['version'] != 1) continue;
        var memo = VoiceMemo.tryFromMap(record['memo']);
        final seed = record['seed'];
        final id = record['noteId'];
        if (memo == null ||
            seed is! NoteDto ||
            id is! String ||
            seed.id != id) {
          continue;
        }
        var existing =
            notes.getAllNotes().where((note) => note.id == id).firstOrNull;
        final previouslyStored = existing != null;
        if (existing?.isDeleted == true ||
            (existing == null &&
                (record['committed'] == true || record['existed'] == true))) {
          await discard(memo);
          continue;
        }
        if (existing?.voiceMemos?.any((value) => value['id'] == memo!.id) ==
            true) {
          await complete(memo);
          continue;
        }
        final path = await audio.resolvePath(memo.path);
        final file = File(path);
        if (!await file.exists()) {
          await journal.delete(key);
          continue;
        }
        if (memo.durationMs <= 0) {
          final duration = await readDuration(path);
          if (duration <= 0) continue; // Keep an interrupted file for retry.
          memo = memo.copyWith(durationMs: duration);
        }
        await retain(memo);
        // File validation and duration inspection can outlive a library edit
        // or deletion. Resolve the owner again before adopting the recording.
        existing =
            notes.getAllNotes().where((note) => note.id == id).firstOrNull;
        if (_unavailable(existing, record, previouslyStored)) {
          await discard(memo);
          continue;
        }
        final draft = journal.get(id);
        final content =
            draft is NoteDto && draft.id == id ? draft : existing ?? seed;
        final current = _mergeLibraryMetadata(content, existing);
        if (current.isDeleted) continue;
        final updated = current.copyWith(voiceMemos: [
          for (final value in current.voiceMemos ?? <Map<dynamic, dynamic>>[])
            if (value['id'] != memo.id) value,
          memo.toMap(),
        ]);
        await journal.put(id, updated);
        await journal.flush();
        // Draft I/O is another suspension point. A deleted note must never be
        // recreated, and the latest library placement wins over this draft.
        existing =
            notes.getAllNotes().where((note) => note.id == id).firstOrNull;
        if (_unavailable(existing, record, previouslyStored)) {
          await journal.delete(id);
          await discard(memo);
          continue;
        }
        await notes.addUpdateNote(_mergeLibraryMetadata(updated, existing));
        await journal.delete(id);
        await complete(memo);
      } catch (error) {
        debugPrint('Recording recovery deferred: $error');
      }
    }
  }

  static bool _unavailable(
          NoteDto? existing, Map record, bool previouslyStored) =>
      existing?.isDeleted == true ||
      (existing == null &&
          (previouslyStored ||
              record['committed'] == true ||
              record['existed'] == true));

  static NoteDto _mergeLibraryMetadata(NoteDto content, NoteDto? existing) =>
      existing == null
          ? content
          : NoteDto.fromNote(content.toDomain().copyWith(
                isArchived: existing.isArchived,
                isPinned: existing.isPinned ?? false,
                folderId: existing.folderId,
                dailyNoteDateKey: existing.dailyNoteDateKey,
                sortOrder: existing.sortOrder,
              ));
}
