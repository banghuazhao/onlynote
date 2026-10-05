part of 'home_bloc.dart';

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.updateTodo({
    required String noteId,
    required String todoId,
    bool? completed,
    Completer<HomeChecklistResult>? completion,
  }) = _UpdateTodo;
  const factory HomeEvent.getAllNotes() = _GetAllNotes;
  const factory HomeEvent.duplicateNote(Note note) = _DuplicateNote;
  const factory HomeEvent.reorderNotes(List<Note> notes) = _ReorderNotes;
  const factory HomeEvent.searchChanged(String query) = _SearchChanged;
  const factory HomeEvent.filtersChanged(Set<NoteSearchFilter> filters) =
      _FiltersChanged;
  const factory HomeEvent.selectFolder(String? folderId) = _SelectFolder;
  const factory HomeEvent.showTrash(bool show) = _ShowTrash;
  const factory HomeEvent.togglePin(String noteId) = _TogglePin;
  const factory HomeEvent.restoreNotes(List<String> ids) = _RestoreNotes;
  const factory HomeEvent.permanentDelete(List<String> ids) = _PermanentDelete;
  const factory HomeEvent.createFolder(String name) = _CreateFolder;
  const factory HomeEvent.renameFolder(String id, String name) = _RenameFolder;
  const factory HomeEvent.deleteFolder(String id) = _DeleteFolder;
  const factory HomeEvent.moveNoteToFolder({
    required String noteId,
    String? folderId,
  }) = _MoveNoteToFolder;
}
