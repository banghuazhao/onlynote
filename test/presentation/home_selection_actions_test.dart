import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/services/note_tags.dart';

class _Notes implements NoteRepository {
  final saved = <String, NoteDto>{};
  final writes = <String>[];

  /// Ids whose write fails, standing in for a storage error.
  final failing = <String>{};

  @override
  List<NoteDto> getAllNotes() => saved.values.toList();
  @override
  Future<NoteDto> getNote(String id) async {
    final note = saved[id];
    if (note == null) throw StateError('missing note');
    return note;
  }

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (failing.contains(note.id)) throw StateError('write failed');
    writes.add(note.id!);
    saved[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => saved.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      saved.remove(id);
    }
  }
}

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => [
        FolderDto(id: 'work', name: 'Work'),
        FolderDto(id: 'personal', name: 'Personal'),
      ];
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

void main() {
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });

  late _Notes notes;
  late HomeBloc bloc;

  Note? stored(String id) => notes.saved[id]?.toDomain();

  setUp(() async {
    notes = _Notes();
    notes.saved.addAll({
      'first': NoteDto.fromNote(Note(
          id: 'first',
          title: 'First',
          folderId: 'work',
          tags: ['Research'],
          todo: [Todo(id: 'task-1', title: 'Review release')])),
      'second': NoteDto.fromNote(
          Note(id: 'second', title: 'Second', isPinned: true)),
      'third': NoteDto.fromNote(
          Note(id: 'third', title: 'Third', folderId: 'personal')),
    });
    final folders = _Folders();
    bloc = HomeBloc(
      ShowAllNotesUsecase(notes, folders),
      AddNoteUsecase(notes),
      ReorderNotesUsecase(notes),
      TogglePinUsecase(notes),
      RestoreNotesUsecase(notes),
      PermanentDeleteNotesUsecase(notes),
      CreateFolderUsecase(folders),
      RenameFolderUsecase(folders),
      DeleteFolderUsecase(folders, notes),
      MoveNoteToFolderUsecase(notes),
      GetNoteUsecase(notes),
      UpdateNoteUsecase(notes),
    );
    bloc.add(const HomeEvent.getAllNotes());
    await Future<void>.delayed(Duration.zero);
    notes.writes.clear();
  });
  tearDown(() => bloc.close());

  group('moveNotesToFolder', () {
    test('leaves notes already in the chosen folder unwritten', () async {
      final result = await bloc.moveNotesToFolder(['first', 'second'], 'work');

      expect(result.error, isNull);
      expect(result.changed, 1);
      expect(notes.writes, ['second']);
    });

    test('moves every selected note and reports one count', () async {
      final result = await bloc.moveNotesToFolder(['first', 'third'], null);

      expect(result.error, isNull);
      expect(result.changed, 2);
      expect(stored('first')!.folderId, isNull);
      expect(stored('third')!.folderId, isNull);
      expect(
          bloc.state.mapOrNull(loaded: (state) => state.folderCounts), isEmpty);
    });

    test('moves into a folder and refreshes its count', () async {
      final result = await bloc.moveNotesToFolder(['second', 'third'], 'work');

      expect(result.changed, 2);
      expect(stored('second')!.folderId, 'work');
      expect(bloc.state.mapOrNull(loaded: (state) => state.folderCounts),
          {'work': 3});
    });

    test('reports a failed note without stopping the others', () async {
      notes.failing.add('third');

      final result = await bloc.moveNotesToFolder(['first', 'third'], null);

      expect(result.changed, 1);
      expect(result.error, isNotNull);
      expect(stored('first')!.folderId, isNull);
      expect(stored('third')!.folderId, 'personal');
    });
  });

  group('setPinnedNotes', () {
    test('pins a mixed selection instead of flipping it apart', () async {
      final result = await bloc.setPinnedNotes(['first', 'second'], true);

      expect(result.changed, 1);
      expect(stored('first')!.isPinned, isTrue);
      expect(stored('second')!.isPinned, isTrue);
      // The already-pinned note is left alone rather than written again.
      expect(notes.writes, ['first']);
    });

    test('unpins the whole selection', () async {
      await bloc.setPinnedNotes(['first', 'second'], true);
      final result = await bloc.setPinnedNotes(['first', 'second'], false);

      expect(result.changed, 2);
      expect(stored('first')!.isPinned, isFalse);
      expect(stored('second')!.isPinned, isFalse);
    });

    test('pinned notes lead the library after the change', () async {
      await bloc.setPinnedNotes(['second'], false);
      expect(
          bloc.state.mapOrNull(loaded: (state) => state.notes.first.isPinned),
          isFalse);

      await bloc.setPinnedNotes(['third'], true);

      expect(bloc.state.mapOrNull(loaded: (state) => state.notes.first.id),
          'third');
    });

    test('a missing note is reported and the rest still change', () async {
      final result = await bloc.setPinnedNotes(['first', 'gone'], true);

      expect(result.changed, 1);
      expect(result.error, isNotNull);
      expect(stored('first')!.isPinned, isTrue);
    });
  });

  group('addTagsToNotes', () {
    test('adds tags while keeping the tags each note already holds', () async {
      final result =
          await bloc.addTagsToNotes(['first', 'second'], ['Release']);

      expect(result.error, isNull);
      expect(result.changed, 2);
      expect(stored('first')!.tags, ['Research', 'Release']);
      expect(stored('second')!.tags, ['Release']);
    });

    test('leaves a note that already carries the tag unwritten', () async {
      final result = await bloc.addTagsToNotes(['first'], ['research']);

      expect(result.changed, 0);
      expect(result.error, isNull);
      expect(notes.writes, isEmpty);
      // The note keeps its own spelling; the library treats them as one tag.
      expect(stored('first')!.tags, ['Research']);
    });

    test('keeps unrelated note content, including checklist items', () async {
      await bloc.addTagsToNotes(['first'], ['Release']);

      final note = stored('first')!;
      expect(note.title, 'First');
      expect(note.todo.map((todo) => todo.title), ['Review release']);
      expect(note.folderId, 'work');
    });

    test('reports notes already holding the tag limit', () async {
      notes.saved['full'] = NoteDto.fromNote(Note(
          id: 'full',
          title: 'Full',
          tags: [for (var i = 0; i < maxNoteTags; i++) 'tag$i']));
      bloc.add(const HomeEvent.getAllNotes());
      await Future<void>.delayed(Duration.zero);

      final result = await bloc.addTagsToNotes(['first', 'full'], ['Release']);

      expect(result.changed, 1);
      expect(result.skipped, 1);
      expect(result.error, isNull);
      expect(stored('full')!.tags.length, maxNoteTags);
      expect(stored('full')!.tags, isNot(contains('Release')));
    });

    test('new tags join the library catalog once saved', () async {
      await bloc.addTagsToNotes(['second'], ['Release']);

      expect(
          bloc.state.mapOrNull(
              loaded: (state) => state.availableTags.map(tagKey).toSet()),
          {'research', 'release'});
      expect(bloc.tagUsageCounts['release'], 1);
    });

    test('a missing note is reported and the rest still change', () async {
      final result =
          await bloc.addTagsToNotes(['first', 'gone'], ['Release']);

      expect(result.changed, 1);
      expect(result.error, isNotNull);
      expect(stored('first')!.tags, ['Research', 'Release']);
    });
  });

  test('a closed bloc reports failure instead of throwing', () async {
    await bloc.close();

    expect((await bloc.moveNotesToFolder(['first'], null)).error, isNotNull);
    expect((await bloc.setPinnedNotes(['first'], true)).error, isNotNull);
    expect((await bloc.addTagsToNotes(['first'], ['Release'])).error, isNotNull);
    expect(notes.writes, isEmpty);
  });
}
