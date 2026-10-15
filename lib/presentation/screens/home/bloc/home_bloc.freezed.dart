// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeEventCopyWith<$Res> {
  factory $HomeEventCopyWith(HomeEvent value, $Res Function(HomeEvent) then) =
      _$HomeEventCopyWithImpl<$Res, HomeEvent>;
}

/// @nodoc
class _$HomeEventCopyWithImpl<$Res, $Val extends HomeEvent>
    implements $HomeEventCopyWith<$Res> {
  _$HomeEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$UpdateTodoImplCopyWith<$Res> {
  factory _$$UpdateTodoImplCopyWith(
          _$UpdateTodoImpl value, $Res Function(_$UpdateTodoImpl) then) =
      __$$UpdateTodoImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String noteId,
      String todoId,
      bool? completed,
      Completer<HomeChecklistResult>? completion});
}

/// @nodoc
class __$$UpdateTodoImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$UpdateTodoImpl>
    implements _$$UpdateTodoImplCopyWith<$Res> {
  __$$UpdateTodoImplCopyWithImpl(
      _$UpdateTodoImpl _value, $Res Function(_$UpdateTodoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? todoId = null,
    Object? completed = freezed,
    Object? completion = freezed,
  }) {
    return _then(_$UpdateTodoImpl(
      noteId: null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
      todoId: null == todoId
          ? _value.todoId
          : todoId // ignore: cast_nullable_to_non_nullable
              as String,
      completed: freezed == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool?,
      completion: freezed == completion
          ? _value.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as Completer<HomeChecklistResult>?,
    ));
  }
}

/// @nodoc

class _$UpdateTodoImpl implements _UpdateTodo {
  const _$UpdateTodoImpl(
      {required this.noteId,
      required this.todoId,
      this.completed,
      this.completion});

  @override
  final String noteId;
  @override
  final String todoId;
  @override
  final bool? completed;
  @override
  final Completer<HomeChecklistResult>? completion;

