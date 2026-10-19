import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_tags.dart';

class _Notes implements NoteRepository {
  final saved = <String, NoteDto>{};
  int writes = 0;

  @override
  List<NoteDto> getAllNotes() => saved.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => saved[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
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
  List<FolderDto> getAllFolders() => [FolderDto(id: 'work', name: 'Work')];
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

  Future<void> send(HomeEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    notes = _Notes();
    // Direct DTO fixtures retain legacy duplicate spellings so the count
    // itself must deduplicate them, without a read rewriting stored tags.
    notes.saved.addAll({
      'active': NoteDto(
          id: 'active',
          title: 'Current project',
          folderId: 'work',
          tags: ['Work', ' WORK ', 'Work\tMeetings', 'work   meetings']),
      'other-folder':
          NoteDto(id: 'other-folder', title: 'Unfiled project', tags: ['work']),
      'archived': NoteDto(
          id: 'archived',
          title: 'Old project',
          isArchived: true,
          tags: ['work', 'Research']),
      'personal':
          NoteDto(id: 'personal', title: 'Personal', tags: ['Personal']),
      'trash': NoteDto(
          id: 'trash',
          title: 'Removed project',
          isArchived: true,
          deletedAt: DateTime.utc(2026).toIso8601String(),
          tags: ['Work', ' WORK ', 'Removed']),
      'other-trash': NoteDto(
          id: 'other-trash',
          title: 'Removed unfiled note',
          deletedAt: DateTime.utc(2026, 2).toIso8601String(),
          tags: ['work']),
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
    expect(bloc.tagUsageCounts, isEmpty);
    await send(const HomeEvent.getAllNotes());
  });
  tearDown(() => bloc.close());

  test('catalog counts active and archived notes once per normalized tag', () {
    expect(bloc.tagUsageCounts,
        {'work': 3, 'work meetings': 1, 'research': 1, 'personal': 1});
    expect(
        bloc.state.mapOrNull(
            loaded: (state) => state.availableTags.map(tagKey).toSet()),
        bloc.tagUsageCounts.keys.toSet());
    expect(notes.saved['active']!.tags,
        ['Work', ' WORK ', 'Work\tMeetings', 'work   meetings']);
    expect(notes.writes, 0);
  });

  test('search, folder, filters, selection and archive scope keep counts',
      () async {
    final original = bloc.tagUsageCounts;
    for (final event in [
      const HomeEvent.selectFolder('work'),
      const HomeEvent.searchChanged('no matching notes'),
      const HomeEvent.filtersChanged({NoteSearchFilter.recordings}),
      const HomeEvent.tagsChanged({'Missing selected tag'}),
      const HomeEvent.showArchive(true),
      const HomeEvent.includeArchived(true),
    ]) {
      await send(event);
      expect(bloc.tagUsageCounts, original);
    }
    expect(bloc.state.mapOrNull(loaded: (state) => state.notes), isEmpty);
    expect(notes.writes, 0);
  });

  test('Trash uses its own catalog across folders and ignores filters',
      () async {
    await send(const HomeEvent.showTrash(true));
    expect(bloc.tagUsageCounts, {'work': 2, 'removed': 1});
    await send(const HomeEvent.searchChanged('no matching notes'));
    await send(const HomeEvent.filtersChanged({NoteSearchFilter.recordings}));
    await send(const HomeEvent.tagsChanged({'Missing'}));
    await send(const HomeEvent.selectFolder('work', preserveScope: true));
    expect(bloc.tagUsageCounts, {'work': 2, 'removed': 1});
    expect(bloc.state.mapOrNull(loaded: (state) => state.notes), isEmpty);
    await send(const HomeEvent.showTrash(false));
    expect(bloc.tagUsageCounts['work'], 3);
    expect(bloc.tagUsageCounts, isNot(contains('removed')));
    expect(notes.writes, 0);
  });

  test('count snapshots are immutable and refresh without writing notes',
      () async {
    final original = bloc.tagUsageCounts;
    expect(() => original['work'] = 99, throwsUnsupportedError);
    notes.saved['active'] = notes.saved['active']!.copyWith(tags: ['New']);
    await send(const HomeEvent.getAllNotes());
    expect(bloc.tagUsageCounts,
        {'new': 1, 'work': 2, 'research': 1, 'personal': 1});
    expect(original['work'], 3);
    expect(original, isNot(contains('new')));
    notes.saved.clear();
    await send(const HomeEvent.getAllNotes());
    expect(bloc.tagUsageCounts, isEmpty);
    expect(notes.writes, 0);
  });
}
