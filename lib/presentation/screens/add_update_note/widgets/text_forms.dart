part of '../add_update_note_screen.dart';

class _BuildTitleField extends StatelessWidget {
  const _BuildTitleField({
    super.key,
    required this.state,
    required TextEditingController titleController,
    required this.focusNode,
    required this.onCopySelection,
    required this.onAddSelectionToChecklist,
  }) : _titleController = titleController;

  final AddUpdateFormState state;
  final TextEditingController _titleController;
  final FocusNode focusNode;
  final ValueChanged<NoteTextSelection> onCopySelection;
  final ValueChanged<NoteTextSelection> onAddSelectionToChecklist;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (state.showTitleHint)
          Opacity(
            opacity: 0.6,
            child: Text(
              S.of(context).Title,
              style: AppTypography.headline4.copyWith(
                color: AppColors.ink.withValues(alpha: 0.35),
              ),
              softWrap: true,
            ),
          ),
        TextField(
          key: const ValueKey('note-title-input'),
          controller: _titleController,
          focusNode: focusNode,
          contextMenuBuilder: (context, editable) =>
              buildNoteSelectionContextMenu(context, editable,
                  onCopySelection: onCopySelection,
                  onAddSelectionToChecklist: onAddSelectionToChecklist),
          style: AppTypography.headline4.copyWith(height: 1.25),
          textInputAction: TextInputAction.next,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
          minLines: 1,
          maxLines: maxTitleLinesCount,
          maxLength: maxTitleCharCount,
          onChanged: (value) {
            context.read<AddUpdateFormBloc>().add(
                  AddUpdateFormEvent.titleChanged(value),
                );
          },
        ),
      ],
    );
  }
}

class _BuildDescriptionField extends StatelessWidget {
  const _BuildDescriptionField({
    super.key,
    required this.state,
    required SimpleFormattingController descriptionController,
    required this.focusNode,
    required this.outlineController,
    required this.formattingController,
    required this.onImageLayoutsChanged,
    required this.onRemoveImage,
    required this.onEditImage,
    required this.onCopySelection,
    required this.onAddSelectionToChecklist,
    this.autofocus = false,
  }) : _descriptionController = descriptionController;

  final AddUpdateFormState state;
  final SimpleFormattingController _descriptionController;
  final FocusNode focusNode;
  final NoteOutlineNavigationController outlineController;
  final NoteBodyFormattingController formattingController;
  final ValueChanged<List<NoteImageLayout>> onImageLayoutsChanged;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<String> onEditImage;
  final ValueChanged<NoteTextSelection> onCopySelection;
  final ValueChanged<NoteTextSelection> onAddSelectionToChecklist;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => NoteBodyEditor(
        controller: _descriptionController,
        focusNode: focusNode,
        outlineController: outlineController,
        formattingController: formattingController,
        showFormattingToolbar: false,
        imagePaths: state.imagePaths,
        imageLayouts: state.imageLayouts,
        onImageLayoutsChanged: onImageLayoutsChanged,
        onRemoveImage: onRemoveImage,
        onEditImage: onEditImage,
        onCopySelection: onCopySelection,
        onAddSelectionToChecklist: onAddSelectionToChecklist,
        autofocus: autofocus,
        paperColor: state.selectedColor ?? AppColors.parchment,
      );
}
