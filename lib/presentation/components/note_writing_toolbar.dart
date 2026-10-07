import 'package:flutter/material.dart';
import 'note_editor_tip.dart';
import 'note_formatting_toolbar.dart';
import 'simple_formatting_controller.dart';

/// Sits above the software keyboard, and at the bottom for hardware keyboards.
class NoteWritingToolbar extends StatelessWidget {
  const NoteWritingToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.beforeApply,
    this.tip,
    this.onDismissTip,
    this.enabled = true,
  });

  final SimpleFormattingController controller;
  final FocusNode focusNode;
  final VoidCallback? beforeApply;
  final String? tip;
  final VoidCallback? onDismissTip;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tip != null && onDismissTip != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .18),
                    child: SingleChildScrollView(
                      child: NoteEditorTip(
                        message: tip!,
                        onDismiss: onDismissTip!,
                      ),
                    ),
                  ),
                IgnorePointer(
                  ignoring: !enabled,
                  child: ExcludeFocus(
                    child: NoteFormattingToolbar(
                      key: const ValueKey('editor-keyboard-formatting'),
                      controller: controller,
                      focusNode: focusNode,
                      beforeApply: beforeApply,
                      useSurfaceColors: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
