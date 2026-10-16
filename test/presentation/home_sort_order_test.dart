import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_sort_settings.dart';
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

import '../support/memory_preferences.dart';

class _Notes implements NoteRepository {
  final saved = <String, NoteDto>{};
  @override
  List<NoteDto> getAllNotes() => saved.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => saved[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async => saved[note.id!] = note;
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

/// Storage that refuses writes, to prove a lost preference never costs the
/// user the order they just chose.
class _UnwritablePreferences extends MemoryPreferences {
  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('Preferences unavailable');
}

List<String> visibleIds(HomeBloc bloc) => bloc.state
    .maybeMap(
        loaded: (state) => state.notes,
        orElse: () => throw StateError('Not loaded'))
    .map((note) => note.id!)
    .toList();

NoteSortOrder currentOrder(HomeBloc bloc) => bloc.state.maybeMap(
    loaded: (state) => state.sortOrder,
    orElse: () => throw StateError('Not loaded'));

void main() {
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });

  late _Notes notes;
  late _Folders folders;
  late MemoryPreferences preferences;
  late AppSortSettings settings;
  late HomeBloc bloc;

  Future<void> send(HomeEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  Future<HomeBloc> build({MemoryPreferences? store}) async {
    preferences = store ?? MemoryPreferences();
    settings = AppSortSettings(preferences: preferences);
    await settings.load();
    final created = HomeBloc(
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
      sortSettings: settings,
    );
    bloc = created;
    await send(const HomeEvent.getAllNotes());
    return created;
  }

  setUp(() async {
    notes = _Notes();
    folders = _Folders();
    notes.saved.addAll({
      // Dragged into an order that contradicts both dates and titles, so every
      // mode below is distinguishable from the manual one.
      'beta': NoteDto.fromNote(Note(
          id: 'beta',
          title: 'Beta',
          sortOrder: 1,
          dateTime: DateTime(2026, 3, 1),
          folderId: 'work',
          tags: ['Work'])),
      'alpha': NoteDto.fromNote(Note(
          id: 'alpha',
          title: 'Alpha',
          sortOrder: 2,
          dateTime: DateTime(2026, 1, 1),
          todo: [Todo(id: 'task', title: 'Open task')])),
      'gamma': NoteDto.fromNote(Note(
          id: 'gamma',
          title: 'Gamma',
          sortOrder: 3,
          dateTime: DateTime(2026, 2, 1),
          folderId: 'work')),
      'trashed-old': NoteDto.fromNote(Note(
          id: 'trashed-old',
          title: 'Aaa removed',
          deletedAt: DateTime(2026, 1, 1))),
      'trashed-new': NoteDto.fromNote(Note(
          id: 'trashed-new',
          title: 'Zzz removed',
          deletedAt: DateTime(2026, 5, 1))),
    });
    await build();
  });
  tearDown(() => bloc.close());

  test('manual order is the default and keeps the dragged arrangement', () {
    expect(currentOrder(bloc), NoteSortOrder.manual);
    expect(visibleIds(bloc), ['beta', 'alpha', 'gamma']);
  });

  test('each order rearranges the library and is stored for next launch',
      () async {
    await send(const HomeEvent.sortChanged(NoteSortOrder.titleAsc));
    expect(visibleIds(bloc), ['alpha', 'beta', 'gamma']);
    expect(preferences.values[AppSortSettings.storageKey], 'titleAsc');

    await send(const HomeEvent.sortChanged(NoteSortOrder.modifiedNewest));
    expect(visibleIds(bloc), ['beta', 'gamma', 'alpha']);

    await send(const HomeEvent.sortChanged(NoteSortOrder.modifiedOldest));
    expect(visibleIds(bloc), ['alpha', 'gamma', 'beta']);
    expect(preferences.values[AppSortSettings.storageKey], 'modifiedOldest');

    await send(const HomeEvent.sortChanged(NoteSortOrder.manual));
    expect(visibleIds(bloc), ['beta', 'alpha', 'gamma']);
  });

  test('a stored order is applied to the first loaded library', () async {
    await bloc.close();
    final store = MemoryPreferences();
    store.values[AppSortSettings.storageKey] = 'titleDesc';
    await build(store: store);
    expect(currentOrder(bloc), NoteSortOrder.titleDesc);
    expect(visibleIds(bloc), ['gamma', 'beta', 'alpha']);
  });

  test('an unreadable stored order falls back to the familiar manual order',
      () async {
    await bloc.close();
    final store = MemoryPreferences();
    store.values[AppSortSettings.storageKey] = 'sortedByVibes';
    await build(store: store);
    expect(currentOrder(bloc), NoteSortOrder.manual);
    expect(visibleIds(bloc), ['beta', 'alpha', 'gamma']);
  });

  test('a failed write still applies the order on screen', () async {
    await bloc.close();
    await build(store: _UnwritablePreferences());
    await send(const HomeEvent.sortChanged(NoteSortOrder.titleAsc));
    expect(currentOrder(bloc), NoteSortOrder.titleAsc);
    expect(visibleIds(bloc), ['alpha', 'beta', 'gamma']);
  });

  test('pinning still floats a note above the chosen order', () async {
    await send(const HomeEvent.sortChanged(NoteSortOrder.titleAsc));
    await send(const HomeEvent.togglePin('gamma'));
    // Pinning writes the note and the library reloads, as Home does on focus.
    await send(const HomeEvent.getAllNotes());
    expect(visibleIds(bloc), ['gamma', 'alpha', 'beta']);
  });

  test('the order survives search, filter, folder and tag changes', () async {
    await send(const HomeEvent.sortChanged(NoteSortOrder.modifiedOldest));
    await send(const HomeEvent.searchChanged('a'));
    expect(visibleIds(bloc), ['alpha', 'gamma', 'beta']);
    await send(const HomeEvent.searchChanged(''));
    await send(const HomeEvent.selectFolder('work'));
    expect(visibleIds(bloc), ['gamma', 'beta']);
    await send(const HomeEvent.tagsChanged({'work'}));
    expect(visibleIds(bloc), ['beta']);
    expect(currentOrder(bloc), NoteSortOrder.modifiedOldest);
  });

  test('sorting keeps the applied saved view selected', () async {
    final view = SavedNoteView(
        id: 'view', name: 'Work', filters: {NoteSearchFilter.pinned});
    await send(HomeEvent.savedViewsChanged([view]));
    await send(HomeEvent.applySavedView(view));
    await send(const HomeEvent.sortChanged(NoteSortOrder.titleAsc));
    // Sorting arranges what the view already selected, so it is not a
    // departure from that view the way changing a filter is.
    expect(
        bloc.state.maybeMap(
            loaded: (state) => state.selectedViewId, orElse: () => 'missing'),
        'view');
  });

  test('Trash keeps most recently deleted first under any order', () async {
    await send(const HomeEvent.sortChanged(NoteSortOrder.titleAsc));
    await send(const HomeEvent.showTrash(true));
    expect(visibleIds(bloc), ['trashed-new', 'trashed-old']);
    await send(const HomeEvent.sortChanged(NoteSortOrder.modifiedOldest));
    expect(visibleIds(bloc), ['trashed-new', 'trashed-old']);
  });

  test('a drag under another order saves it and returns to manual', () async {
    await send(const HomeEvent.sortChanged(NoteSortOrder.titleAsc));
    expect(visibleIds(bloc), ['alpha', 'beta', 'gamma']);
    final dragged = bloc.state.maybeMap(
        loaded: (state) => state.notes.reversed.toList(),
        orElse: () => throw StateError('Not loaded'));
    expect(await bloc.reorderNotes(dragged), isNull);
    // Dragging is only meaningful in manual order; the drop switches back
    // instead of saving an arrangement the grid would re-sort away.
    expect(currentOrder(bloc), NoteSortOrder.manual);
    expect(visibleIds(bloc), ['gamma', 'beta', 'alpha']);
    expect(preferences.values[AppSortSettings.storageKey], 'manual');
  });
}
