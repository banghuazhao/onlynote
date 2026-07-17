import 'dart:io';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/extension/random.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

import 'bloc/add_update_bloc.dart';
import 'bloc/add_update_form/add_update_form_bloc.dart';

part 'widgets/colors_bar.dart';
part 'widgets/image_section.dart';
part 'widgets/text_forms.dart';
part 'widgets/todo_tile.dart';

@RoutePage(name: 'AddUpdateNoteRoute')
class AddUpdateNoteScreen extends StatefulWidget {
  const AddUpdateNoteScreen({super.key, this.note, this.folderId});
  final Note? note;
  final String? folderId;

  @override
  State<AddUpdateNoteScreen> createState() => _AddUpdateNoteScreenState();
}

class _AddUpdateNoteScreenState extends State<AddUpdateNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.title);
    _descriptionController =
        TextEditingController(text: widget.note?.description);

    context.read<AddUpdateFormBloc>().add(
          AddUpdateFormEvent.initialize(
            title: widget.note?.title,
            description: widget.note?.description,
            color: widget.note?.color ?? colors.randomElement,
            todos: widget.note?.todo,
            imagePaths: widget.note?.imagePaths,
          ),
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddUpdateFormBloc, AddUpdateFormState>(
      builder: (ctx, state) {
        return Stack(
          children: [
            _BuildForm(
              widget: widget,
              state: state,
              titleController: _titleController,
              descriptionController: _descriptionController,
            ),

            //* show overlay screen while saving.
            context.watch<AddUpdateBloc>().state.maybeMap(
                  orElse: () => Container(),
                  saving: (_) => FadeIn(
                    child: Container(
                      color: Theme.of(context)
                          .colorScheme
                          .scrim
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _BuildForm extends StatelessWidget {
  const _BuildForm({
    required this.widget,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required this.state,
  })  : _titleController = titleController,
        _descriptionController = descriptionController;

  final AddUpdateNoteScreen widget;
  final TextEditingController _titleController;
  final TextEditingController _descriptionController;
  final AddUpdateFormState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: state.selectedColor,
      bottomNavigationBar: ColorsBar(
        selectedColor: state.selectedColor,
        onChanged: (Color color) {
          context
              .read<AddUpdateFormBloc>()
              .add(AddUpdateFormEvent.colorChanged(color));
        },
      ),
      appBar: NoteAppBar(
        actions: [
          AppButton(
            tooltip: S.of(context).save,
            isLoading: context.watch<AddUpdateBloc>().state.maybeMap(
                  orElse: () => false,
                  saving: (_) => true,
                ),
            child: Text(S.of(context).save),
            onPressed: () => _addOrUpdateNote(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.tokens.contentMaxWidth),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(context.tokens.space4),
            children: [
              //* Add/Update Note title
              _BuildTitleField(
                state: state,
                titleController: _titleController,
              ),
              const SizedBox(height: AppSpacings.xl),

              //* Add/Update todo list.
              _BuildTodoListField(state: state),
              const SizedBox(height: AppSpacings.xl),

              //* Attach / remove photos.
              _BuildImageSection(state: state),
              const SizedBox(height: AppSpacings.xl),

              //* Add/Update note description.
              _BuildDescriptionField(
                state: state,
                descriptionController: _descriptionController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addOrUpdateNote(BuildContext context) {
    if (widget.note == null) {
      context.read<AddUpdateBloc>().add(
            AddUpdateEvent.addNote(
              Note(
                title: _titleController.text,
                description: _descriptionController.text,
                color: state.selectedColor,
                dateTime: DateTime.now(),
                todo: state.todos,
                imagePaths: state.imagePaths,
                folderId: widget.folderId,
              ),
            ),
          );
    } else {
      context.read<AddUpdateBloc>().add(
            AddUpdateEvent.updateNote(
              Note(
                id: widget.note!.id!,
                title: _titleController.text,
                description: _descriptionController.text,
                color: state.selectedColor,
                dateTime: DateTime.now(),
                todo: state.todos,
                imagePaths: state.imagePaths,
                sortOrder: widget.note!.sortOrder,
                isPinned: widget.note!.isPinned,
                folderId: widget.note!.folderId,
                deletedAt: widget.note!.deletedAt,
              ),
              widget.note!.id!,
            ),
          );
    }
  }
}
