import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
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
  ) : super(const HomeState.initial()) {
    on<_GetAllNotes>(_onGetAllNotes);
    on<_DuplicateNote>(_onDuplicateNote);
    on<_ReorderNotes>(_onReorderNotes);
    on<_SearchChanged>(_onSearchChanged);
    on<_SelectFolder>(_onSelectFolder);
    on<_ShowTrash>(_onShowTrash);
    on<_TogglePin>(_onTogglePin);
    on<_RestoreNotes>(_onRestoreNotes);
    on<_PermanentDelete>(_onPermanentDelete);
    on<_CreateFolder>(_onCreateFolder);
    on<_RenameFolder>(_onRenameFolder);
    on<_DeleteFolder>(_onDeleteFolder);
    on<_MoveNoteToFolder>(_onMoveNoteToFolder);
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

  List<Note> _activeNotes = [];
  List<Note> _trashedNotes = [];
  List<Folder> _folders = [];
  String _searchQuery = '';
  String? _selectedFolderId;
  bool _showTrash = false;

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
    emit(_buildLoaded(overrideVisible: event.notes));

    final failureOrSuccess = await _reorderNotesUsecase(event.notes);

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
      (_) => getIt<AppRouter>().context.showToast(_i10n.Notes_Restored),
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
      (_) => getIt<AppRouter>()
          .context
          .showToast(_i10n.Notes_Permanently_Deleted),
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
      selectedFolderId: _selectedFolderId,
      showTrash: _showTrash,
      trashCount: _trashedNotes.length,
    );
  }

  List<Note> _visibleNotes() {
    Iterable<Note> notes = _showTrash ? _trashedNotes : _activeNotes;

    if (!_showTrash && _selectedFolderId != null) {
      notes = notes.where((n) => n.folderId == _selectedFolderId);
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      notes = notes.where((n) => _matchesSearch(n, query));
    }

    return notes.toList();
  }

  bool _matchesSearch(Note note, String query) {
    if ((note.title ?? '').toLowerCase().contains(query)) return true;
    if ((note.description ?? '').toLowerCase().contains(query)) return true;
    for (final todo in note.todo) {
      if ((todo.title ?? '').toLowerCase().contains(query)) return true;
    }
    return false;
  }
}
