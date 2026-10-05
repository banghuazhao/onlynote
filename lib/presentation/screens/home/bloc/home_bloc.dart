import 'dart:async';

import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
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
    this._updateNoteUsecase,
  ) : super(const HomeState.initial()) {
    // Refreshes and mutations share one queue. A second checklist tap reads
    // the first saved result; pin/folder changes cannot race that write.
    on<HomeEvent>(_handleEvent,
        transformer: (events, mapper) => events.asyncExpand(mapper));
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

  List<Note> _activeNotes = [];
  List<Note> _trashedNotes = [];
  List<Folder> _folders = [];
  String _searchQuery = '';
  Set<NoteSearchFilter> _filters = {};
  String? _selectedFolderId;
  bool _showTrash = false;

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
      emit(_buildLoaded());
    } else if (event is _SelectFolder) {
      _onSelectFolder(event, emit);
    } else if (event is _ShowTrash) {
      _onShowTrash(event, emit);
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
      _activeNotes = [
        if (!_activeNotes.any((note) => note.id == updated.id)) updated,
        for (final active in _activeNotes)
          if (active.id == updated.id) updated else active,
      ];
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
    final duplicated = event.note.copyWith(
      title: '${event.note.title ?? ''} ${_i10n.Copy_Suffix}',
      dateTime: DateTime.now(),
      todo: event.note.todo.map((todo) => todo.copyWith()).toList(),
      // Its own copies of the images: sharing the files would mean deleting
      // either note takes the other note's pictures with it.
      imagePaths: await ImageStorage.copyImages(event.note.imagePaths),
      isPinned: false,
      deletedAt: null,
    );

    final failureOrSuccess = await _addNoteUsecase(duplicated);

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
    for (final snapshot in event.notes) {
      if (snapshot.id == null) continue;
      final fetched = await _getNoteUsecase(snapshot.id!);
      final note = fetched.fold<Note?>((_) => null, (note) => note);
      if (note == null || note.isDeleted) continue;
      latest.add(note);
    }
    emit(_buildLoaded(overrideVisible: latest));

    // A drag snapshot can predate a queued checkbox change. Apply ordering to
    // freshly read notes so the drag never restores an old completion value.
    final failureOrSuccess = await _reorderNotesUsecase(latest);

    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (_) => null,
    );
  }

  void _onSearchChanged(_SearchChanged event, Emitter<HomeState> emit) {
    _searchQuery = event.query;
    emit(_buildLoaded());
  }

  void _onSelectFolder(_SelectFolder event, Emitter<HomeState> emit) {
    _selectedFolderId = event.folderId;
    _showTrash = false;
    emit(_buildLoaded());
  }

  void _onShowTrash(_ShowTrash event, Emitter<HomeState> emit) {
    _showTrash = event.show;
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
    final failureOrSuccess = await _createFolderUsecase(event.name);
    failureOrSuccess.fold(
      (error) => getIt<AppRouter>()
          .context
          .showToast('${error.message}', isError: true),
      (id) {
        _selectedFolderId = id;
        _showTrash = false;
        getIt<AppRouter>().context.showToast(_i10n.Folder_Created);
      },
    );
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
    Iterable<Note> notes = _showTrash ? _trashedNotes : _activeNotes;

    if (!_showTrash && _selectedFolderId != null) {
      notes = notes.where((n) => n.folderId == _selectedFolderId);
    }

    return notes
        .where((note) => matchesNoteSearch(note, _searchQuery, _filters,
            hasReminder: ReminderData.shared.getCurrentReminder(note) != null))
        .toList();
  }
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
