part of '../add_update_note_screen.dart';

class _AddTodoTile extends StatelessWidget {
  const _AddTodoTile({
    required this.onAdd,
  });

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
            Icon(
              Icons.add_circle_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              S.of(context).Add_todo,
              style: Theme.of(context).textTheme.titleMedium,
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
    required this.focusNode,
    required this.onChanged,
    required this.onRemoved,
  });

  final int index;
  final String? value;
  final FocusNode focusNode;
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
  void dispose() {
    todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: context.tokens.space2),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerLow
          .withValues(alpha: 0.72),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: context.tokens.space2),
        title: TextField(
          controller: todoController,
          focusNode: widget.focusNode,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            hintText: S.of(context).Todo,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              iconSize: 18,
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onRemoved,
            ),
            ReorderableDragStartListener(
              index: widget.index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildTodoListField extends StatefulWidget {
  const _BuildTodoListField({required this.state});
  final AddUpdateFormState state;

  @override
  State<_BuildTodoListField> createState() => _BuildTodoListFieldState();
}

class _BuildTodoListFieldState extends State<_BuildTodoListField> {
  final Map<String, FocusNode> _focusNodes = {};
  bool _focusNextTodo = false;

  FocusNode _focusNodeFor(String todoId) =>
      _focusNodes.putIfAbsent(todoId, FocusNode.new);

  @override
  void didUpdateWidget(covariant _BuildTodoListField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentIds = widget.state.todos.map((todo) => todo.id).toSet();
    final removedIds = _focusNodes.keys
        .where((todoId) => !currentIds.contains(todoId))
        .toList();
    for (final todoId in removedIds) {
      _focusNodes.remove(todoId)?.dispose();
    }

    if (!_focusNextTodo ||
        widget.state.todos.length <= oldWidget.state.todos.length) {
      return;
    }

    final oldIds = oldWidget.state.todos.map((todo) => todo.id).toSet();
    for (final todo in widget.state.todos.reversed) {
      if (!oldIds.contains(todo.id)) {
        final newTodoId = todo.id!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _focusNodes[newTodoId]?.requestFocus();
        });
        break;
      }
    }
    _focusNextTodo = false;
  }

  @override
  void dispose() {
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.state.todos.length,
          onReorderItem: (oldIndex, newIndex) {
            context.read<AddUpdateFormBloc>().add(
                  AddUpdateFormEvent.reorderTodo(
                      oldIndex: oldIndex, newIndex: newIndex),
                );
          },
          itemBuilder: (_, index) {
            final Todo todo = widget.state.todos[index];

            Future<bool> confirmAndDelete() async {
              final confirmed = await showConfirmDialog(
                context,
                title: S.of(context).Delete_Todo_Confirm_Title,
                message: S.of(context).Delete_Todo_Confirm_Message,
              );
              if (!context.mounted) return false;
              if (confirmed) {
                context
                    .read<AddUpdateFormBloc>()
                    .add(AddUpdateFormEvent.deleteTodo(todo.id!));
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
                focusNode: _focusNodeFor(todo.id!),
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
            _focusNextTodo = true;
            context
                .read<AddUpdateFormBloc>()
                .add(const AddUpdateFormEvent.addEmptyTodo());
          },
        ),
      ],
    );
  }
}
