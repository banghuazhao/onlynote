part of 'add_update_form_bloc.dart';

@freezed
class AddUpdateFormEvent with _$AddUpdateFormEvent {
  const factory AddUpdateFormEvent.initialize({
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
  }) = _Initialize;

  const factory AddUpdateFormEvent.titleChanged(String value) = _TitleChanged;

  const factory AddUpdateFormEvent.descriptionChanged(String value) =
      _DescriptionChanged;

  const factory AddUpdateFormEvent.bodyChanged(
      String text,
      List<NoteTextStyleRange> styles,
      List<NoteImageLayout> layouts) = _BodyChanged;

  const factory AddUpdateFormEvent.imageLayoutsChanged(
      List<NoteImageLayout> value) = _ImageLayoutsChanged;

  const factory AddUpdateFormEvent.colorChanged(Color value) = _ColorChanged;

  const factory AddUpdateFormEvent.addOrUpdateNote({
    String? id,
    String? folderId,
    @Default(false) bool isPinned,
    @Default(false) bool isArchived,
    int? sortOrder,
    DateTime? deletedAt,
  }) = _AddOrUpdateNote;

  const factory AddUpdateFormEvent.addEmptyTodo({String? afterId}) =
      _AddEmptyTodo;

  const factory AddUpdateFormEvent.deleteTodo(String id) = _DeleteTodo;

  const factory AddUpdateFormEvent.todoValueChanged({
    required String value,
    required String id,
  }) = _TodoValueChanged;

  const factory AddUpdateFormEvent.toggleTodoCheckbox(String id) =
      _ToggleTodoCheckbox;

  const factory AddUpdateFormEvent.setTodoCompleted(
      {required String id, required bool completed}) = _SetTodoCompleted;

  const factory AddUpdateFormEvent.replaceTodoLines({
    required String id,
    required List<String> lines,
  }) = _ReplaceTodoLines;

  const factory AddUpdateFormEvent.reorderTodo({
    required int oldIndex,
    required int newIndex,
  }) = _ReorderTodo;

  const factory AddUpdateFormEvent.addImage(String path, {int? textOffset}) =
      _AddImage;

  const factory AddUpdateFormEvent.removeImage(String path) = _RemoveImage;

  const factory AddUpdateFormEvent.voiceMemosChanged(List<VoiceMemo> value) =
      _VoiceMemosChanged;
  const factory AddUpdateFormEvent.tagsChanged(List<String> value) =
      _TagsChanged;
  const factory AddUpdateFormEvent.linksChanged(List<String> value) =
      _LinksChanged;
}
