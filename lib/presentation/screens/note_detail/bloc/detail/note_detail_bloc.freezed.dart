// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NoteDetailEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) showNote,
    required TResult Function(String todoId) toggleTodoCheckbox,
    required TResult Function(
            String noteId, Completer<List<String>?>? completion)
        resetChecklist,
    required TResult Function(String noteId, List<String> todoIds)
        restoreCompletedTodos,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? showNote,
    TResult? Function(String todoId)? toggleTodoCheckbox,
    TResult? Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult? Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? showNote,
    TResult Function(String todoId)? toggleTodoCheckbox,
    TResult Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowNote value) showNote,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_ResetChecklist value) resetChecklist,
    required TResult Function(_RestoreCompletedTodos value)
        restoreCompletedTodos,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ShowNote value)? showNote,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_ResetChecklist value)? resetChecklist,
    TResult? Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowNote value)? showNote,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_ResetChecklist value)? resetChecklist,
    TResult Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteDetailEventCopyWith<$Res> {
  factory $NoteDetailEventCopyWith(
          NoteDetailEvent value, $Res Function(NoteDetailEvent) then) =
      _$NoteDetailEventCopyWithImpl<$Res, NoteDetailEvent>;
}

/// @nodoc
class _$NoteDetailEventCopyWithImpl<$Res, $Val extends NoteDetailEvent>
    implements $NoteDetailEventCopyWith<$Res> {
  _$NoteDetailEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$ShowNoteImplCopyWith<$Res> {
  factory _$$ShowNoteImplCopyWith(
          _$ShowNoteImpl value, $Res Function(_$ShowNoteImpl) then) =
      __$$ShowNoteImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String noteId});
}

/// @nodoc
class __$$ShowNoteImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$ShowNoteImpl>
    implements _$$ShowNoteImplCopyWith<$Res> {
  __$$ShowNoteImplCopyWithImpl(
      _$ShowNoteImpl _value, $Res Function(_$ShowNoteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
  }) {
    return _then(_$ShowNoteImpl(
      null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ShowNoteImpl implements _ShowNote {
  const _$ShowNoteImpl(this.noteId);

  @override
  final String noteId;

  @override
  String toString() {
    return 'NoteDetailEvent.showNote(noteId: $noteId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShowNoteImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShowNoteImplCopyWith<_$ShowNoteImpl> get copyWith =>
      __$$ShowNoteImplCopyWithImpl<_$ShowNoteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) showNote,
    required TResult Function(String todoId) toggleTodoCheckbox,
    required TResult Function(
            String noteId, Completer<List<String>?>? completion)
        resetChecklist,
    required TResult Function(String noteId, List<String> todoIds)
        restoreCompletedTodos,
  }) {
    return showNote(noteId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? showNote,
    TResult? Function(String todoId)? toggleTodoCheckbox,
    TResult? Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult? Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
  }) {
    return showNote?.call(noteId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? showNote,
    TResult Function(String todoId)? toggleTodoCheckbox,
    TResult Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (showNote != null) {
      return showNote(noteId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowNote value) showNote,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_ResetChecklist value) resetChecklist,
    required TResult Function(_RestoreCompletedTodos value)
        restoreCompletedTodos,
  }) {
    return showNote(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ShowNote value)? showNote,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_ResetChecklist value)? resetChecklist,
    TResult? Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
  }) {
    return showNote?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowNote value)? showNote,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_ResetChecklist value)? resetChecklist,
    TResult Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (showNote != null) {
      return showNote(this);
    }
    return orElse();
  }
}

abstract class _ShowNote implements NoteDetailEvent {
  const factory _ShowNote(final String noteId) = _$ShowNoteImpl;

  String get noteId;
  @JsonKey(ignore: true)
  _$$ShowNoteImplCopyWith<_$ShowNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ToggleTodoCheckboxImplCopyWith<$Res> {
  factory _$$ToggleTodoCheckboxImplCopyWith(_$ToggleTodoCheckboxImpl value,
          $Res Function(_$ToggleTodoCheckboxImpl) then) =
      __$$ToggleTodoCheckboxImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String todoId});
}

