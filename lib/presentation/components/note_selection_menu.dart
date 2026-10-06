import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_selection.dart';

/// Add one app action while retaining the native copy, paste, and selection
/// actions. The snapshot is captured before a picker can blur the text field.
Widget buildNoteSelectionContextMenu(
  BuildContext context,
  EditableTextState editableTextState, {
  required ValueChanged<NoteTextSelection> onCopySelection,
  Iterable<NoteTextStyleRange> textStyles = const [],
}) {
  final value = editableTextState.textEditingValue;
  final snapshot = captureNoteTextSelection(
    text: value.text,
    selection: value.selection,
    styles: textStyles,
    composing: value.composing,
  );
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: [
      ...editableTextState.contextMenuButtonItems,
      if (snapshot != null && snapshot.text.trim().isNotEmpty)
        ContextMenuButtonItem(
          label: S.maybeOf(context)?.Copy_Selection_To_Note ?? 'Copy to note',
          onPressed: () {
            ContextMenuController.removeAny();
            onCopySelection(snapshot);
          },
        ),
    ],
  );
}
