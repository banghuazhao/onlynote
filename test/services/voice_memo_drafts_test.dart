import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';

class _MemoNotes implements NoteRepository {
  final values = <String, NoteDto>{};
  bool failSave = false;
  int writes = 0;
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (failSave) throw StateError('Disk unavailable');
    writes++;
    values[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      values.remove(id);
    }
  }
}

class _FieldsReader extends Fake implements BinaryReader {
  _FieldsReader(Map<int, dynamic> fields)
      : bytes = [fields.length, ...fields.keys],
        values = fields.values.toList();
  final List<int> bytes;
  final List<dynamic> values;
  int byte = 0;
  int value = 0;
  @override
  int readByte() => bytes[byte++];
  @override
  dynamic read([int? typeId]) => values[value++];
}

void main() {
  late Directory directory;
  late Box journal;
  late Box historyBox;
  late _MemoNotes notes;
  late AudioStorage audio;
  late VoiceMemoDrafts drafts;
  late NoteHistory history;
  NoteHistory? previousHistory;
  var durationReads = 0;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-voice-drafts-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    journal = await Hive.openBox('voice_drafts_tests');
    historyBox = await Hive.openBox('voice_history_tests');
    notes = _MemoNotes();
    audio = AudioStorage(documentsPath: directory.path);
    durationReads = 0;
    drafts = VoiceMemoDrafts(
        journal: journal,
        notes: notes,
        audio: audio,
        readDuration: (path) async {
          expect(path, startsWith('${directory.path}/note_audio/'));
          durationReads++;
          return 4200;
        });
    previousHistory = NoteHistory.initializedInstance;
    history = NoteHistory(box: historyBox, repository: notes);
    NoteHistory.configure(history);
  });
  tearDown(() async {
    NoteHistory.initializedInstance = previousHistory;
    history.dispose();
    await journal.close();
    await historyBox.close();
    await directory.delete(recursive: true);
  });

  Future<File> writeRecording(VoiceMemo memo) async {
    final file = File(await audio.resolvePath(memo.path));
    await file.parent.create(recursive: true);
    await file.writeAsBytes([0, 1, 2, 3], flush: true);
    return file;
  }

  test('interrupted recording merges into latest draft and replays once',
      () async {
    final seed = Note(id: 'note', title: 'Before', description: 'Before body');
    notes.values['note'] = NoteDto.fromNote(seed);
    final memo = await drafts.prepare(seed);
    final file = await writeRecording(memo);
    final other = memo.copyWith(
        id: 'other',
        path: 'note_audio/other.m4a',
        durationMs: 500,
        transcript: 'Existing recording');
    await journal.put(
        'note',
        NoteDto.fromNote(seed.copyWith(
          title: 'Latest title',
          description: 'Do not replace my draft',
          folderId: 'folder',
          isPinned: true,
          todo: [Todo(id: 'task', title: 'Latest task', completed: true)],
          imagePaths: const ['note_images/keep.jpg'],
          voiceMemos: [other],
        )));
    await drafts.recover();
    final restored = notes.values['note']!.toDomain();
    expect(restored.title, 'Latest title');
    expect(restored.description, 'Do not replace my draft');
    expect(restored.folderId, 'folder');
    expect(restored.isPinned, isTrue);
    expect(restored.todo.single.completed, isTrue);
    expect(restored.imagePaths, ['note_images/keep.jpg']);
    expect(restored.voiceMemos.map((memo) => memo.id), ['other', memo.id]);
    expect(restored.voiceMemos.last.durationMs, 4200);
    expect(durationReads, 1);
    expect(drafts.hasPending, isFalse);
    expect(journal.isEmpty, isTrue);
    expect(await file.exists(), isTrue);
    await drafts.recover();
    expect(notes.writes, 1);
  });

  test('failed save retains recording journal through ordinary draft recovery',
      () async {
    final memo = await drafts.prepare(Note(id: 'audio-only'));
    final file = await writeRecording(memo);
    notes.failSave = true;
    await drafts.recover();
    expect(notes.values, isEmpty);
    expect(drafts.hasPending, isTrue);
    expect(journal.get('audio-only'), isA<NoteDto>());
    expect(await file.exists(), isTrue);
    notes.failSave = false;
    await HiveNoteAutosaveStore(notes, journal).recover();
    await drafts.recover();
    expect(
        notes.values['audio-only']!.toDomain().voiceMemos.single.id, memo.id);
    expect(notes.writes, 1);
    expect(durationReads, 1);
    expect(drafts.hasPending, isFalse);
  });

  for (final trashed in [false, true]) {
    test(
        'recovery does not resurrect a ${trashed ? 'trashed' : 'removed'} note',
        () async {
      final note = Note(id: 'existing', description: 'Keep or delete');
      notes.values['existing'] = NoteDto.fromNote(note);
      final memo = await drafts.prepare(note);
      final file = await writeRecording(memo);
      if (trashed) {
        notes.values['existing'] = NoteDto.fromNote(
            note.copyWith(deletedAt: DateTime.utc(2026, 10, 6)));
      } else {
        notes.values.remove('existing');
      }
      await drafts.recover();
      expect(notes.writes, 0);
      expect(notes.values['existing']?.isDeleted ?? !trashed, isTrue);
      expect(drafts.hasPending, isFalse);
      expect(durationReads, 0);
      expect(await file.exists(), isFalse);
    });
  }

  test(
      'discard deletes only unreferenced files and preserves shared recordings',
      () async {
    final memo = await drafts.prepare(Note(id: 'draft'));
    final file = await writeRecording(memo);
    notes.values['other'] = NoteDto.fromNote(
        Note(id: 'other', voiceMemos: [memo.copyWith(durationMs: 3000)]));
    await drafts.discard(memo);
    expect(drafts.hasPending, isFalse);
    expect(await file.exists(), isTrue);
    notes.values.clear();
    await drafts.discard(memo);
    expect(await file.exists(), isFalse);
  });

  test('discard preserves history and ordinary recovery draft references',
      () async {
    final memo = await drafts.prepare(Note(id: 'draft'));
    final file = await writeRecording(memo);
    final old = NoteDto.fromNote(Note(
        id: 'other',
        title: 'Old',
        voiceMemos: [memo.copyWith(durationMs: 3000)]));
    await history.recordBeforeSave(old, old.copyWith(voiceMemos: []));
    expect(history.referencedAudio, contains(memo.path));
    await drafts.discard(memo);
    expect(await file.exists(), isTrue);
    await historyBox.clear();
    await journal.put('other', old);
    await drafts.discard(memo);
    expect(await file.exists(), isTrue);
    await journal.delete('other');
    await drafts.discard(memo);
    expect(await file.exists(), isFalse);
  });

  test('missing and invalid recordings cannot be retained as completed audio',
      () async {
    final memo = await drafts.prepare(Note(id: 'draft'));
    await expectLater(drafts.retain(memo), throwsFormatException);
    await expectLater(drafts.retain(memo.copyWith(durationMs: 2000)),
        throwsA(isA<FileSystemException>()));
    expect(drafts.hasPending, isTrue);
    await drafts.recover();
    expect(notes.writes, 0);
    expect(drafts.hasPending, isFalse);
  });

  test(
      'legacy binary notes without field 11 retain body and default to no audio',
      () {
    final old = NoteDtoAdapter()
        .read(_FieldsReader({
          0: 'old',
          1: 'Before voice memos',
          2: 'Original body',
          5: <TodoDto>[],
          6: <String>[]
        }))
        .toDomain();
    expect(old.description, 'Original body');
    expect(old.voiceMemos, isEmpty);
  });

  test('malformed memo maps are skipped while a valid recording survives', () {
    final valid = VoiceMemo(
        id: 'valid',
        path: 'note_audio/valid.m4a',
        durationMs: 2500,
        createdAt: DateTime.utc(2026, 10, 6));
    final dto = NoteDtoAdapter().read(_FieldsReader({
      0: 'note',
      11: [
        {'id': 'missing-fields'},
        {...valid.toMap(), 'path': '../../private.m4a'},
        {...valid.toMap(), 'durationMs': 'invalid'},
        {...valid.toMap(), 'createdAt': 'invalid'},
        valid.toMap(),
      ]
    }));
    expect(dto.toDomain().voiceMemos, [valid]);
  });
}
