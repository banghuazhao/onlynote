// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_update_form_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AddUpdateFormEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddUpdateFormEventCopyWith<$Res> {
  factory $AddUpdateFormEventCopyWith(
          AddUpdateFormEvent value, $Res Function(AddUpdateFormEvent) then) =
      _$AddUpdateFormEventCopyWithImpl<$Res, AddUpdateFormEvent>;
}

/// @nodoc
class _$AddUpdateFormEventCopyWithImpl<$Res, $Val extends AddUpdateFormEvent>
    implements $AddUpdateFormEventCopyWith<$Res> {
  _$AddUpdateFormEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$InitializeImplCopyWith<$Res> {
  factory _$$InitializeImplCopyWith(
          _$InitializeImpl value, $Res Function(_$InitializeImpl) then) =
      __$$InitializeImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String? title,
      String? description,
      List<NoteTextStyleRange>? textStyles,
      Color? color,
      List<Todo>? todos,
      List<String>? imagePaths,
      List<NoteImageLayout>? imageLayouts,
      List<VoiceMemo>? voiceMemos,
      List<String>? tags,
      List<String>? linkedNoteIds,
      String? dailyNoteDateKey});
}

/// @nodoc
class __$$InitializeImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$InitializeImpl>
    implements _$$InitializeImplCopyWith<$Res> {
  __$$InitializeImplCopyWithImpl(
      _$InitializeImpl _value, $Res Function(_$InitializeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? textStyles = freezed,
    Object? color = freezed,
    Object? todos = freezed,
    Object? imagePaths = freezed,
    Object? imageLayouts = freezed,
    Object? voiceMemos = freezed,
    Object? tags = freezed,
    Object? linkedNoteIds = freezed,
    Object? dailyNoteDateKey = freezed,
  }) {
    return _then(_$InitializeImpl(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      textStyles: freezed == textStyles
          ? _value._textStyles
          : textStyles // ignore: cast_nullable_to_non_nullable
              as List<NoteTextStyleRange>?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      todos: freezed == todos
          ? _value._todos
          : todos // ignore: cast_nullable_to_non_nullable
              as List<Todo>?,
      imagePaths: freezed == imagePaths
          ? _value._imagePaths
          : imagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      imageLayouts: freezed == imageLayouts
          ? _value._imageLayouts
          : imageLayouts // ignore: cast_nullable_to_non_nullable
              as List<NoteImageLayout>?,
      voiceMemos: freezed == voiceMemos
          ? _value._voiceMemos
          : voiceMemos // ignore: cast_nullable_to_non_nullable
              as List<VoiceMemo>?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      linkedNoteIds: freezed == linkedNoteIds
          ? _value._linkedNoteIds
          : linkedNoteIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      dailyNoteDateKey: freezed == dailyNoteDateKey
          ? _value.dailyNoteDateKey
          : dailyNoteDateKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$InitializeImpl implements _Initialize {
  const _$InitializeImpl(
      {this.title,
      this.description,
      final List<NoteTextStyleRange>? textStyles,
      this.color,
      final List<Todo>? todos,
      final List<String>? imagePaths,
      final List<NoteImageLayout>? imageLayouts,
      final List<VoiceMemo>? voiceMemos,
      final List<String>? tags,
      final List<String>? linkedNoteIds,
      this.dailyNoteDateKey})
      : _textStyles = textStyles,
        _todos = todos,
        _imagePaths = imagePaths,
        _imageLayouts = imageLayouts,
        _voiceMemos = voiceMemos,
        _tags = tags,
        _linkedNoteIds = linkedNoteIds;

  @override
  final String? title;
  @override
  final String? description;
  final List<NoteTextStyleRange>? _textStyles;
  @override
  List<NoteTextStyleRange>? get textStyles {
    final value = _textStyles;
    if (value == null) return null;
    if (_textStyles is EqualUnmodifiableListView) return _textStyles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final Color? color;
  final List<Todo>? _todos;
  @override
  List<Todo>? get todos {
    final value = _todos;
    if (value == null) return null;
    if (_todos is EqualUnmodifiableListView) return _todos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _imagePaths;
  @override
  List<String>? get imagePaths {
    final value = _imagePaths;
    if (value == null) return null;
    if (_imagePaths is EqualUnmodifiableListView) return _imagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<NoteImageLayout>? _imageLayouts;
  @override
  List<NoteImageLayout>? get imageLayouts {
    final value = _imageLayouts;
    if (value == null) return null;
    if (_imageLayouts is EqualUnmodifiableListView) return _imageLayouts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<VoiceMemo>? _voiceMemos;
  @override
  List<VoiceMemo>? get voiceMemos {
    final value = _voiceMemos;
    if (value == null) return null;
    if (_voiceMemos is EqualUnmodifiableListView) return _voiceMemos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _linkedNoteIds;
  @override
  List<String>? get linkedNoteIds {
    final value = _linkedNoteIds;
    if (value == null) return null;
    if (_linkedNoteIds is EqualUnmodifiableListView) return _linkedNoteIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? dailyNoteDateKey;

  @override
  String toString() {
    return 'AddUpdateFormEvent.initialize(title: $title, description: $description, textStyles: $textStyles, color: $color, todos: $todos, imagePaths: $imagePaths, imageLayouts: $imageLayouts, voiceMemos: $voiceMemos, tags: $tags, linkedNoteIds: $linkedNoteIds, dailyNoteDateKey: $dailyNoteDateKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InitializeImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._textStyles, _textStyles) &&
            (identical(other.color, color) || other.color == color) &&
            const DeepCollectionEquality().equals(other._todos, _todos) &&
            const DeepCollectionEquality()
                .equals(other._imagePaths, _imagePaths) &&
            const DeepCollectionEquality()
                .equals(other._imageLayouts, _imageLayouts) &&
            const DeepCollectionEquality()
                .equals(other._voiceMemos, _voiceMemos) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._linkedNoteIds, _linkedNoteIds) &&
            (identical(other.dailyNoteDateKey, dailyNoteDateKey) ||
                other.dailyNoteDateKey == dailyNoteDateKey));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      const DeepCollectionEquality().hash(_textStyles),
      color,
      const DeepCollectionEquality().hash(_todos),
      const DeepCollectionEquality().hash(_imagePaths),
      const DeepCollectionEquality().hash(_imageLayouts),
      const DeepCollectionEquality().hash(_voiceMemos),
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_linkedNoteIds),
      dailyNoteDateKey);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InitializeImplCopyWith<_$InitializeImpl> get copyWith =>
      __$$InitializeImplCopyWithImpl<_$InitializeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return initialize(title, description, textStyles, color, todos, imagePaths,
        imageLayouts, voiceMemos, tags, linkedNoteIds, dailyNoteDateKey);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return initialize?.call(
        title,
        description,
        textStyles,
        color,
        todos,
        imagePaths,
        imageLayouts,
        voiceMemos,
        tags,
        linkedNoteIds,
        dailyNoteDateKey);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (initialize != null) {
      return initialize(
          title,
          description,
          textStyles,
          color,
          todos,
          imagePaths,
          imageLayouts,
          voiceMemos,
          tags,
          linkedNoteIds,
          dailyNoteDateKey);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return initialize(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return initialize?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (initialize != null) {
      return initialize(this);
    }
    return orElse();
  }
}

abstract class _Initialize implements AddUpdateFormEvent {
  const factory _Initialize(
      {final String? title,
      final String? description,
      final List<NoteTextStyleRange>? textStyles,
      final Color? color,
      final List<Todo>? todos,
      final List<String>? imagePaths,
      final List<NoteImageLayout>? imageLayouts,
      final List<VoiceMemo>? voiceMemos,
      final List<String>? tags,
      final List<String>? linkedNoteIds,
      final String? dailyNoteDateKey}) = _$InitializeImpl;

  String? get title;
  String? get description;
  List<NoteTextStyleRange>? get textStyles;
  Color? get color;
  List<Todo>? get todos;
  List<String>? get imagePaths;
  List<NoteImageLayout>? get imageLayouts;
  List<VoiceMemo>? get voiceMemos;
  List<String>? get tags;
  List<String>? get linkedNoteIds;
  String? get dailyNoteDateKey;
  @JsonKey(ignore: true)
  _$$InitializeImplCopyWith<_$InitializeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TitleChangedImplCopyWith<$Res> {
  factory _$$TitleChangedImplCopyWith(
          _$TitleChangedImpl value, $Res Function(_$TitleChangedImpl) then) =
      __$$TitleChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$TitleChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$TitleChangedImpl>
    implements _$$TitleChangedImplCopyWith<$Res> {
  __$$TitleChangedImplCopyWithImpl(
      _$TitleChangedImpl _value, $Res Function(_$TitleChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$TitleChangedImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TitleChangedImpl implements _TitleChanged {
  const _$TitleChangedImpl(this.value);

  @override
  final String value;

  @override
  String toString() {
    return 'AddUpdateFormEvent.titleChanged(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TitleChangedImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TitleChangedImplCopyWith<_$TitleChangedImpl> get copyWith =>
      __$$TitleChangedImplCopyWithImpl<_$TitleChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return titleChanged(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return titleChanged?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (titleChanged != null) {
      return titleChanged(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return titleChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return titleChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (titleChanged != null) {
      return titleChanged(this);
    }
    return orElse();
  }
}

abstract class _TitleChanged implements AddUpdateFormEvent {
  const factory _TitleChanged(final String value) = _$TitleChangedImpl;

  String get value;
  @JsonKey(ignore: true)
  _$$TitleChangedImplCopyWith<_$TitleChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DescriptionChangedImplCopyWith<$Res> {
  factory _$$DescriptionChangedImplCopyWith(_$DescriptionChangedImpl value,
          $Res Function(_$DescriptionChangedImpl) then) =
      __$$DescriptionChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$DescriptionChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$DescriptionChangedImpl>
    implements _$$DescriptionChangedImplCopyWith<$Res> {
  __$$DescriptionChangedImplCopyWithImpl(_$DescriptionChangedImpl _value,
      $Res Function(_$DescriptionChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$DescriptionChangedImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DescriptionChangedImpl implements _DescriptionChanged {
  const _$DescriptionChangedImpl(this.value);

  @override
  final String value;

  @override
  String toString() {
    return 'AddUpdateFormEvent.descriptionChanged(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DescriptionChangedImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DescriptionChangedImplCopyWith<_$DescriptionChangedImpl> get copyWith =>
      __$$DescriptionChangedImplCopyWithImpl<_$DescriptionChangedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return descriptionChanged(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return descriptionChanged?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (descriptionChanged != null) {
      return descriptionChanged(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return descriptionChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return descriptionChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (descriptionChanged != null) {
      return descriptionChanged(this);
    }
    return orElse();
  }
}

abstract class _DescriptionChanged implements AddUpdateFormEvent {
  const factory _DescriptionChanged(final String value) =
      _$DescriptionChangedImpl;

  String get value;
  @JsonKey(ignore: true)
  _$$DescriptionChangedImplCopyWith<_$DescriptionChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BodyChangedImplCopyWith<$Res> {
  factory _$$BodyChangedImplCopyWith(
          _$BodyChangedImpl value, $Res Function(_$BodyChangedImpl) then) =
      __$$BodyChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String text,
      List<NoteTextStyleRange> styles,
      List<NoteImageLayout> layouts});
}

/// @nodoc
class __$$BodyChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$BodyChangedImpl>
    implements _$$BodyChangedImplCopyWith<$Res> {
  __$$BodyChangedImplCopyWithImpl(
      _$BodyChangedImpl _value, $Res Function(_$BodyChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? styles = null,
    Object? layouts = null,
  }) {
    return _then(_$BodyChangedImpl(
      null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      null == styles
          ? _value._styles
          : styles // ignore: cast_nullable_to_non_nullable
              as List<NoteTextStyleRange>,
      null == layouts
          ? _value._layouts
          : layouts // ignore: cast_nullable_to_non_nullable
              as List<NoteImageLayout>,
    ));
  }
}

/// @nodoc

class _$BodyChangedImpl implements _BodyChanged {
  const _$BodyChangedImpl(this.text, final List<NoteTextStyleRange> styles,
      final List<NoteImageLayout> layouts)
      : _styles = styles,
        _layouts = layouts;

  @override
  final String text;
  final List<NoteTextStyleRange> _styles;
  @override
  List<NoteTextStyleRange> get styles {
    if (_styles is EqualUnmodifiableListView) return _styles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_styles);
  }

  final List<NoteImageLayout> _layouts;
  @override
  List<NoteImageLayout> get layouts {
    if (_layouts is EqualUnmodifiableListView) return _layouts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_layouts);
  }

  @override
  String toString() {
    return 'AddUpdateFormEvent.bodyChanged(text: $text, styles: $styles, layouts: $layouts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BodyChangedImpl &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._styles, _styles) &&
            const DeepCollectionEquality().equals(other._layouts, _layouts));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      text,
      const DeepCollectionEquality().hash(_styles),
      const DeepCollectionEquality().hash(_layouts));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BodyChangedImplCopyWith<_$BodyChangedImpl> get copyWith =>
      __$$BodyChangedImplCopyWithImpl<_$BodyChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return bodyChanged(text, styles, layouts);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return bodyChanged?.call(text, styles, layouts);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (bodyChanged != null) {
      return bodyChanged(text, styles, layouts);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return bodyChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return bodyChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (bodyChanged != null) {
      return bodyChanged(this);
    }
    return orElse();
  }
}

abstract class _BodyChanged implements AddUpdateFormEvent {
  const factory _BodyChanged(
      final String text,
      final List<NoteTextStyleRange> styles,
      final List<NoteImageLayout> layouts) = _$BodyChangedImpl;

  String get text;
  List<NoteTextStyleRange> get styles;
  List<NoteImageLayout> get layouts;
  @JsonKey(ignore: true)
  _$$BodyChangedImplCopyWith<_$BodyChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImageLayoutsChangedImplCopyWith<$Res> {
  factory _$$ImageLayoutsChangedImplCopyWith(_$ImageLayoutsChangedImpl value,
          $Res Function(_$ImageLayoutsChangedImpl) then) =
      __$$ImageLayoutsChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<NoteImageLayout> value});
}

/// @nodoc
class __$$ImageLayoutsChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$ImageLayoutsChangedImpl>
    implements _$$ImageLayoutsChangedImplCopyWith<$Res> {
  __$$ImageLayoutsChangedImplCopyWithImpl(_$ImageLayoutsChangedImpl _value,
      $Res Function(_$ImageLayoutsChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ImageLayoutsChangedImpl(
      null == value
          ? _value._value
          : value // ignore: cast_nullable_to_non_nullable
              as List<NoteImageLayout>,
    ));
  }
}

/// @nodoc

class _$ImageLayoutsChangedImpl implements _ImageLayoutsChanged {
  const _$ImageLayoutsChangedImpl(final List<NoteImageLayout> value)
      : _value = value;

  final List<NoteImageLayout> _value;
  @override
  List<NoteImageLayout> get value {
    if (_value is EqualUnmodifiableListView) return _value;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_value);
  }

  @override
  String toString() {
    return 'AddUpdateFormEvent.imageLayoutsChanged(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageLayoutsChangedImpl &&
            const DeepCollectionEquality().equals(other._value, _value));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_value));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageLayoutsChangedImplCopyWith<_$ImageLayoutsChangedImpl> get copyWith =>
      __$$ImageLayoutsChangedImplCopyWithImpl<_$ImageLayoutsChangedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return imageLayoutsChanged(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return imageLayoutsChanged?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (imageLayoutsChanged != null) {
      return imageLayoutsChanged(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return imageLayoutsChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return imageLayoutsChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (imageLayoutsChanged != null) {
      return imageLayoutsChanged(this);
    }
    return orElse();
  }
}

abstract class _ImageLayoutsChanged implements AddUpdateFormEvent {
  const factory _ImageLayoutsChanged(final List<NoteImageLayout> value) =
      _$ImageLayoutsChangedImpl;

  List<NoteImageLayout> get value;
  @JsonKey(ignore: true)
  _$$ImageLayoutsChangedImplCopyWith<_$ImageLayoutsChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ColorChangedImplCopyWith<$Res> {
  factory _$$ColorChangedImplCopyWith(
          _$ColorChangedImpl value, $Res Function(_$ColorChangedImpl) then) =
      __$$ColorChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Color value});
}

/// @nodoc
class __$$ColorChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$ColorChangedImpl>
    implements _$$ColorChangedImplCopyWith<$Res> {
  __$$ColorChangedImplCopyWithImpl(
      _$ColorChangedImpl _value, $Res Function(_$ColorChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ColorChangedImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as Color,
    ));
  }
}

/// @nodoc

class _$ColorChangedImpl implements _ColorChanged {
  const _$ColorChangedImpl(this.value);

  @override
  final Color value;

  @override
  String toString() {
    return 'AddUpdateFormEvent.colorChanged(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ColorChangedImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ColorChangedImplCopyWith<_$ColorChangedImpl> get copyWith =>
      __$$ColorChangedImplCopyWithImpl<_$ColorChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return colorChanged(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return colorChanged?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (colorChanged != null) {
      return colorChanged(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return colorChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return colorChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (colorChanged != null) {
      return colorChanged(this);
    }
    return orElse();
  }
}

abstract class _ColorChanged implements AddUpdateFormEvent {
  const factory _ColorChanged(final Color value) = _$ColorChangedImpl;

  Color get value;
  @JsonKey(ignore: true)
  _$$ColorChangedImplCopyWith<_$ColorChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AddOrUpdateNoteImplCopyWith<$Res> {
  factory _$$AddOrUpdateNoteImplCopyWith(_$AddOrUpdateNoteImpl value,
          $Res Function(_$AddOrUpdateNoteImpl) then) =
      __$$AddOrUpdateNoteImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String? id,
      String? folderId,
      bool isPinned,
      bool isArchived,
      int? sortOrder,
      DateTime? deletedAt});
}

/// @nodoc
class __$$AddOrUpdateNoteImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$AddOrUpdateNoteImpl>
    implements _$$AddOrUpdateNoteImplCopyWith<$Res> {
  __$$AddOrUpdateNoteImplCopyWithImpl(
      _$AddOrUpdateNoteImpl _value, $Res Function(_$AddOrUpdateNoteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? folderId = freezed,
    Object? isPinned = null,
    Object? isArchived = null,
    Object? sortOrder = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_$AddOrUpdateNoteImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: freezed == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$AddOrUpdateNoteImpl implements _AddOrUpdateNote {
  const _$AddOrUpdateNoteImpl(
      {this.id,
      this.folderId,
      this.isPinned = false,
      this.isArchived = false,
      this.sortOrder,
      this.deletedAt});

  @override
  final String? id;
  @override
  final String? folderId;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  @JsonKey()
  final bool isArchived;
  @override
  final int? sortOrder;
  @override
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'AddUpdateFormEvent.addOrUpdateNote(id: $id, folderId: $folderId, isPinned: $isPinned, isArchived: $isArchived, sortOrder: $sortOrder, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddOrUpdateNoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, folderId, isPinned, isArchived, sortOrder, deletedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AddOrUpdateNoteImplCopyWith<_$AddOrUpdateNoteImpl> get copyWith =>
      __$$AddOrUpdateNoteImplCopyWithImpl<_$AddOrUpdateNoteImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return addOrUpdateNote(
        id, folderId, isPinned, isArchived, sortOrder, deletedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return addOrUpdateNote?.call(
        id, folderId, isPinned, isArchived, sortOrder, deletedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (addOrUpdateNote != null) {
      return addOrUpdateNote(
          id, folderId, isPinned, isArchived, sortOrder, deletedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return addOrUpdateNote(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return addOrUpdateNote?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (addOrUpdateNote != null) {
      return addOrUpdateNote(this);
    }
    return orElse();
  }
}

abstract class _AddOrUpdateNote implements AddUpdateFormEvent {
  const factory _AddOrUpdateNote(
      {final String? id,
      final String? folderId,
      final bool isPinned,
      final bool isArchived,
      final int? sortOrder,
      final DateTime? deletedAt}) = _$AddOrUpdateNoteImpl;

  String? get id;
  String? get folderId;
  bool get isPinned;
  bool get isArchived;
  int? get sortOrder;
  DateTime? get deletedAt;
  @JsonKey(ignore: true)
  _$$AddOrUpdateNoteImplCopyWith<_$AddOrUpdateNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AddEmptyTodoImplCopyWith<$Res> {
  factory _$$AddEmptyTodoImplCopyWith(
          _$AddEmptyTodoImpl value, $Res Function(_$AddEmptyTodoImpl) then) =
      __$$AddEmptyTodoImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? afterId});
}

/// @nodoc
class __$$AddEmptyTodoImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$AddEmptyTodoImpl>
    implements _$$AddEmptyTodoImplCopyWith<$Res> {
  __$$AddEmptyTodoImplCopyWithImpl(
      _$AddEmptyTodoImpl _value, $Res Function(_$AddEmptyTodoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? afterId = freezed,
  }) {
    return _then(_$AddEmptyTodoImpl(
      afterId: freezed == afterId
          ? _value.afterId
          : afterId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AddEmptyTodoImpl implements _AddEmptyTodo {
  const _$AddEmptyTodoImpl({this.afterId});

  @override
  final String? afterId;

  @override
  String toString() {
    return 'AddUpdateFormEvent.addEmptyTodo(afterId: $afterId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddEmptyTodoImpl &&
            (identical(other.afterId, afterId) || other.afterId == afterId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, afterId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AddEmptyTodoImplCopyWith<_$AddEmptyTodoImpl> get copyWith =>
      __$$AddEmptyTodoImplCopyWithImpl<_$AddEmptyTodoImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return addEmptyTodo(afterId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return addEmptyTodo?.call(afterId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (addEmptyTodo != null) {
      return addEmptyTodo(afterId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return addEmptyTodo(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return addEmptyTodo?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (addEmptyTodo != null) {
      return addEmptyTodo(this);
    }
    return orElse();
  }
}

abstract class _AddEmptyTodo implements AddUpdateFormEvent {
  const factory _AddEmptyTodo({final String? afterId}) = _$AddEmptyTodoImpl;

  String? get afterId;
  @JsonKey(ignore: true)
  _$$AddEmptyTodoImplCopyWith<_$AddEmptyTodoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeleteTodoImplCopyWith<$Res> {
  factory _$$DeleteTodoImplCopyWith(
          _$DeleteTodoImpl value, $Res Function(_$DeleteTodoImpl) then) =
      __$$DeleteTodoImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$DeleteTodoImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$DeleteTodoImpl>
    implements _$$DeleteTodoImplCopyWith<$Res> {
  __$$DeleteTodoImplCopyWithImpl(
      _$DeleteTodoImpl _value, $Res Function(_$DeleteTodoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_$DeleteTodoImpl(
      null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DeleteTodoImpl implements _DeleteTodo {
  const _$DeleteTodoImpl(this.id);

  @override
  final String id;

  @override
  String toString() {
    return 'AddUpdateFormEvent.deleteTodo(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteTodoImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeleteTodoImplCopyWith<_$DeleteTodoImpl> get copyWith =>
      __$$DeleteTodoImplCopyWithImpl<_$DeleteTodoImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return deleteTodo(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return deleteTodo?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (deleteTodo != null) {
      return deleteTodo(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return deleteTodo(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return deleteTodo?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (deleteTodo != null) {
      return deleteTodo(this);
    }
    return orElse();
  }
}

abstract class _DeleteTodo implements AddUpdateFormEvent {
  const factory _DeleteTodo(final String id) = _$DeleteTodoImpl;

  String get id;
  @JsonKey(ignore: true)
  _$$DeleteTodoImplCopyWith<_$DeleteTodoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TodoValueChangedImplCopyWith<$Res> {
  factory _$$TodoValueChangedImplCopyWith(_$TodoValueChangedImpl value,
          $Res Function(_$TodoValueChangedImpl) then) =
      __$$TodoValueChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String value, String id});
}

/// @nodoc
class __$$TodoValueChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$TodoValueChangedImpl>
    implements _$$TodoValueChangedImplCopyWith<$Res> {
  __$$TodoValueChangedImplCopyWithImpl(_$TodoValueChangedImpl _value,
      $Res Function(_$TodoValueChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? id = null,
  }) {
    return _then(_$TodoValueChangedImpl(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TodoValueChangedImpl implements _TodoValueChanged {
  const _$TodoValueChangedImpl({required this.value, required this.id});

  @override
  final String value;
  @override
  final String id;

  @override
  String toString() {
    return 'AddUpdateFormEvent.todoValueChanged(value: $value, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoValueChangedImpl &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoValueChangedImplCopyWith<_$TodoValueChangedImpl> get copyWith =>
      __$$TodoValueChangedImplCopyWithImpl<_$TodoValueChangedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return todoValueChanged(value, id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return todoValueChanged?.call(value, id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (todoValueChanged != null) {
      return todoValueChanged(value, id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return todoValueChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return todoValueChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (todoValueChanged != null) {
      return todoValueChanged(this);
    }
    return orElse();
  }
}

abstract class _TodoValueChanged implements AddUpdateFormEvent {
  const factory _TodoValueChanged(
      {required final String value,
      required final String id}) = _$TodoValueChangedImpl;

  String get value;
  String get id;
  @JsonKey(ignore: true)
  _$$TodoValueChangedImplCopyWith<_$TodoValueChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ToggleTodoCheckboxImplCopyWith<$Res> {
  factory _$$ToggleTodoCheckboxImplCopyWith(_$ToggleTodoCheckboxImpl value,
          $Res Function(_$ToggleTodoCheckboxImpl) then) =
      __$$ToggleTodoCheckboxImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$ToggleTodoCheckboxImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$ToggleTodoCheckboxImpl>
    implements _$$ToggleTodoCheckboxImplCopyWith<$Res> {
  __$$ToggleTodoCheckboxImplCopyWithImpl(_$ToggleTodoCheckboxImpl _value,
      $Res Function(_$ToggleTodoCheckboxImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_$ToggleTodoCheckboxImpl(
      null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ToggleTodoCheckboxImpl implements _ToggleTodoCheckbox {
  const _$ToggleTodoCheckboxImpl(this.id);

  @override
  final String id;

  @override
  String toString() {
    return 'AddUpdateFormEvent.toggleTodoCheckbox(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToggleTodoCheckboxImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ToggleTodoCheckboxImplCopyWith<_$ToggleTodoCheckboxImpl> get copyWith =>
      __$$ToggleTodoCheckboxImplCopyWithImpl<_$ToggleTodoCheckboxImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return toggleTodoCheckbox(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return toggleTodoCheckbox?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (toggleTodoCheckbox != null) {
      return toggleTodoCheckbox(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return toggleTodoCheckbox(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return toggleTodoCheckbox?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (toggleTodoCheckbox != null) {
      return toggleTodoCheckbox(this);
    }
    return orElse();
  }
}

abstract class _ToggleTodoCheckbox implements AddUpdateFormEvent {
  const factory _ToggleTodoCheckbox(final String id) = _$ToggleTodoCheckboxImpl;

  String get id;
  @JsonKey(ignore: true)
  _$$ToggleTodoCheckboxImplCopyWith<_$ToggleTodoCheckboxImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SetTodoCompletedImplCopyWith<$Res> {
  factory _$$SetTodoCompletedImplCopyWith(_$SetTodoCompletedImpl value,
          $Res Function(_$SetTodoCompletedImpl) then) =
      __$$SetTodoCompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, bool completed});
}

/// @nodoc
class __$$SetTodoCompletedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$SetTodoCompletedImpl>
    implements _$$SetTodoCompletedImplCopyWith<$Res> {
  __$$SetTodoCompletedImplCopyWithImpl(_$SetTodoCompletedImpl _value,
      $Res Function(_$SetTodoCompletedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? completed = null,
  }) {
    return _then(_$SetTodoCompletedImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SetTodoCompletedImpl implements _SetTodoCompleted {
  const _$SetTodoCompletedImpl({required this.id, required this.completed});

  @override
  final String id;
  @override
  final bool completed;

  @override
  String toString() {
    return 'AddUpdateFormEvent.setTodoCompleted(id: $id, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetTodoCompletedImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.completed, completed) ||
                other.completed == completed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, completed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SetTodoCompletedImplCopyWith<_$SetTodoCompletedImpl> get copyWith =>
      __$$SetTodoCompletedImplCopyWithImpl<_$SetTodoCompletedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return setTodoCompleted(id, completed);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return setTodoCompleted?.call(id, completed);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (setTodoCompleted != null) {
      return setTodoCompleted(id, completed);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return setTodoCompleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return setTodoCompleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (setTodoCompleted != null) {
      return setTodoCompleted(this);
    }
    return orElse();
  }
}

abstract class _SetTodoCompleted implements AddUpdateFormEvent {
  const factory _SetTodoCompleted(
      {required final String id,
      required final bool completed}) = _$SetTodoCompletedImpl;

  String get id;
  bool get completed;
  @JsonKey(ignore: true)
  _$$SetTodoCompletedImplCopyWith<_$SetTodoCompletedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ReplaceTodoLinesImplCopyWith<$Res> {
  factory _$$ReplaceTodoLinesImplCopyWith(_$ReplaceTodoLinesImpl value,
          $Res Function(_$ReplaceTodoLinesImpl) then) =
      __$$ReplaceTodoLinesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, List<String> lines});
}

/// @nodoc
class __$$ReplaceTodoLinesImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$ReplaceTodoLinesImpl>
    implements _$$ReplaceTodoLinesImplCopyWith<$Res> {
  __$$ReplaceTodoLinesImplCopyWithImpl(_$ReplaceTodoLinesImpl _value,
      $Res Function(_$ReplaceTodoLinesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lines = null,
  }) {
    return _then(_$ReplaceTodoLinesImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lines: null == lines
          ? _value._lines
          : lines // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$ReplaceTodoLinesImpl implements _ReplaceTodoLines {
  const _$ReplaceTodoLinesImpl(
      {required this.id, required final List<String> lines})
      : _lines = lines;

  @override
  final String id;
  final List<String> _lines;
  @override
  List<String> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  String toString() {
    return 'AddUpdateFormEvent.replaceTodoLines(id: $id, lines: $lines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplaceTodoLinesImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._lines, _lines));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, const DeepCollectionEquality().hash(_lines));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplaceTodoLinesImplCopyWith<_$ReplaceTodoLinesImpl> get copyWith =>
      __$$ReplaceTodoLinesImplCopyWithImpl<_$ReplaceTodoLinesImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return replaceTodoLines(id, lines);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return replaceTodoLines?.call(id, lines);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (replaceTodoLines != null) {
      return replaceTodoLines(id, lines);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return replaceTodoLines(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return replaceTodoLines?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (replaceTodoLines != null) {
      return replaceTodoLines(this);
    }
    return orElse();
  }
}

abstract class _ReplaceTodoLines implements AddUpdateFormEvent {
  const factory _ReplaceTodoLines(
      {required final String id,
      required final List<String> lines}) = _$ReplaceTodoLinesImpl;

  String get id;
  List<String> get lines;
  @JsonKey(ignore: true)
  _$$ReplaceTodoLinesImplCopyWith<_$ReplaceTodoLinesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ReorderTodoImplCopyWith<$Res> {
  factory _$$ReorderTodoImplCopyWith(
          _$ReorderTodoImpl value, $Res Function(_$ReorderTodoImpl) then) =
      __$$ReorderTodoImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int oldIndex, int newIndex});
}

/// @nodoc
class __$$ReorderTodoImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$ReorderTodoImpl>
    implements _$$ReorderTodoImplCopyWith<$Res> {
  __$$ReorderTodoImplCopyWithImpl(
      _$ReorderTodoImpl _value, $Res Function(_$ReorderTodoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? oldIndex = null,
    Object? newIndex = null,
  }) {
    return _then(_$ReorderTodoImpl(
      oldIndex: null == oldIndex
          ? _value.oldIndex
          : oldIndex // ignore: cast_nullable_to_non_nullable
              as int,
      newIndex: null == newIndex
          ? _value.newIndex
          : newIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$ReorderTodoImpl implements _ReorderTodo {
  const _$ReorderTodoImpl({required this.oldIndex, required this.newIndex});

  @override
  final int oldIndex;
  @override
  final int newIndex;

  @override
  String toString() {
    return 'AddUpdateFormEvent.reorderTodo(oldIndex: $oldIndex, newIndex: $newIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReorderTodoImpl &&
            (identical(other.oldIndex, oldIndex) ||
                other.oldIndex == oldIndex) &&
            (identical(other.newIndex, newIndex) ||
                other.newIndex == newIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, oldIndex, newIndex);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReorderTodoImplCopyWith<_$ReorderTodoImpl> get copyWith =>
      __$$ReorderTodoImplCopyWithImpl<_$ReorderTodoImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return reorderTodo(oldIndex, newIndex);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return reorderTodo?.call(oldIndex, newIndex);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (reorderTodo != null) {
      return reorderTodo(oldIndex, newIndex);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return reorderTodo(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return reorderTodo?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (reorderTodo != null) {
      return reorderTodo(this);
    }
    return orElse();
  }
}

abstract class _ReorderTodo implements AddUpdateFormEvent {
  const factory _ReorderTodo(
      {required final int oldIndex,
      required final int newIndex}) = _$ReorderTodoImpl;

  int get oldIndex;
  int get newIndex;
  @JsonKey(ignore: true)
  _$$ReorderTodoImplCopyWith<_$ReorderTodoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AddImageImplCopyWith<$Res> {
  factory _$$AddImageImplCopyWith(
          _$AddImageImpl value, $Res Function(_$AddImageImpl) then) =
      __$$AddImageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String path, int? textOffset});
}

/// @nodoc
class __$$AddImageImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$AddImageImpl>
    implements _$$AddImageImplCopyWith<$Res> {
  __$$AddImageImplCopyWithImpl(
      _$AddImageImpl _value, $Res Function(_$AddImageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? textOffset = freezed,
  }) {
    return _then(_$AddImageImpl(
      null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      textOffset: freezed == textOffset
          ? _value.textOffset
          : textOffset // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$AddImageImpl implements _AddImage {
  const _$AddImageImpl(this.path, {this.textOffset});

  @override
  final String path;
  @override
  final int? textOffset;

  @override
  String toString() {
    return 'AddUpdateFormEvent.addImage(path: $path, textOffset: $textOffset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddImageImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.textOffset, textOffset) ||
                other.textOffset == textOffset));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path, textOffset);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AddImageImplCopyWith<_$AddImageImpl> get copyWith =>
      __$$AddImageImplCopyWithImpl<_$AddImageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return addImage(path, textOffset);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return addImage?.call(path, textOffset);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (addImage != null) {
      return addImage(path, textOffset);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return addImage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return addImage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (addImage != null) {
      return addImage(this);
    }
    return orElse();
  }
}

abstract class _AddImage implements AddUpdateFormEvent {
  const factory _AddImage(final String path, {final int? textOffset}) =
      _$AddImageImpl;

  String get path;
  int? get textOffset;
  @JsonKey(ignore: true)
  _$$AddImageImplCopyWith<_$AddImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RemoveImageImplCopyWith<$Res> {
  factory _$$RemoveImageImplCopyWith(
          _$RemoveImageImpl value, $Res Function(_$RemoveImageImpl) then) =
      __$$RemoveImageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String path});
}

/// @nodoc
class __$$RemoveImageImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$RemoveImageImpl>
    implements _$$RemoveImageImplCopyWith<$Res> {
  __$$RemoveImageImplCopyWithImpl(
      _$RemoveImageImpl _value, $Res Function(_$RemoveImageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
  }) {
    return _then(_$RemoveImageImpl(
      null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RemoveImageImpl implements _RemoveImage {
  const _$RemoveImageImpl(this.path);

  @override
  final String path;

  @override
  String toString() {
    return 'AddUpdateFormEvent.removeImage(path: $path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoveImageImpl &&
            (identical(other.path, path) || other.path == path));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoveImageImplCopyWith<_$RemoveImageImpl> get copyWith =>
      __$$RemoveImageImplCopyWithImpl<_$RemoveImageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return removeImage(path);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return removeImage?.call(path);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (removeImage != null) {
      return removeImage(path);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return removeImage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return removeImage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (removeImage != null) {
      return removeImage(this);
    }
    return orElse();
  }
}

abstract class _RemoveImage implements AddUpdateFormEvent {
  const factory _RemoveImage(final String path) = _$RemoveImageImpl;

  String get path;
  @JsonKey(ignore: true)
  _$$RemoveImageImplCopyWith<_$RemoveImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ReplaceImageImplCopyWith<$Res> {
  factory _$$ReplaceImageImplCopyWith(
          _$ReplaceImageImpl value, $Res Function(_$ReplaceImageImpl) then) =
      __$$ReplaceImageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String oldPath, String newPath, double aspectRatio});
}

/// @nodoc
class __$$ReplaceImageImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$ReplaceImageImpl>
    implements _$$ReplaceImageImplCopyWith<$Res> {
  __$$ReplaceImageImplCopyWithImpl(
      _$ReplaceImageImpl _value, $Res Function(_$ReplaceImageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? oldPath = null,
    Object? newPath = null,
    Object? aspectRatio = null,
  }) {
    return _then(_$ReplaceImageImpl(
      oldPath: null == oldPath
          ? _value.oldPath
          : oldPath // ignore: cast_nullable_to_non_nullable
              as String,
      newPath: null == newPath
          ? _value.newPath
          : newPath // ignore: cast_nullable_to_non_nullable
              as String,
      aspectRatio: null == aspectRatio
          ? _value.aspectRatio
          : aspectRatio // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$ReplaceImageImpl implements _ReplaceImage {
  const _$ReplaceImageImpl(
      {required this.oldPath,
      required this.newPath,
      required this.aspectRatio});

  @override
  final String oldPath;
  @override
  final String newPath;
  @override
  final double aspectRatio;

  @override
  String toString() {
    return 'AddUpdateFormEvent.replaceImage(oldPath: $oldPath, newPath: $newPath, aspectRatio: $aspectRatio)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReplaceImageImpl &&
            (identical(other.oldPath, oldPath) || other.oldPath == oldPath) &&
            (identical(other.newPath, newPath) || other.newPath == newPath) &&
            (identical(other.aspectRatio, aspectRatio) ||
                other.aspectRatio == aspectRatio));
  }

  @override
  int get hashCode => Object.hash(runtimeType, oldPath, newPath, aspectRatio);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReplaceImageImplCopyWith<_$ReplaceImageImpl> get copyWith =>
      __$$ReplaceImageImplCopyWithImpl<_$ReplaceImageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return replaceImage(oldPath, newPath, aspectRatio);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return replaceImage?.call(oldPath, newPath, aspectRatio);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (replaceImage != null) {
      return replaceImage(oldPath, newPath, aspectRatio);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return replaceImage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return replaceImage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (replaceImage != null) {
      return replaceImage(this);
    }
    return orElse();
  }
}

abstract class _ReplaceImage implements AddUpdateFormEvent {
  const factory _ReplaceImage(
      {required final String oldPath,
      required final String newPath,
      required final double aspectRatio}) = _$ReplaceImageImpl;

  String get oldPath;
  String get newPath;
  double get aspectRatio;
  @JsonKey(ignore: true)
  _$$ReplaceImageImplCopyWith<_$ReplaceImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VoiceMemosChangedImplCopyWith<$Res> {
  factory _$$VoiceMemosChangedImplCopyWith(_$VoiceMemosChangedImpl value,
          $Res Function(_$VoiceMemosChangedImpl) then) =
      __$$VoiceMemosChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<VoiceMemo> value});
}

/// @nodoc
class __$$VoiceMemosChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$VoiceMemosChangedImpl>
    implements _$$VoiceMemosChangedImplCopyWith<$Res> {
  __$$VoiceMemosChangedImplCopyWithImpl(_$VoiceMemosChangedImpl _value,
      $Res Function(_$VoiceMemosChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$VoiceMemosChangedImpl(
      null == value
          ? _value._value
          : value // ignore: cast_nullable_to_non_nullable
              as List<VoiceMemo>,
    ));
  }
}

/// @nodoc

class _$VoiceMemosChangedImpl implements _VoiceMemosChanged {
  const _$VoiceMemosChangedImpl(final List<VoiceMemo> value) : _value = value;

  final List<VoiceMemo> _value;
  @override
  List<VoiceMemo> get value {
    if (_value is EqualUnmodifiableListView) return _value;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_value);
  }

  @override
  String toString() {
    return 'AddUpdateFormEvent.voiceMemosChanged(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceMemosChangedImpl &&
            const DeepCollectionEquality().equals(other._value, _value));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_value));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VoiceMemosChangedImplCopyWith<_$VoiceMemosChangedImpl> get copyWith =>
      __$$VoiceMemosChangedImplCopyWithImpl<_$VoiceMemosChangedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return voiceMemosChanged(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return voiceMemosChanged?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (voiceMemosChanged != null) {
      return voiceMemosChanged(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return voiceMemosChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return voiceMemosChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (voiceMemosChanged != null) {
      return voiceMemosChanged(this);
    }
    return orElse();
  }
}

abstract class _VoiceMemosChanged implements AddUpdateFormEvent {
  const factory _VoiceMemosChanged(final List<VoiceMemo> value) =
      _$VoiceMemosChangedImpl;

  List<VoiceMemo> get value;
  @JsonKey(ignore: true)
  _$$VoiceMemosChangedImplCopyWith<_$VoiceMemosChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TagsChangedImplCopyWith<$Res> {
  factory _$$TagsChangedImplCopyWith(
          _$TagsChangedImpl value, $Res Function(_$TagsChangedImpl) then) =
      __$$TagsChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> value});
}

/// @nodoc
class __$$TagsChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$TagsChangedImpl>
    implements _$$TagsChangedImplCopyWith<$Res> {
  __$$TagsChangedImplCopyWithImpl(
      _$TagsChangedImpl _value, $Res Function(_$TagsChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$TagsChangedImpl(
      null == value
          ? _value._value
          : value // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$TagsChangedImpl implements _TagsChanged {
  const _$TagsChangedImpl(final List<String> value) : _value = value;

  final List<String> _value;
  @override
  List<String> get value {
    if (_value is EqualUnmodifiableListView) return _value;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_value);
  }

  @override
  String toString() {
    return 'AddUpdateFormEvent.tagsChanged(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagsChangedImpl &&
            const DeepCollectionEquality().equals(other._value, _value));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_value));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TagsChangedImplCopyWith<_$TagsChangedImpl> get copyWith =>
      __$$TagsChangedImplCopyWithImpl<_$TagsChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return tagsChanged(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return tagsChanged?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (tagsChanged != null) {
      return tagsChanged(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return tagsChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return tagsChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (tagsChanged != null) {
      return tagsChanged(this);
    }
    return orElse();
  }
}

abstract class _TagsChanged implements AddUpdateFormEvent {
  const factory _TagsChanged(final List<String> value) = _$TagsChangedImpl;

  List<String> get value;
  @JsonKey(ignore: true)
  _$$TagsChangedImplCopyWith<_$TagsChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LinksChangedImplCopyWith<$Res> {
  factory _$$LinksChangedImplCopyWith(
          _$LinksChangedImpl value, $Res Function(_$LinksChangedImpl) then) =
      __$$LinksChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<String> value});
}

/// @nodoc
class __$$LinksChangedImplCopyWithImpl<$Res>
    extends _$AddUpdateFormEventCopyWithImpl<$Res, _$LinksChangedImpl>
    implements _$$LinksChangedImplCopyWith<$Res> {
  __$$LinksChangedImplCopyWithImpl(
      _$LinksChangedImpl _value, $Res Function(_$LinksChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$LinksChangedImpl(
      null == value
          ? _value._value
          : value // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$LinksChangedImpl implements _LinksChanged {
  const _$LinksChangedImpl(final List<String> value) : _value = value;

  final List<String> _value;
  @override
  List<String> get value {
    if (_value is EqualUnmodifiableListView) return _value;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_value);
  }

  @override
  String toString() {
    return 'AddUpdateFormEvent.linksChanged(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LinksChangedImpl &&
            const DeepCollectionEquality().equals(other._value, _value));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_value));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LinksChangedImplCopyWith<_$LinksChangedImpl> get copyWith =>
      __$$LinksChangedImplCopyWithImpl<_$LinksChangedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)
        initialize,
    required TResult Function(String value) titleChanged,
    required TResult Function(String value) descriptionChanged,
    required TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)
        bodyChanged,
    required TResult Function(List<NoteImageLayout> value) imageLayoutsChanged,
    required TResult Function(Color value) colorChanged,
    required TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)
        addOrUpdateNote,
    required TResult Function(String? afterId) addEmptyTodo,
    required TResult Function(String id) deleteTodo,
    required TResult Function(String value, String id) todoValueChanged,
    required TResult Function(String id) toggleTodoCheckbox,
    required TResult Function(String id, bool completed) setTodoCompleted,
    required TResult Function(String id, List<String> lines) replaceTodoLines,
    required TResult Function(int oldIndex, int newIndex) reorderTodo,
    required TResult Function(String path, int? textOffset) addImage,
    required TResult Function(String path) removeImage,
    required TResult Function(
            String oldPath, String newPath, double aspectRatio)
        replaceImage,
    required TResult Function(List<VoiceMemo> value) voiceMemosChanged,
    required TResult Function(List<String> value) tagsChanged,
    required TResult Function(List<String> value) linksChanged,
  }) {
    return linksChanged(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult? Function(String value)? titleChanged,
    TResult? Function(String value)? descriptionChanged,
    TResult? Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult? Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult? Function(Color value)? colorChanged,
    TResult? Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult? Function(String? afterId)? addEmptyTodo,
    TResult? Function(String id)? deleteTodo,
    TResult? Function(String value, String id)? todoValueChanged,
    TResult? Function(String id)? toggleTodoCheckbox,
    TResult? Function(String id, bool completed)? setTodoCompleted,
    TResult? Function(String id, List<String> lines)? replaceTodoLines,
    TResult? Function(int oldIndex, int newIndex)? reorderTodo,
    TResult? Function(String path, int? textOffset)? addImage,
    TResult? Function(String path)? removeImage,
    TResult? Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult? Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult? Function(List<String> value)? tagsChanged,
    TResult? Function(List<String> value)? linksChanged,
  }) {
    return linksChanged?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String? title,
            String? description,
            List<NoteTextStyleRange>? textStyles,
            Color? color,
            List<Todo>? todos,
            List<String>? imagePaths,
            List<NoteImageLayout>? imageLayouts,
            List<VoiceMemo>? voiceMemos,
            List<String>? tags,
            List<String>? linkedNoteIds,
            String? dailyNoteDateKey)?
        initialize,
    TResult Function(String value)? titleChanged,
    TResult Function(String value)? descriptionChanged,
    TResult Function(String text, List<NoteTextStyleRange> styles,
            List<NoteImageLayout> layouts)?
        bodyChanged,
    TResult Function(List<NoteImageLayout> value)? imageLayoutsChanged,
    TResult Function(Color value)? colorChanged,
    TResult Function(String? id, String? folderId, bool isPinned,
            bool isArchived, int? sortOrder, DateTime? deletedAt)?
        addOrUpdateNote,
    TResult Function(String? afterId)? addEmptyTodo,
    TResult Function(String id)? deleteTodo,
    TResult Function(String value, String id)? todoValueChanged,
    TResult Function(String id)? toggleTodoCheckbox,
    TResult Function(String id, bool completed)? setTodoCompleted,
    TResult Function(String id, List<String> lines)? replaceTodoLines,
    TResult Function(int oldIndex, int newIndex)? reorderTodo,
    TResult Function(String path, int? textOffset)? addImage,
    TResult Function(String path)? removeImage,
    TResult Function(String oldPath, String newPath, double aspectRatio)?
        replaceImage,
    TResult Function(List<VoiceMemo> value)? voiceMemosChanged,
    TResult Function(List<String> value)? tagsChanged,
    TResult Function(List<String> value)? linksChanged,
    required TResult orElse(),
  }) {
    if (linksChanged != null) {
      return linksChanged(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initialize value) initialize,
    required TResult Function(_TitleChanged value) titleChanged,
    required TResult Function(_DescriptionChanged value) descriptionChanged,
    required TResult Function(_BodyChanged value) bodyChanged,
    required TResult Function(_ImageLayoutsChanged value) imageLayoutsChanged,
    required TResult Function(_ColorChanged value) colorChanged,
    required TResult Function(_AddOrUpdateNote value) addOrUpdateNote,
    required TResult Function(_AddEmptyTodo value) addEmptyTodo,
    required TResult Function(_DeleteTodo value) deleteTodo,
    required TResult Function(_TodoValueChanged value) todoValueChanged,
    required TResult Function(_ToggleTodoCheckbox value) toggleTodoCheckbox,
    required TResult Function(_SetTodoCompleted value) setTodoCompleted,
    required TResult Function(_ReplaceTodoLines value) replaceTodoLines,
    required TResult Function(_ReorderTodo value) reorderTodo,
    required TResult Function(_AddImage value) addImage,
    required TResult Function(_RemoveImage value) removeImage,
    required TResult Function(_ReplaceImage value) replaceImage,
    required TResult Function(_VoiceMemosChanged value) voiceMemosChanged,
    required TResult Function(_TagsChanged value) tagsChanged,
    required TResult Function(_LinksChanged value) linksChanged,
  }) {
    return linksChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initialize value)? initialize,
    TResult? Function(_TitleChanged value)? titleChanged,
    TResult? Function(_DescriptionChanged value)? descriptionChanged,
    TResult? Function(_BodyChanged value)? bodyChanged,
    TResult? Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult? Function(_ColorChanged value)? colorChanged,
    TResult? Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult? Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult? Function(_DeleteTodo value)? deleteTodo,
    TResult? Function(_TodoValueChanged value)? todoValueChanged,
    TResult? Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult? Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult? Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult? Function(_ReorderTodo value)? reorderTodo,
    TResult? Function(_AddImage value)? addImage,
    TResult? Function(_RemoveImage value)? removeImage,
    TResult? Function(_ReplaceImage value)? replaceImage,
    TResult? Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult? Function(_TagsChanged value)? tagsChanged,
    TResult? Function(_LinksChanged value)? linksChanged,
  }) {
    return linksChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initialize value)? initialize,
    TResult Function(_TitleChanged value)? titleChanged,
    TResult Function(_DescriptionChanged value)? descriptionChanged,
    TResult Function(_BodyChanged value)? bodyChanged,
    TResult Function(_ImageLayoutsChanged value)? imageLayoutsChanged,
    TResult Function(_ColorChanged value)? colorChanged,
    TResult Function(_AddOrUpdateNote value)? addOrUpdateNote,
    TResult Function(_AddEmptyTodo value)? addEmptyTodo,
    TResult Function(_DeleteTodo value)? deleteTodo,
    TResult Function(_TodoValueChanged value)? todoValueChanged,
    TResult Function(_ToggleTodoCheckbox value)? toggleTodoCheckbox,
    TResult Function(_SetTodoCompleted value)? setTodoCompleted,
    TResult Function(_ReplaceTodoLines value)? replaceTodoLines,
    TResult Function(_ReorderTodo value)? reorderTodo,
    TResult Function(_AddImage value)? addImage,
    TResult Function(_RemoveImage value)? removeImage,
    TResult Function(_ReplaceImage value)? replaceImage,
    TResult Function(_VoiceMemosChanged value)? voiceMemosChanged,
    TResult Function(_TagsChanged value)? tagsChanged,
    TResult Function(_LinksChanged value)? linksChanged,
    required TResult orElse(),
  }) {
    if (linksChanged != null) {
      return linksChanged(this);
    }
    return orElse();
  }
}

abstract class _LinksChanged implements AddUpdateFormEvent {
  const factory _LinksChanged(final List<String> value) = _$LinksChangedImpl;

  List<String> get value;
  @JsonKey(ignore: true)
  _$$LinksChangedImplCopyWith<_$LinksChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AddUpdateFormState {
  String? get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<NoteTextStyleRange> get textStyles => throw _privateConstructorUsedError;
  Color? get selectedColor => throw _privateConstructorUsedError;
  List<Todo> get todos => throw _privateConstructorUsedError;
  List<String> get imagePaths => throw _privateConstructorUsedError;
  List<NoteImageLayout> get imageLayouts => throw _privateConstructorUsedError;
  List<VoiceMemo> get voiceMemos => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  List<String> get linkedNoteIds => throw _privateConstructorUsedError;
  String? get dailyNoteDateKey => throw _privateConstructorUsedError;
  DateTime? get reminderDate => throw _privateConstructorUsedError;
  int? get reminderId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AddUpdateFormStateCopyWith<AddUpdateFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddUpdateFormStateCopyWith<$Res> {
  factory $AddUpdateFormStateCopyWith(
          AddUpdateFormState value, $Res Function(AddUpdateFormState) then) =
      _$AddUpdateFormStateCopyWithImpl<$Res, AddUpdateFormState>;
  @useResult
  $Res call(
      {String? title,
      String? description,
      List<NoteTextStyleRange> textStyles,
      Color? selectedColor,
      List<Todo> todos,
      List<String> imagePaths,
      List<NoteImageLayout> imageLayouts,
      List<VoiceMemo> voiceMemos,
      List<String> tags,
      List<String> linkedNoteIds,
      String? dailyNoteDateKey,
      DateTime? reminderDate,
      int? reminderId});
}

/// @nodoc
class _$AddUpdateFormStateCopyWithImpl<$Res, $Val extends AddUpdateFormState>
    implements $AddUpdateFormStateCopyWith<$Res> {
  _$AddUpdateFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? textStyles = null,
    Object? selectedColor = freezed,
    Object? todos = null,
    Object? imagePaths = null,
    Object? imageLayouts = null,
    Object? voiceMemos = null,
    Object? tags = null,
    Object? linkedNoteIds = null,
    Object? dailyNoteDateKey = freezed,
    Object? reminderDate = freezed,
    Object? reminderId = freezed,
  }) {
    return _then(_value.copyWith(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      textStyles: null == textStyles
          ? _value.textStyles
          : textStyles // ignore: cast_nullable_to_non_nullable
              as List<NoteTextStyleRange>,
      selectedColor: freezed == selectedColor
          ? _value.selectedColor
          : selectedColor // ignore: cast_nullable_to_non_nullable
              as Color?,
      todos: null == todos
          ? _value.todos
          : todos // ignore: cast_nullable_to_non_nullable
              as List<Todo>,
      imagePaths: null == imagePaths
          ? _value.imagePaths
          : imagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageLayouts: null == imageLayouts
          ? _value.imageLayouts
          : imageLayouts // ignore: cast_nullable_to_non_nullable
              as List<NoteImageLayout>,
      voiceMemos: null == voiceMemos
          ? _value.voiceMemos
          : voiceMemos // ignore: cast_nullable_to_non_nullable
              as List<VoiceMemo>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      linkedNoteIds: null == linkedNoteIds
          ? _value.linkedNoteIds
          : linkedNoteIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dailyNoteDateKey: freezed == dailyNoteDateKey
          ? _value.dailyNoteDateKey
          : dailyNoteDateKey // ignore: cast_nullable_to_non_nullable
              as String?,
      reminderDate: freezed == reminderDate
          ? _value.reminderDate
          : reminderDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderId: freezed == reminderId
          ? _value.reminderId
          : reminderId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AddUpdateFormStateImplCopyWith<$Res>
    implements $AddUpdateFormStateCopyWith<$Res> {
  factory _$$AddUpdateFormStateImplCopyWith(_$AddUpdateFormStateImpl value,
          $Res Function(_$AddUpdateFormStateImpl) then) =
      __$$AddUpdateFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? title,
      String? description,
      List<NoteTextStyleRange> textStyles,
      Color? selectedColor,
      List<Todo> todos,
      List<String> imagePaths,
      List<NoteImageLayout> imageLayouts,
      List<VoiceMemo> voiceMemos,
      List<String> tags,
      List<String> linkedNoteIds,
      String? dailyNoteDateKey,
      DateTime? reminderDate,
      int? reminderId});
}

/// @nodoc
class __$$AddUpdateFormStateImplCopyWithImpl<$Res>
    extends _$AddUpdateFormStateCopyWithImpl<$Res, _$AddUpdateFormStateImpl>
    implements _$$AddUpdateFormStateImplCopyWith<$Res> {
  __$$AddUpdateFormStateImplCopyWithImpl(_$AddUpdateFormStateImpl _value,
      $Res Function(_$AddUpdateFormStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? textStyles = null,
    Object? selectedColor = freezed,
    Object? todos = null,
    Object? imagePaths = null,
    Object? imageLayouts = null,
    Object? voiceMemos = null,
    Object? tags = null,
    Object? linkedNoteIds = null,
    Object? dailyNoteDateKey = freezed,
    Object? reminderDate = freezed,
    Object? reminderId = freezed,
  }) {
    return _then(_$AddUpdateFormStateImpl(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      textStyles: null == textStyles
          ? _value._textStyles
          : textStyles // ignore: cast_nullable_to_non_nullable
              as List<NoteTextStyleRange>,
      selectedColor: freezed == selectedColor
          ? _value.selectedColor
          : selectedColor // ignore: cast_nullable_to_non_nullable
              as Color?,
      todos: null == todos
          ? _value._todos
          : todos // ignore: cast_nullable_to_non_nullable
              as List<Todo>,
      imagePaths: null == imagePaths
          ? _value._imagePaths
          : imagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageLayouts: null == imageLayouts
          ? _value._imageLayouts
          : imageLayouts // ignore: cast_nullable_to_non_nullable
              as List<NoteImageLayout>,
      voiceMemos: null == voiceMemos
          ? _value._voiceMemos
          : voiceMemos // ignore: cast_nullable_to_non_nullable
              as List<VoiceMemo>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      linkedNoteIds: null == linkedNoteIds
          ? _value._linkedNoteIds
          : linkedNoteIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dailyNoteDateKey: freezed == dailyNoteDateKey
          ? _value.dailyNoteDateKey
          : dailyNoteDateKey // ignore: cast_nullable_to_non_nullable
              as String?,
      reminderDate: freezed == reminderDate
          ? _value.reminderDate
          : reminderDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reminderId: freezed == reminderId
          ? _value.reminderId
          : reminderId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$AddUpdateFormStateImpl extends _AddUpdateFormState {
  _$AddUpdateFormStateImpl(
      {this.title,
      this.description,
      final List<NoteTextStyleRange> textStyles = const [],
      this.selectedColor,
      final List<Todo> todos = const [],
      final List<String> imagePaths = const [],
      final List<NoteImageLayout> imageLayouts = const [],
      final List<VoiceMemo> voiceMemos = const [],
      final List<String> tags = const [],
      final List<String> linkedNoteIds = const [],
      this.dailyNoteDateKey,
      this.reminderDate,
      this.reminderId})
      : _textStyles = textStyles,
        _todos = todos,
        _imagePaths = imagePaths,
        _imageLayouts = imageLayouts,
        _voiceMemos = voiceMemos,
        _tags = tags,
        _linkedNoteIds = linkedNoteIds,
        super._();

  @override
  final String? title;
  @override
  final String? description;
  final List<NoteTextStyleRange> _textStyles;
  @override
  @JsonKey()
  List<NoteTextStyleRange> get textStyles {
    if (_textStyles is EqualUnmodifiableListView) return _textStyles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_textStyles);
  }

  @override
  final Color? selectedColor;
  final List<Todo> _todos;
  @override
  @JsonKey()
  List<Todo> get todos {
    if (_todos is EqualUnmodifiableListView) return _todos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_todos);
  }

  final List<String> _imagePaths;
  @override
  @JsonKey()
  List<String> get imagePaths {
    if (_imagePaths is EqualUnmodifiableListView) return _imagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imagePaths);
  }

  final List<NoteImageLayout> _imageLayouts;
  @override
  @JsonKey()
  List<NoteImageLayout> get imageLayouts {
    if (_imageLayouts is EqualUnmodifiableListView) return _imageLayouts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageLayouts);
  }

  final List<VoiceMemo> _voiceMemos;
  @override
  @JsonKey()
  List<VoiceMemo> get voiceMemos {
    if (_voiceMemos is EqualUnmodifiableListView) return _voiceMemos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_voiceMemos);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<String> _linkedNoteIds;
  @override
  @JsonKey()
  List<String> get linkedNoteIds {
    if (_linkedNoteIds is EqualUnmodifiableListView) return _linkedNoteIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_linkedNoteIds);
  }

  @override
  final String? dailyNoteDateKey;
  @override
  final DateTime? reminderDate;
  @override
  final int? reminderId;

  @override
  String toString() {
    return 'AddUpdateFormState(title: $title, description: $description, textStyles: $textStyles, selectedColor: $selectedColor, todos: $todos, imagePaths: $imagePaths, imageLayouts: $imageLayouts, voiceMemos: $voiceMemos, tags: $tags, linkedNoteIds: $linkedNoteIds, dailyNoteDateKey: $dailyNoteDateKey, reminderDate: $reminderDate, reminderId: $reminderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddUpdateFormStateImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._textStyles, _textStyles) &&
            (identical(other.selectedColor, selectedColor) ||
                other.selectedColor == selectedColor) &&
            const DeepCollectionEquality().equals(other._todos, _todos) &&
            const DeepCollectionEquality()
                .equals(other._imagePaths, _imagePaths) &&
            const DeepCollectionEquality()
                .equals(other._imageLayouts, _imageLayouts) &&
            const DeepCollectionEquality()
                .equals(other._voiceMemos, _voiceMemos) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._linkedNoteIds, _linkedNoteIds) &&
            (identical(other.dailyNoteDateKey, dailyNoteDateKey) ||
                other.dailyNoteDateKey == dailyNoteDateKey) &&
            (identical(other.reminderDate, reminderDate) ||
                other.reminderDate == reminderDate) &&
            (identical(other.reminderId, reminderId) ||
                other.reminderId == reminderId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      const DeepCollectionEquality().hash(_textStyles),
      selectedColor,
      const DeepCollectionEquality().hash(_todos),
      const DeepCollectionEquality().hash(_imagePaths),
      const DeepCollectionEquality().hash(_imageLayouts),
      const DeepCollectionEquality().hash(_voiceMemos),
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_linkedNoteIds),
      dailyNoteDateKey,
      reminderDate,
      reminderId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AddUpdateFormStateImplCopyWith<_$AddUpdateFormStateImpl> get copyWith =>
      __$$AddUpdateFormStateImplCopyWithImpl<_$AddUpdateFormStateImpl>(
          this, _$identity);
}

abstract class _AddUpdateFormState extends AddUpdateFormState {
  factory _AddUpdateFormState(
      {final String? title,
      final String? description,
      final List<NoteTextStyleRange> textStyles,
      final Color? selectedColor,
      final List<Todo> todos,
      final List<String> imagePaths,
      final List<NoteImageLayout> imageLayouts,
      final List<VoiceMemo> voiceMemos,
      final List<String> tags,
      final List<String> linkedNoteIds,
      final String? dailyNoteDateKey,
      final DateTime? reminderDate,
      final int? reminderId}) = _$AddUpdateFormStateImpl;
  _AddUpdateFormState._() : super._();

  @override
  String? get title;
  @override
  String? get description;
  @override
  List<NoteTextStyleRange> get textStyles;
  @override
  Color? get selectedColor;
  @override
  List<Todo> get todos;
  @override
  List<String> get imagePaths;
  @override
  List<NoteImageLayout> get imageLayouts;
  @override
  List<VoiceMemo> get voiceMemos;
  @override
  List<String> get tags;
  @override
  List<String> get linkedNoteIds;
  @override
  String? get dailyNoteDateKey;
  @override
  DateTime? get reminderDate;
  @override
  int? get reminderId;
  @override
  @JsonKey(ignore: true)
  _$$AddUpdateFormStateImplCopyWith<_$AddUpdateFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
