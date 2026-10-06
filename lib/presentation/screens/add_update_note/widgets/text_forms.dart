part of '../add_update_note_screen.dart';

class _BuildTitleField extends StatelessWidget {
  const _BuildTitleField({
    super.key,
    required this.state,
    required TextEditingController titleController,
    required this.focusNode,
    required this.onCopySelection,
  }) : _titleController = titleController;

  final AddUpdateFormState state;
  final TextEditingController _titleController;
  final FocusNode focusNode;
  final ValueChanged<NoteTextSelection> onCopySelection;

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
                  onCopySelection: onCopySelection),
          style: AppTypography.headline4.copyWith(height: 1.25),
          textInputAction: TextInputAction.next,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            filled: false,
            border: InputBorder.none,
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
    required this.onImageLayoutsChanged,
    required this.onRemoveImage,
    required this.onEditImage,
    required this.onCopySelection,
    this.autofocus = false,
  }) : _descriptionController = descriptionController;

  final AddUpdateFormState state;
  final SimpleFormattingController _descriptionController;
  final FocusNode focusNode;
  final NoteOutlineNavigationController outlineController;
  final ValueChanged<List<NoteImageLayout>> onImageLayoutsChanged;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<String> onEditImage;
  final ValueChanged<NoteTextSelection> onCopySelection;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => NoteBodyEditor(
        controller: _descriptionController,
        focusNode: focusNode,
        outlineController: outlineController,
        imagePaths: state.imagePaths,
        imageLayouts: state.imageLayouts,
        onImageLayoutsChanged: onImageLayoutsChanged,
        onRemoveImage: onRemoveImage,
        onEditImage: onEditImage,
        onCopySelection: onCopySelection,
        autofocus: autofocus,
        paperColor: state.selectedColor ?? AppColors.parchment,
      );
}
