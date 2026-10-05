import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

import 'reminder_labels.dart';

/// A confirmable hint, separate from the user's writing. Text may wrap at
/// accessibility sizes, and both actions keep a 48-point touch target.
class ReminderSuggestionChip extends StatelessWidget {
  const ReminderSuggestionChip({
    super.key,
    required this.date,
    required this.onPressed,
    required this.onDismiss,
    this.busy = false,
  });

  final DateTime date;
  final VoidCallback onPressed;
  final VoidCallback onDismiss;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: .48),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: busy ? null : onPressed,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Row(
                  children: [
                    if (busy && MediaQuery.disableAnimationsOf(context))
                      Icon(Icons.hourglass_empty_rounded,
                          size: 20, color: colors.onPrimaryContainer)
                    else if (busy)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimaryContainer,
                        ),
                      )
                    else
                      Icon(Icons.notifications_active_outlined,
                          size: 20, color: colors.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        S.of(context).Reminder_Suggestion(
                            formatReminderTime(context, date)),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: S.of(context).Reminder_Suggestion_Dismiss,
            onPressed: busy ? null : onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: colors.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}
