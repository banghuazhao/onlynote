part of 'home_bloc.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded({
    required List<Note> notes,
    required List<Folder> folders,
    @Default('') String searchQuery,
    @Default(<NoteSearchFilter>{}) Set<NoteSearchFilter> filters,
    String? selectedFolderId,
    @Default(false) bool showTrash,
    @Default(false) bool showArchive,
    @Default(false) bool includeArchived,
    @Default(0) int archiveCount,
    @Default(<String>{}) Set<String> selectedTags,
    @Default(<String>[]) List<String> availableTags,
    @Default(<SavedNoteView>[]) List<SavedNoteView> savedViews,
    String? selectedViewId,
    @Default(NoteSortOrder.manual) NoteSortOrder sortOrder,
    @Default(0) int trashCount,

    /// Active notes per folder id, for the folder picker. Counts ignore the
    /// current search so the picker always shows what each folder holds, not
    /// what happens to match right now.
    @Default(<String, int>{}) Map<String, int> folderCounts,
    @Default(0) int allNotesCount,
  }) = _Loaded;
  const factory HomeState.error(String? message) = _Error;
}
