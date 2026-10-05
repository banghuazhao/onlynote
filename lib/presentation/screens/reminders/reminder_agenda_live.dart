import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/reminder_agenda.dart';
import 'package:onlynote/services/reminder_agenda_controller.dart';

ReminderAgendaController createLiveReminderAgendaController({
  required String title,
  required String Function(Note) body,
  required Future<bool> Function(NotificationService) requestPermission,
}) {
  final data = ReminderData.shared;
  final repository = getIt<NoteRepository>();
  final notifications = NotificationService();

  Future<bool> reschedule(
      ReminderAgendaEntry entry, DateTime date, ReminderRepeat repeat) async {
    final updated = Reminder(
      reminderDate: date,
      reminderId: entry.reminder.reminderId,
      noteId: entry.reminder.noteId,
      repeat: repeat,
    );
    if (!updated.isSchedulable(DateTime.now())) return false;
    if (!await requestPermission(notifications)) return false;
    return notifications.rescheduleReminder(
      entry.reminder,
      updated,
      title: title,
      body: body(entry.note),
      persist: () => data.modifyReminder(entry.reminder, updated),
    );
  }

  return ReminderAgendaController(
    reminderChanges: data,
    readReminders: () => data.reminders,
    readNotes: () async =>
        repository.getAllNotes().map((note) => note.toDomain()).toList(),
    readNote: (id) async {
      try {
        return (await repository.getNote(id)).toDomain();
      } catch (_) {
        return null;
      }
    },
    readPendingSnoozes: notifications.readPendingSnoozeDates,
    rescheduleReminder: reschedule,
    snoozeReminder: (entry, delay) async {
      if (entry.reminder.isRepeating) {
        if (!await requestPermission(notifications)) return false;
        return notifications.snoozeReminder(
          entry.reminder,
          delay: delay,
          title: title,
          body: body(entry.note),
        );
      }
      final now = DateTime.now().toUtc();
      final due = entry.dueDate.toUtc();
      // A one-time reminder has one notification. Postponing it changes its
      // persisted due date rather than adding a second alert beside the first.
      final postponed = (due.isAfter(now) ? due : now).add(delay);
      return reschedule(entry, postponed, ReminderRepeat.none);
    },
  );
}
