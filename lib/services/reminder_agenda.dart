import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';

enum ReminderAgendaGroup { overdue, today, upcoming }

/// A repeating reminder represents its next calendar occurrence. A delivered
/// occurrence is not an unfinished task, so it must not stay overdue forever.
class ReminderAgendaEntry {
  const ReminderAgendaEntry({
    required this.reminder,
    required this.note,
    required this.dueDate,
    this.snoozed = false,
  });

  final Reminder reminder;
  final Note note;
  final DateTime dueDate;
  final bool snoozed;

  ReminderAgendaGroup groupAt(DateTime now) {
    if (dueDate.isBefore(now)) return ReminderAgendaGroup.overdue;
    final localNow = now.toLocal();
    final tomorrow = DateTime(localNow.year, localNow.month, localNow.day + 1);
    return dueDate.toLocal().isBefore(tomorrow)
        ? ReminderAgendaGroup.today
        : ReminderAgendaGroup.upcoming;
  }
}

List<ReminderAgendaEntry> buildReminderAgenda({
  required List<Reminder> reminders,
  required Iterable<Note> notes,
  required DateTime now,
  Map<int, DateTime> pendingSnoozes = const {},
}) {
  final byId = {for (final note in notes) note.id: note};
  final entries = <ReminderAgendaEntry>[];
  for (final reminder in reminders) {
    final note = byId[reminder.noteId];
    if (note == null || note.isDeleted) continue;
    final base = reminder.nextOccurrence(now);
    final snooze = pendingSnoozes[reminder.reminderId];
    final useSnooze = snooze != null &&
        snooze.isAfter(now) &&
        (!reminder.isRepeating || !snooze.isAfter(base));
    entries.add(ReminderAgendaEntry(
      reminder: reminder,
      note: note,
      dueDate: useSnooze ? snooze : base,
      snoozed: useSnooze,
    ));
  }
  entries.sort((a, b) {
    final date = a.dueDate.compareTo(b.dueDate);
    return date != 0
        ? date
        : a.reminder.reminderId.compareTo(b.reminder.reminderId);
  });
  return entries;
}
