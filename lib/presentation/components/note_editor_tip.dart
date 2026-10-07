import 'package:flutter/material.dart';

/// Brief, contextual guidance that leaves the editor usable while visible.
/// The caller removes the tip immediately and persists the dismissal.
class NoteEditorTip extends StatelessWidget {
  const NoteEditorTip({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const dismissSize = Size(48, 48);
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: .6)),
        ),
        child: Padding(
          padding:
              const EdgeInsetsDirectional.only(start: 12, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 14, end: 8),
                child: ExcludeSemantics(
                  child: Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: colors.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              TextFieldTapRegion(
                child: ExcludeFocus(
                  child: IconButton(
                    key: const ValueKey('note-editor-tip-dismiss'),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: onDismiss,
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(dismissSize),
                      maximumSize: const WidgetStatePropertyAll(dismissSize),
                      fixedSize: const WidgetStatePropertyAll(dismissSize),
                      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                      foregroundColor:
                          WidgetStatePropertyAll(colors.onSurfaceVariant),
                      visualDensity: VisualDensity.standard,
                      animationDuration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
