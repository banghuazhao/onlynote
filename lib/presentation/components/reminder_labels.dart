import 'package:flutter/material.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/generated/l10n.dart';

String reminderRepeatLabel(BuildContext context, ReminderRepeat repeat) =>
    switch (repeat) {
      ReminderRepeat.none => S.of(context).Reminder_Repeat_Never,
      ReminderRepeat.daily => S.of(context).Reminder_Repeat_Daily,
      ReminderRepeat.weekly => S.of(context).Reminder_Repeat_Weekly,
    };

String formatReminderTime(BuildContext context, DateTime date) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(date.toLocal())} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date.toLocal()), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
}
