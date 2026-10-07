import 'dart:async';
import 'dart:ui' show Color;
import 'package:onlynote/Tools/widget_commands.dart';

import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/photo_search_index.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/note_archive.dart';
import 'package:onlynote/services/note_tags.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/toast.dart';

part 'home_bloc.freezed.dart';
part 'home_event.dart';
part 'home_state.dart';

final S _i10n = locator<S>();

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._showNotesUsecase,
    this._addNoteUsecase,
    this._reorderNotesUsecase,
    this._togglePinUsecase,
    this._restoreNotesUsecase,
    this._permanentDeleteNotesUsecase,
    this._createFolderUsecase,
    this._renameFolderUsecase,
    this._deleteFolderUsecase,
    this._moveNoteToFolderUsecase,
    this._getNoteUsecase,
    this._updateNoteUsecase, {
    @ignoreParam PremiumAccess? premiumAccess,
  })  : premiumAccess = premiumAccess ?? PremiumAccess.instance,
        super(const HomeState.initial()) {
    // Refreshes and mutations share one queue. A second checklist tap reads
    // the first saved result; pin/folder changes cannot race that write.
    on<HomeEvent>(_handleEvent,
        transformer: (events, mapper) => events.asyncExpand(mapper));
    _photoSearchIndex = PhotoSearchIndex.initializedInstance;
    _photoSearchIndex?.addListener(_photoSearchUpdated);
  }

  final ShowAllNotesUsecase _showNotesUsecase;
  final AddNoteUsecase _addNoteUsecase;
  final ReorderNotesUsecase _reorderNotesUsecase;
  final TogglePinUsecase _togglePinUsecase;
  final RestoreNotesUsecase _restoreNotesUsecase;
  final PermanentDeleteNotesUsecase _permanentDeleteNotesUsecase;
  final CreateFolderUsecase _createFolderUsecase;
  final RenameFolderUsecase _renameFolderUsecase;
  final DeleteFolderUsecase _deleteFolderUsecase;
  final MoveNoteToFolderUsecase _moveNoteToFolderUsecase;
  final GetNoteUsecase _getNoteUsecase;
  final UpdateNoteUsecase _updateNoteUsecase;
  final PremiumAccess premiumAccess;
  late final PhotoSearchIndex? _photoSearchIndex;

  void _photoSearchUpdated() {
    // Reapply the active query as recognition completes, preserving every
    // folder, tag and saved-view filter. No refresh is needed for plain Home.
    if (!isClosed && _searchQuery.trim().isNotEmpty) {
      add(const HomeEvent.getAllNotes());
    }
  }

  @override
  Future<void> close() {
    _photoSearchIndex?.removeListener(_photoSearchUpdated);
    return super.close();
  }

  List<Note> _activeNotes = [];
  List<Note> _trashedNotes = [];
  List<Note> _archivedNotes = [];
  List<Folder> _folders = [];
  String _searchQuery = '';
  Set<NoteSearchFilter> _filters = {};
  String? _selectedFolderId;
  bool _showTrash = false;
  bool _showArchive = false;
  bool _includeArchived = false;
  Set<String> _selectedTags = {};
  List<SavedNoteView> _savedViews = [];
  String? _selectedViewId;

  Future<String?> createFolder(String name) {
    if (isClosed) return Future.value(_i10n.Failed_to_save_folder);
    final completion = Completer<String?>();
    add(HomeEvent.createFolder(name, completion: completion));
    return completion.future;
  }

  Future<HomeArchiveResult> setArchived(String noteId, bool archived) {
    if (isClosed) {
      return Future.value(HomeArchiveResult(
          error: _i10n.Failed_to_Update_note_please_try_again));
    }
    final completion = Completer<HomeArchiveResult>();
    add(HomeEvent.setArchived(
        noteId: noteId, archived: archived, completion: completion));
    return completion.future;
  }

  Future<String?> setTags(String noteId, List<String> tags) {
    if (isClosed) {
      return Future.value(_i10n.Failed_to_Update_note_please_try_again);
    }
    final completion = Completer<String?>();
    add(HomeEvent.setTags(
        noteId: noteId, tags: List.of(tags), completion: completion));
    return completion.future;
  }

  Future<String?> setCardStyle(String noteId, NoteCardStyle style) {
    if (isClosed) {
      return Future.value(_i10n.Card_Style_Save_Failed);
    }
    final completion = Completer<String?>();
    add(HomeEvent.setCardStyle(
        noteId: noteId, style: style, completion: completion));
    return completion.future;
  }

  Future<String?> setCardAppearance(
      String noteId, NoteCardStyle style, Color? color) {
    if (isClosed) return Future.value(_i10n.Card_Style_Save_Failed);
    final completion = Completer<String?>();
    add(HomeEvent.setCardStyle(
        noteId: noteId,
        style: style,
        color: color,
        updateColor: true,
        completion: completion));
    return completion.future;
  }

  Future<String?> reorderNotes(List<Note> notes) {
    if (isClosed) return Future.value(_i10n.Reorder_Save_Failed);
    final completion = Completer<String?>();
    add(HomeEvent.reorderNotes(List.of(notes), completion: completion));
    return completion.future;
  }

  Future<HomeChecklistResult> toggleTodo({
    required String noteId,
    required String todoId,
  }) =>
      _changeTodo(noteId: noteId, todoId: todoId);

  /// Undo sets the affected item explicitly, leaving all other changes intact.
  Future<HomeChecklistResult> setTodoCompleted({
    required String noteId,
    required String todoId,
    required bool completed,
  }) =>
      _changeTodo(noteId: noteId, todoId: todoId, completed: completed);

  Future<HomeChecklistResult> _changeTodo({
    required String noteId,
    required String todoId,
    bool? completed,
  }) {
    if (isClosed) {
      return Future.value(
          HomeChecklistResult(error: _i10n.Checklist_Item_Unavailable));
    }
    final completion = Completer<HomeChecklistResult>();
    add(HomeEvent.updateTodo(
        noteId: noteId,
        todoId: todoId,
        completed: completed,
        completion: completion));
    return completion.future;
  }

  Future<void> _handleEvent(HomeEvent event, Emitter<HomeState> emit) async {
    if (event is _GetAllNotes) {
      await _onGetAllNotes(event, emit);
    } else if (event is _DuplicateNote) {
      await _onDuplicateNote(event, emit);
    } else if (event is _ReorderNotes) {
      await _onReorderNotes(event, emit);
    } else if (event is _SearchChanged) {
      _onSearchChanged(event, emit);
    } else if (event is _FiltersChanged) {
      _filters = Set.of(event.filters);
      _selectedViewId = null;
      emit(_buildLoaded());
    } else if (event is _SelectFolder) {
      _onSelectFolder(event, emit);
    } else if (event is _ShowTrash) {
      _onShowTrash(event, emit);
    } else if (event is _ShowArchive) {
      _showArchive = event.show;
      _showTrash = false;
      _includeArchived = false;
      _selectedFolderId = null;
      _selectedViewId = null;
      emit(_buildLoaded());
    } else if (event is _IncludeArchived) {
      _includeArchived = event.include;
      _showArchive = false;
      _showTrash = false;
      _selectedViewId = null;
      emit(_buildLoaded());
    } else if (event is _TagsChanged) {
      _selectedTags = normalizeNoteTags(event.tags).toSet();
      _selectedViewId = null;
      emit(_buildLoaded());
    } else if (event is _SavedViewsChanged) {
      _savedViews = List.of(event.views);
      if (!_savedViews.any((view) => view.id == _selectedViewId)) {
        _selectedViewId = null;
      }
      emit(_buildLoaded());
    } else if (event is _ApplySavedView) {
      final view = event.view
          .withAvailableFolders(_folders.map((folder) => folder.id).toSet());
      _searchQuery = view.query;
      _filters = Set.of(view.filters);
      _selectedTags = view.tags.toSet();
      _selectedFolderId = view.folderId;
      _showTrash = false;
      _showArchive = view.archiveScope == NoteArchiveScope.archived;
      _includeArchived = view.archiveScope == NoteArchiveScope.all;
      _selectedViewId = view.id;
      emit(_buildLoaded());
    } else if (event is _SetArchived) {
      await _onSetArchived(event, emit);
    } else if (event is _SetTags) {
      await _onSetTags(event, emit);
    } else if (event is _SetCardStyle) {
      await _onSetCardStyle(event, emit);
    } else if (event is _TogglePin) {
      await _onTogglePin(event, emit);
    } else if (event is _RestoreNotes) {
      await _onRestoreNotes(event, emit);
    } else if (event is _PermanentDelete) {
      await _onPermanentDelete(event, emit);
    } else if (event is _CreateFolder) {
      await _onCreateFolder(event, emit);
    } else if (event is _RenameFolder) {
      await _onRenameFolder(event, emit);
    } else if (event is _DeleteFolder) {
      await _onDeleteFolder(event, emit);
    } else if (event is _MoveNoteToFolder) {
      await _onMoveNoteToFolder(event, emit);
    } else if (event is _UpdateTodo) {
      await _onUpdateTodo(event, emit);
    }
  }

  Future<void> _onUpdateTodo(_UpdateTodo event, Emitter<HomeState> emit) async {
    await WidgetCommands.initializedInstance?.importPending();
    // Cards are excerpts and may have become stale while another screen edits
    // the note. Start with the latest saved note instead of the card snapshot.
    final fetched = await _getNoteUsecase(event.noteId);
    final note = fetched.fold<Note?>((_) => null, (note) => note);
    if (note == null || note.isDeleted) {
      event.completion?.complete(HomeChecklistResult(
          error: fetched.fold((error) => error.message, (_) => null) ??
              _i10n.Checklist_Item_Unavailable));
      return;
    }
    final index = note.todo.indexWhere((todo) => todo.id == event.todoId);
    if (index < 0) {
      event.completion?.complete(
          HomeChecklistResult(error: _i10n.Checklist_Item_Unavailable));
      return;
    }
    final previous = note.todo[index].completed;
    final completed = event.completed ?? !previous;
    if (previous == completed) {
      event.completion?.complete(const HomeChecklistResult());
      return;
    }
    final todos = List<Todo>.from(note.todo);
    todos[index] = todos[index].copyWith(completed: completed);
    final updated = note.copyWith(todo: todos);
    final saved = await _updateNoteUsecase(updated);
    final error = saved.fold<String?>(
        (error) =>
            error.message ?? _i10n.Failed_to_Update_note_please_try_again,
        (_) => null);
    if (error != null) {
      event.completion?.complete(HomeChecklistResult(error: error));
      return;
    }
    if (!emit.isDone) {
      _replaceSavedNote(updated);
      emit(_buildLoaded());
    }
    event.completion?.complete(HomeChecklistResult(
        change: HomeChecklistChange(
      noteId: event.noteId,
      todoId: event.todoId,
      previousCompleted: previous,
      completed: completed,
      checklistNowComplete: updated.todo
          .where((todo) => todo.title?.trim().isNotEmpty == true)
          .every((todo) => todo.completed),
    )));
  }

  Future<void> _onGetAllNotes(
    _GetAllNotes event,
    Emitter<HomeState> emit,
  ) async {
    // Keep prior loaded UI visible while refreshing to avoid skeleton flicker.
    if (state is! _Loaded) {
      emit(const HomeState.loading());
    }

    final failureOrSuccess = await _showNotesUsecase();

    failureOrSuccess.fold((error) {
      emit(HomeState.error(error.message));
    }, (bundle) {
      _activeNotes = bundle.activeNotes;
      _trashedNotes = bundle.trashedNotes;
      _archivedNotes = bundle.archivedNotes;
      _folders = bundle.folders;
      // If selected folder was deleted, fall back to All Notes.
      if (_selectedFolderId != null &&
          !_folders.any((f) => f.id == _selectedFolderId)) {
        _selectedFolderId = null;
      }
      emit(_buildLoaded());
    });
  }

  Future<void> _onDuplicateNote(
    _DuplicateNote event,
    Emitter<HomeState> emit,
  ) async {
    final current = await _showNotesUsecase();
    final bundle = current.fold<NotesBundle?>((_) => null, (bundle) => bundle);
    if (bundle == null) {
      final context = getIt<AppRouter>().context;
      if (context.mounted) {
        context.showToast(_i10n.Failed_to_load_notes_please_try_again,
            isError: true);
      }
      return;
    }
    try {
      premiumAccess.require(PremiumFeature.notes,
          currentCount:
              bundle.activeNotes.length + bundle.archivedNotes.length);
    } on PremiumRequired {
      final context = getIt<AppRouter>().context;
      if (context.mounted) {
        context.showToast(_i10n.Premium_Note_Limit(PremiumAccess.freeNoteLimit),
            isError: true);
      }
      return;
    }
    List<VoiceMemo> audio;
    try {
      audio = await AudioStorage.instance.copyToNote(event.note.voiceMemos);
    } catch (_) {
      final context = getIt<AppRouter>().context;
      if (context.mounted) {
        context.showToast(_i10n.Voice_Save_Failed, isError: true);
      }
      return;
    }
    final images = await ImageStorage.copyImagePaths(event.note.imagePaths);
    final duplicated = event.note.copyWith(
      title: '${event.note.title ?? ''} ${_i10n.Copy_Suffix}',
      dateTime: DateTime.now(),
      todo: event.note.todo.map((todo) => todo.copyWith()).toList(),
      // Its own copies of the images: sharing the files would mean deleting
      // either note takes the other note's pictures with it.
      imagePaths: images.values.toList(),
      imageLayouts: remapNoteImageLayouts(event.note.imageLayouts, images),
      voiceMemos: audio,
      isPinned: false,
      isArchived: false,
      deletedAt: null,
      dailyNoteDateKey: null,
    );

    final failureOrSuccess = await _addNoteUsecase(duplicated);
    if (failureOrSuccess.isLeft()) {
      await AudioStorage.instance.deletePaths(audio.map((memo) => memo.path));
      await ImageStorage.deleteImages(duplicated.imagePaths);
    }

    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (_) => getIt<AppRouter>()
          .context
          .showToast(_i10n.Note_Duplicated_Successfully),
    );
  }

  Future<void> _onReorderNotes(
    _ReorderNotes event,
    Emitter<HomeState> emit,
  ) async {
    final latest = <Note>[];
    final seen = <String>{};
    for (final snapshot in event.notes) {
      if (snapshot.id == null || !seen.add(snapshot.id!)) continue;
      final fetched = await _getNoteUsecase(snapshot.id!);
      final note = fetched.fold<Note?>((_) => null, (note) => note);
      if (note == null || note.isDeleted || note.isArchived) continue;
      latest.add(note);
    }
    final ordered = [
      ...latest.where((note) => note.isPinned),
      ...latest.where((note) => !note.isPinned),
    ];
    emit(_buildLoaded(overrideVisible: ordered));

    // A drag snapshot can predate a queued checkbox change. Apply ordering to
    // freshly read notes so the drag never restores an old completion value.
    final failureOrSuccess = await _reorderNotesUsecase(ordered);
    // Replace the cached notes with their saved sort order. Otherwise a later
    // filter or checkbox event sorts the pre-drag snapshot back into place.
    await _onGetAllNotes(const _GetAllNotes(), emit);
    final error = failureOrSuccess.fold<String?>(
        (_) => _i10n.Reorder_Save_Failed, (_) => null);
    event.completion?.complete(error);
    if (error != null && event.completion == null) {
      final context = getIt<AppRouter>().context;
      if (context.mounted) context.showToast(error, isError: true);
    }
  }

  void _onSearchChanged(_SearchChanged event, Emitter<HomeState> emit) {
    _searchQuery = event.query;
    _selectedViewId = null;
    emit(_buildLoaded());
  }

  void _onSelectFolder(_SelectFolder event, Emitter<HomeState> emit) {
    _selectedFolderId = event.folderId;
    _showTrash = false;
    _showArchive = false;
    _includeArchived = false;
    _selectedViewId = null;
    emit(_buildLoaded());
  }

  void _onShowTrash(_ShowTrash event, Emitter<HomeState> emit) {
    _showTrash = event.show;
    _showArchive = false;
    _includeArchived = false;
    _selectedViewId = null;
    if (_showTrash) {
      _selectedFolderId = null;
    }
    emit(_buildLoaded());
  }

  Future<void> _onTogglePin(_TogglePin event, Emitter<HomeState> emit) async {
    final failureOrSuccess = await _togglePinUsecase(event.noteId);
    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (_) => null,
    );
  }

  Future<void> _onRestoreNotes(
    _RestoreNotes event,
    Emitter<HomeState> emit,
  ) async {
    final failureOrSuccess = await _restoreNotesUsecase(event.ids);
    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (remindersRestored) => getIt<AppRouter>().context.showToast(
          remindersRestored
              ? _i10n.Notes_Restored
              : _i10n.Restore_Reminder_Warning),
    );
  }

  Future<void> _onPermanentDelete(
    _PermanentDelete event,
    Emitter<HomeState> emit,
  ) async {
    final failureOrSuccess = await _permanentDeleteNotesUsecase(event.ids);
    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (_) =>
          getIt<AppRouter>().context.showToast(_i10n.Notes_Permanently_Deleted),
    );
  }

  Future<void> _onCreateFolder(
    _CreateFolder event,
    Emitter<HomeState> emit,
  ) async {
    // Read persisted folders inside the mutation queue. Rapid submissions and
    // folders imported while Home is open must both count toward new additions.
    final current = await _showNotesUsecase();
    final loadError =
        current.fold<String?>((error) => error.message, (_) => null);
    if (current.isLeft()) {
      final message = loadError ?? _i10n.Failed_to_save_folder;
      if (event.completion != null) {
        event.completion!.complete(message);
      } else {
        final context = getIt<AppRouter>().context;
        if (context.mounted) {
          context.showToast(message, isError: true);
        }
      }
      return;
    }
    _folders = current.fold((_) => _folders, (bundle) => bundle.folders);
    try {
      premiumAccess.require(PremiumFeature.folders,
          currentCount: _folders.length);
    } on PremiumRequired catch (error, stack) {
      if (event.completion != null) {
        event.completion!.completeError(error, stack);
      } else {
        final context = getIt<AppRouter>().context;
        if (context.mounted) {
          context.showToast(
              _i10n.Premium_Folder_Limit(PremiumAccess.freeFolderLimit),
              isError: true);
        }
      }
      return;
    }
    final failureOrSuccess = await _createFolderUsecase(event.name);
    failureOrSuccess.fold(
      (error) {
        final message = error.message ?? _i10n.Failed_to_save_folder;
        if (event.completion != null) {
          event.completion!.complete(message);
        } else {
          getIt<AppRouter>().context.showToast(message, isError: true);
        }
      },
      (id) {
        _selectedFolderId = id;
        _showTrash = false;
        _showArchive = false;
        _includeArchived = false;
        _selectedViewId = null;
        if (event.completion == null) {
          getIt<AppRouter>().context.showToast(_i10n.Folder_Created);
        }
      },
    );
    if (failureOrSuccess.isRight()) {
      await _onGetAllNotes(const _GetAllNotes(), emit);
      event.completion?.complete(null);
    }
  }

  Future<void> _onRenameFolder(
    _RenameFolder event,
    Emitter<HomeState> emit,
  ) async {
    final failureOrSuccess = await _renameFolderUsecase(
      id: event.id,
      name: event.name,
    );
    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (_) => null,
    );
  }

  Future<void> _onDeleteFolder(
    _DeleteFolder event,
    Emitter<HomeState> emit,
  ) async {
    final failureOrSuccess = await _deleteFolderUsecase(event.id);
    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (_) {
        if (_selectedFolderId == event.id) {
          _selectedFolderId = null;
        }
        getIt<AppRouter>().context.showToast(_i10n.Folder_Deleted);
      },
    );
  }

  Future<void> _onMoveNoteToFolder(
    _MoveNoteToFolder event,
    Emitter<HomeState> emit,
  ) async {
    final failureOrSuccess = await _moveNoteToFolderUsecase(
      noteId: event.noteId,
      folderId: event.folderId,
    );
    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (_) => getIt<AppRouter>().context.showToast(_i10n.Note_Moved),
    );
  }

  HomeState _buildLoaded({List<Note>? overrideVisible}) {
    return HomeState.loaded(
      notes: overrideVisible ?? _visibleNotes(),
      folders: List.unmodifiable(_folders),
      searchQuery: _searchQuery,
      filters: _filters,
      selectedFolderId: _selectedFolderId,
      showTrash: _showTrash,
      showArchive: _showArchive,
      includeArchived: _includeArchived,
      archiveCount: _archivedNotes.length,
      selectedTags: Set.unmodifiable(_selectedTags),
      availableTags: _availableTags(),
      savedViews: List.unmodifiable(_savedViews),
      selectedViewId: _selectedViewId,
      trashCount: _trashedNotes.length,
      folderCounts: _folderCounts(),
      allNotesCount: _activeNotes.length,
    );
  }

  Map<String, int> _folderCounts() {
    final counts = <String, int>{};
    for (final note in _activeNotes) {
      final folderId = note.folderId;
      if (folderId == null) continue;
      counts[folderId] = (counts[folderId] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  List<Note> _visibleNotes() {
    Iterable<Note> notes = _showTrash
        ? _trashedNotes
        : _showArchive
            ? _archivedNotes
            : _includeArchived
                ? [..._activeNotes, ..._archivedNotes]
                : _activeNotes;

    if (!_showTrash && _selectedFolderId != null) {
      notes = notes.where((n) => n.folderId == _selectedFolderId);
    }

    final visible = notes
        .where((note) =>
            _selectedTags.every((tag) =>
                note.tags.any((value) => tagKey(value) == tagKey(tag))) &&
            matchesNoteSearch(note, _searchQuery, _filters,
                photoText: _photoSearchIndex?.textsForNote(note) ?? const [],
                hasReminder:
                    ReminderData.shared.getCurrentReminder(note) != null))
        .toList();
    if (!_showTrash) visible.sort(_compareLibraryNotes);
    return visible;
  }

  int _compareLibraryNotes(Note a, Note b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    if (a.sortOrder != null && b.sortOrder != null) {
      final order = a.sortOrder!.compareTo(b.sortOrder!);
      if (order != 0) return order;
    }
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final date = (b.dateTime ?? epoch).compareTo(a.dateTime ?? epoch);
    return date != 0 ? date : (a.id ?? '').compareTo(b.id ?? '');
  }

  List<String> _availableTags() {
    final tags = <String, String>{};
    final notes =
        _showTrash ? _trashedNotes : [..._activeNotes, ..._archivedNotes];
    for (final note in notes) {
      for (final tag in note.tags) {
        tags.putIfAbsent(tagKey(tag), () => tag);
      }
    }
    final labels = tags.values.toList()
      ..sort((a, b) => tagKey(a).compareTo(tagKey(b)));
    return List.unmodifiable(labels);
  }

  void _replaceSavedNote(Note updated) {
    _activeNotes = [
      if (!updated.isArchived &&
          !_activeNotes.any((note) => note.id == updated.id))
        updated,
      for (final note in _activeNotes)
        if (note.id == updated.id && !updated.isArchived)
          updated
        else if (note.id != updated.id)
          note,
    ];
    _archivedNotes = [
      if (updated.isArchived &&
          !_archivedNotes.any((note) => note.id == updated.id))
        updated,
      for (final note in _archivedNotes)
        if (note.id == updated.id && updated.isArchived)
          updated
        else if (note.id != updated.id)
          note,
    ];
  }

  Future<void> _onSetArchived(
      _SetArchived event, Emitter<HomeState> emit) async {
    final fetched = await _getNoteUsecase(event.noteId);
    final note = fetched.fold<Note?>((_) => null, (note) => note);
    if (note == null || note.isDeleted) {
      event.completion?.complete(HomeArchiveResult(
          error: _i10n.Failed_to_Update_note_please_try_again));
      return;
    }
    if (note.isArchived == event.archived) {
      event.completion?.complete(const HomeArchiveResult());
      return;
    }
    final updated = note.copyWith(isArchived: event.archived);
    final saved = await _updateNoteUsecase(updated);
    final error = saved.fold<String?>(
        (error) =>
            error.message ?? _i10n.Failed_to_Update_note_please_try_again,
        (_) => null);
    if (error == null && !emit.isDone) {
      _replaceSavedNote(updated);
      emit(_buildLoaded());
    }
    event.completion?.complete(HomeArchiveResult(
        error: error,
        change: error == null
            ? NoteArchiveChange(
                noteId: event.noteId,
                previousArchived: note.isArchived,
                archived: event.archived)
            : null));
  }

  Future<void> _onSetTags(_SetTags event, Emitter<HomeState> emit) async {
    try {
      final tags = normalizeNoteTags(event.tags);
      final fetched = await _getNoteUsecase(event.noteId);
      final note = fetched.fold<Note?>((_) => null, (note) => note);
      if (note == null || note.isDeleted) {
        throw StateError('Note is unavailable');
      }
      final updated = note.copyWith(tags: tags);
      final saved = await _updateNoteUsecase(updated);
      final error = saved.fold<String?>(
          (error) =>
              error.message ?? _i10n.Failed_to_Update_note_please_try_again,
          (_) => null);
      if (error == null && !emit.isDone) {
        _replaceSavedNote(updated);
        emit(_buildLoaded());
      }
      event.completion?.complete(error);
    } catch (_) {
      event.completion?.complete(_i10n.Failed_to_Update_note_please_try_again);
    }
  }

  Future<void> _onSetCardStyle(
      _SetCardStyle event, Emitter<HomeState> emit) async {
    try {
      await WidgetCommands.initializedInstance?.importPending();
      final fetched = await _getNoteUsecase(event.noteId);
      final note = fetched.fold<Note?>((_) => null, (note) => note);
      if (note == null || note.isDeleted) {
        throw StateError('Note is unavailable');
      }
      if (event.style != note.cardStyle && !event.style.isDefault) {
        premiumAccess.require(PremiumFeature.individualCardStyle);
      }
      final updated = note.copyWith(
          cardStyle: event.style,
          color: event.updateColor ? event.color : note.color);
      final saved = await _updateNoteUsecase(updated);
      final error =
          saved.fold<String?>((_) => _i10n.Card_Style_Save_Failed, (_) => null);
      if (error == null && !emit.isDone) {
        _replaceSavedNote(updated);
        emit(_buildLoaded());
      }
      event.completion?.complete(error);
    } on PremiumRequired catch (error) {
      event.completion?.completeError(error);
    } catch (_) {
      event.completion?.complete(_i10n.Card_Style_Save_Failed);
    }
  }
}

class HomeArchiveResult {
  const HomeArchiveResult({this.change, this.error});
  final NoteArchiveChange? change;
  final String? error;
}

class HomeChecklistChange {
  const HomeChecklistChange({
    required this.noteId,
    required this.todoId,
    required this.previousCompleted,
    required this.completed,
    required this.checklistNowComplete,
  });
  final String noteId;
  final String todoId;
  final bool previousCompleted;
  final bool completed;
  final bool checklistNowComplete;
  bool get newlyCompleted => !previousCompleted && completed;
}

class HomeChecklistResult {
  const HomeChecklistResult({this.change, this.error});
  final HomeChecklistChange? change;
  final String? error;
}
