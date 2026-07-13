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
              style: Theme.of(context).textTheme.titleLarge,
              softWrap: true,
            ),
          ),
        TextField(
          controller: _titleController,
          style: Theme.of(context).textTheme.titleLarge,
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
    required TextEditingController descriptionController,
  }) : _descriptionController = descriptionController;

  final AddUpdateFormState state;
  final TextEditingController _descriptionController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (state.showDescriptionHint)
          Opacity(
            opacity: 0.6,
            child: Text(
              S.of(context).Type_something,
              style: Theme.of(context).textTheme.bodyLarge,
              softWrap: true,
            ),
          ),
        TextField(
          controller: _descriptionController,
          style: Theme.of(context).textTheme.bodyLarge,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            filled: false,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          minLines: 2,
          maxLines: 100,
          onChanged: (value) {
            context.read<AddUpdateFormBloc>().add(
                  AddUpdateFormEvent.descriptionChanged(value),
                );
          },
        ),
      ],
    );
  }
}
