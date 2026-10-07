import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_autosave.dart';

/// Save feedback that lets writers retry without leaving the note.
///
/// The retry control joins the text field's tap region and does not take focus,
/// so tapping it preserves the cursor, selection, and on-screen keyboard.
class NoteSaveStatus extends StatelessWidget {
  const NoteSaveStatus({
    super.key,
    required this.status,
    this.onRetry,
    this.retrying = false,
  });

  final AutosaveStatus status;
  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final failed = status == AutosaveStatus.failed && !retrying;
    final retryControl = failed || retrying;
    final label = retrying
        ? strings.Autosave_Saving
        : switch (status) {
            AutosaveStatus.saved => strings.Autosave_Saved,
            AutosaveStatus.failed => strings.Autosave_Retry,
            _ => strings.Autosave_Saving,
          };
    final enabled = failed && onRetry != null;
    final accessibleLabel = failed ? '$label. ${strings.Retry}' : label;
    final scheme = Theme.of(context).colorScheme;
    final color = failed ? scheme.error : scheme.onSurfaceVariant;
    final style =
        Theme.of(context).textTheme.labelLarge?.copyWith(color: color);

    if (!retryControl) {
      return Semantics(
        // Routine autosaves should not interrupt screen-reader typing.
        label: label,
        child: ExcludeSemantics(
          child: SizedBox(
            height: 48,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final showLabel = constraints.maxWidth >= painter.width + 48;
      painter.dispose();
      return Semantics(
        key: const ValueKey('editor-retry-save'),
        liveRegion: true,
        button: true,
        enabled: enabled,
        label: accessibleLabel,
        onTap: enabled ? onRetry : null,
        child: ExcludeSemantics(
          child: TextFieldTapRegion(
            child: Tooltip(
              message: accessibleLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  canRequestFocus: false,
                  onTap: enabled ? onRetry : null,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minHeight: 48, minWidth: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 24, color: color),
                          if (showLabel) ...[
                            const SizedBox(width: 8),
                            Text(label, maxLines: 1, style: style),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
