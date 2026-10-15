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
  const factory HomeEvent.reorderNotes(List<Note> notes,
      {Completer<String?>? completion}) = _ReorderNotes;
  const factory HomeEvent.searchChanged(String query) = _SearchChanged;
  const factory HomeEvent.filtersChanged(Set<NoteSearchFilter> filters) =
      _FiltersChanged;
  const factory HomeEvent.removeFilter(NoteSearchFilter filter) = _RemoveFilter;
  const factory HomeEvent.selectFolder(String? folderId,
      {@Default(false) bool preserveScope}) = _SelectFolder;
  const factory HomeEvent.showTrash(bool show) = _ShowTrash;
  const factory HomeEvent.showArchive(bool show) = _ShowArchive;
  const factory HomeEvent.includeArchived(bool include) = _IncludeArchived;
  const factory HomeEvent.removeIncludeArchived() = _RemoveIncludeArchived;
  const factory HomeEvent.tagsChanged(Set<String> tags) = _TagsChanged;
  const factory HomeEvent.removeTag(String tag) = _RemoveTag;
  const factory HomeEvent.sortChanged(NoteSortOrder order) = _SortChanged;
  const factory HomeEvent.savedViewsChanged(List<SavedNoteView> views) =
      _SavedViewsChanged;
  const factory HomeEvent.applySavedView(SavedNoteView view) = _ApplySavedView;
  const factory HomeEvent.setArchived({
    required String noteId,
    required bool archived,
    Completer<HomeArchiveResult>? completion,
  }) = _SetArchived;
  const factory HomeEvent.setTags({
    required String noteId,
    required List<String> tags,
    Completer<String?>? completion,
  }) = _SetTags;
  const factory HomeEvent.setCardStyle({
    required String noteId,
    required NoteCardStyle style,
    Color? color,
    @Default(false) bool updateColor,
    Completer<String?>? completion,
  }) = _SetCardStyle;
  const factory HomeEvent.togglePin(String noteId) = _TogglePin;
  const factory HomeEvent.restoreNotes(List<String> ids) = _RestoreNotes;
  const factory HomeEvent.permanentDelete(List<String> ids) = _PermanentDelete;
  const factory HomeEvent.createFolder(String name,
      {Completer<String?>? completion}) = _CreateFolder;
  const factory HomeEvent.renameFolder(String id, String name) = _RenameFolder;
  const factory HomeEvent.deleteFolder(String id) = _DeleteFolder;
  const factory HomeEvent.moveNoteToFolder({
    required String noteId,
    String? folderId,
  }) = _MoveNoteToFolder;
}
