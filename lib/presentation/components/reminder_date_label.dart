import 'package:flutter/material.dart';

import 'reminder_labels.dart';

/// A display-only reminder row that follows the local date and clock format.
class ReminderDateLabel extends StatelessWidget {
  const ReminderDateLabel({super.key, required this.date, this.style});

  final DateTime date;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(Icons.alarm_rounded, size: 14, color: style?.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              formatReminderTime(context, date),
              key: const ValueKey('reminder-date-text'),
              style: style,
            ),
          ),
        ],
      );
}