/// @nodoc
class __$$ToggleTodoCheckboxImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$ToggleTodoCheckboxImpl>
    implements _$$ToggleTodoCheckboxImplCopyWith<$Res> {
  __$$ToggleTodoCheckboxImplCopyWithImpl(_$ToggleTodoCheckboxImpl _value,
      $Res Function(_$ToggleTodoCheckboxImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
  }) {
    return _then(_$ToggleTodoCheckboxImpl(
      null == todoId
          ? _value.todoId
          : todoId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ToggleTodoCheckboxImpl implements _ToggleTodoCheckbox {
  const _$ToggleTodoCheckboxImpl(this.todoId);

  @override
  final String todoId;

  @override
  String toString() {
    return 'NoteDetailEvent.toggleTodoCheckbox(todoId: $todoId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToggleTodoCheckboxImpl &&
            (identical(other.todoId, todoId) || other.todoId == todoId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, todoId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToggleTodoCheckboxImplCopyWith<_$ToggleTodoCheckboxImpl> get copyWith =>
      __$$ToggleTodoCheckboxImplCopyWithImpl<_$ToggleTodoCheckboxImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) showNote,
    required TResult Function(String todoId) toggleTodoCheckbox,
    required TResult Function(
            String noteId, Completer<List<String>?>? completion)
        resetChecklist,
    required TResult Function(String noteId, List<String> todoIds)
        restoreCompletedTodos,
  }) {
    return toggleTodoCheckbox(todoId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? showNote,
    TResult? Function(String todoId)? toggleTodoCheckbox,
    TResult? Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult? Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
  }) {
    return toggleTodoCheckbox?.call(todoId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? showNote,
    TResult Function(String todoId)? toggleTodoCheckbox,
    TResult Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (toggleTodoCheckbox != null) {
      return toggleTodoCheckbox(todoId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowNote value) showNote,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_ResetChecklist value) resetChecklist,
    required TResult Function(_RestoreCompletedTodos value)
        restoreCompletedTodos,
  }) {
    return toggleTodoCheckbox(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ShowNote value)? showNote,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_ResetChecklist value)? resetChecklist,
    TResult? Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
  }) {
    return toggleTodoCheckbox?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowNote value)? showNote,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_ResetChecklist value)? resetChecklist,
    TResult Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (toggleTodoCheckbox != null) {
      return toggleTodoCheckbox(this);
    }
    return orElse();
  }
}

abstract class _ToggleTodoCheckbox implements NoteDetailEvent {
  const factory _ToggleTodoCheckbox(final String todoId) =
      _$ToggleTodoCheckboxImpl;

  String get todoId;
  @JsonKey(ignore: true)
  _$$ToggleTodoCheckboxImplCopyWith<_$ToggleTodoCheckboxImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ResetChecklistImplCopyWith<$Res> {
  factory _$$ResetChecklistImplCopyWith(_$ResetChecklistImpl value,
          $Res Function(_$ResetChecklistImpl) then) =
      __$$ResetChecklistImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String noteId, Completer<List<String>?>? completion});
}

/// @nodoc
class __$$ResetChecklistImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$ResetChecklistImpl>
    implements _$$ResetChecklistImplCopyWith<$Res> {
  __$$ResetChecklistImplCopyWithImpl(
      _$ResetChecklistImpl _value, $Res Function(_$ResetChecklistImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? completion = freezed,
  }) {
    return _then(_$ResetChecklistImpl(
      noteId: null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
      completion: freezed == completion
          ? _value.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as Completer<List<String>?>?,
    ));
  }
}

/// @nodoc

class _$ResetChecklistImpl implements _ResetChecklist {
  const _$ResetChecklistImpl({required this.noteId, this.completion});

  @override
  final String noteId;
  @override
  final Completer<List<String>?>? completion;

