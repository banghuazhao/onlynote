import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/reminder_shortcuts.dart';

import 'app_sheet.dart';
import 'reminder_labels.dart';
import 'toast.dart';

export 'reminder_labels.dart';

class ReminderPickerResult {
  const ReminderPickerResult.schedule(this.date, this.repeat) : delete = false;
  const ReminderPickerResult.delete()
      : date = null,
        repeat = ReminderRepeat.none,
        delete = true;

  final DateTime? date;
  final ReminderRepeat repeat;
  final bool delete;
}

/// One-time shortcuts remain one tap; recurring schedules choose a wall-clock
/// time and, for weekly reminders, a weekday rather than a future start date.
class ReminderPickerSheet extends StatefulWidget {
  const ReminderPickerSheet({super.key, this.current, this.allowDelete = true});
  final Reminder? current;
  final bool allowDelete;

  @override
  State<ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<ReminderPickerSheet> {
  late ReminderRepeat _repeat;
  late TimeOfDay _time;
  late int _weekday;

  @override
  void initState() {
    super.initState();
    _repeat = widget.current?.repeat ?? ReminderRepeat.none;
    final initial = widget.current?.reminderDate.toLocal() ??
        ReminderShortcut.inOneHour.resolve(DateTime.now());
    _time = TimeOfDay.fromDateTime(initial);
    _weekday = initial.weekday;
  }

  DateTime _nextOccurrence() {
    return Reminder(
      noteId: widget.current?.noteId ?? '',
      reminderId: widget.current?.reminderId ?? 0,
      reminderDate: _pattern,
      repeat: _repeat,
    ).nextOccurrence(DateTime.now());
  }

  // 1 January 2024 is a Monday. Store the selected pattern independently of
  // the next date, which may normalize a nonexistent time at a DST transition.
  DateTime get _pattern =>
      DateTime(2024, 1, _weekday, _time.hour, _time.minute);

  Future<void> _chooseTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time != null && mounted) setState(() => _time = time);
  }

  Future<void> _chooseDateAndTime() async {
    final now = DateTime.now();
    final current = widget.current;
    final initial = current != null && current.reminderDate.isAfter(now)
        ? current.reminderDate.toLocal()
        : now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      helpText: S.of(context).Reminder,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      helpText: S.of(context).Reminder,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final selected =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!selected.isAfter(DateTime.now())) {
      showTransientSnackBar(
          context, SnackBar(content: Text(S.of(context).Reminder_Future_Time)));
      return;
    }
    Navigator.pop(
        context, ReminderPickerResult.schedule(selected, ReminderRepeat.none));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    return AppSheet(
      title: l10n.Reminder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.Reminder_Repeat,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ReminderRepeat>(
                  segments: [
                    for (final repeat in ReminderRepeat.values)
                      ButtonSegment(
                        value: repeat,
                        label: Text(reminderRepeatLabel(context, repeat)),
                      ),
                  ],
                  selected: {_repeat},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      setState(() => _repeat = values.single),
                ),
              ],
            ),
          ),
          if (_repeat == ReminderRepeat.none) ...[
            for (final shortcut in ReminderShortcut.values)
              ListTile(
                minVerticalPadding: 14,
                leading: Icon(switch (shortcut) {
                  ReminderShortcut.inOneHour => Icons.schedule_outlined,
                  ReminderShortcut.tomorrowMorning => Icons.wb_sunny_outlined,
                  ReminderShortcut.nextWeek => Icons.event_outlined,
                }),
                title: Text(switch (shortcut) {
                  ReminderShortcut.inOneHour => l10n.Reminder_In_One_Hour,
                  ReminderShortcut.tomorrowMorning => l10n.Reminder_Tomorrow,
                  ReminderShortcut.nextWeek => l10n.Reminder_Next_Week,
                }),
                subtitle: Text(formatReminderTime(
                    context, shortcut.resolve(DateTime.now()))),
                onTap: () => Navigator.pop(
                    context,
                    ReminderPickerResult.schedule(
                        shortcut.resolve(DateTime.now()), ReminderRepeat.none)),
              ),
            ListTile(
              minVerticalPadding: 14,
              leading: const Icon(Icons.edit_calendar_outlined),
              title: Text(l10n.Reminder_Custom),
              subtitle: widget.current == null
                  ? null
                  : Text(formatReminderTime(
                      context, widget.current!.reminderDate)),
              onTap: _chooseDateAndTime,
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(l10n.Reminder_Time),
              subtitle: Text(_time.format(context)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _chooseTime,
            ),
            if (_repeat == ReminderRepeat.weekly)
              ListTile(
                leading: const Icon(Icons.event_repeat_outlined),
                title: Text(l10n.Reminder_Day),
                subtitle: DropdownButton<int>(
                  value: _weekday,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (var day = 1; day <= 7; day++)
                      DropdownMenuItem(
                        value: day,
                        child: Text(DateFormat.EEEE(locale)
                            .format(DateTime(2024, 1, day))),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _weekday = value);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Text(
                l10n.Reminder_Next_Time(
                    formatReminderTime(context, _nextOccurrence())),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                  context, ReminderPickerResult.schedule(_pattern, _repeat)),
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l10n.Reminder_Set),
            ),
          ],
          if (widget.current != null && widget.allowDelete) ...[
            const Divider(indent: 12, endIndent: 12, height: 24),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: Text(l10n.Delete),
              textColor: colors.error,
              iconColor: colors.error,
              onTap: () =>
                  Navigator.pop(context, const ReminderPickerResult.delete()),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.Cancel),
          ),
        ],
      ),
    );
  }
}
