import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Familiar editing controls that stay within reach while a note scrolls.
class NoteEditingActions extends StatelessWidget {
  const NoteEditingActions({
    super.key,
    required this.onUndo,
    required this.onRedo,
    this.onOutline,
    this.onToggleFocus,
    this.writingFocused = false,
  });

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onOutline;
  final VoidCallback? onToggleFocus;
  final bool writingFocused;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final focusLabel = writingFocused
        ? strings.Note_ShowWritingTools
        : strings.Note_FocusWriting;
    final actionStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      visualDensity: VisualDensity.standard,
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
    );
    final outline = onOutline == null
        ? null
        : TextButton.icon(
            key: const ValueKey('note-outline'),
            onPressed: onOutline,
            style: actionStyle,
            icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
            label: Text(strings.Note_Outline,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          );
    final iconActions = <Widget>[
      if (onToggleFocus != null)
        TextFieldTapRegion(
          child: ExcludeFocus(
            child: MergeSemantics(
              child: Semantics(
                button: true,
                enabled: true,
                selected: writingFocused,
                toggled: writingFocused,
                label: focusLabel,
                onTap: onToggleFocus,
                excludeSemantics: true,
                child: IconButton(
                  key: const ValueKey('note-focus-writing'),
                  tooltip: focusLabel,
                  isSelected: writingFocused,
                  onPressed: onToggleFocus,
                  style: actionStyle.copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? colors.primaryContainer
                            : null),
                    foregroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? colors.onPrimaryContainer
                            : null),
                  ),
                  icon: const Icon(Icons.fullscreen_rounded),
                  selectedIcon: const Icon(Icons.fullscreen_exit_rounded),
                ),
              ),
            ),
          ),
        ),
      IconButton(
        key: const ValueKey('note-undo'),
        tooltip: strings.Note_Undo,
        onPressed: onUndo,
        style: actionStyle,
        icon: const Icon(Icons.undo_rounded),
      ),
      IconButton(
        key: const ValueKey('note-redo'),
        tooltip: strings.Note_Redo,
        onPressed: onRedo,
        style: actionStyle,
        icon: const Icon(Icons.redo_rounded),
      ),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        // Reserve the icon targets plus room for Outline's icon and padding.
        final minimumRowWidth =
            iconActions.length * 48 + (outline == null ? 0 : 64);
        if (constraints.maxWidth < minimumRowWidth) {
          return Wrap(
            key: const ValueKey('note-editing-actions-wrap'),
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [if (outline != null) outline, ...iconActions],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: outline ?? const SizedBox.shrink(),
              ),
            ),
            ...iconActions,
          ],
        );
      }),
    );
  }
}
