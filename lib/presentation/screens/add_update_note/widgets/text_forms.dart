part of '../add_update_note_screen.dart';

class _BuildTitleField extends StatelessWidget {
  const _BuildTitleField({
    required this.state,
    required TextEditingController titleController,
  }) : _titleController = titleController;

  final AddUpdateFormState state;
  final TextEditingController _titleController;

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
          controller: _titleController,
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
    required this.state,
    required SimpleFormattingController descriptionController,
    required this.focusNode,
    this.autofocus = false,
  }) : _descriptionController = descriptionController;

  final AddUpdateFormState state;
  final SimpleFormattingController _descriptionController;
  final FocusNode focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final lineHeight = MediaQuery.textScalerOf(context)
            .scale(AppTypography.formText.fontSize ?? 17) *
        (AppTypography.formText.height ?? 1.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteFormattingToolbar(
            controller: _descriptionController, focusNode: focusNode),
        const SizedBox(height: 8),
        RuledWritingArea(
          paperColor: state.selectedColor ?? AppColors.parchment,
          lineHeight: lineHeight,
          child: Stack(
            children: [
              if (state.showDescriptionHint)
                Opacity(
                  opacity: 0.55,
                  child: Text(
                    S.of(context).Type_something,
                    style: AppTypography.formText.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.4),
                    ),
                    softWrap: true,
                  ),
                ),
              TextField(
                controller: _descriptionController,
                focusNode: focusNode,
                autofocus: autofocus,
                style: AppTypography.formText,
                strutStyle: StrutStyle.fromTextStyle(
                  AppTypography.formText,
                  forceStrutHeight: true,
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                minLines: 6,
                maxLines: 100,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