  @override
  String toString() {
    return 'HomeEvent.updateTodo(noteId: $noteId, todoId: $todoId, completed: $completed, completion: $completion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateTodoImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.completion, completion) ||
                other.completion == completion));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, noteId, todoId, completed, completion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateTodoImplCopyWith<_$UpdateTodoImpl> get copyWith =>
      __$$UpdateTodoImplCopyWithImpl<_$UpdateTodoImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return updateTodo(noteId, todoId, completed, completion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return updateTodo?.call(noteId, todoId, completed, completion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (updateTodo != null) {
      return updateTodo(noteId, todoId, completed, completion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return updateTodo(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return updateTodo?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (updateTodo != null) {
      return updateTodo(this);
    }
    return orElse();
  }
}

abstract class _UpdateTodo implements HomeEvent {
  const factory _UpdateTodo(
      {required final String noteId,
      required final String todoId,
      final bool? completed,
      final Completer<HomeChecklistResult>? completion}) = _$UpdateTodoImpl;

  String get noteId;
  String get todoId;
  bool? get completed;
  Completer<HomeChecklistResult>? get completion;
  @JsonKey(ignore: true)
  _$$UpdateTodoImplCopyWith<_$UpdateTodoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GetAllNotesImplCopyWith<$Res> {
  factory _$$GetAllNotesImplCopyWith(
          _$GetAllNotesImpl value, $Res Function(_$GetAllNotesImpl) then) =
      __$$GetAllNotesImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GetAllNotesImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$GetAllNotesImpl>
    implements _$$GetAllNotesImplCopyWith<$Res> {
  __$$GetAllNotesImplCopyWithImpl(
      _$GetAllNotesImpl _value, $Res Function(_$GetAllNotesImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$GetAllNotesImpl implements _GetAllNotes {
  const _$GetAllNotesImpl();

  @override
  String toString() {
    return 'HomeEvent.getAllNotes()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$GetAllNotesImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return getAllNotes();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return getAllNotes?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (getAllNotes != null) {
      return getAllNotes();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return getAllNotes(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return getAllNotes?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (getAllNotes != null) {
      return getAllNotes(this);
    }
    return orElse();
  }
}

abstract class _GetAllNotes implements HomeEvent {
  const factory _GetAllNotes() = _$GetAllNotesImpl;
}

/// @nodoc
abstract class _$$DuplicateNoteImplCopyWith<$Res> {
  factory _$$DuplicateNoteImplCopyWith(
          _$DuplicateNoteImpl value, $Res Function(_$DuplicateNoteImpl) then) =
      __$$DuplicateNoteImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Note note});

  $NoteCopyWith<$Res> get note;
}

/// @nodoc
class __$$DuplicateNoteImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$DuplicateNoteImpl>
    implements _$$DuplicateNoteImplCopyWith<$Res> {
  __$$DuplicateNoteImplCopyWithImpl(
      _$DuplicateNoteImpl _value, $Res Function(_$DuplicateNoteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? note = null,
  }) {
    return _then(_$DuplicateNoteImpl(
      null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as Note,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $NoteCopyWith<$Res> get note {
    return $NoteCopyWith<$Res>(_value.note, (value) {
      return _then(_value.copyWith(note: value));
    });
  }
}

/// @nodoc

class _$DuplicateNoteImpl implements _DuplicateNote {
  const _$DuplicateNoteImpl(this.note);

  @override
  final Note note;

  @override
  String toString() {
    return 'HomeEvent.duplicateNote(note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DuplicateNoteImpl &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode => Object.hash(runtimeType, note);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DuplicateNoteImplCopyWith<_$DuplicateNoteImpl> get copyWith =>
      __$$DuplicateNoteImplCopyWithImpl<_$DuplicateNoteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return duplicateNote(note);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return duplicateNote?.call(note);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (duplicateNote != null) {
      return duplicateNote(note);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return duplicateNote(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return duplicateNote?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (duplicateNote != null) {
      return duplicateNote(this);
    }
    return orElse();
  }
}

abstract class _DuplicateNote implements HomeEvent {
  const factory _DuplicateNote(final Note note) = _$DuplicateNoteImpl;

  Note get note;
  @JsonKey(ignore: true)
  _$$DuplicateNoteImplCopyWith<_$DuplicateNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ReorderNotesImplCopyWith<$Res> {
  factory _$$ReorderNotesImplCopyWith(
          _$ReorderNotesImpl value, $Res Function(_$ReorderNotesImpl) then) =
      __$$ReorderNotesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Note> notes, Completer<String?>? completion});
}

/// @nodoc
class __$$ReorderNotesImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$ReorderNotesImpl>
    implements _$$ReorderNotesImplCopyWith<$Res> {
  __$$ReorderNotesImplCopyWithImpl(
      _$ReorderNotesImpl _value, $Res Function(_$ReorderNotesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notes = null,
    Object? completion = freezed,
  }) {
    return _then(_$ReorderNotesImpl(
      null == notes
          ? _value._notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<Note>,
      completion: freezed == completion
          ? _value.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as Completer<String?>?,
    ));
  }
}

/// @nodoc

class _$ReorderNotesImpl implements _ReorderNotes {
  const _$ReorderNotesImpl(final List<Note> notes, {this.completion})
      : _notes = notes;

  final List<Note> _notes;
  @override
  List<Note> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  @override
  final Completer<String?>? completion;

  @override
  String toString() {
    return 'HomeEvent.reorderNotes(notes: $notes, completion: $completion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReorderNotesImpl &&
            const DeepCollectionEquality().equals(other._notes, _notes) &&
            (identical(other.completion, completion) ||
                other.completion == completion));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_notes), completion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReorderNotesImplCopyWith<_$ReorderNotesImpl> get copyWith =>
      __$$ReorderNotesImplCopyWithImpl<_$ReorderNotesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return reorderNotes(notes, completion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return reorderNotes?.call(notes, completion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (reorderNotes != null) {
      return reorderNotes(notes, completion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return reorderNotes(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return reorderNotes?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (reorderNotes != null) {
      return reorderNotes(this);
    }
    return orElse();
  }
}

abstract class _ReorderNotes implements HomeEvent {
  const factory _ReorderNotes(final List<Note> notes,
      {final Completer<String?>? completion}) = _$ReorderNotesImpl;

  List<Note> get notes;
  Completer<String?>? get completion;
  @JsonKey(ignore: true)
  _$$ReorderNotesImplCopyWith<_$ReorderNotesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchChangedImplCopyWith<$Res> {
  factory _$$SearchChangedImplCopyWith(
          _$SearchChangedImpl value, $Res Function(_$SearchChangedImpl) then) =
      __$$SearchChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query});
}

/// @nodoc
class __$$SearchChangedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$SearchChangedImpl>
    implements _$$SearchChangedImplCopyWith<$Res> {
  __$$SearchChangedImplCopyWithImpl(
      _$SearchChangedImpl _value, $Res Function(_$SearchChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
  }) {
    return _then(_$SearchChangedImpl(
      null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SearchChangedImpl implements _SearchChanged {
  const _$SearchChangedImpl(this.query);

  @override
  final String query;

  @override
  String toString() {
    return 'HomeEvent.searchChanged(query: $query)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchChangedImpl &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchChangedImplCopyWith<_$SearchChangedImpl> get copyWith =>
      __$$SearchChangedImplCopyWithImpl<_$SearchChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return searchChanged(query);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return searchChanged?.call(query);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (searchChanged != null) {
      return searchChanged(query);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return searchChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return searchChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (searchChanged != null) {
      return searchChanged(this);
    }
    return orElse();
  }
}

abstract class _SearchChanged implements HomeEvent {
  const factory _SearchChanged(final String query) = _$SearchChangedImpl;

  String get query;
  @JsonKey(ignore: true)
  _$$SearchChangedImplCopyWith<_$SearchChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FiltersChangedImplCopyWith<$Res> {
  factory _$$FiltersChangedImplCopyWith(_$FiltersChangedImpl value,
          $Res Function(_$FiltersChangedImpl) then) =
      __$$FiltersChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Set<NoteSearchFilter> filters});
}

/// @nodoc
class __$$FiltersChangedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$FiltersChangedImpl>
    implements _$$FiltersChangedImplCopyWith<$Res> {
  __$$FiltersChangedImplCopyWithImpl(
      _$FiltersChangedImpl _value, $Res Function(_$FiltersChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filters = null,
  }) {
    return _then(_$FiltersChangedImpl(
      null == filters
          ? _value._filters
          : filters // ignore: cast_nullable_to_non_nullable
              as Set<NoteSearchFilter>,
    ));
  }
}

/// @nodoc

class _$FiltersChangedImpl implements _FiltersChanged {
  const _$FiltersChangedImpl(final Set<NoteSearchFilter> filters)
      : _filters = filters;

  final Set<NoteSearchFilter> _filters;
  @override
  Set<NoteSearchFilter> get filters {
    if (_filters is EqualUnmodifiableSetView) return _filters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_filters);
  }

  @override
  String toString() {
    return 'HomeEvent.filtersChanged(filters: $filters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FiltersChangedImpl &&
            const DeepCollectionEquality().equals(other._filters, _filters));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_filters));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FiltersChangedImplCopyWith<_$FiltersChangedImpl> get copyWith =>
      __$$FiltersChangedImplCopyWithImpl<_$FiltersChangedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return filtersChanged(filters);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return filtersChanged?.call(filters);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (filtersChanged != null) {
      return filtersChanged(filters);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return filtersChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return filtersChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (filtersChanged != null) {
      return filtersChanged(this);
    }
    return orElse();
  }
}

abstract class _FiltersChanged implements HomeEvent {
  const factory _FiltersChanged(final Set<NoteSearchFilter> filters) =
      _$FiltersChangedImpl;

  Set<NoteSearchFilter> get filters;
  @JsonKey(ignore: true)
  _$$FiltersChangedImplCopyWith<_$FiltersChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RemoveFilterImplCopyWith<$Res> {
  factory _$$RemoveFilterImplCopyWith(
          _$RemoveFilterImpl value, $Res Function(_$RemoveFilterImpl) then) =
      __$$RemoveFilterImplCopyWithImpl<$Res>;
  @useResult
  $Res call({NoteSearchFilter filter});
}

/// @nodoc
class __$$RemoveFilterImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$RemoveFilterImpl>
    implements _$$RemoveFilterImplCopyWith<$Res> {
  __$$RemoveFilterImplCopyWithImpl(
      _$RemoveFilterImpl _value, $Res Function(_$RemoveFilterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filter = null,
  }) {
    return _then(_$RemoveFilterImpl(
      null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as NoteSearchFilter,
    ));
  }
}

/// @nodoc

class _$RemoveFilterImpl implements _RemoveFilter {
  const _$RemoveFilterImpl(this.filter);

  @override
  final NoteSearchFilter filter;

  @override
  String toString() {
    return 'HomeEvent.removeFilter(filter: $filter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoveFilterImpl &&
            (identical(other.filter, filter) || other.filter == filter));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filter);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoveFilterImplCopyWith<_$RemoveFilterImpl> get copyWith =>
      __$$RemoveFilterImplCopyWithImpl<_$RemoveFilterImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return removeFilter(filter);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return removeFilter?.call(filter);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (removeFilter != null) {
      return removeFilter(filter);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return removeFilter(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return removeFilter?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (removeFilter != null) {
      return removeFilter(this);
    }
    return orElse();
  }
}

abstract class _RemoveFilter implements HomeEvent {
  const factory _RemoveFilter(final NoteSearchFilter filter) =
      _$RemoveFilterImpl;

  NoteSearchFilter get filter;
  @JsonKey(ignore: true)
  _$$RemoveFilterImplCopyWith<_$RemoveFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SelectFolderImplCopyWith<$Res> {
  factory _$$SelectFolderImplCopyWith(
          _$SelectFolderImpl value, $Res Function(_$SelectFolderImpl) then) =
      __$$SelectFolderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? folderId, bool preserveScope});
}

/// @nodoc
class __$$SelectFolderImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$SelectFolderImpl>
    implements _$$SelectFolderImplCopyWith<$Res> {
  __$$SelectFolderImplCopyWithImpl(
      _$SelectFolderImpl _value, $Res Function(_$SelectFolderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? folderId = freezed,
    Object? preserveScope = null,
  }) {
    return _then(_$SelectFolderImpl(
      freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      preserveScope: null == preserveScope
          ? _value.preserveScope
          : preserveScope // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SelectFolderImpl implements _SelectFolder {
  const _$SelectFolderImpl(this.folderId, {this.preserveScope = false});

  @override
  final String? folderId;
  @override
  @JsonKey()
  final bool preserveScope;

  @override
  String toString() {
    return 'HomeEvent.selectFolder(folderId: $folderId, preserveScope: $preserveScope)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectFolderImpl &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.preserveScope, preserveScope) ||
                other.preserveScope == preserveScope));
  }

  @override
  int get hashCode => Object.hash(runtimeType, folderId, preserveScope);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectFolderImplCopyWith<_$SelectFolderImpl> get copyWith =>
      __$$SelectFolderImplCopyWithImpl<_$SelectFolderImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return selectFolder(folderId, preserveScope);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return selectFolder?.call(folderId, preserveScope);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (selectFolder != null) {
      return selectFolder(folderId, preserveScope);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return selectFolder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return selectFolder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (selectFolder != null) {
      return selectFolder(this);
    }
    return orElse();
  }
}

abstract class _SelectFolder implements HomeEvent {
  const factory _SelectFolder(final String? folderId,
      {final bool preserveScope}) = _$SelectFolderImpl;

  String? get folderId;
  bool get preserveScope;
  @JsonKey(ignore: true)
  _$$SelectFolderImplCopyWith<_$SelectFolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ShowTrashImplCopyWith<$Res> {
  factory _$$ShowTrashImplCopyWith(
          _$ShowTrashImpl value, $Res Function(_$ShowTrashImpl) then) =
      __$$ShowTrashImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool show});
}

/// @nodoc
class __$$ShowTrashImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$ShowTrashImpl>
    implements _$$ShowTrashImplCopyWith<$Res> {
  __$$ShowTrashImplCopyWithImpl(
      _$ShowTrashImpl _value, $Res Function(_$ShowTrashImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? show = null,
  }) {
    return _then(_$ShowTrashImpl(
      null == show
          ? _value.show
          : show // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ShowTrashImpl implements _ShowTrash {
  const _$ShowTrashImpl(this.show);

  @override
  final bool show;

  @override
  String toString() {
    return 'HomeEvent.showTrash(show: $show)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShowTrashImpl &&
            (identical(other.show, show) || other.show == show));
  }

  @override
  int get hashCode => Object.hash(runtimeType, show);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShowTrashImplCopyWith<_$ShowTrashImpl> get copyWith =>
      __$$ShowTrashImplCopyWithImpl<_$ShowTrashImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return showTrash(show);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return showTrash?.call(show);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (showTrash != null) {
      return showTrash(show);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return showTrash(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return showTrash?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (showTrash != null) {
      return showTrash(this);
    }
    return orElse();
  }
}

abstract class _ShowTrash implements HomeEvent {
  const factory _ShowTrash(final bool show) = _$ShowTrashImpl;

  bool get show;
  @JsonKey(ignore: true)
  _$$ShowTrashImplCopyWith<_$ShowTrashImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ShowArchiveImplCopyWith<$Res> {
  factory _$$ShowArchiveImplCopyWith(
          _$ShowArchiveImpl value, $Res Function(_$ShowArchiveImpl) then) =
      __$$ShowArchiveImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool show});
}

/// @nodoc
class __$$ShowArchiveImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$ShowArchiveImpl>
    implements _$$ShowArchiveImplCopyWith<$Res> {
  __$$ShowArchiveImplCopyWithImpl(
      _$ShowArchiveImpl _value, $Res Function(_$ShowArchiveImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? show = null,
  }) {
    return _then(_$ShowArchiveImpl(
      null == show
          ? _value.show
          : show // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ShowArchiveImpl implements _ShowArchive {
  const _$ShowArchiveImpl(this.show);

  @override
  final bool show;

  @override
  String toString() {
    return 'HomeEvent.showArchive(show: $show)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShowArchiveImpl &&
            (identical(other.show, show) || other.show == show));
  }

  @override
  int get hashCode => Object.hash(runtimeType, show);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShowArchiveImplCopyWith<_$ShowArchiveImpl> get copyWith =>
      __$$ShowArchiveImplCopyWithImpl<_$ShowArchiveImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return showArchive(show);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return showArchive?.call(show);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (showArchive != null) {
      return showArchive(show);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return showArchive(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return showArchive?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (showArchive != null) {
      return showArchive(this);
    }
    return orElse();
  }
}

abstract class _ShowArchive implements HomeEvent {
  const factory _ShowArchive(final bool show) = _$ShowArchiveImpl;

  bool get show;
  @JsonKey(ignore: true)
  _$$ShowArchiveImplCopyWith<_$ShowArchiveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$IncludeArchivedImplCopyWith<$Res> {
  factory _$$IncludeArchivedImplCopyWith(_$IncludeArchivedImpl value,
          $Res Function(_$IncludeArchivedImpl) then) =
      __$$IncludeArchivedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool include});
}

/// @nodoc
class __$$IncludeArchivedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$IncludeArchivedImpl>
    implements _$$IncludeArchivedImplCopyWith<$Res> {
  __$$IncludeArchivedImplCopyWithImpl(
      _$IncludeArchivedImpl _value, $Res Function(_$IncludeArchivedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? include = null,
  }) {
    return _then(_$IncludeArchivedImpl(
      null == include
          ? _value.include
          : include // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$IncludeArchivedImpl implements _IncludeArchived {
  const _$IncludeArchivedImpl(this.include);

  @override
  final bool include;

  @override
  String toString() {
    return 'HomeEvent.includeArchived(include: $include)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncludeArchivedImpl &&
            (identical(other.include, include) || other.include == include));
  }

  @override
  int get hashCode => Object.hash(runtimeType, include);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IncludeArchivedImplCopyWith<_$IncludeArchivedImpl> get copyWith =>
      __$$IncludeArchivedImplCopyWithImpl<_$IncludeArchivedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return includeArchived(include);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return includeArchived?.call(include);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (includeArchived != null) {
      return includeArchived(include);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return includeArchived(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return includeArchived?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (includeArchived != null) {
      return includeArchived(this);
    }
    return orElse();
  }
}

abstract class _IncludeArchived implements HomeEvent {
  const factory _IncludeArchived(final bool include) = _$IncludeArchivedImpl;

  bool get include;
  @JsonKey(ignore: true)
  _$$IncludeArchivedImplCopyWith<_$IncludeArchivedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RemoveIncludeArchivedImplCopyWith<$Res> {
  factory _$$RemoveIncludeArchivedImplCopyWith(
          _$RemoveIncludeArchivedImpl value,
          $Res Function(_$RemoveIncludeArchivedImpl) then) =
      __$$RemoveIncludeArchivedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RemoveIncludeArchivedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$RemoveIncludeArchivedImpl>
    implements _$$RemoveIncludeArchivedImplCopyWith<$Res> {
  __$$RemoveIncludeArchivedImplCopyWithImpl(_$RemoveIncludeArchivedImpl _value,
      $Res Function(_$RemoveIncludeArchivedImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RemoveIncludeArchivedImpl implements _RemoveIncludeArchived {
  const _$RemoveIncludeArchivedImpl();

  @override
  String toString() {
    return 'HomeEvent.removeIncludeArchived()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoveIncludeArchivedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return removeIncludeArchived();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return removeIncludeArchived?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (removeIncludeArchived != null) {
      return removeIncludeArchived();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return removeIncludeArchived(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return removeIncludeArchived?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (removeIncludeArchived != null) {
      return removeIncludeArchived(this);
    }
    return orElse();
  }
}

abstract class _RemoveIncludeArchived implements HomeEvent {
  const factory _RemoveIncludeArchived() = _$RemoveIncludeArchivedImpl;
}

/// @nodoc
abstract class _$$TagsChangedImplCopyWith<$Res> {
  factory _$$TagsChangedImplCopyWith(
          _$TagsChangedImpl value, $Res Function(_$TagsChangedImpl) then) =
      __$$TagsChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Set<String> tags});
}

/// @nodoc
class __$$TagsChangedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$TagsChangedImpl>
    implements _$$TagsChangedImplCopyWith<$Res> {
  __$$TagsChangedImplCopyWithImpl(
      _$TagsChangedImpl _value, $Res Function(_$TagsChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tags = null,
  }) {
    return _then(_$TagsChangedImpl(
      null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$TagsChangedImpl implements _TagsChanged {
  const _$TagsChangedImpl(final Set<String> tags) : _tags = tags;

  final Set<String> _tags;
  @override
  Set<String> get tags {
    if (_tags is EqualUnmodifiableSetView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_tags);
  }

  @override
  String toString() {
    return 'HomeEvent.tagsChanged(tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagsChangedImpl &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TagsChangedImplCopyWith<_$TagsChangedImpl> get copyWith =>
      __$$TagsChangedImplCopyWithImpl<_$TagsChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return tagsChanged(tags);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return tagsChanged?.call(tags);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (tagsChanged != null) {
      return tagsChanged(tags);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return tagsChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return tagsChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (tagsChanged != null) {
      return tagsChanged(this);
    }
    return orElse();
  }
}

abstract class _TagsChanged implements HomeEvent {
  const factory _TagsChanged(final Set<String> tags) = _$TagsChangedImpl;

  Set<String> get tags;
  @JsonKey(ignore: true)
  _$$TagsChangedImplCopyWith<_$TagsChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RemoveTagImplCopyWith<$Res> {
  factory _$$RemoveTagImplCopyWith(
          _$RemoveTagImpl value, $Res Function(_$RemoveTagImpl) then) =
      __$$RemoveTagImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String tag});
}

/// @nodoc
class __$$RemoveTagImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$RemoveTagImpl>
    implements _$$RemoveTagImplCopyWith<$Res> {
  __$$RemoveTagImplCopyWithImpl(
      _$RemoveTagImpl _value, $Res Function(_$RemoveTagImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tag = null,
  }) {
    return _then(_$RemoveTagImpl(
      null == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RemoveTagImpl implements _RemoveTag {
  const _$RemoveTagImpl(this.tag);

  @override
  final String tag;

  @override
  String toString() {
    return 'HomeEvent.removeTag(tag: $tag)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoveTagImpl &&
            (identical(other.tag, tag) || other.tag == tag));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tag);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoveTagImplCopyWith<_$RemoveTagImpl> get copyWith =>
      __$$RemoveTagImplCopyWithImpl<_$RemoveTagImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return removeTag(tag);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return removeTag?.call(tag);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (removeTag != null) {
      return removeTag(tag);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return removeTag(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return removeTag?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (removeTag != null) {
      return removeTag(this);
    }
    return orElse();
  }
}

abstract class _RemoveTag implements HomeEvent {
  const factory _RemoveTag(final String tag) = _$RemoveTagImpl;

  String get tag;
  @JsonKey(ignore: true)
  _$$RemoveTagImplCopyWith<_$RemoveTagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SortChangedImplCopyWith<$Res> {
  factory _$$SortChangedImplCopyWith(
          _$SortChangedImpl value, $Res Function(_$SortChangedImpl) then) =
      __$$SortChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({NoteSortOrder order});
}

/// @nodoc
class __$$SortChangedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$SortChangedImpl>
    implements _$$SortChangedImplCopyWith<$Res> {
  __$$SortChangedImplCopyWithImpl(
      _$SortChangedImpl _value, $Res Function(_$SortChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? order = null,
  }) {
    return _then(_$SortChangedImpl(
      null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as NoteSortOrder,
    ));
  }
}

/// @nodoc

class _$SortChangedImpl implements _SortChanged {
  const _$SortChangedImpl(this.order);

  @override
  final NoteSortOrder order;

  @override
  String toString() {
    return 'HomeEvent.sortChanged(order: $order)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SortChangedImpl &&
            (identical(other.order, order) || other.order == order));
  }

  @override
  int get hashCode => Object.hash(runtimeType, order);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SortChangedImplCopyWith<_$SortChangedImpl> get copyWith =>
      __$$SortChangedImplCopyWithImpl<_$SortChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return sortChanged(order);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return sortChanged?.call(order);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (sortChanged != null) {
      return sortChanged(order);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return sortChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return sortChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (sortChanged != null) {
      return sortChanged(this);
    }
    return orElse();
  }
}

abstract class _SortChanged implements HomeEvent {
  const factory _SortChanged(final NoteSortOrder order) = _$SortChangedImpl;

  NoteSortOrder get order;
  @JsonKey(ignore: true)
  _$$SortChangedImplCopyWith<_$SortChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SavedViewsChangedImplCopyWith<$Res> {
  factory _$$SavedViewsChangedImplCopyWith(_$SavedViewsChangedImpl value,
          $Res Function(_$SavedViewsChangedImpl) then) =
      __$$SavedViewsChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<SavedNoteView> views});
}

/// @nodoc
class __$$SavedViewsChangedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$SavedViewsChangedImpl>
    implements _$$SavedViewsChangedImplCopyWith<$Res> {
  __$$SavedViewsChangedImplCopyWithImpl(_$SavedViewsChangedImpl _value,
      $Res Function(_$SavedViewsChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? views = null,
  }) {
    return _then(_$SavedViewsChangedImpl(
      null == views
          ? _value._views
          : views // ignore: cast_nullable_to_non_nullable
              as List<SavedNoteView>,
    ));
  }
}

/// @nodoc

class _$SavedViewsChangedImpl implements _SavedViewsChanged {
  const _$SavedViewsChangedImpl(final List<SavedNoteView> views)
      : _views = views;

  final List<SavedNoteView> _views;
  @override
  List<SavedNoteView> get views {
    if (_views is EqualUnmodifiableListView) return _views;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_views);
  }

  @override
  String toString() {
    return 'HomeEvent.savedViewsChanged(views: $views)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedViewsChangedImpl &&
            const DeepCollectionEquality().equals(other._views, _views));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_views));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedViewsChangedImplCopyWith<_$SavedViewsChangedImpl> get copyWith =>
      __$$SavedViewsChangedImplCopyWithImpl<_$SavedViewsChangedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return savedViewsChanged(views);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return savedViewsChanged?.call(views);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (savedViewsChanged != null) {
      return savedViewsChanged(views);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return savedViewsChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return savedViewsChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (savedViewsChanged != null) {
      return savedViewsChanged(this);
    }
    return orElse();
  }
}

abstract class _SavedViewsChanged implements HomeEvent {
  const factory _SavedViewsChanged(final List<SavedNoteView> views) =
      _$SavedViewsChangedImpl;

  List<SavedNoteView> get views;
  @JsonKey(ignore: true)
  _$$SavedViewsChangedImplCopyWith<_$SavedViewsChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApplySavedViewImplCopyWith<$Res> {
  factory _$$ApplySavedViewImplCopyWith(_$ApplySavedViewImpl value,
          $Res Function(_$ApplySavedViewImpl) then) =
      __$$ApplySavedViewImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SavedNoteView view});
}

/// @nodoc
class __$$ApplySavedViewImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$ApplySavedViewImpl>
    implements _$$ApplySavedViewImplCopyWith<$Res> {
  __$$ApplySavedViewImplCopyWithImpl(
      _$ApplySavedViewImpl _value, $Res Function(_$ApplySavedViewImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? view = null,
  }) {
    return _then(_$ApplySavedViewImpl(
      null == view
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as SavedNoteView,
    ));
  }
}

/// @nodoc

class _$ApplySavedViewImpl implements _ApplySavedView {
  const _$ApplySavedViewImpl(this.view);

  @override
  final SavedNoteView view;

  @override
  String toString() {
    return 'HomeEvent.applySavedView(view: $view)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplySavedViewImpl &&
            (identical(other.view, view) || other.view == view));
  }

  @override
  int get hashCode => Object.hash(runtimeType, view);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplySavedViewImplCopyWith<_$ApplySavedViewImpl> get copyWith =>
      __$$ApplySavedViewImplCopyWithImpl<_$ApplySavedViewImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return applySavedView(view);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return applySavedView?.call(view);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (applySavedView != null) {
      return applySavedView(view);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return applySavedView(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return applySavedView?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (applySavedView != null) {
      return applySavedView(this);
    }
    return orElse();
  }
}

abstract class _ApplySavedView implements HomeEvent {
  const factory _ApplySavedView(final SavedNoteView view) =
      _$ApplySavedViewImpl;

  SavedNoteView get view;
  @JsonKey(ignore: true)
  _$$ApplySavedViewImplCopyWith<_$ApplySavedViewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SetArchivedImplCopyWith<$Res> {
  factory _$$SetArchivedImplCopyWith(
          _$SetArchivedImpl value, $Res Function(_$SetArchivedImpl) then) =
      __$$SetArchivedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String noteId, bool archived, Completer<HomeArchiveResult>? completion});
}

/// @nodoc
class __$$SetArchivedImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$SetArchivedImpl>
    implements _$$SetArchivedImplCopyWith<$Res> {
  __$$SetArchivedImplCopyWithImpl(
      _$SetArchivedImpl _value, $Res Function(_$SetArchivedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? archived = null,
    Object? completion = freezed,
  }) {
    return _then(_$SetArchivedImpl(
      noteId: null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
      archived: null == archived
          ? _value.archived
          : archived // ignore: cast_nullable_to_non_nullable
              as bool,
      completion: freezed == completion
          ? _value.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as Completer<HomeArchiveResult>?,
    ));
  }
}

/// @nodoc

class _$SetArchivedImpl implements _SetArchived {
  const _$SetArchivedImpl(
      {required this.noteId, required this.archived, this.completion});

  @override
  final String noteId;
  @override
  final bool archived;
  @override
  final Completer<HomeArchiveResult>? completion;

  @override
  String toString() {
    return 'HomeEvent.setArchived(noteId: $noteId, archived: $archived, completion: $completion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetArchivedImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            (identical(other.archived, archived) ||
                other.archived == archived) &&
            (identical(other.completion, completion) ||
                other.completion == completion));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId, archived, completion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SetArchivedImplCopyWith<_$SetArchivedImpl> get copyWith =>
      __$$SetArchivedImplCopyWithImpl<_$SetArchivedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return setArchived(noteId, archived, completion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return setArchived?.call(noteId, archived, completion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (setArchived != null) {
      return setArchived(noteId, archived, completion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return setArchived(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return setArchived?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (setArchived != null) {
      return setArchived(this);
    }
    return orElse();
  }
}

abstract class _SetArchived implements HomeEvent {
  const factory _SetArchived(
      {required final String noteId,
      required final bool archived,
      final Completer<HomeArchiveResult>? completion}) = _$SetArchivedImpl;

  String get noteId;
  bool get archived;
  Completer<HomeArchiveResult>? get completion;
  @JsonKey(ignore: true)
  _$$SetArchivedImplCopyWith<_$SetArchivedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SetTagsImplCopyWith<$Res> {
  factory _$$SetTagsImplCopyWith(
          _$SetTagsImpl value, $Res Function(_$SetTagsImpl) then) =
      __$$SetTagsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String noteId, List<String> tags, Completer<String?>? completion});
}

/// @nodoc
class __$$SetTagsImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$SetTagsImpl>
    implements _$$SetTagsImplCopyWith<$Res> {
  __$$SetTagsImplCopyWithImpl(
      _$SetTagsImpl _value, $Res Function(_$SetTagsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? tags = null,
    Object? completion = freezed,
  }) {
    return _then(_$SetTagsImpl(
      noteId: null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      completion: freezed == completion
          ? _value.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as Completer<String?>?,
    ));
  }
}

/// @nodoc

class _$SetTagsImpl implements _SetTags {
  const _$SetTagsImpl(
      {required this.noteId, required final List<String> tags, this.completion})
      : _tags = tags;

  @override
  final String noteId;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final Completer<String?>? completion;

  @override
  String toString() {
    return 'HomeEvent.setTags(noteId: $noteId, tags: $tags, completion: $completion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetTagsImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.completion, completion) ||
                other.completion == completion));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId,
      const DeepCollectionEquality().hash(_tags), completion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SetTagsImplCopyWith<_$SetTagsImpl> get copyWith =>
      __$$SetTagsImplCopyWithImpl<_$SetTagsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return setTags(noteId, tags, completion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return setTags?.call(noteId, tags, completion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (setTags != null) {
      return setTags(noteId, tags, completion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return setTags(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return setTags?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (setTags != null) {
      return setTags(this);
    }
    return orElse();
  }
}

abstract class _SetTags implements HomeEvent {
  const factory _SetTags(
      {required final String noteId,
      required final List<String> tags,
      final Completer<String?>? completion}) = _$SetTagsImpl;

  String get noteId;
  List<String> get tags;
  Completer<String?>? get completion;
  @JsonKey(ignore: true)
  _$$SetTagsImplCopyWith<_$SetTagsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SetCardStyleImplCopyWith<$Res> {
  factory _$$SetCardStyleImplCopyWith(
          _$SetCardStyleImpl value, $Res Function(_$SetCardStyleImpl) then) =
      __$$SetCardStyleImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String noteId,
      NoteCardStyle style,
      Color? color,
      bool updateColor,
      Completer<String?>? completion});
}

/// @nodoc
class __$$SetCardStyleImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$SetCardStyleImpl>
    implements _$$SetCardStyleImplCopyWith<$Res> {
  __$$SetCardStyleImplCopyWithImpl(
      _$SetCardStyleImpl _value, $Res Function(_$SetCardStyleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? style = null,
    Object? color = freezed,
    Object? updateColor = null,
    Object? completion = freezed,
  }) {
    return _then(_$SetCardStyleImpl(
      noteId: null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as NoteCardStyle,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      updateColor: null == updateColor
          ? _value.updateColor
          : updateColor // ignore: cast_nullable_to_non_nullable
              as bool,
      completion: freezed == completion
          ? _value.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as Completer<String?>?,
    ));
  }
}

/// @nodoc

class _$SetCardStyleImpl implements _SetCardStyle {
  const _$SetCardStyleImpl(
      {required this.noteId,
      required this.style,
      this.color,
      this.updateColor = false,
      this.completion});

  @override
  final String noteId;
  @override
  final NoteCardStyle style;
  @override
  final Color? color;
  @override
  @JsonKey()
  final bool updateColor;
  @override
  final Completer<String?>? completion;

  @override
  String toString() {
    return 'HomeEvent.setCardStyle(noteId: $noteId, style: $style, color: $color, updateColor: $updateColor, completion: $completion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetCardStyleImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.updateColor, updateColor) ||
                other.updateColor == updateColor) &&
            (identical(other.completion, completion) ||
                other.completion == completion));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, noteId, style, color, updateColor, completion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SetCardStyleImplCopyWith<_$SetCardStyleImpl> get copyWith =>
      __$$SetCardStyleImplCopyWithImpl<_$SetCardStyleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return setCardStyle(noteId, style, color, updateColor, completion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return setCardStyle?.call(noteId, style, color, updateColor, completion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (setCardStyle != null) {
      return setCardStyle(noteId, style, color, updateColor, completion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return setCardStyle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return setCardStyle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (setCardStyle != null) {
      return setCardStyle(this);
    }
    return orElse();
  }
}

abstract class _SetCardStyle implements HomeEvent {
  const factory _SetCardStyle(
      {required final String noteId,
      required final NoteCardStyle style,
      final Color? color,
      final bool updateColor,
      final Completer<String?>? completion}) = _$SetCardStyleImpl;

  String get noteId;
  NoteCardStyle get style;
  Color? get color;
  bool get updateColor;
  Completer<String?>? get completion;
  @JsonKey(ignore: true)
  _$$SetCardStyleImplCopyWith<_$SetCardStyleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TogglePinImplCopyWith<$Res> {
  factory _$$TogglePinImplCopyWith(
          _$TogglePinImpl value, $Res Function(_$TogglePinImpl) then) =
      __$$TogglePinImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String noteId});
}

/// @nodoc
class __$$TogglePinImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$TogglePinImpl>
    implements _$$TogglePinImplCopyWith<$Res> {
  __$$TogglePinImplCopyWithImpl(
      _$TogglePinImpl _value, $Res Function(_$TogglePinImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
  }) {
    return _then(_$TogglePinImpl(
      null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TogglePinImpl implements _TogglePin {
  const _$TogglePinImpl(this.noteId);

  @override
  final String noteId;

  @override
  String toString() {
    return 'HomeEvent.togglePin(noteId: $noteId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TogglePinImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TogglePinImplCopyWith<_$TogglePinImpl> get copyWith =>
      __$$TogglePinImplCopyWithImpl<_$TogglePinImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return togglePin(noteId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return togglePin?.call(noteId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (togglePin != null) {
      return togglePin(noteId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return togglePin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return togglePin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (togglePin != null) {
      return togglePin(this);
    }
    return orElse();
  }
}

abstract class _TogglePin implements HomeEvent {
  const factory _TogglePin(final String noteId) = _$TogglePinImpl;

  String get noteId;
  @JsonKey(ignore: true)
  _$$TogglePinImplCopyWith<_$TogglePinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RestoreNotesImplCopyWith<$Res> {
  factory _$$RestoreNotesImplCopyWith(
          _$RestoreNotesImpl value, $Res Function(_$RestoreNotesImpl) then) =
      __$$RestoreNotesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> ids});
}

/// @nodoc
class __$$RestoreNotesImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$RestoreNotesImpl>
    implements _$$RestoreNotesImplCopyWith<$Res> {
  __$$RestoreNotesImplCopyWithImpl(
      _$RestoreNotesImpl _value, $Res Function(_$RestoreNotesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ids = null,
  }) {
    return _then(_$RestoreNotesImpl(
      null == ids
          ? _value._ids
          : ids // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$RestoreNotesImpl implements _RestoreNotes {
  const _$RestoreNotesImpl(final List<String> ids) : _ids = ids;

  final List<String> _ids;
  @override
  List<String> get ids {
    if (_ids is EqualUnmodifiableListView) return _ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ids);
  }

  @override
  String toString() {
    return 'HomeEvent.restoreNotes(ids: $ids)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestoreNotesImpl &&
            const DeepCollectionEquality().equals(other._ids, _ids));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_ids));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RestoreNotesImplCopyWith<_$RestoreNotesImpl> get copyWith =>
      __$$RestoreNotesImplCopyWithImpl<_$RestoreNotesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return restoreNotes(ids);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return restoreNotes?.call(ids);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (restoreNotes != null) {
      return restoreNotes(ids);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return restoreNotes(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return restoreNotes?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (restoreNotes != null) {
      return restoreNotes(this);
    }
    return orElse();
  }
}

abstract class _RestoreNotes implements HomeEvent {
  const factory _RestoreNotes(final List<String> ids) = _$RestoreNotesImpl;

  List<String> get ids;
  @JsonKey(ignore: true)
  _$$RestoreNotesImplCopyWith<_$RestoreNotesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PermanentDeleteImplCopyWith<$Res> {
  factory _$$PermanentDeleteImplCopyWith(_$PermanentDeleteImpl value,
          $Res Function(_$PermanentDeleteImpl) then) =
      __$$PermanentDeleteImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> ids});
}

/// @nodoc
class __$$PermanentDeleteImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$PermanentDeleteImpl>
    implements _$$PermanentDeleteImplCopyWith<$Res> {
  __$$PermanentDeleteImplCopyWithImpl(
      _$PermanentDeleteImpl _value, $Res Function(_$PermanentDeleteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ids = null,
  }) {
    return _then(_$PermanentDeleteImpl(
      null == ids
          ? _value._ids
          : ids // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$PermanentDeleteImpl implements _PermanentDelete {
  const _$PermanentDeleteImpl(final List<String> ids) : _ids = ids;

  final List<String> _ids;
  @override
  List<String> get ids {
    if (_ids is EqualUnmodifiableListView) return _ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ids);
  }

  @override
  String toString() {
    return 'HomeEvent.permanentDelete(ids: $ids)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermanentDeleteImpl &&
            const DeepCollectionEquality().equals(other._ids, _ids));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_ids));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PermanentDeleteImplCopyWith<_$PermanentDeleteImpl> get copyWith =>
      __$$PermanentDeleteImplCopyWithImpl<_$PermanentDeleteImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return permanentDelete(ids);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return permanentDelete?.call(ids);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (permanentDelete != null) {
      return permanentDelete(ids);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return permanentDelete(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return permanentDelete?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (permanentDelete != null) {
      return permanentDelete(this);
    }
    return orElse();
  }
}

abstract class _PermanentDelete implements HomeEvent {
  const factory _PermanentDelete(final List<String> ids) =
      _$PermanentDeleteImpl;

  List<String> get ids;
  @JsonKey(ignore: true)
  _$$PermanentDeleteImplCopyWith<_$PermanentDeleteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CreateFolderImplCopyWith<$Res> {
  factory _$$CreateFolderImplCopyWith(
          _$CreateFolderImpl value, $Res Function(_$CreateFolderImpl) then) =
      __$$CreateFolderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String name, Completer<String?>? completion});
}

/// @nodoc
class __$$CreateFolderImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$CreateFolderImpl>
    implements _$$CreateFolderImplCopyWith<$Res> {
  __$$CreateFolderImplCopyWithImpl(
      _$CreateFolderImpl _value, $Res Function(_$CreateFolderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? completion = freezed,
  }) {
    return _then(_$CreateFolderImpl(
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      completion: freezed == completion
          ? _value.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as Completer<String?>?,
    ));
  }
}

/// @nodoc

class _$CreateFolderImpl implements _CreateFolder {
  const _$CreateFolderImpl(this.name, {this.completion});

  @override
  final String name;
  @override
  final Completer<String?>? completion;

  @override
  String toString() {
    return 'HomeEvent.createFolder(name: $name, completion: $completion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateFolderImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.completion, completion) ||
                other.completion == completion));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, completion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateFolderImplCopyWith<_$CreateFolderImpl> get copyWith =>
      __$$CreateFolderImplCopyWithImpl<_$CreateFolderImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return createFolder(name, completion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return createFolder?.call(name, completion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (createFolder != null) {
      return createFolder(name, completion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return createFolder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return createFolder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (createFolder != null) {
      return createFolder(this);
    }
    return orElse();
  }
}

abstract class _CreateFolder implements HomeEvent {
  const factory _CreateFolder(final String name,
      {final Completer<String?>? completion}) = _$CreateFolderImpl;

  String get name;
  Completer<String?>? get completion;
  @JsonKey(ignore: true)
  _$$CreateFolderImplCopyWith<_$CreateFolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RenameFolderImplCopyWith<$Res> {
  factory _$$RenameFolderImplCopyWith(
          _$RenameFolderImpl value, $Res Function(_$RenameFolderImpl) then) =
      __$$RenameFolderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$RenameFolderImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$RenameFolderImpl>
    implements _$$RenameFolderImplCopyWith<$Res> {
  __$$RenameFolderImplCopyWithImpl(
      _$RenameFolderImpl _value, $Res Function(_$RenameFolderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$RenameFolderImpl(
      null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RenameFolderImpl implements _RenameFolder {
  const _$RenameFolderImpl(this.id, this.name);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'HomeEvent.renameFolder(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RenameFolderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RenameFolderImplCopyWith<_$RenameFolderImpl> get copyWith =>
      __$$RenameFolderImplCopyWithImpl<_$RenameFolderImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return renameFolder(id, name);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return renameFolder?.call(id, name);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (renameFolder != null) {
      return renameFolder(id, name);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return renameFolder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return renameFolder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (renameFolder != null) {
      return renameFolder(this);
    }
    return orElse();
  }
}

abstract class _RenameFolder implements HomeEvent {
  const factory _RenameFolder(final String id, final String name) =
      _$RenameFolderImpl;

  String get id;
  String get name;
  @JsonKey(ignore: true)
  _$$RenameFolderImplCopyWith<_$RenameFolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeleteFolderImplCopyWith<$Res> {
  factory _$$DeleteFolderImplCopyWith(
          _$DeleteFolderImpl value, $Res Function(_$DeleteFolderImpl) then) =
      __$$DeleteFolderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$DeleteFolderImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$DeleteFolderImpl>
    implements _$$DeleteFolderImplCopyWith<$Res> {
  __$$DeleteFolderImplCopyWithImpl(
      _$DeleteFolderImpl _value, $Res Function(_$DeleteFolderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_$DeleteFolderImpl(
      null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DeleteFolderImpl implements _DeleteFolder {
  const _$DeleteFolderImpl(this.id);

  @override
  final String id;

  @override
  String toString() {
    return 'HomeEvent.deleteFolder(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteFolderImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeleteFolderImplCopyWith<_$DeleteFolderImpl> get copyWith =>
      __$$DeleteFolderImplCopyWithImpl<_$DeleteFolderImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return deleteFolder(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return deleteFolder?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (deleteFolder != null) {
      return deleteFolder(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return deleteFolder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return deleteFolder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (deleteFolder != null) {
      return deleteFolder(this);
    }
    return orElse();
  }
}

abstract class _DeleteFolder implements HomeEvent {
  const factory _DeleteFolder(final String id) = _$DeleteFolderImpl;

  String get id;
  @JsonKey(ignore: true)
  _$$DeleteFolderImplCopyWith<_$DeleteFolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MoveNoteToFolderImplCopyWith<$Res> {
  factory _$$MoveNoteToFolderImplCopyWith(_$MoveNoteToFolderImpl value,
          $Res Function(_$MoveNoteToFolderImpl) then) =
      __$$MoveNoteToFolderImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String noteId, String? folderId});
}

/// @nodoc
class __$$MoveNoteToFolderImplCopyWithImpl<$Res>
    extends _$HomeEventCopyWithImpl<$Res, _$MoveNoteToFolderImpl>
    implements _$$MoveNoteToFolderImplCopyWith<$Res> {
  __$$MoveNoteToFolderImplCopyWithImpl(_$MoveNoteToFolderImpl _value,
      $Res Function(_$MoveNoteToFolderImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? folderId = freezed,
  }) {
    return _then(_$MoveNoteToFolderImpl(
      noteId: null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MoveNoteToFolderImpl implements _MoveNoteToFolder {
  const _$MoveNoteToFolderImpl({required this.noteId, this.folderId});

  @override
  final String noteId;
  @override
  final String? folderId;

  @override
  String toString() {
    return 'HomeEvent.moveNoteToFolder(noteId: $noteId, folderId: $folderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoveNoteToFolderImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId, folderId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MoveNoteToFolderImplCopyWith<_$MoveNoteToFolderImpl> get copyWith =>
      __$$MoveNoteToFolderImplCopyWithImpl<_$MoveNoteToFolderImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)
        updateTodo,
    required TResult Function() getAllNotes,
    required TResult Function(Note note) duplicateNote,
    required TResult Function(List<Note> notes, Completer<String?>? completion)
        reorderNotes,
    required TResult Function(String query) searchChanged,
    required TResult Function(Set<NoteSearchFilter> filters) filtersChanged,
    required TResult Function(NoteSearchFilter filter) removeFilter,
    required TResult Function(String? folderId, bool preserveScope)
        selectFolder,
    required TResult Function(bool show) showTrash,
    required TResult Function(bool show) showArchive,
    required TResult Function(bool include) includeArchived,
    required TResult Function() removeIncludeArchived,
    required TResult Function(Set<String> tags) tagsChanged,
    required TResult Function(String tag) removeTag,
    required TResult Function(NoteSortOrder order) sortChanged,
    required TResult Function(List<SavedNoteView> views) savedViewsChanged,
    required TResult Function(SavedNoteView view) applySavedView,
    required TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)
        setArchived,
    required TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)
        setTags,
    required TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)
        setCardStyle,
    required TResult Function(String noteId) togglePin,
    required TResult Function(List<String> ids) restoreNotes,
    required TResult Function(List<String> ids) permanentDelete,
    required TResult Function(String name, Completer<String?>? completion)
        createFolder,
    required TResult Function(String id, String name) renameFolder,
    required TResult Function(String id) deleteFolder,
    required TResult Function(String noteId, String? folderId) moveNoteToFolder,
  }) {
    return moveNoteToFolder(noteId, folderId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult? Function()? getAllNotes,
    TResult? Function(Note note)? duplicateNote,
    TResult? Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult? Function(String query)? searchChanged,
    TResult? Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult? Function(NoteSearchFilter filter)? removeFilter,
    TResult? Function(String? folderId, bool preserveScope)? selectFolder,
    TResult? Function(bool show)? showTrash,
    TResult? Function(bool show)? showArchive,
    TResult? Function(bool include)? includeArchived,
    TResult? Function()? removeIncludeArchived,
    TResult? Function(Set<String> tags)? tagsChanged,
    TResult? Function(String tag)? removeTag,
    TResult? Function(NoteSortOrder order)? sortChanged,
    TResult? Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult? Function(SavedNoteView view)? applySavedView,
    TResult? Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult? Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult? Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult? Function(String noteId)? togglePin,
    TResult? Function(List<String> ids)? restoreNotes,
    TResult? Function(List<String> ids)? permanentDelete,
    TResult? Function(String name, Completer<String?>? completion)?
        createFolder,
    TResult? Function(String id, String name)? renameFolder,
    TResult? Function(String id)? deleteFolder,
    TResult? Function(String noteId, String? folderId)? moveNoteToFolder,
  }) {
    return moveNoteToFolder?.call(noteId, folderId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId, String todoId, bool? completed,
            Completer<HomeChecklistResult>? completion)?
        updateTodo,
    TResult Function()? getAllNotes,
    TResult Function(Note note)? duplicateNote,
    TResult Function(List<Note> notes, Completer<String?>? completion)?
        reorderNotes,
    TResult Function(String query)? searchChanged,
    TResult Function(Set<NoteSearchFilter> filters)? filtersChanged,
    TResult Function(NoteSearchFilter filter)? removeFilter,
    TResult Function(String? folderId, bool preserveScope)? selectFolder,
    TResult Function(bool show)? showTrash,
    TResult Function(bool show)? showArchive,
    TResult Function(bool include)? includeArchived,
    TResult Function()? removeIncludeArchived,
    TResult Function(Set<String> tags)? tagsChanged,
    TResult Function(String tag)? removeTag,
    TResult Function(NoteSortOrder order)? sortChanged,
    TResult Function(List<SavedNoteView> views)? savedViewsChanged,
    TResult Function(SavedNoteView view)? applySavedView,
    TResult Function(String noteId, bool archived,
            Completer<HomeArchiveResult>? completion)?
        setArchived,
    TResult Function(
            String noteId, List<String> tags, Completer<String?>? completion)?
        setTags,
    TResult Function(String noteId, NoteCardStyle style, Color? color,
            bool updateColor, Completer<String?>? completion)?
        setCardStyle,
    TResult Function(String noteId)? togglePin,
    TResult Function(List<String> ids)? restoreNotes,
    TResult Function(List<String> ids)? permanentDelete,
    TResult Function(String name, Completer<String?>? completion)? createFolder,
    TResult Function(String id, String name)? renameFolder,
    TResult Function(String id)? deleteFolder,
    TResult Function(String noteId, String? folderId)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (moveNoteToFolder != null) {
      return moveNoteToFolder(noteId, folderId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_UpdateTodo value) updateTodo,
    required TResult Function(_GetAllNotes value) getAllNotes,
    required TResult Function(_DuplicateNote value) duplicateNote,
    required TResult Function(_ReorderNotes value) reorderNotes,
    required TResult Function(_SearchChanged value) searchChanged,
    required TResult Function(_FiltersChanged value) filtersChanged,
    required TResult Function(_RemoveFilter value) removeFilter,
    required TResult Function(_SelectFolder value) selectFolder,
    required TResult Function(_ShowTrash value) showTrash,
    required TResult Function(_ShowArchive value) showArchive,
    required TResult Function(_IncludeArchived value) includeArchived,
    required TResult Function(_RemoveIncludeArchived value)
        removeIncludeArchived,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_RemoveTag value) removeTag,
    required TResult Function(_SortChanged value) sortChanged,
    required TResult Function(_SavedViewsChanged value) savedViewsChanged,
    required TResult Function(_ApplySavedView value) applySavedView,
    required TResult Function(_SetArchived value) setArchived,
    required TResult Function(_SetTags value) setTags,
    required TResult Function(_SetCardStyle value) setCardStyle,
    required TResult Function(_TogglePin value) togglePin,
    required TResult Function(_RestoreNotes value) restoreNotes,
    required TResult Function(_PermanentDelete value) permanentDelete,
    required TResult Function(_CreateFolder value) createFolder,
    required TResult Function(_RenameFolder value) renameFolder,
    required TResult Function(_DeleteFolder value) deleteFolder,
    required TResult Function(_MoveNoteToFolder value) moveNoteToFolder,
  }) {
    return moveNoteToFolder(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_UpdateTodo value)? updateTodo,
    TResult? Function(_GetAllNotes value)? getAllNotes,
    TResult? Function(_DuplicateNote value)? duplicateNote,
    TResult? Function(_ReorderNotes value)? reorderNotes,
    TResult? Function(_SearchChanged value)? searchChanged,
    TResult? Function(_FiltersChanged value)? filtersChanged,
    TResult? Function(_RemoveFilter value)? removeFilter,
    TResult? Function(_SelectFolder value)? selectFolder,
    TResult? Function(_ShowTrash value)? showTrash,
    TResult? Function(_ShowArchive value)? showArchive,
    TResult? Function(_IncludeArchived value)? includeArchived,
    TResult? Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_RemoveTag value)? removeTag,
    TResult? Function(_SortChanged value)? sortChanged,
    TResult? Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult? Function(_ApplySavedView value)? applySavedView,
    TResult? Function(_SetArchived value)? setArchived,
    TResult? Function(_SetTags value)? setTags,
    TResult? Function(_SetCardStyle value)? setCardStyle,
    TResult? Function(_TogglePin value)? togglePin,
    TResult? Function(_RestoreNotes value)? restoreNotes,
    TResult? Function(_PermanentDelete value)? permanentDelete,
    TResult? Function(_CreateFolder value)? createFolder,
    TResult? Function(_RenameFolder value)? renameFolder,
    TResult? Function(_DeleteFolder value)? deleteFolder,
    TResult? Function(_MoveNoteToFolder value)? moveNoteToFolder,
  }) {
    return moveNoteToFolder?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_UpdateTodo value)? updateTodo,
    TResult Function(_GetAllNotes value)? getAllNotes,
    TResult Function(_DuplicateNote value)? duplicateNote,
    TResult Function(_ReorderNotes value)? reorderNotes,
    TResult Function(_SearchChanged value)? searchChanged,
    TResult Function(_FiltersChanged value)? filtersChanged,
    TResult Function(_RemoveFilter value)? removeFilter,
    TResult Function(_SelectFolder value)? selectFolder,
    TResult Function(_ShowTrash value)? showTrash,
    TResult Function(_ShowArchive value)? showArchive,
    TResult Function(_IncludeArchived value)? includeArchived,
    TResult Function(_RemoveIncludeArchived value)? removeIncludeArchived,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_RemoveTag value)? removeTag,
    TResult Function(_SortChanged value)? sortChanged,
    TResult Function(_SavedViewsChanged value)? savedViewsChanged,
    TResult Function(_ApplySavedView value)? applySavedView,
    TResult Function(_SetArchived value)? setArchived,
    TResult Function(_SetTags value)? setTags,
    TResult Function(_SetCardStyle value)? setCardStyle,
    TResult Function(_TogglePin value)? togglePin,
    TResult Function(_RestoreNotes value)? restoreNotes,
    TResult Function(_PermanentDelete value)? permanentDelete,
    TResult Function(_CreateFolder value)? createFolder,
    TResult Function(_RenameFolder value)? renameFolder,
    TResult Function(_DeleteFolder value)? deleteFolder,
    TResult Function(_MoveNoteToFolder value)? moveNoteToFolder,
    required TResult orElse(),
  }) {
    if (moveNoteToFolder != null) {
      return moveNoteToFolder(this);
    }
    return orElse();
  }
}

abstract class _MoveNoteToFolder implements HomeEvent {
  const factory _MoveNoteToFolder(
      {required final String noteId,
      final String? folderId}) = _$MoveNoteToFolderImpl;

  String get noteId;
  String? get folderId;
  @JsonKey(ignore: true)
  _$$MoveNoteToFolderImplCopyWith<_$MoveNoteToFolderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HomeState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)
        loaded,
    required TResult Function(String? message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult? Function(String? message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeStateCopyWith<$Res> {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) then) =
      _$HomeStateCopyWithImpl<$Res, HomeState>;
}

/// @nodoc
class _$HomeStateCopyWithImpl<$Res, $Val extends HomeState>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$HomeStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'HomeState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)
        loaded,
    required TResult Function(String? message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult? Function(String? message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements HomeState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$HomeStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'HomeState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)
        loaded,
    required TResult Function(String? message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult? Function(String? message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements HomeState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
          _$LoadedImpl value, $Res Function(_$LoadedImpl) then) =
      __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<Note> notes,
      List<Folder> folders,
      String searchQuery,
      Set<NoteSearchFilter> filters,
      String? selectedFolderId,
      bool showTrash,
      bool showArchive,
      bool includeArchived,
      int archiveCount,
      Set<String> selectedTags,
      List<String> availableTags,
      List<SavedNoteView> savedViews,
      String? selectedViewId,
      NoteSortOrder sortOrder,
      int trashCount,
      Map<String, int> folderCounts,
      int allNotesCount});
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$HomeStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
      _$LoadedImpl _value, $Res Function(_$LoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notes = null,
    Object? folders = null,
    Object? searchQuery = null,
    Object? filters = null,
    Object? selectedFolderId = freezed,
    Object? showTrash = null,
    Object? showArchive = null,
    Object? includeArchived = null,
    Object? archiveCount = null,
    Object? selectedTags = null,
    Object? availableTags = null,
    Object? savedViews = null,
    Object? selectedViewId = freezed,
    Object? sortOrder = null,
    Object? trashCount = null,
    Object? folderCounts = null,
    Object? allNotesCount = null,
  }) {
    return _then(_$LoadedImpl(
      notes: null == notes
          ? _value._notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<Note>,
      folders: null == folders
          ? _value._folders
          : folders // ignore: cast_nullable_to_non_nullable
              as List<Folder>,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      filters: null == filters
          ? _value._filters
          : filters // ignore: cast_nullable_to_non_nullable
              as Set<NoteSearchFilter>,
      selectedFolderId: freezed == selectedFolderId
          ? _value.selectedFolderId
          : selectedFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      showTrash: null == showTrash
          ? _value.showTrash
          : showTrash // ignore: cast_nullable_to_non_nullable
              as bool,
      showArchive: null == showArchive
          ? _value.showArchive
          : showArchive // ignore: cast_nullable_to_non_nullable
              as bool,
      includeArchived: null == includeArchived
          ? _value.includeArchived
          : includeArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      archiveCount: null == archiveCount
          ? _value.archiveCount
          : archiveCount // ignore: cast_nullable_to_non_nullable
              as int,
      selectedTags: null == selectedTags
          ? _value._selectedTags
          : selectedTags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      availableTags: null == availableTags
          ? _value._availableTags
          : availableTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      savedViews: null == savedViews
          ? _value._savedViews
          : savedViews // ignore: cast_nullable_to_non_nullable
              as List<SavedNoteView>,
      selectedViewId: freezed == selectedViewId
          ? _value.selectedViewId
          : selectedViewId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as NoteSortOrder,
      trashCount: null == trashCount
          ? _value.trashCount
          : trashCount // ignore: cast_nullable_to_non_nullable
              as int,
      folderCounts: null == folderCounts
          ? _value._folderCounts
          : folderCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      allNotesCount: null == allNotesCount
          ? _value.allNotesCount
          : allNotesCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl(
      {required final List<Note> notes,
      required final List<Folder> folders,
      this.searchQuery = '',
      final Set<NoteSearchFilter> filters = const <NoteSearchFilter>{},
      this.selectedFolderId,
      this.showTrash = false,
      this.showArchive = false,
      this.includeArchived = false,
      this.archiveCount = 0,
      final Set<String> selectedTags = const <String>{},
      final List<String> availableTags = const <String>[],
      final List<SavedNoteView> savedViews = const <SavedNoteView>[],
      this.selectedViewId,
      this.sortOrder = NoteSortOrder.manual,
      this.trashCount = 0,
      final Map<String, int> folderCounts = const <String, int>{},
      this.allNotesCount = 0})
      : _notes = notes,
        _folders = folders,
        _filters = filters,
        _selectedTags = selectedTags,
        _availableTags = availableTags,
        _savedViews = savedViews,
        _folderCounts = folderCounts;

  final List<Note> _notes;
  @override
  List<Note> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  final List<Folder> _folders;
  @override
  List<Folder> get folders {
    if (_folders is EqualUnmodifiableListView) return _folders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_folders);
  }

  @override
  @JsonKey()
  final String searchQuery;
  final Set<NoteSearchFilter> _filters;
  @override
  @JsonKey()
  Set<NoteSearchFilter> get filters {
    if (_filters is EqualUnmodifiableSetView) return _filters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_filters);
  }

  @override
  final String? selectedFolderId;
  @override
  @JsonKey()
  final bool showTrash;
  @override
  @JsonKey()
  final bool showArchive;
  @override
  @JsonKey()
  final bool includeArchived;
  @override
  @JsonKey()
  final int archiveCount;
  final Set<String> _selectedTags;
  @override
  @JsonKey()
  Set<String> get selectedTags {
    if (_selectedTags is EqualUnmodifiableSetView) return _selectedTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedTags);
  }

  final List<String> _availableTags;
  @override
  @JsonKey()
  List<String> get availableTags {
    if (_availableTags is EqualUnmodifiableListView) return _availableTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableTags);
  }

  final List<SavedNoteView> _savedViews;
  @override
  @JsonKey()
  List<SavedNoteView> get savedViews {
    if (_savedViews is EqualUnmodifiableListView) return _savedViews;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_savedViews);
  }

  @override
  final String? selectedViewId;
  @override
  @JsonKey()
  final NoteSortOrder sortOrder;
  @override
  @JsonKey()
  final int trashCount;

  /// Active notes per folder id, for the folder picker. Counts ignore the
  /// current search so the picker always shows what each folder holds, not
  /// what happens to match right now.
  final Map<String, int> _folderCounts;

  /// Active notes per folder id, for the folder picker. Counts ignore the
  /// current search so the picker always shows what each folder holds, not
  /// what happens to match right now.
  @override
  @JsonKey()
  Map<String, int> get folderCounts {
    if (_folderCounts is EqualUnmodifiableMapView) return _folderCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_folderCounts);
  }

  @override
  @JsonKey()
  final int allNotesCount;

  @override
  String toString() {
    return 'HomeState.loaded(notes: $notes, folders: $folders, searchQuery: $searchQuery, filters: $filters, selectedFolderId: $selectedFolderId, showTrash: $showTrash, showArchive: $showArchive, includeArchived: $includeArchived, archiveCount: $archiveCount, selectedTags: $selectedTags, availableTags: $availableTags, savedViews: $savedViews, selectedViewId: $selectedViewId, sortOrder: $sortOrder, trashCount: $trashCount, folderCounts: $folderCounts, allNotesCount: $allNotesCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            const DeepCollectionEquality().equals(other._notes, _notes) &&
            const DeepCollectionEquality().equals(other._folders, _folders) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            const DeepCollectionEquality().equals(other._filters, _filters) &&
            (identical(other.selectedFolderId, selectedFolderId) ||
                other.selectedFolderId == selectedFolderId) &&
            (identical(other.showTrash, showTrash) ||
                other.showTrash == showTrash) &&
            (identical(other.showArchive, showArchive) ||
                other.showArchive == showArchive) &&
            (identical(other.includeArchived, includeArchived) ||
                other.includeArchived == includeArchived) &&
            (identical(other.archiveCount, archiveCount) ||
                other.archiveCount == archiveCount) &&
            const DeepCollectionEquality()
                .equals(other._selectedTags, _selectedTags) &&
            const DeepCollectionEquality()
                .equals(other._availableTags, _availableTags) &&
            const DeepCollectionEquality()
                .equals(other._savedViews, _savedViews) &&
            (identical(other.selectedViewId, selectedViewId) ||
                other.selectedViewId == selectedViewId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.trashCount, trashCount) ||
                other.trashCount == trashCount) &&
            const DeepCollectionEquality()
                .equals(other._folderCounts, _folderCounts) &&
            (identical(other.allNotesCount, allNotesCount) ||
                other.allNotesCount == allNotesCount));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_notes),
      const DeepCollectionEquality().hash(_folders),
      searchQuery,
      const DeepCollectionEquality().hash(_filters),
      selectedFolderId,
      showTrash,
      showArchive,
      includeArchived,
      archiveCount,
      const DeepCollectionEquality().hash(_selectedTags),
      const DeepCollectionEquality().hash(_availableTags),
      const DeepCollectionEquality().hash(_savedViews),
      selectedViewId,
      sortOrder,
      trashCount,
      const DeepCollectionEquality().hash(_folderCounts),
      allNotesCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)
        loaded,
    required TResult Function(String? message) error,
  }) {
    return loaded(
        notes,
        folders,
        searchQuery,
        filters,
        selectedFolderId,
        showTrash,
        showArchive,
        includeArchived,
        archiveCount,
        selectedTags,
        availableTags,
        savedViews,
        selectedViewId,
        sortOrder,
        trashCount,
        folderCounts,
        allNotesCount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult? Function(String? message)? error,
  }) {
    return loaded?.call(
        notes,
        folders,
        searchQuery,
        filters,
        selectedFolderId,
        showTrash,
        showArchive,
        includeArchived,
        archiveCount,
        selectedTags,
        availableTags,
        savedViews,
        selectedViewId,
        sortOrder,
        trashCount,
        folderCounts,
        allNotesCount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(
          notes,
          folders,
          searchQuery,
          filters,
          selectedFolderId,
          showTrash,
          showArchive,
          includeArchived,
          archiveCount,
          selectedTags,
          availableTags,
          savedViews,
          selectedViewId,
          sortOrder,
          trashCount,
          folderCounts,
          allNotesCount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements HomeState {
  const factory _Loaded(
      {required final List<Note> notes,
      required final List<Folder> folders,
      final String searchQuery,
      final Set<NoteSearchFilter> filters,
      final String? selectedFolderId,
      final bool showTrash,
      final bool showArchive,
      final bool includeArchived,
      final int archiveCount,
      final Set<String> selectedTags,
      final List<String> availableTags,
      final List<SavedNoteView> savedViews,
      final String? selectedViewId,
      final NoteSortOrder sortOrder,
      final int trashCount,
      final Map<String, int> folderCounts,
      final int allNotesCount}) = _$LoadedImpl;

  List<Note> get notes;
  List<Folder> get folders;
  String get searchQuery;
  Set<NoteSearchFilter> get filters;
  String? get selectedFolderId;
  bool get showTrash;
  bool get showArchive;
  bool get includeArchived;
  int get archiveCount;
  Set<String> get selectedTags;
  List<String> get availableTags;
  List<SavedNoteView> get savedViews;
  String? get selectedViewId;
  NoteSortOrder get sortOrder;
  int get trashCount;

  /// Active notes per folder id, for the folder picker. Counts ignore the
  /// current search so the picker always shows what each folder holds, not
  /// what happens to match right now.
  Map<String, int> get folderCounts;
  int get allNotesCount;
  @JsonKey(ignore: true)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$HomeStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$ErrorImpl(
      freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String? message;

  @override
  String toString() {
    return 'HomeState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)
        loaded,
    required TResult Function(String? message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult? Function(String? message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
            List<Note> notes,
            List<Folder> folders,
            String searchQuery,
            Set<NoteSearchFilter> filters,
            String? selectedFolderId,
            bool showTrash,
            bool showArchive,
            bool includeArchived,
            int archiveCount,
            Set<String> selectedTags,
            List<String> availableTags,
            List<SavedNoteView> savedViews,
            String? selectedViewId,
            NoteSortOrder sortOrder,
            int trashCount,
            Map<String, int> folderCounts,
            int allNotesCount)?
        loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements HomeState {
  const factory _Error(final String? message) = _$ErrorImpl;

  String? get message;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
