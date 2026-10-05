import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/reminder_agenda.dart';

void main() {
  final now = DateTime(2026, 10, 6, 14);
  final note = Note(id: 'note', title: 'Call the dentist');
  Reminder reminder(int id, DateTime date,
          {ReminderRepeat repeat = ReminderRepeat.none,
          String noteId = 'note'}) =>
      Reminder(
          reminderId: id, noteId: noteId, reminderDate: date, repeat: repeat);

  test('past, remaining today, and future dates sort by due time', () {
    final entries = buildReminderAgenda(
      reminders: [
        reminder(3, DateTime(2026, 10, 7, 8)),
        reminder(2, DateTime(2026, 10, 6, 18)),
        reminder(1, DateTime(2026, 10, 6, 9)),
      ],
      notes: [note],
      now: now,
    );
    expect(entries.map((e) => e.reminder.reminderId), [1, 2, 3]);
    expect(entries.map((e) => e.groupAt(now)), [
      ReminderAgendaGroup.overdue,
      ReminderAgendaGroup.today,
      ReminderAgendaGroup.upcoming,
    ]);
  });

  test('today ends at the local calendar boundary', () {
    final entries = buildReminderAgenda(
      reminders: [
        reminder(1, DateTime(2026, 10, 6, 23, 59)),
        reminder(2, DateTime(2026, 10, 7)),
      ],
      notes: [note],
      now: now,
    );
    expect(entries.first.groupAt(now), ReminderAgendaGroup.today);
    expect(entries.last.groupAt(now), ReminderAgendaGroup.upcoming);
  });

  test('daily and weekly patterns advance without inventing overdue history',
      () {
    final entries = buildReminderAgenda(
      reminders: [
        reminder(1, DateTime(2024, 1, 1, 9), repeat: ReminderRepeat.daily),
        reminder(2, DateTime(2024, 1, 1, 9), repeat: ReminderRepeat.weekly),
      ],
      notes: [note],
      now: now,
    );
    expect(entries[0].dueDate, DateTime(2026, 10, 7, 9));
    expect(entries[1].dueDate, DateTime(2026, 10, 12, 9));
    expect(entries.every((e) => e.groupAt(now) == ReminderAgendaGroup.upcoming),
        isTrue);
  });

  test('a future snooze moves a delivered one-time reminder out of overdue',
      () {
    final due = now.add(const Duration(minutes: 10));
    final entries = buildReminderAgenda(
      reminders: [reminder(1, now.subtract(const Duration(hours: 1)))],
      notes: [note],
      now: now,
      pendingSnoozes: {1: due},
    );
    expect(entries.single.dueDate, due);
    expect(entries.single.snoozed, isTrue);
    expect(entries.single.groupAt(now), ReminderAgendaGroup.today);
  });

  test('repeat shows the earliest pending occurrence, retaining its pattern',
      () {
    final repeating =
        reminder(1, DateTime(2024, 1, 1, 15), repeat: ReminderRepeat.daily);
    final earlier = buildReminderAgenda(
      reminders: [repeating],
      notes: [note],
      now: now,
      pendingSnoozes: {1: now.add(const Duration(minutes: 10))},
    ).single;
    expect(earlier.snoozed, isTrue);
    expect(earlier.reminder.repeat, ReminderRepeat.daily);
    final later = buildReminderAgenda(
      reminders: [repeating],
      notes: [note],
      now: now,
      pendingSnoozes: {1: now.add(const Duration(hours: 2))},
    ).single;
    expect(later.dueDate, DateTime(2026, 10, 6, 15));
    expect(later.snoozed, isFalse);
  });

  test('expired snoozes cannot hide overdue one-time reminders', () {
    final date = now.subtract(const Duration(hours: 1));
    final entry = buildReminderAgenda(
      reminders: [reminder(1, date)],
      notes: [note],
      now: now,
      pendingSnoozes: {1: now.subtract(const Duration(minutes: 5))},
    ).single;
    expect(entry.dueDate, date);
    expect(entry.snoozed, isFalse);
    expect(entry.groupAt(now), ReminderAgendaGroup.overdue);
  });

  test('missing and trashed notes never appear in the agenda', () {
    final entries = buildReminderAgenda(
      reminders: [
        reminder(1, now, noteId: 'deleted'),
        reminder(2, now, noteId: 'missing'),
        reminder(3, now),
      ],
      notes: [note, Note(id: 'deleted', deletedAt: now)],
      now: now,
    );
    expect(entries.map((e) => e.reminder.reminderId), [3]);
  });
}
