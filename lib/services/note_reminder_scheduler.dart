import 'package:flutter/material.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:uuid/uuid.dart';

enum NoteReminderSaveResult { saved, denied, failed, past }

/// Scheduling has injectable boundaries for editor interaction tests. Existing
/// reminders use the notification service's rollback-aware transaction.
class NoteReminderScheduler {
  NoteReminderScheduler({
    NotificationService? notifications,
    Reminder? Function(Note)? readCurrent,
    List<Reminder> Function()? readReminders,
    Future<void> Function(Reminder)? addReminder,
    Future<void> Function(Reminder, Reminder)? modifyReminder,
    DateTime Function()? now,
  })  : _notifications = notifications,
        readCurrent = readCurrent ?? ReminderData.shared.getCurrentReminder,
        readReminders = readReminders ?? (() => ReminderData.shared.reminders),
        addReminder = addReminder ?? ReminderData.shared.addReminder,
        modifyReminder = modifyReminder ?? ReminderData.shared.modifyReminder,
        now = now ?? DateTime.now;

  // Merely opening an editor or evaluating a local hint must not initialize
  // platform notification/shared-preference plugins.
  NotificationService? _notifications;
  NotificationService get notifications =>
      _notifications ??= NotificationService();
  final Reminder? Function(Note) readCurrent;
  final List<Reminder> Function() readReminders;
  final Future<void> Function(Reminder) addReminder;
  final Future<void> Function(Reminder, Reminder) modifyReminder;
  final DateTime Function() now;

  Reminder? current(Note note) => readCurrent(note);

  Future<NoteReminderSaveResult> save(BuildContext context, Note note,
      DateTime date, ReminderRepeat repeat) async {
    try {
      final l10n = S.of(context);
      if (note.id == null || note.isDeleted) {
        return NoteReminderSaveResult.failed;
      }
      if (repeat == ReminderRepeat.none && !date.isAfter(now())) {
        return NoteReminderSaveResult.past;
      }
      final allowed = await notifications.checkAndAskForPermission(context);
      if (allowed != true || !context.mounted) {
        return NoteReminderSaveResult.denied;
      }
      // Permission sheets may keep the app suspended while another surface
      // edits the reminder. Resolve its latest identity before replacing it.
      final original = current(note);
      final used =
          readReminders().map((reminder) => reminder.reminderId).toSet();
      var id =
          original?.reminderId ?? (const Uuid().v4().hashCode & 0x7fffffff);
      if (original == null) {
        while (used.contains(id)) {
          id = (id + 1) & 0x7fffffff;
        }
      }
      final updated = Reminder(
          noteId: note.id!, reminderId: id, reminderDate: date, repeat: repeat);
      if (!updated.isSchedulable(now())) return NoteReminderSaveResult.past;
      final body = '${l10n.Reminder}: ${note.title ?? ''}';
      if (original != null) {
        final saved = await notifications.rescheduleReminder(original, updated,
            title: l10n.Onlynote,
            body: body,
            persist: () => modifyReminder(original, updated));
        return saved
            ? NoteReminderSaveResult.saved
            : NoteReminderSaveResult.failed;
      }
      final scheduled = await notifications.scheduleNotifications(
        id: id,
        title: l10n.Onlynote,
        body: body,
        time: date,
        noteId: note.id!,
        repeat: repeat,
      );
      if (!scheduled) return NoteReminderSaveResult.failed;
      try {
        await addReminder(updated);
      } catch (_) {
        await notifications.removeNotification(updated);
        rethrow;
      }
      return NoteReminderSaveResult.saved;
    } catch (_) {
      return NoteReminderSaveResult.failed;
    }
  }
}
