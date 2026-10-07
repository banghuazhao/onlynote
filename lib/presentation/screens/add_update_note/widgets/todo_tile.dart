part of '../add_update_note_screen.dart';

class _AddTodoTile extends StatelessWidget {
  const _AddTodoTile({
    required this.onAdd,
  });

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacings.s),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          style: AppButtonStyles.paperAction(),
          onPressed: onAdd,
          icon: const SizedBox(
              width: 28, child: Icon(Icons.add_rounded, size: 20)),
          label: Text(S.of(context).Add_todo),
        ),
      ),
    );
  }
}

ButtonStyle _todoControlStyle({bool destructive = false}) =>
    AppButtonStyles.paperAction(destructive: destructive).copyWith(
      fixedSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );

//* Todo list tile
class _TodoFieldTile extends StatefulWidget {
  const _TodoFieldTile({
    super.key,
    required this.index,
    required this.id,
    this.value,
    required this.completed,
    required this.focusNode,
    this.autofocus = false,
    required this.onChanged,
    required this.onToggle,
    required this.onSubmitted,
    required this.onSplit,
    required this.onRemoved,
    required this.onInputChanged,
    required this.onCopySelection,
    this.restoredSelection,
    this.restoreRevision = 0,
  });

  final int index;
  final String id;
  final String? value;
  final bool completed;
  final FocusNode focusNode;
  final bool autofocus;
  final Function(String value) onChanged;
  final VoidCallback onToggle;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<List<String>> onSplit;
  final VoidCallback onRemoved;
  final ValueChanged<TextEditingValue> onInputChanged;
  final ValueChanged<NoteTextSelection> onCopySelection;
  final TextSelection? restoredSelection;
  final int restoreRevision;

  @override
  State<_TodoFieldTile> createState() => _TodoFieldTileState();
}

class _TodoFieldTileState extends State<_TodoFieldTile> {
  late TextEditingController todoController;

  @override
  void initState() {
    super.initState();
    todoController = TextEditingController(text: widget.value);
    todoController.addListener(_inputChanged);
    widget.focusNode.addListener(_inputChanged);
  }

  void _inputChanged() => widget.onInputChanged(todoController.value);