  @override
  String toString() {
    return 'NoteDetailEvent.resetChecklist(noteId: $noteId, completion: $completion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResetChecklistImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            (identical(other.completion, completion) ||
                other.completion == completion));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId, completion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ResetChecklistImplCopyWith<_$ResetChecklistImpl> get copyWith =>
      __$$ResetChecklistImplCopyWithImpl<_$ResetChecklistImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) showNote,
    required TResult Function(String todoId) toggleTodoCheckbox,
    required TResult Function(
            String noteId, Completer<List<String>?>? completion)
        resetChecklist,
    required TResult Function(String noteId, List<String> todoIds)
        restoreCompletedTodos,
  }) {
    return resetChecklist(noteId, completion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? showNote,
    TResult? Function(String todoId)? toggleTodoCheckbox,
    TResult? Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult? Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
  }) {
    return resetChecklist?.call(noteId, completion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? showNote,
    TResult Function(String todoId)? toggleTodoCheckbox,
    TResult Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (resetChecklist != null) {
      return resetChecklist(noteId, completion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowNote value) showNote,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_ResetChecklist value) resetChecklist,
    required TResult Function(_RestoreCompletedTodos value)
        restoreCompletedTodos,
  }) {
    return resetChecklist(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ShowNote value)? showNote,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_ResetChecklist value)? resetChecklist,
    TResult? Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
  }) {
    return resetChecklist?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowNote value)? showNote,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_ResetChecklist value)? resetChecklist,
    TResult Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (resetChecklist != null) {
      return resetChecklist(this);
    }
    return orElse();
  }
}

abstract class _ResetChecklist implements NoteDetailEvent {
  const factory _ResetChecklist(
      {required final String noteId,
      final Completer<List<String>?>? completion}) = _$ResetChecklistImpl;

  String get noteId;
  Completer<List<String>?>? get completion;
  @JsonKey(ignore: true)
  _$$ResetChecklistImplCopyWith<_$ResetChecklistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RestoreCompletedTodosImplCopyWith<$Res> {
  factory _$$RestoreCompletedTodosImplCopyWith(
          _$RestoreCompletedTodosImpl value,
          $Res Function(_$RestoreCompletedTodosImpl) then) =
      __$$RestoreCompletedTodosImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String noteId, List<String> todoIds});
}

/// @nodoc
class __$$RestoreCompletedTodosImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$RestoreCompletedTodosImpl>
    implements _$$RestoreCompletedTodosImplCopyWith<$Res> {
  __$$RestoreCompletedTodosImplCopyWithImpl(_$RestoreCompletedTodosImpl _value,
      $Res Function(_$RestoreCompletedTodosImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noteId = null,
    Object? todoIds = null,
  }) {
    return _then(_$RestoreCompletedTodosImpl(
      noteId: null == noteId
          ? _value.noteId
          : noteId // ignore: cast_nullable_to_non_nullable
              as String,
      todoIds: null == todoIds
          ? _value._todoIds
          : todoIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$RestoreCompletedTodosImpl implements _RestoreCompletedTodos {
  const _$RestoreCompletedTodosImpl(
      {required this.noteId, required final List<String> todoIds})
      : _todoIds = todoIds;

  @override
  final String noteId;
  final List<String> _todoIds;
  @override
  List<String> get todoIds {
    if (_todoIds is EqualUnmodifiableListView) return _todoIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_todoIds);
  }

  @override
  String toString() {
    return 'NoteDetailEvent.restoreCompletedTodos(noteId: $noteId, todoIds: $todoIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestoreCompletedTodosImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId) &&
            const DeepCollectionEquality().equals(other._todoIds, _todoIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, noteId, const DeepCollectionEquality().hash(_todoIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RestoreCompletedTodosImplCopyWith<_$RestoreCompletedTodosImpl>
      get copyWith => __$$RestoreCompletedTodosImplCopyWithImpl<
          _$RestoreCompletedTodosImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) showNote,
    required TResult Function(String todoId) toggleTodoCheckbox,
    required TResult Function(
            String noteId, Completer<List<String>?>? completion)
        resetChecklist,
    required TResult Function(String noteId, List<String> todoIds)
        restoreCompletedTodos,
  }) {
    return restoreCompletedTodos(noteId, todoIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? showNote,
    TResult? Function(String todoId)? toggleTodoCheckbox,
    TResult? Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult? Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
  }) {
    return restoreCompletedTodos?.call(noteId, todoIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? showNote,
    TResult Function(String todoId)? toggleTodoCheckbox,
    TResult Function(String noteId, Completer<List<String>?>? completion)?
        resetChecklist,
    TResult Function(String noteId, List<String> todoIds)?
        restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (restoreCompletedTodos != null) {
      return restoreCompletedTodos(noteId, todoIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ShowNote value) showNote,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_ResetChecklist value) resetChecklist,
    required TResult Function(_RestoreCompletedTodos value)
        restoreCompletedTodos,
  }) {
    return restoreCompletedTodos(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ShowNote value)? showNote,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_ResetChecklist value)? resetChecklist,
    TResult? Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
  }) {
    return restoreCompletedTodos?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ShowNote value)? showNote,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_ResetChecklist value)? resetChecklist,
    TResult Function(_RestoreCompletedTodos value)? restoreCompletedTodos,
    required TResult orElse(),
  }) {
    if (restoreCompletedTodos != null) {
      return restoreCompletedTodos(this);
    }
    return orElse();
  }
}

