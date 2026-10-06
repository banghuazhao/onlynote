import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_history.dart';

class _HistoryNotes implements NoteRepository {
  final notes = <String, NoteDto>{};
  NoteHistory? history;
  bool failSave = false;
  int writes = 0;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    final previous = notes[note.id];
    if (previous != null) await history?.recordBeforeSave(previous, note);
    if (failSave) throw StateError('Disk unavailable');
    writes++;
    notes[note.id!] = note;
  }

  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
  @override
  Future<void> deleteNote(String id) async => notes.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      notes.remove(id);
    }
  }
}

class _FailingHistoryBox extends Fake implements Box {
  _FailingHistoryBox(this.delegate);
  final Box delegate;
  bool failWrite = true;
  Future<void> Function()? onFlush;
  @override
  Iterable<dynamic> get keys => delegate.keys;
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      delegate.get(key, defaultValue: defaultValue);
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failWrite) throw StateError('Snapshot storage unavailable');
    await delegate.put(key, value);
  }

  @override
  Future<void> flush() async {
    await delegate.flush();
    await onFlush?.call();
  }

  @override
  Future<void> delete(dynamic key) => delegate.delete(key);
}

void main() {
  late Directory directory;
  late Box box;
  late _HistoryNotes repository;
  late DateTime now;
  late NoteHistory history;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-history-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    box = await Hive.openBox('history_tests');
    repository = _HistoryNotes();
    now = DateTime.utc(2026, 10, 10, 10);
    history = NoteHistory(box: box, repository: repository, now: () => now);
    repository.history = history;
  });
  tearDown(() async {
    history.dispose();
    await box.close();
    await directory.delete(recursive: true);
  });

  test('link edits make versions and restore keeps current archive and tags',
      () async {
    final before = NoteDto(
        id: 'note', title: 'Hub', linkedNoteIds: ['one'], tags: ['Old']);
    repository.notes['note'] = before;
    await repository.addUpdateNote(before.copyWith(linkedNoteIds: ['two']));
    final version = history.versionsFor('note').single;
    await repository.addUpdateNote(
        repository.notes['note']!.copyWith(isArchived: true, tags: ['New']));
    expect(history.versionsFor('note').length, 1);
    expect(await history.restore('note', version.id),
        NoteHistoryRestoreResult.restored);
    expect(repository.notes['note']!.linkedNoteIds, ['one']);
    expect(repository.notes['note']!.isArchived, isTrue);
    expect(repository.notes['note']!.tags, ['New']);
  });

  test('typing rebases image anchors and resize or movement makes versions',
      () async {
    const path = 'note_images/photo.jpg';
    const layout = NoteImageLayout(path: path, textOffset: 2, widthFactor: .6);
    final before = NoteDto(
        id: 'photo',
        description: 'A\nB',
        imagePaths: [path],
        imageLayouts: [layout.toMap()]);
    repository.notes['photo'] = before;
    await repository.addUpdateNote(before.copyWith(
        description: 'AX\nB',
        imageLayouts: [layout.copyWith(textOffset: 3).toMap()]));
    now = now.add(const Duration(seconds: 1));
    await repository.addUpdateNote(repository.notes['photo']!.copyWith(
        description: 'AXY\nB',
        imageLayouts: [layout.copyWith(textOffset: 4).toMap()]));
    expect(history.versionsFor('photo').length, 1);
    await repository.addUpdateNote(repository.notes['photo']!.copyWith(
        imageLayouts: [
          layout.copyWith(textOffset: 4, widthFactor: .8).toMap()
        ]));
    final resizedVersion = history.versionsFor('photo').first;
    expect(history.versionsFor('photo').length, 2);
    expect(resizedVersion.note.toDomain().imageLayouts.single.widthFactor, .6);
    await repository.addUpdateNote(repository.notes['photo']!.copyWith(
        imageLayouts: [
          layout.copyWith(textOffset: 0, widthFactor: .8).toMap()
        ]));
    expect(history.versionsFor('photo').length, 3);
    await repository.addUpdateNote(repository.notes['photo']!
        .copyWith(isArchived: true, tags: ['Current'], folderId: 'folder'));
    expect(await history.restore('photo', resizedVersion.id),
        NoteHistoryRestoreResult.restored);
    final restored = repository.notes['photo']!;
    expect(restored.toDomain().imageLayouts.single,
        layout.copyWith(textOffset: 4));
    expect(restored.isArchived, isTrue);
    expect(restored.tags, ['Current']);
    expect(restored.folderId, 'folder');
  });

  test('typing in the block after a photo coalesces without moving that photo',
      () async {
    const layout =
        NoteImageLayout(path: 'note_images/photo.jpg', textOffset: 2);
    final before = NoteDto(
        id: 'photo',
        description: 'A\nB',
        imagePaths: [layout.path],
        imageLayouts: [layout.toMap()]);
    repository.notes['photo'] = before;
    await repository.addUpdateNote(before.copyWith(description: 'A\nXB'));
    now = now.add(const Duration(seconds: 1));
    await repository.addUpdateNote(before.copyWith(description: 'A\nXYB'));
    expect(history.versionsFor('photo').length, 1);
    expect(repository.notes['photo']!.toDomain().imageLayouts.single, layout);
  });

  test('image layout snapshots own their map data', () async {
    final layout =
        NoteImageLayout(path: 'note_images/photo.jpg', textOffset: 0).toMap();
    final before = NoteDto(
        id: 'photo',
        imagePaths: ['note_images/photo.jpg'],
        imageLayouts: [layout]);
    await history.recordBeforeSave(
        before,
        before.copyWith(imageLayouts: [
          {...layout, 'widthFactor': .5},
        ]));
    layout['widthFactor'] = .25;
    final snapshot = history.versionsFor('photo').single.note;
    expect(snapshot.imageLayouts!.single['widthFactor'], .85);
    expect(() => snapshot.imageLayouts!.single['widthFactor'] = .5,
        throwsUnsupportedError);
  });

  test('styled typing coalesces while formatting changes create restore points',
      () async {
    Map<String, dynamic> bold(int end) =>
        const NoteTextStyleRange(start: 0, end: 5, kind: NoteTextStyleKind.bold)
            .toMap()
          ..['end'] = end;
    final before =
        NoteDto(id: 'styled', description: 'Hello', textStyles: [bold(5)]);
    repository.notes['styled'] = before;
    await repository.addUpdateNote(
        before.copyWith(description: 'HeXllo', textStyles: [bold(6)]));
    now = now.add(const Duration(seconds: 1));
    final current = repository.notes['styled']!;
    await repository.addUpdateNote(
        current.copyWith(description: 'HeXYllo', textStyles: [bold(7)]));
    expect(history.versionsFor('styled').length, 1);
    expect(history.versionsFor('styled').single.note.description, 'Hello');
    await repository
        .addUpdateNote(repository.notes['styled']!.copyWith(textStyles: []));
    final formattedVersion = history.versionsFor('styled').first;
    expect(history.versionsFor('styled').length, 2);
    expect(formattedVersion.note.description, 'HeXYllo');
    expect(formattedVersion.note.textStyles, [bold(7)]);
    await repository.addUpdateNote(repository.notes['styled']!
        .copyWith(isArchived: true, tags: ['Current']));
    expect(await history.restore('styled', formattedVersion.id),
        NoteHistoryRestoreResult.restored);
    expect(repository.notes['styled']!.textStyles, [bold(7)]);
    expect(repository.notes['styled']!.isArchived, isTrue);
    expect(repository.notes['styled']!.tags, ['Current']);
  });

  test('formatting snapshots own their map data across later draft mutations',
      () async {
    final style = <String, dynamic>{'start': 0, 'end': 4, 'kind': 'bold'};
    final before =
        NoteDto(id: 'styled', description: 'Text', textStyles: [style]);
    await history.recordBeforeSave(before, before.copyWith(textStyles: []));
    style['end'] = 1;
    final snapshot = history.versionsFor('styled').single.note;
    expect(snapshot.textStyles!.single['end'], 4);
    expect(
        () => snapshot.textStyles!.single['end'] = 2, throwsUnsupportedError);
  });

  test('metadata-only edits and empty seeds never create content history',
      () async {
    final note = NoteDto(id: 'note', title: 'Keep');
    await history.recordBeforeSave(
        note,
        note.copyWith(
            dateTime: now.toIso8601String(),
            sortOrder: 10,
            isPinned: true,
            folderId: 'folder',
            deletedAt: now.toIso8601String()));
    await history.recordBeforeSave(
        NoteDto(id: 'new'), NoteDto(id: 'new', title: 'First saved content'));
    expect(box.isEmpty, isTrue);
    expect(history.versionsFor('note'), isEmpty);
    expect(history.versionsFor('new'), isEmpty);
  });

  test('content comparison covers checklist state, color, images, and audio',
      () async {
    var before = NoteDto(id: 'note', title: 'Title');
    final states = [
      before.copyWith(description: 'Body'),
      before.copyWith(colorValue: 0xffeeddcc),
      before.copyWith(todoList: [TodoDto(id: 'todo', title: 'Task')]),
      before.copyWith(
          todoList: [TodoDto(id: 'todo', title: 'Task', completed: true)]),
      before.copyWith(imagePaths: ['note_images/photo.jpg']),
      before.copyWith(voiceMemos: [
        {'id': 'memo', 'path': 'note_audio/memo.m4a', 'transcript': 'Remember'}
      ]),
    ];
    for (final after in states) {
      await history.recordBeforeSave(before, after);
      now = now.add(const Duration(seconds: 31));
      before = after;
    }
    expect(history.versionsFor('note').length, states.length);
    expect(history.referencedImages, contains('note_images/photo.jpg'));
    // Capture the version that owns the audio reference too.
    await history.recordBeforeSave(before, before.copyWith(title: 'Later'));
    expect(history.referencedAudio, contains('note_audio/memo.m4a'));
  });

  test('typing bursts retain earliest saved state and separate after idle',
      () async {
    final first = NoteDto(id: 'note', description: 'A');
    final second = first.copyWith(description: 'AB');
    final third = first.copyWith(description: 'ABC');
    await history.recordBeforeSave(first, second);
    now = now.add(const Duration(seconds: 10));
    await history.recordBeforeSave(second, third);
    expect(history.versionsFor('note').map((v) => v.note.description), ['A']);
    now = now.add(const Duration(seconds: 31));
    await history.recordBeforeSave(third, third.copyWith(description: 'ABCD'));
    expect(history.versionsFor('note').map((v) => v.note.description),
        ['ABC', 'A']);
  });

  test('adding then removing a recording within a typing burst retains it',
      () async {
    final original = NoteDto(id: 'note', description: 'Saved text');
    final withAudio = original.copyWith(voiceMemos: [
      {'id': 'memo', 'path': 'note_audio/recent.m4a'}
    ]);
    await history.recordBeforeSave(original, withAudio);
    now = now.add(const Duration(seconds: 1));
    await history.recordBeforeSave(withAudio, original);
    expect(history.versionsFor('note').length, 2);
    expect(history.versionsFor('note').first.note.voiceMemos!.single['path'],
        'note_audio/recent.m4a');
    expect(history.referencedAudio, contains('note_audio/recent.m4a'));
  });

  test('typing after a structural change captures the new structural state',
      () async {
    final original = NoteDto(id: 'note', description: 'Saved text');
    final withTask =
        original.copyWith(todoList: [TodoDto(id: 'task', title: 'New task')]);
    await history.recordBeforeSave(original, withTask);
    now = now.add(const Duration(seconds: 1));
    final typed = withTask.copyWith(description: 'Saved text edited');
    await history.recordBeforeSave(withTask, typed);
    await history.recordBeforeSave(
        typed, typed.copyWith(description: 'Saved text edited twice'));
    final versions = history.versionsFor('note');
    expect(versions.length, 2);
    expect(versions.first.note.todoList!.single.title, 'New task');
    expect(versions.first.note.description, 'Saved text');
  });

  test('bounded history retains the latest twenty previous versions', () async {
    for (var index = 0; index < 25; index++) {
      await history.recordBeforeSave(
          NoteDto(id: 'note', title: 'Version $index'),
          NoteDto(id: 'note', title: 'Version ${index + 1}'));
      now = now.add(const Duration(seconds: 31));
    }
    final versions = history.versionsFor('note');
    expect(versions.length, 20);
    expect(versions.first.note.title, 'Version 24');
    expect(versions.last.note.title, 'Version 5');
    expect(versions.map((v) => v.id).toSet().length, 20);
  });

  test('snapshots own immutable checklist, photo, and memo collections',
      () async {
    final todos = [TodoDto(id: 'todo', title: 'Original')];
    final images = ['note_images/original.jpg'];
    final waveform = [1, 2];
    final memo = <String, dynamic>{
      'id': 'memo',
      'path': 'note_audio/original.m4a',
      'waveform': waveform
    };
    final note = NoteDto(
        id: 'note', todoList: todos, imagePaths: images, voiceMemos: [memo]);
    await history.recordBeforeSave(note, note.copyWith(title: 'Edited'));
    todos.clear();
    images.clear();
    waveform.add(3);
    memo['path'] = 'note_audio/new.m4a';
    final snapshot = history.versionsFor('note').single.note;
    expect(snapshot.todoList!.single.title, 'Original');
    expect(snapshot.imagePaths, ['note_images/original.jpg']);
    expect(snapshot.voiceMemos!.single['path'], 'note_audio/original.m4a');
    expect(snapshot.voiceMemos!.single['waveform'], [1, 2]);
    expect(() => snapshot.imagePaths!.add('mutation'), throwsUnsupportedError);
  });

  test('snapshot storage failure blocks note write and remains retryable',
      () async {
    final guardedBox = _FailingHistoryBox(box);
    final guardedHistory = NoteHistory(box: guardedBox, repository: repository);
    addTearDown(guardedHistory.dispose);
    repository.history = guardedHistory;
    repository.notes['note'] = NoteDto(id: 'note', title: 'Original');
    await expectLater(
        repository.addUpdateNote(NoteDto(id: 'note', title: 'Changed')),
        throwsStateError);
    expect(repository.notes['note']!.title, 'Original');
    expect(repository.writes, 0);
    guardedBox.failWrite = false;
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Changed'));
    expect(guardedHistory.versionsFor('note').single.note.title, 'Original');
    expect(repository.notes['note']!.title, 'Changed');
  });

  test('restore preserves freshest metadata and records current content first',
      () async {
    final original = NoteDto(
        id: 'note',
        title: 'Original',
        description: 'Original body',
        colorValue: 0xffeeddcc,
        imagePaths: [
          'note_images/history.jpg'
        ],
        voiceMemos: [
          {'id': 'memo', 'path': 'note_audio/history.m4a'}
        ]);
    repository.notes['note'] = original;
    await repository.addUpdateNote(original.copyWith(title: 'Current'));
    final version = history.versionsFor('note').single;
    repository.notes['note'] = repository.notes['note']!
        .copyWith(sortOrder: 42, isPinned: true, folderId: 'latest-folder');
    final result = await history.restore('note', version.id);
    expect(result, NoteHistoryRestoreResult.restored);
    final restored = repository.notes['note']!;
    expect(restored.id, 'note');
    expect(restored.title, 'Original');
    expect(restored.imagePaths, ['note_images/history.jpg']);
    expect(restored.voiceMemos!.single['path'], 'note_audio/history.m4a');
    expect(restored.sortOrder, 42);
    expect(restored.isPinned, isTrue);
    expect(restored.folderId, 'latest-folder');
    expect(restored.dateTime, now.toIso8601String());
    expect(history.versionsFor('note').first.note.title, 'Current');
    await repository.addUpdateNote(restored.copyWith(title: 'After restore'));
    expect(history.versionsFor('note').first.note.title, 'Original');
  });

  test('failed restore retains current note and succeeds on explicit retry',
      () async {
    repository.notes['note'] = NoteDto(id: 'note', title: 'Original');
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Current'));
    final version = history.versionsFor('note').single;
    repository.failSave = true;
    expect(await history.restore('note', version.id),
        NoteHistoryRestoreResult.failed);
    expect(repository.notes['note']!.title, 'Current');
    repository.failSave = false;
    expect(await history.restore('note', version.id),
        NoteHistoryRestoreResult.restored);
    expect(repository.notes['note']!.title, 'Original');
  });

  test('missing and trashed notes cannot be resurrected through history',
      () async {
    final original = NoteDto(id: 'note', title: 'Original');
    await history.recordBeforeSave(original, original.copyWith(title: 'New'));
    final version = history.versionsFor('note').single;
    expect(await history.restore('note', version.id),
        NoteHistoryRestoreResult.unavailable);
    repository.notes['note'] =
        original.copyWith(deletedAt: now.toIso8601String());
    expect(await history.restore('note', version.id),
        NoteHistoryRestoreResult.unavailable);
    expect(repository.writes, 0);
  });

  test('restore revalidates note after awaiting history boundary storage',
      () async {
    final guardedBox = _FailingHistoryBox(box)..failWrite = false;
    final guardedHistory =
        NoteHistory(box: guardedBox, repository: repository, now: () => now);
    addTearDown(guardedHistory.dispose);
    repository.history = guardedHistory;
    repository.notes['note'] = NoteDto(id: 'note', title: 'Original');
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Current'));
    final version = guardedHistory.versionsFor('note').single;
    guardedBox.onFlush = () async => repository.notes.remove('note');
    expect(await guardedHistory.restore('note', version.id),
        NoteHistoryRestoreResult.unavailable);
    expect(repository.notes, isEmpty);
  });

  test('same content restore is unchanged and never writes a new note',
      () async {
    final note = NoteDto(id: 'note', title: 'Original');
    await history.recordBeforeSave(note, note.copyWith(title: 'Different'));
    repository.notes['note'] = note;
    expect(await history.restore('note', history.versionsFor('note').single.id),
        NoteHistoryRestoreResult.unchanged);
    expect(repository.writes, 0);
  });

  test('malformed and unsupported history envelopes are ignored safely',
      () async {
    await box.put('note', {
      'version': 1,
      'entries': [
        {'id': 'bad-date', 'savedAt': 'unknown', 'note': NoteDto(id: 'note')},
        {
          'id': 'wrong-note',
          'savedAt': now.toIso8601String(),
          'note': NoteDto(id: 'other')
        },
        {
          'id': 'valid',
          'savedAt': now.toIso8601String(),
          'note': NoteDto(id: 'note', title: 'Saved')
        },
        {
          'id': 'valid',
          'savedAt': now.toIso8601String(),
          'note': NoteDto(id: 'note', title: 'Duplicate')
        },
      ],
    });
    expect(history.versionsFor('note').single.note.title, 'Saved');
    await box.put('future', {'version': 2, 'entries': []});
    expect(history.versionsFor('future'), isEmpty);
  });

  test('per-note concurrent saves serialize with stable equal-time ordering',
      () async {
    await Future.wait([
      history.recordBeforeSave(
          NoteDto(id: 'note', title: 'A'), NoteDto(id: 'note', title: 'B'),
          forceBoundary: true),
      history.recordBeforeSave(
          NoteDto(id: 'note', title: 'B'), NoteDto(id: 'note', title: 'C'),
          forceBoundary: true),
    ]);
    expect(history.versionsFor('note').map((v) => v.note.title), ['B', 'A']);
  });

  test('permanent deletion purge releases only the selected note media',
      () async {
    for (final id in ['one', 'two']) {
      final note = NoteDto(id: id, title: id, imagePaths: [
        'note_images/$id.jpg'
      ], voiceMemos: [
        {'id': 'memo-$id', 'path': 'note_audio/$id.m4a'}
      ]);
      await history.recordBeforeSave(note, note.copyWith(title: 'Changed'));
    }
    await history.purge(['one']);
    expect(history.versionsFor('one'), isEmpty);
    expect(history.versionsFor('two').length, 1);
    expect(history.referencedImages, {'note_images/two.jpg'});
    expect(history.referencedAudio, {'note_audio/two.m4a'});
  });
  test('backup history import merges immutable IDs and forces an edit boundary',
      () async {
    final original =
        NoteDto(id: 'restored', title: 'Imported previous content');
    await history.importVersions({
      'restored': [
        NoteHistoryVersion(id: 'version-one', savedAt: now, note: original),
      ],
    });
    await history.importVersions({
      'restored': [
        NoteHistoryVersion(
            id: 'version-one',
            savedAt: now,
            note: original.copyWith(title: 'Should not replace version')),
        NoteHistoryVersion(
            id: 'version-two',
            savedAt: now.subtract(const Duration(minutes: 1)),
            note: original.copyWith(title: 'Older imported content')),
      ],
    });
    expect(history.versionsFor('restored').map((v) => v.note.title),
        ['Imported previous content', 'Older imported content']);
    await history.recordBeforeSave(
        original.copyWith(title: 'Current imported note'),
        original.copyWith(title: 'First edit after import'));
    expect(history.versionsFor('restored').first.note.title,
        'Current imported note');
  });

  test('invalid imported ownership is rejected before history writes',
      () async {
    await expectLater(
        history.importVersions({
          'note': [
            NoteHistoryVersion(
                id: 'version',
                savedAt: now,
                note: NoteDto(id: 'different', title: 'Wrong owner'))
          ],
        }),
        throwsFormatException);
    expect(box.isEmpty, isTrue);
  });
}
