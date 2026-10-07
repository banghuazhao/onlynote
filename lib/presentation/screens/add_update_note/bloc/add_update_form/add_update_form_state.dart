part of 'add_update_form_bloc.dart';

@freezed
class AddUpdateFormState with _$AddUpdateFormState {
  const AddUpdateFormState._();
  factory AddUpdateFormState(
      {String? title,
      String? description,
      @Default([]) List<NoteTextStyleRange> textStyles,
      Color? selectedColor,
      @Default([]) List<Todo> todos,
      @Default([]) List<String> imagePaths,
      @Default([]) List<NoteImageLayout> imageLayouts,
      @Default([]) List<VoiceMemo> voiceMemos,
      @Default([]) List<String> tags,
      @Default([]) List<String> linkedNoteIds,
      String? dailyNoteDateKey,
      @Default(NoteCardStyle()) NoteCardStyle cardStyle,
      DateTime? reminderDate,
      int? reminderId}) = _AddUpdateFormState;

  bool get showTitleHint => title.isEmptyString;

  bool get showDescriptionHint => description.isEmptyString;

  bool get hasTodo => todos.isNotEmpty;

  bool get hasImages => imagePaths.isNotEmpty;
}
