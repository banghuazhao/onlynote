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
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/saved_note_views.dart';

class _Notes implements NoteRepository {
  final saved = <String, NoteDto>{};
  bool fail = false;
  @override
  List<NoteDto> getAllNotes() => saved.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => saved[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (fail) throw StateError('Storage unavailable');
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
  final saved = <FolderDto>[FolderDto(id: 'work', name: 'Work')];
  @override
  List<FolderDto> getAllFolders() => List.of(saved);
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

List<Note> visible(HomeBloc bloc) => bloc.state.maybeMap(
    loaded: (state) => state.notes,
    orElse: () => throw StateError('Not loaded'));

void main() {
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  late _Notes notes;
  late _Folders folders;
  late HomeBloc bloc;

  Future<void> send(HomeEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    notes = _Notes();
    folders = _Folders();
    notes.saved.addAll({
      'active': NoteDto.fromNote(Note(
          id: 'active',
          title: 'Current project',
          folderId: 'work',
          tags: ['Work', 'Priority'],
          todo: [Todo(id: 'task', title: 'Follow up')])),
      'archived': NoteDto.fromNote(Note(
          id: 'archived',
          title: 'Old project',
          folderId: 'work',
          tags: ['work'],
          isArchived: true,
          isPinned: true,
          todo: [Todo(id: 'old-task', title: 'Completed', completed: true)])),
      'personal': NoteDto.fromNote(
          Note(id: 'personal', title: 'Personal', tags: ['Personal'])),
      'trash': NoteDto.fromNote(Note(
          id: 'trash',
          title: 'Removed project',
          isArchived: true,
          tags: ['Work'],
          deletedAt: DateTime.utc(2026))),
    });
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
    await send(const HomeEvent.getAllNotes());
  });
  tearDown(() => bloc.close());

  test('default library excludes archived and trashed notes from folder counts',
      () {
    expect(
        visible(bloc).map((note) => note.id).toSet(), {'active', 'personal'});
    bloc.state.mapOrNull(loaded: (state) {
      expect(state.allNotesCount, 2);
      expect(state.archiveCount, 1);
      expect(state.trashCount, 1);
      expect(state.folderCounts, {'work': 1});
    });
  });

  test('archive is separately searchable and tag filters ignore casing',
      () async {
    await send(const HomeEvent.showArchive(true));
    await send(const HomeEvent.searchChanged('Old'));
    await send(const HomeEvent.tagsChanged({' WORK '}));
    expect(visible(bloc).single.id, 'archived');
    await send(const HomeEvent.searchChanged('Current'));
    expect(visible(bloc), isEmpty);
  });

  test('include archived combines active and archived while excluding trash',
      () async {
    await send(const HomeEvent.includeArchived(true));
    expect(visible(bloc).map((note) => note.id).toSet(),
        {'active', 'archived', 'personal'});
    await send(const HomeEvent.tagsChanged({'work', 'priority'}));
    expect(visible(bloc).single.id, 'active');
  });

  test('archiving and undo use fresh content and preserve pin folder and tags',
      () async {
    notes.saved['active'] = notes.saved['active']!.copyWith(
        title: 'Edited elsewhere', isPinned: true, linkedNoteIds: ['personal']);
    final result = await bloc.setArchived('active', true);
    expect(result.error, isNull);
    expect(result.change!.previousArchived, isFalse);
    expect(visible(bloc).any((note) => note.id == 'active'), isFalse);
    final saved = notes.saved['active']!;
    expect(saved.title, 'Edited elsewhere');
    expect(saved.isPinned, isTrue);
    expect(saved.folderId, 'work');
    expect(saved.tags, ['Work', 'Priority']);
    expect(saved.linkedNoteIds, ['personal']);
    await bloc.setArchived('active', result.change!.previousArchived);
    expect(visible(bloc).firstWhere((note) => note.id == 'active').title,
        'Edited elsewhere');
  });

  test('archive save failure keeps the note and offers no Undo change',
      () async {
    notes.fail = true;
    final result = await bloc.setArchived('active', true);
    expect(result.error, isNotNull);
    expect(result.change, isNull);
    expect(visible(bloc).any((note) => note.id == 'active'), isTrue);
  });

  test('saved view applies every criterion with orphan folder fallback',
      () async {
    final view = SavedNoteView(
        id: 'saved',
        name: 'Old projects',
        query: 'Old',
        folderId: 'deleted-folder',
        tags: ['WORK'],
        filters: {NoteSearchFilter.pinned},
        archiveScope: NoteArchiveScope.archived);
    await send(HomeEvent.savedViewsChanged([view]));
    await send(HomeEvent.applySavedView(view));
    expect(visible(bloc).single.id, 'archived');
    bloc.state.mapOrNull(loaded: (state) {
      expect(state.selectedViewId, 'saved');
      expect(state.selectedFolderId, isNull);
      expect(state.showArchive, isTrue);
      expect(state.searchQuery, 'Old');
      expect(state.selectedTags, {'WORK'});
      expect(state.filters, {NoteSearchFilter.pinned});
    });
    await send(const HomeEvent.searchChanged('Current'));
    expect(
        bloc.state.mapOrNull(loaded: (state) => state.selectedViewId), isNull);
  });

  test('editing tags preserves archived scope and freshest saved note',
      () async {
    await send(const HomeEvent.showArchive(true));
    notes.saved['archived'] =
        notes.saved['archived']!.copyWith(title: 'Fresh title');
    expect(await bloc.setTags('archived', [' Research ', 'research', '项目']),
        isNull);
    expect(visible(bloc).single.title, 'Fresh title');
    expect(visible(bloc).single.isArchived, isTrue);
    expect(notes.saved['archived']!.tags, ['Research', '项目']);
    await send(const HomeEvent.tagsChanged({'research'}));
    expect(visible(bloc).single.id, 'archived');
  });

  test('checkbox action within Archive never leaks note into default Home',
      () async {
    await send(const HomeEvent.showArchive(true));
    await bloc.setTodoCompleted(
        noteId: 'archived', todoId: 'old-task', completed: false);
    expect(visible(bloc).single.isArchived, isTrue);
    await send(const HomeEvent.showArchive(false));
    expect(visible(bloc).any((note) => note.id == 'archived'), isFalse);
  });

  test('trashed or missing notes reject archive and tag edits', () async {
    expect((await bloc.setArchived('trash', true)).error, isNotNull);
    expect(await bloc.setTags('missing', ['Tag']), isNotNull);
    expect(notes.saved['trash']!.isDeleted, isTrue);
  });
}
