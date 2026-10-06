import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

class DailyNoteShortcut extends StatelessWidget {
  const DailyNoteShortcut(
      {super.key,
      required this.onPressed,
      this.onOpenCalendar,
      this.isOpening = false});

  final VoidCallback onPressed;
  final VoidCallback? onOpenCalendar;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final todayAction = Tooltip(
      message: S.of(context).Today_Note,
      child: ActionChip(
        key: const ValueKey('daily-note-shortcut'),
        avatar: isOpening
            ? SizedBox.square(
                dimension: 18,
                child: reduceMotion
                    ? const Icon(Icons.hourglass_top_rounded, size: 18)
                    : const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.edit_calendar_outlined, size: 18),
        label: Text(S.of(context).Today_Note),
        onPressed: isOpening ? null : onPressed,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
    if (onOpenCalendar == null) return todayAction;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        todayAction,
        const SizedBox(width: 4),
        IconButton(
          key: const ValueKey('daily-note-calendar-shortcut'),
          tooltip: S.of(context).Daily_Note_Calendar,
          onPressed: isOpening ? null : onOpenCalendar,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ],
    );
  }
}
