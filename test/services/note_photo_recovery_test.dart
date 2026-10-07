import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_photo_recovery.dart';

class _PhotoNotes implements NoteRepository {
  final notes = <String, NoteDto>{};
  bool failSave = false;
  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (failSave) throw StateError('Repository temporarily unavailable');
    notes[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => notes.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      notes.remove(id);
    }
  }
}

class _JournalHook implements Box {
  _JournalHook(this.box, this.afterNoteWrite);
  final Box box;
  final void Function() afterNoteWrite;

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      box.get(key, defaultValue: defaultValue);
  @override
  Iterable<dynamic> get keys => box.keys;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    await box.put(key, value);
    if (key == 'existing' && value is NoteDto) afterNoteWrite();
  }

  @override
  Future<void> flush() => box.flush();
  @override
  Future<void> delete(dynamic key) => box.delete(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory directory;
  late Box drafts;
  late _PhotoNotes notes;

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('onlynote-capture-journal-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    drafts = await Hive.openBox('capture_drafts');
    notes = _PhotoNotes();
  });
  tearDown(() async {
    await drafts.close();
    await directory.delete(recursive: true);
  });

  test('lost camera image merges into latest draft with original ID and photos',
      () async {
    final initial = Note(
      id: 'origin',
      title: 'Original title',
      description: 'Original text',
      folderId: 'folder',
      imagePaths: const ['note_images/existing.jpg'],
    );
    notes.notes['origin'] = NoteDto.fromNote(initial);
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => ['/tmp/camera-result.jpg'],
      save: (_) async => 'note_images/recovered.jpg',
    );
    await recovery.begin(initial);
    await drafts.put(
      'origin',
      NoteDto.fromNote(initial.copyWith(
        title: 'Newest unsaved title',
        description: 'Keep every recent edit',
        todo: [Todo(id: 'task', title: 'Keep this task')],
        imagePaths: const [
          'note_images/existing.jpg',
          'note_images/draft-extra.jpg',
        ],
      )),
    );
    await recovery.recoverPending();
    final recovered = notes.notes['origin']!.toDomain();
    expect(notes.notes.length, 1);
    expect(recovered.title, 'Newest unsaved title');
    expect(recovered.description, 'Keep every recent edit');
    expect(recovered.folderId, 'folder');
    expect(recovered.todo.single.title, 'Keep this task');
    expect(recovered.imagePaths, [
      'note_images/existing.jpg',
      'note_images/draft-extra.jpg',
      'note_images/recovered.jpg',
    ]);
    expect(recovery.hasPendingCapture, isFalse);
    expect(drafts.isEmpty, isTrue);
  });

  for (final currentFolder in [null, 'new-folder']) {
    test('photo recovery keeps latest library metadata for $currentFolder',
        () async {
      final seed = Note(
          id: 'origin',
          title: 'Original',
          folderId: 'old-folder',
          sortOrder: 5,
          dailyNoteDateKey: '2026-10-06');
      notes.notes['origin'] = NoteDto.fromNote(seed);
      final recovery = NotePhotoRecovery(
        drafts: drafts,
        notes: notes,
        retrieve: () async => ['/tmp/captured-library-photo.jpg'],
        save: (_) async => 'note_images/recovered-library-photo.jpg',
      );
      await recovery.begin(seed);
      final pending = seed.copyWith(
          title: 'Draft title',
          description: 'Keep pending prose',
          todo: [Todo(id: 'pending-task', title: 'Keep pending task')],
          imagePaths: ['note_images/draft-photo.jpg'],
          tags: ['Draft tag'],
          linkedNoteIds: ['draft-link']);
      await drafts.put('origin', NoteDto.fromNote(pending));
      notes.notes['origin'] = NoteDto.fromNote(seed.copyWith(
          title: 'Saved title',
          isPinned: true,
          isArchived: true,
          folderId: currentFolder,
          sortOrder: 1234,
          dailyNoteDateKey: null,
          tags: ['Saved tag'],
          linkedNoteIds: ['saved-link']));

      await recovery.recoverPending();

      final restored = notes.notes['origin']!.toDomain();
      expect(restored.isPinned, isTrue);
      expect(restored.isArchived, isTrue);
      expect(restored.folderId, currentFolder);
      expect(restored.sortOrder, 1234);
      expect(restored.dailyNoteDateKey, isNull);
      expect(restored.title, pending.title);
      expect(restored.description, pending.description);
      expect(restored.todo, pending.todo);
      expect(restored.tags, pending.tags);
      expect(restored.linkedNoteIds, pending.linkedNoteIds);
      expect(restored.imagePaths, [
        'note_images/draft-photo.jpg',
        'note_images/recovered-library-photo.jpg',
      ]);
      expect(recovery.hasPendingCapture, isFalse);
      expect(drafts.isEmpty, isTrue);
    });
  }

  for (final currentDay in [null, '2026-10-05']) {
    test('photo recovery retains the persisted daily identity $currentDay',
        () async {
      final seed = Note(
          id: 'origin',
          title: 'Old daily note',
          dailyNoteDateKey: '2026-10-06');
      notes.notes['origin'] = NoteDto.fromNote(seed);
      final recovery = NotePhotoRecovery(
        drafts: drafts,
        notes: notes,
        retrieve: () async => ['/tmp/captured-daily-photo.jpg'],
        save: (_) async => 'note_images/recovered-daily-photo.jpg',
      );
      await recovery.begin(seed);
      await drafts.put(
          'origin',
          NoteDto.fromNote(seed.copyWith(
              title: 'Keep latest draft title',
              description: 'Keep unsaved thoughts')));
      notes.notes['origin'] =
          NoteDto.fromNote(seed.copyWith(dailyNoteDateKey: currentDay));
      final owner =
          NoteDto(id: 'today', title: 'Today', dailyNoteDateKey: '2026-10-06');
      notes.notes['today'] = owner;

      await recovery.recoverPending();

      final restored = notes.notes['origin']!;
      expect(restored.dailyNoteDateKey, currentDay);
      expect(restored.title, 'Keep latest draft title');
      expect(restored.description, 'Keep unsaved thoughts');
      expect(restored.imagePaths, ['note_images/recovered-daily-photo.jpg']);
      expect(notes.notes['today'], same(owner));
      expect(recovery.hasPendingCapture, isFalse);
      expect(drafts.isEmpty, isTrue);
    });
  }

  test('canceled camera removes metadata without saving an empty Photo Note',
      () async {
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => [],
    );
    await recovery.begin(Note(id: 'empty'));
    expect(recovery.hasPendingCapture, isTrue);
    await recovery.recoverPending();
    expect(notes.notes, isEmpty);
    expect(drafts.isEmpty, isTrue);
  });

  test('copy failure retains consumed lost data for the next startup retry',
      () async {
    var reads = 0;
    var copies = 0;
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => ++reads == 1 ? ['/tmp/lost-once.jpg'] : [],
      save: (source) async {
        expect(source.path, '/tmp/lost-once.jpg');
        if (++copies == 1) throw FileSystemException('Disk temporarily full');
        return 'note_images/retried.jpg';
      },
    );
    await recovery.begin(Note(id: 'new-photo'));
    await recovery.recoverPending();
    expect(notes.notes, isEmpty);
    expect(recovery.hasPendingCapture, isTrue);
    await recovery.recoverPending();
    expect(notes.notes['new-photo']!.imagePaths, ['note_images/retried.jpg']);
    expect(copies, 2);
    expect(recovery.hasPendingCapture, isFalse);
  });

  test(
      'failed note save survives normal draft recovery and never duplicates photo',
      () async {
    var reads = 0;
    var copies = 0;
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => ++reads == 1 ? ['/tmp/selected.jpg'] : [],
      save: (_) async {
        copies++;
        return 'note_images/copied.jpg';
      },
    );
    await recovery.begin(Note(id: 'retry-note', description: 'Caption'));
    notes.failSave = true;
    await recovery.recoverPending();
    expect(notes.notes, isEmpty);
    expect(recovery.hasPendingCapture, isTrue);
    expect(drafts.get('retry-note'), isA<NoteDto>());
    notes.failSave = false;
    await HiveNoteAutosaveStore(notes, drafts).recover();
    expect(notes.notes['retry-note']!.description, 'Caption');
    await recovery.recoverPending();
    expect(notes.notes['retry-note']!.imagePaths, ['note_images/copied.jpg']);
    expect(copies, 1);
    expect(recovery.hasPendingCapture, isFalse);
  });

  test(
      'malformed metadata causes no file access and can be replaced by capture',
      () async {
    await drafts.put(NotePhotoRecovery.recordKey, {
      'version': 1,
      'token': 'corrupted',
      'note': 'not a note',
      'sources': ['/etc/private-file'],
      'saved': ['../../arbitrary-file'],
      'existed': true,
    });
    var copies = 0;
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => [],
      save: (_) async {
        copies++;
        return 'note_images/unused.jpg';
      },
    );
    await recovery.recoverPending();
    expect(copies, 0);
    expect(notes.notes, isEmpty);
    expect(recovery.hasPendingCapture, isTrue);
    await recovery.begin(Note(id: 'valid-new-capture'));
    await recovery.recoverPending();
    expect(recovery.hasPendingCapture, isFalse);
  });

  for (final trashed in [false, true]) {
    test('recovery never resurrects ${trashed ? 'trashed' : 'removed'} origin',
        () async {
      final origin = Note(id: 'existing', title: 'Original');
      notes.notes['existing'] = NoteDto.fromNote(origin);
      var copies = 0;
      final recovery = NotePhotoRecovery(
        drafts: drafts,
        notes: notes,
        retrieve: () async => ['/tmp/captured.jpg'],
        save: (_) async {
          copies++;
          return 'note_images/unused.jpg';
        },
      );
      await recovery.begin(origin);
      if (trashed) {
        notes.notes['existing'] =
            NoteDto.fromNote(origin.copyWith(deletedAt: DateTime(2026, 10, 6)));
      } else {
        notes.notes.remove('existing');
      }
      await recovery.recoverPending();
      expect(copies, 0);
      expect(notes.notes['existing']?.isDeleted ?? !trashed, isTrue);
      expect(recovery.hasPendingCapture, isFalse);
    });
  }

  test('already autosaved photo is deduplicated while clearing stale metadata',
      () async {
    final origin = Note(
        id: 'saved',
        description: 'Caption',
        imagePaths: const ['note_images/photo.jpg']);
    notes.notes['saved'] = NoteDto.fromNote(origin);
    var copies = 0;
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => [],
      save: (_) async {
        copies++;
        return 'note_images/unused.jpg';
      },
    );
    final token = await recovery.begin(origin);
    await recovery.selected(token, '/tmp/photo.jpg');
    await recovery.copied(token, 'note_images/photo.jpg');
    await recovery.complete('wrong-token');
    expect(recovery.hasPendingCapture, isTrue);
    await recovery.recoverPending();
    expect(notes.notes['saved']!.imagePaths, ['note_images/photo.jpg']);
    expect(copies, 0);
    expect(recovery.hasPendingCapture, isFalse);
  });

  test('photo copying merges prose and metadata changed during file I/O',
      () async {
    final origin =
        Note(id: 'existing', description: 'Before copy', folderId: 'old');
    notes.notes['existing'] = NoteDto.fromNote(origin);
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => ['/tmp/captured.jpg'],
      save: (_) async {
        notes.notes['existing'] = NoteDto.fromNote(origin.copyWith(
            description: 'Edited while the image copied',
            isArchived: true,
            isPinned: true,
            folderId: null,
            sortOrder: 200));
        return 'note_images/copied.jpg';
      },
    );
    await recovery.begin(origin);
    await recovery.recoverPending();

    final saved = notes.notes['existing']!.toDomain();
    expect(saved.description, 'Edited while the image copied');
    expect(saved.isArchived, isTrue);
    expect(saved.isPinned, isTrue);
    expect(saved.folderId, isNull);
    expect(saved.sortOrder, 200);
    expect(saved.imagePaths, ['note_images/copied.jpg']);
    expect(drafts.isEmpty, isTrue);
  });

  for (final trashed in [false, true]) {
    for (final duringJournal in [false, true]) {
      for (final savedBeforeCapture in [false, true]) {
        test(
            'deletion during ${duringJournal ? 'journal' : 'copy'} keeps '
            '${trashed ? 'trashed' : 'removed'} photo origin deleted '
            '(saved before capture: $savedBeforeCapture)', () async {
          final origin = Note(id: 'existing', title: 'Before capture');
          if (savedBeforeCapture) {
            notes.notes['existing'] = NoteDto.fromNote(origin);
          }
          void removeOrigin() {
            if (trashed) {
              notes.notes['existing'] = NoteDto.fromNote(
                  origin.copyWith(deletedAt: DateTime(2026, 10, 7)));
            } else {
              notes.notes.remove('existing');
            }
          }

          final recovery = NotePhotoRecovery(
            drafts: duringJournal ? _JournalHook(drafts, removeOrigin) : drafts,
            notes: notes,
            retrieve: () async => ['/tmp/captured.jpg'],
            save: (_) async {
              if (!duringJournal) removeOrigin();
              return 'note_images/copied.jpg';
            },
          );
          await recovery.begin(origin);
          // The editor can finish its first autosave while the camera is open.
          notes.notes['existing'] = NoteDto.fromNote(origin);
          await recovery.recoverPending();
          expect(notes.notes['existing']?.isDeleted ?? !trashed, isTrue);
          expect(notes.notes['existing']?.imagePaths ?? [], isEmpty);
          expect(drafts.isEmpty, isTrue);
          expect(recovery.hasPendingCapture, isFalse);
          await HiveNoteAutosaveStore(notes, drafts).recover();
          expect(notes.notes['existing']?.isDeleted ?? !trashed, isTrue);
        });
      }
    }
  }

  test(
      'batch journal appends completed copies and recovers only remaining sources',
      () async {
    final copied = <String>[];
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      // Android may return the entire original selection after a restart.
      retrieve: () async => ['/tmp/one.jpg', '/tmp/two.jpg', '/tmp/three.jpg'],
      save: (source) async {
        copied.add(source.path);
        return 'note_images/${source.path.split('/').last}';
      },
    );
    final token = await recovery.begin(Note(id: 'batch'));
    await recovery.selectedMany(
        token, ['/tmp/one.jpg', '/tmp/two.jpg', '/tmp/three.jpg']);
    await recovery.copied(token, 'note_images/one.jpg',
        sourcePath: '/tmp/one.jpg');
    await recovery.copied(token, 'note_images/two.jpg',
        sourcePath: '/tmp/two.jpg');
    final record = drafts.get(NotePhotoRecovery.recordKey) as Map;
    expect(record['sources'], ['/tmp/three.jpg']);
    expect(record['saved'], ['note_images/one.jpg', 'note_images/two.jpg']);
    await recovery.recoverPending();
    expect(copied, ['/tmp/three.jpg']);
    expect(notes.notes['batch']!.imagePaths, [
      'note_images/one.jpg',
      'note_images/two.jpg',
      'note_images/three.jpg'
    ]);
    expect(recovery.hasPendingCapture, isFalse);
  });

  test(
      'legacy unclaimed picker result becomes a photo note rather than disappearing',
      () async {
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => ['/tmp/legacy-camera.jpg'],
      save: (_) async => 'note_images/legacy-recovered.jpg',
    );
    await recovery.recoverPending();
    expect(notes.notes.length, 1);
    expect(notes.notes.values.single.imagePaths,
        ['note_images/legacy-recovered.jpg']);
    expect(recovery.hasPendingCapture, isFalse);
  });

  test(
      'missing old camera cache never blocks a new capture or erases its journal',
      () async {
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => [],
      save: (source) async {
        if (source.path.endsWith('gone.jpg')) {
          throw FileSystemException('Camera cache file is gone', source.path);
        }
        return 'note_images/new-photo.jpg';
      },
    );
    final oldToken = await recovery.begin(Note(id: 'old-photo'));
    await recovery.selected(oldToken, '${directory.path}/gone.jpg');
    final newToken = await recovery.begin(Note(id: 'new-photo'));
    expect(drafts.values.whereType<Map>().length, 2);
    await recovery.selected(newToken, '${directory.path}/new.jpg');
    await recovery.recoverPending();
    expect(notes.notes['new-photo']!.imagePaths, ['note_images/new-photo.jpg']);
    expect(notes.notes.containsKey('old-photo'), isFalse);
    expect(recovery.hasPendingCapture, isTrue);
    expect(drafts.values.whereType<Map>().single['token'], oldToken);
    // Deferred metadata is retried, but no longer owns the active slot.
    await recovery.begin(Note(id: 'next-photo'));
  });

  test('still-present captured source remains protected until it is saved',
      () async {
    final source = File('${directory.path}/recoverable.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final recovery = NotePhotoRecovery(
      drafts: drafts,
      notes: notes,
      retrieve: () async => [],
      save: (_) async => 'note_images/recoverable.jpg',
    );
    final token = await recovery.begin(Note(id: 'original-photo'));
    await recovery.selected(token, source.path);
    await expectLater(
        recovery.begin(Note(id: 'another-photo')), throwsStateError);
    expect(await source.exists(), isTrue);
    expect(drafts.values.whereType<Map>().single['token'], token);
    await recovery.recoverPending();
    expect(notes.notes['original-photo']!.imagePaths,
        ['note_images/recoverable.jpg']);
    await recovery.begin(Note(id: 'another-photo'));
  });
}