  @override
  void didUpdateWidget(covariant _TodoFieldTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_inputChanged);
      widget.focusNode.addListener(_inputChanged);
    }
    if (todoController.text != widget.value) {
      final text = widget.value ?? '';
      final offset = todoController.selection.extentOffset;
      todoController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
            offset: offset < 0 ? text.length : offset.clamp(0, text.length)),
      );
    }
    if (widget.restoreRevision != oldWidget.restoreRevision &&
        widget.restoredSelection?.isValid == true) {
      final selection = widget.restoredSelection!;
      todoController.selection = TextSelection(
          baseOffset: selection.baseOffset.clamp(0, todoController.text.length),
          extentOffset:
              selection.extentOffset.clamp(0, todoController.text.length));
    }
  }

  void _onChanged(String value) {
    final composing = todoController.value.composing;
    if (value.contains('\n') && (!composing.isValid || composing.isCollapsed)) {
      final lines = value
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => line.characters.take(todoMaxCharCount).toString())
          .toList();
      if (lines.isNotEmpty) {
        final text = lines.first;
        todoController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        if (lines.length == 1 && value.endsWith('\n')) {
          widget.onChanged(text);
          widget.onSubmitted(text);
          return;
        }
        widget.onSplit(lines);
        return;
      }
      todoController.clear();
      widget.onChanged('');
      widget.onSubmitted('');
      return;
    }
    widget.onChanged(value);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_inputChanged);
    todoController.removeListener(_inputChanged);
    todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.formText.copyWith(
      fontSize: 16,
      color: AppColors.ink.withValues(alpha: widget.completed ? 0.5 : 0.88),
      decoration: widget.completed ? TextDecoration.lineThrough : null,
    );
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(textStyle.fontSize ?? 16) *
            (textStyle.height ?? 1.55);
    // Center controls on the first line, even when the item wraps or text grows.
    // The field adds 12px above and below its line; controls remain 48px.
    final controlTopInset = ((lineHeight - 24) / 2).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: controlTopInset),
            child: Semantics(
              checked: widget.completed,
              label: widget.value?.isNotEmpty == true
                  ? widget.value
                  : S.of(context).Todo,
              child: IconButton(
                key: ValueKey('todo-check-${widget.id}'),
                style: _todoControlStyle(),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: widget.onToggle,
                icon: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  child: InkCheckbox(
                    key: ValueKey(widget.completed),
                    checked: widget.completed,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: ValueKey('todo-field-${widget.id}'),
              controller: todoController,
              contextMenuBuilder: (context, editable) =>
                  buildNoteSelectionContextMenu(context, editable,
                      onCopySelection: widget.onCopySelection),
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              style: textStyle,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: S.of(context).Todo,
                hintMaxLines: 1,
                hintStyle: AppTypography.formText.copyWith(
                  fontSize: 16,
                  color: AppColors.ink.withValues(alpha: 0.35),
                ),
                counterText: '',
              ),
              onChanged: _onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) =>
                    newValue.text.contains('\n')
                        ? newValue
                        : LengthLimitingTextInputFormatter(todoMaxCharCount)
                            .formatEditUpdate(oldValue, newValue)),
              ],
              maxLines: null,
              minLines: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: controlTopInset),
            child: IconButton(
              style: _todoControlStyle(destructive: true),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              iconSize: 18,
              icon: const Icon(Icons.close_rounded),
              onPressed: widget.onRemoved,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: controlTopInset),
            child: ReorderableDragStartListener(
              index: widget.index,
              child: Semantics(
                label: S.of(context).Reorder,
                child: Tooltip(
                  message: S.of(context).Reorder,
                  child: SizedBox(
                    width: 44,
                    height: 48,
                    child: Icon(
                      Icons.drag_handle,
                      size: 18,
                      color: AppColors.ink.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildTodoListField extends StatefulWidget {
  const _BuildTodoListField({
    super.key,
    this.showAddButton = true,
    required this.state,
    required this.onInputChanged,
    required this.onCopySelection,
    this.restoredEdit,
    this.restoreRevision = 0,
    this.autofocusFirstTodo = false,
  });
  final AddUpdateFormState state;
  final bool autofocusFirstTodo;
  final bool showAddButton;
  final void Function(String, TextEditingValue) onInputChanged;
  final ValueChanged<NoteTextSelection> onCopySelection;
  final NoteEditSnapshot? restoredEdit;
  final int restoreRevision;

  @override
  State<_BuildTodoListField> createState() => _BuildTodoListFieldState();
}

class _BuildTodoListFieldState extends State<_BuildTodoListField> {
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, GlobalKey<_TodoFieldTileState>> _fieldKeys = {};
  bool _focusNextTodo = false;

  FocusNode _focusNodeFor(String todoId) => _focusNodes.putIfAbsent(
      todoId, () => FocusNode(debugLabel: 'note-todo:$todoId'));

  void addItem() {
    _focusNextTodo = true;
    context
        .read<AddUpdateFormBloc>()
        .add(const AddUpdateFormEvent.addEmptyTodo());
  }

  @override
  void didUpdateWidget(covariant _BuildTodoListField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentIds = widget.state.todos.map((todo) => todo.id).toSet();
    final removedIds = _focusNodes.keys
        .where((todoId) => !currentIds.contains(todoId))
        .toList();
    for (final todoId in removedIds) {
      _focusNodes.remove(todoId)?.dispose();
      _fieldKeys.remove(todoId);
    }

    if (widget.restoreRevision != oldWidget.restoreRevision) {
      _focusNextTodo = false;
      final id = widget.restoredEdit?.focusedField;
      if (id != null && currentIds.contains(id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNodes[id]?.requestFocus();
        });
      }
      return;
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

  Future<void> selectMatch(
    String id,
    TextSelection selection, {
    bool requestFocus = true,
    bool Function()? canRestore,
  }) async {
    final field = _fieldKeys[id]?.currentState;
    if (field == null ||
        canRestore?.call() == false ||
        (!requestFocus &&
            (_focusNodes[id]?.hasFocus == true ||
                (field.todoController.value.composing.isValid &&
                    !field.todoController.value.composing.isCollapsed)))) {
      return;
    }
    field.todoController.selection = TextSelection(
        baseOffset:
            selection.baseOffset.clamp(0, field.todoController.text.length),
        extentOffset:
            selection.extentOffset.clamp(0, field.todoController.text.length));
    if (requestFocus) _focusNodes[id]?.requestFocus();
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && field.mounted && canRestore?.call() != false) {
      revealNoteTextOffset(field.context, selection.start,
          animate: requestFocus);
    }
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
        if (widget.state.todos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacings.m),
            child: Text(
              S.of(context).Checklist_Progress(
                    widget.state.todos.where((todo) => todo.completed).length,
                    widget.state.todos.length,
                  ),
              style: AppTypography.description.copyWith(
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
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
              background: ColoredBox(
                color: AppColors.error.withValues(alpha: 0.9),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacings.l),
                    child: Icon(Icons.delete_outline, color: Colors.white),
                  ),
                ),
              ),
              child: _TodoFieldTile(
                onCopySelection: widget.onCopySelection,
                key: _fieldKeys.putIfAbsent(
                    todo.id!, () => GlobalKey<_TodoFieldTileState>()),
                index: index,
                id: todo.id!,
                value: todo.title,
                completed: todo.completed,
                focusNode: _focusNodeFor(todo.id!),
                onInputChanged: (value) =>
                    widget.onInputChanged(todo.id!, value),
                restoredSelection: widget.restoredEdit?.todoSelections[todo.id],
                restoreRevision: widget.restoreRevision,
                autofocus: widget.autofocusFirstTodo && index == 0,
                onChanged: (value) {
                  context.read<AddUpdateFormBloc>().add(
                        AddUpdateFormEvent.todoValueChanged(
                          value: value,
                          id: todo.id!,
                        ),
                      );
                },
                onToggle: () {
                  HapticFeedback.selectionClick();
                  context.read<AddUpdateFormBloc>().add(
                        AddUpdateFormEvent.toggleTodoCheckbox(todo.id!),
                      );
                },
                onSubmitted: (value) {
                  if (value.trim().isEmpty) {
                    _focusNodeFor(todo.id!).unfocus();
                    return;
                  }
                  final nextIndex = index + 1;
                  if (nextIndex < widget.state.todos.length &&
                      widget.state.todos[nextIndex].title?.trim().isEmpty !=
                          false) {
                    _focusNodeFor(widget.state.todos[nextIndex].id!)
                        .requestFocus();
                    return;
                  }
                  _focusNextTodo = true;
                  context.read<AddUpdateFormBloc>().add(
                        AddUpdateFormEvent.addEmptyTodo(afterId: todo.id),
                      );
                },
                onSplit: (lines) {
                  _focusNextTodo = lines.length > 1;
                  context.read<AddUpdateFormBloc>().add(
                        AddUpdateFormEvent.replaceTodoLines(
                            id: todo.id!, lines: lines),
                      );
                },
                onRemoved: confirmAndDelete,
              ),
            );
          },
        ),
        if (widget.showAddButton)
          _AddTodoTile(
            onAdd: addItem,
          ),
      ],
    );
  }
}
