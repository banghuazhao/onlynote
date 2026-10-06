import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Familiar editing controls that stay within reach while a note scrolls.
class NoteEditingActions extends StatelessWidget {
  const NoteEditingActions({
    super.key,
    required this.onUndo,
    required this.onRedo,
    this.onOutline,
  });

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onOutline;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: onOutline == null
                  ? const SizedBox.shrink()
                  : TextButton.icon(
                      key: const ValueKey('note-outline'),
                      onPressed: onOutline,
                      icon: const Icon(Icons.format_list_bulleted_rounded,
                          size: 20),
                      label: Text(strings.Note_Outline,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
            ),
          ),
          IconButton(
            key: const ValueKey('note-undo'),
            tooltip: strings.Note_Undo,
            onPressed: onUndo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey('note-redo'),
            tooltip: strings.Note_Redo,
            onPressed: onRedo,
            icon: const Icon(Icons.redo_rounded),
          ),
        ],
      ),
    );
  }
}