abstract class _RestoreCompletedTodos implements NoteDetailEvent {
  const factory _RestoreCompletedTodos(
      {required final String noteId,
      required final List<String> todoIds}) = _$RestoreCompletedTodosImpl;

  String get noteId;
  List<String> get todoIds;
  @JsonKey(ignore: true)
  _$$RestoreCompletedTodosImplCopyWith<_$RestoreCompletedTodosImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$NoteDetailState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Note note) success,
    required TResult Function(String? message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Note note)? success,
    TResult? Function(String? message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Note note)? success,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) success,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? success,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteDetailStateCopyWith<$Res> {
  factory $NoteDetailStateCopyWith(
          NoteDetailState value, $Res Function(NoteDetailState) then) =
      _$NoteDetailStateCopyWithImpl<$Res, NoteDetailState>;
}

/// @nodoc
class _$NoteDetailStateCopyWithImpl<$Res, $Val extends NoteDetailState>
    implements $NoteDetailStateCopyWith<$Res> {
  _$NoteDetailStateCopyWithImpl(this._value, this._then);

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
    extends _$NoteDetailStateCopyWithImpl<$Res, _$InitialImpl>
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
    return 'NoteDetailState.initial()';
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
    required TResult Function(Note note) success,
    required TResult Function(String? message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Note note)? success,
    TResult? Function(String? message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Note note)? success,
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
    required TResult Function(_Loaded value) success,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements NoteDetailState {
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
    extends _$NoteDetailStateCopyWithImpl<$Res, _$LoadingImpl>
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
    return 'NoteDetailState.loading()';
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
    required TResult Function(Note note) success,
    required TResult Function(String? message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Note note)? success,
    TResult? Function(String? message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Note note)? success,
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
    required TResult Function(_Loaded value) success,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements NoteDetailState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
          _$LoadedImpl value, $Res Function(_$LoadedImpl) then) =
      __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Note note});

  $NoteCopyWith<$Res> get note;
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$NoteDetailStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
      _$LoadedImpl _value, $Res Function(_$LoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? note = null,
  }) {
    return _then(_$LoadedImpl(
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

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl(this.note);

  @override
  final Note note;

  @override
  String toString() {
    return 'NoteDetailState.success(note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode => Object.hash(runtimeType, note);

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
    required TResult Function(Note note) success,
    required TResult Function(String? message) error,
  }) {
    return success(note);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Note note)? success,
    TResult? Function(String? message)? error,
  }) {
    return success?.call(note);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Note note)? success,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(note);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) success,
    required TResult Function(_Error value) error,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements NoteDetailState {
  const factory _Loaded(final Note note) = _$LoadedImpl;

  Note get note;
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
    extends _$NoteDetailStateCopyWithImpl<$Res, _$ErrorImpl>
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
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'NoteDetailState.error(message: $message)';
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
    required TResult Function(Note note) success,
    required TResult Function(String? message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Note note)? success,
    TResult? Function(String? message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Note note)? success,
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
    required TResult Function(_Loaded value) success,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? success,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? success,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements NoteDetailState {
  const factory _Error({final String? message}) = _$ErrorImpl;

  String? get message;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
