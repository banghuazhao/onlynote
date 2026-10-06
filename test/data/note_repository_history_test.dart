import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/data/repository/note_repository.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/note_photo_recovery.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';
// The preference plugin exposes its test platform in a separate package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';

final class _PositionPreferencesPlatform
    extends SharedPreferencesAsyncPlatform {
  final values = <String, String>{};

  @override
  Future<String?> getString(
          String key, SharedPreferencesOptions options) async =>
      values[key];

  @override
  Future<void> setString(
      String key, String value, SharedPreferencesOptions options) async {
    values[key] = value;
  }

  @override
  Future<void> clear(ClearPreferencesParameters parameters,
      SharedPreferencesOptions options) async {
    final allowed = parameters.filter.allowList;
    values.removeWhere((key, _) => allowed == null || allowed.contains(key));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Database implements Database {
  _Database(this.box);
  @override
  final Box box;
  bool failDelete = false;
  int writes = 0;
  @override
  T get<T>(String id) => box.get(id) as T;
  @override
  List<T> getAll<T>() => box.values.cast<T>().toList();
  @override
  Future<void> addUpdate<T>(String id, T item) async {
    writes++;
    await box.put(id, item);
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('Database unavailable');
    await box.delete(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    if (failDelete) throw StateError('Database unavailable');
    await box.deleteAll(ids);
  }
}

class _FailedSnapshots extends NoteHistory {
  _FailedSnapshots({required super.box, required super.repository});
  @override
  Future<void> recordBeforeSave(NoteDto before, NoteDto after,
          {bool forceBoundary = false}) async =>
      throw StateError('History storage unavailable');
}

class _FailedPurge extends NoteHistory {
  _FailedPurge({required super.box, required super.repository});
  @override
  Future<void> purge(Iterable<String> noteIds) async =>
      throw StateError('History cleanup unavailable');
}

class _InterruptedSnapshot extends NoteHistory {
  _InterruptedSnapshot({
    required super.box,
    required super.repository,
    required this.interrupt,
  });
  final Future<void> Function() interrupt;

  @override
  Future<void> recordBeforeSave(NoteDto before, NoteDto after,
      {bool forceBoundary = false}) async {
    await super.recordBeforeSave(before, after, forceBoundary: forceBoundary);
    await interrupt();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box drafts;
  late Box notes;
  late Box versions;
  late _Database database;
  late NoteRepositoryImplementation repository;
  late NoteHistory history;
  final preferences = _PositionPreferencesPlatform();
  final originalPreferences = SharedPreferencesAsyncPlatform.instance;

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = preferences);
  tearDownAll(
      () => SharedPreferencesAsyncPlatform.instance = originalPreferences);

  setUp(() async {
    for (final id in ['note', 'removed', 'kept']) {
      await NotePositionStore.instance.remove(id);
    }
    preferences.values.clear();
    directory = await Directory.systemTemp.createTemp('onlynote-history-repo-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    drafts = await Hive.openBox(draftDatabaseBox);
    notes = await Hive.openBox('repository_notes');
    versions = await Hive.openBox('repository_history');
    database = _Database(notes);
    repository = NoteRepositoryImplementation(database);
    history = NoteHistory(box: versions, repository: repository);
    NoteHistory.configure(history);
    VoiceMemoDrafts.configure(VoiceMemoDrafts(
        journal: drafts,
        notes: repository,
        audio: AudioStorage(documentsPath: directory.path),
        readDuration: (_) async => 1000));
  });
  tearDown(() async {
    for (final id in ['note', 'removed', 'kept']) {
      await NotePositionStore.instance.remove(id);
    }
    NoteHistory.initializedInstance = null;
    VoiceMemoDrafts.initializedInstance = null;
    history.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> seedRecovery(String id) async {
    final note = NoteDto(id: id, title: 'Recovery content');
    await drafts.put(id, note);
    await drafts.put('${VoiceMemoDrafts.prefix}memo-$id', {
      'version': 1,
      'noteId': id,
      'seed': note,
      'memo': {
        'id': 'memo-$id',
        'path': 'note_audio/memo-$id.m4a',
        'durationMs': 1000,
        'createdAt': DateTime.utc(2026).toIso8601String()
      },
    });
    await drafts.put('${NotePhotoRecovery.recordKey}.deferred.$id',
        {'note': note, 'existed': false});
    await NotePositionStore.instance.saveWriting(
      id,
      NoteWritingPosition.capture(
        field: NoteWritingField.title,
        text: note.title!,
        selection: const TextSelection.collapsed(offset: 4),
      ),
    );
    await NotePositionStore.instance.saveReading(
      id,
      NoteReadingPosition.capture(text: note.title!, offset: 8),
    );
  }

  Future<void> expectPositions(String id, {required bool retained}) async {
    final positions = await NotePositionStore.instance.read(id);
    expect(positions.writing, retained ? isNotNull : isNull);
    expect(positions.reading, retained ? isNotNull : isNull);
    expect(preferences.values.containsKey(NotePositionStore.storageKey(id)),
        retained);
  }

  test('repository snapshots prior saved content before updating database',
      () async {
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Original'));
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Edited'));
    expect((await repository.getNote('note')).title, 'Edited');
    expect(history.versionsFor('note').single.note.title, 'Original');
  });

  test('history write failure leaves database note unchanged', () async {
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Original'));
    final failed = _FailedSnapshots(box: versions, repository: repository);
    addTearDown(failed.dispose);
    NoteHistory.configure(failed);
    await expectLater(
        repository.addUpdateNote(NoteDto(id: 'note', title: 'Edited')),
        throwsStateError);
    expect((await repository.getNote('note')).title, 'Original');
    expect(database.writes, 1);
  });

  test('restore cannot recreate a note removed during snapshot persistence',
      () async {
    await repository.addUpdateNote(NoteDto(id: 'removed', title: 'Original'));
    await repository.addUpdateNote(NoteDto(id: 'removed', title: 'Edited'));
    final version = history.versionsFor('removed').single;
    final interrupted = _InterruptedSnapshot(
        box: versions,
        repository: repository,
        interrupt: () => notes.delete('removed'));
    addTearDown(interrupted.dispose);
    NoteHistory.configure(interrupted);

    expect(await interrupted.restore('removed', version.id),
        NoteHistoryRestoreResult.failed);
    expect(notes.containsKey('removed'), isFalse);
    expect(database.writes, 2);
  });

  test('a note trashed during snapshot persistence keeps its trash state',
      () async {
    final original = NoteDto(id: 'note', title: 'Original');
    await repository.addUpdateNote(original);
    final deletedAt = DateTime.utc(2026).toIso8601String();
    final interrupted = _InterruptedSnapshot(
        box: versions,
        repository: repository,
        interrupt: () =>
            notes.put('note', original.copyWith(deletedAt: deletedAt)));
    addTearDown(interrupted.dispose);
    NoteHistory.configure(interrupted);

    await expectLater(
        repository.addUpdateNote(original.copyWith(title: 'Stale edit')),
        throwsStateError);
    expect((await repository.getNote('note')).deletedAt, deletedAt);
    expect(database.writes, 1);
  });

  test('failed database deletion retains history and recovery drafts',
      () async {
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Original'));
    await repository.addUpdateNote(NoteDto(id: 'note', title: 'Edited'));
    await seedRecovery('note');
    database.failDelete = true;
    await expectLater(repository.deleteNote('note'), throwsStateError);
    expect(notes.containsKey('note'), isTrue);
    expect(drafts.get('note'), isA<NoteDto>());
    expect(history.versionsFor('note').length, 1);
    await expectPositions('note', retained: true);
    expect(
        drafts.keys
            .whereType<String>()
            .any((key) => key.startsWith(VoiceMemoDrafts.prefix)),
        isTrue);
    database.failDelete = false;
    expect(await repository.recoverPendingDeletions(), isTrue);
    expect(drafts.get('note'), isA<NoteDto>());
    expect(history.versionsFor('note').length, 1);
    await expectPositions('note', retained: true);
  });

  test('successful permanent deletion purges only deleted recovery ownership',
      () async {
    for (final id in ['removed', 'kept']) {
      await repository.addUpdateNote(NoteDto(id: id, title: 'Original'));
      await repository.addUpdateNote(NoteDto(id: id, title: 'Edited'));
      await seedRecovery(id);
    }
    await repository.deleteMultiNotes(['removed']);
    expect(notes.containsKey('removed'), isFalse);
    expect(drafts.get('removed'), isNull);
    expect(history.versionsFor('removed'), isEmpty);
    expect(drafts.get('${VoiceMemoDrafts.prefix}memo-removed'), isNull);
    expect(
        drafts.get('${NotePhotoRecovery.recordKey}.deferred.removed'), isNull);
    expect(drafts.get('kept'), isA<NoteDto>());
    expect(history.versionsFor('kept').length, 1);
    await expectPositions('removed', retained: false);
    await expectPositions('kept', retained: true);
    expect(
        drafts.keys.whereType<String>().any((key) =>
            key.startsWith(NoteRepositoryImplementation.deletionPrefix)),
        isFalse);
  });

  test('startup completes deletion interrupted after database mutation',
      () async {
    await repository.addUpdateNote(NoteDto(id: 'removed', title: 'Original'));
    await repository.addUpdateNote(NoteDto(id: 'removed', title: 'Edited'));
    await seedRecovery('removed');
    await drafts.put('${NoteRepositoryImplementation.deletionPrefix}crash', {
      'version': 1,
      'ids': ['removed']
    });
    await notes.delete('removed');
    expect(await repository.recoverPendingDeletions(), isTrue);
    await HiveNoteAutosaveStore(repository, drafts).recover();
    await VoiceMemoDrafts.initializedInstance!.recover();
    expect(repository.getAllNotes(), isEmpty);
    expect(history.versionsFor('removed'), isEmpty);
    expect(drafts.values.whereType<NoteDto>(), isEmpty);
    expect(VoiceMemoDrafts.initializedInstance!.hasPending, isFalse);
    await expectPositions('removed', retained: false);
    expect(await repository.recoverPendingDeletions(), isTrue);
    await expectPositions('removed', retained: false);
  });

  test('committed deletion keeps retry intent when history purge fails',
      () async {
    await repository.addUpdateNote(NoteDto(id: 'removed', title: 'Original'));
    await repository.addUpdateNote(NoteDto(id: 'removed', title: 'Edited'));
    await seedRecovery('removed');
    final unavailable = _FailedPurge(box: versions, repository: repository);
    addTearDown(unavailable.dispose);
    NoteHistory.configure(unavailable);

    await repository.deleteNote('removed');
    expect(notes.containsKey('removed'), isFalse);
    expect(drafts.get('removed'), isNull);
    expect(history.versionsFor('removed').length, 1);
    await expectPositions('removed', retained: true);
    expect(
        drafts.keys.whereType<String>().any((key) =>
            key.startsWith(NoteRepositoryImplementation.deletionPrefix)),
        isTrue);
    expect(await repository.recoverPendingDeletions(), isFalse);

    NoteHistory.configure(history);
    expect(await repository.recoverPendingDeletions(), isTrue);
    expect(history.versionsFor('removed'), isEmpty);
    await expectPositions('removed', retained: false);
    expect(
        drafts.keys.whereType<String>().any((key) =>
            key.startsWith(NoteRepositoryImplementation.deletionPrefix)),
        isFalse);
  });
}
