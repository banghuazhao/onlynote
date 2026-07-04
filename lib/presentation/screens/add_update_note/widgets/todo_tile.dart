part of '../add_update_note_screen.dart';

class _AddTodoTile extends StatelessWidget {
  const _AddTodoTile({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppColors.title,
            ),
            const SizedBox(width: 12),
            Text(
              S.of(context).Add_todo,
              style: AppTypography.headline6,
            ),
          ],
        ),
        onTap: onAdd,
      ),
    );
  }
}

//* Todo list tile
class _TodoFieldTile extends StatefulWidget {
  const _TodoFieldTile({
    required this.index,
    this.value,
    required this.onChanged,
    required this.onRemoved,
  });

  final int index;
  final String? value;
  final Function(String value) onChanged;
  final VoidCallback onRemoved;

  @override
  State<_TodoFieldTile> createState() => _TodoFieldTileState();
}

class _TodoFieldTileState extends State<_TodoFieldTile> {
  late TextEditingController todoController;

  @override
  void initState() {
    super.initState();
    todoController = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: TextField(
        controller: todoController,
        style: AppTypography.headline6,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: S.of(context).Todo,
          hintStyle: AppTypography.headline6.copyWith(
            color: AppColors.title.withOpacity(0.6),
          ),
          counterText: '',
        ),
        onChanged: widget.onChanged,
        maxLength: todoMaxCharCount,
        maxLines: 4,
        minLines: 1,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 18,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.black87,
            ),
            onPressed: widget.onRemoved,
          ),
          ReorderableDragStartListener(
            index: widget.index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                Icons.drag_handle,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildTodoListField extends StatelessWidget {
  const _BuildTodoListField({Key? key, required this.state}) : super(key: key);
  final AddUpdateFormState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.todos.length,
          onReorder: (oldIndex, newIndex) {
            context.read<AddUpdateFormBloc>().add(
                  AddUpdateFormEvent.reorderTodo(oldIndex: oldIndex, newIndex: newIndex),
                );
          },
          itemBuilder: (_, index) {
            final Todo todo = state.todos[index];

            Future<bool> confirmAndDelete() async {
              final confirmed = await showConfirmDialog(
                context,
                title: S.of(context).Delete_Todo_Confirm_Title,
                message: S.of(context).Delete_Todo_Confirm_Message,
              );
              if (confirmed) {
                context.read<AddUpdateFormBloc>().add(AddUpdateFormEvent.deleteTodo(todo.id!));
              }
              return confirmed;
            }

            return Dismissible(
              key: ValueKey(todo.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => confirmAndDelete(),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacings.l),
                color: AppColors.error,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _TodoFieldTile(
                index: index,
                value: todo.title,
                onChanged: (value) {
                  context.read<AddUpdateFormBloc>().add(
                        AddUpdateFormEvent.todoValueChanged(
                          value: value,
                          id: todo.id!,
                        ),
                      );
                },
                onRemoved: confirmAndDelete,
              ),
            );
          },
        ),
        _AddTodoTile(
          onAdd: () {
            context.read<AddUpdateFormBloc>().add(const AddUpdateFormEvent.addEmptyTodo());
          },
        ),
      ],
    );
  }
}
