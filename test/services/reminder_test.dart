import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';

void main() {
  Reminder reminder(DateTime date,
          {ReminderRepeat repeat = ReminderRepeat.none}) =>
      Reminder(
        reminderDate: date,
        reminderId: 42,
        noteId: 'shopping',
        repeat: repeat,
      );

  test('legacy persisted reminders remain one-time reminders', () {
    final restored = Reminder.fromJson({
      'reminderDate': '2027-01-01 09:00:00.000',
      'reminderId': 42,
      'noteId': 'shopping',
    });

    expect(restored.repeat, ReminderRepeat.none);
    expect(restored.isRepeating, isFalse);
    expect(restored.nextOccurrence(DateTime(2026, 12, 31)),
        DateTime(2027, 1, 1, 9));
    expect(restored.isSchedulable(DateTime(2027, 1, 1, 10)), isFalse);
  });

  test('each repeat option survives persistence with note and notification IDs',
      () {
    for (final repeat in ReminderRepeat.values) {
      final original = reminder(DateTime(2027, 1, 1, 9), repeat: repeat);
      final restored = Reminder.fromJson(original.toJson());

      expect(restored.repeat, repeat);
      expect(restored.reminderDate, original.reminderDate);
      expect(restored.noteId, original.noteId);
      expect(restored.reminderId, original.reminderId);
    }
  });

  test('unsupported persisted repeats fail validation', () {
    expect(
        () => Reminder.fromJson({
              'reminderDate': '2027-01-01 09:00:00.000',
              'reminderId': 42,
              'noteId': 'shopping',
              'repeat': 'monthly',
            }),
        throwsFormatException);
  });

  test('daily repeats choose the next clock time across year rollover', () {
    final daily =
        reminder(DateTime(2020, 1, 1, 9), repeat: ReminderRepeat.daily);

    expect(daily.nextOccurrence(DateTime(2026, 12, 31, 8)),
        DateTime(2026, 12, 31, 9));
    expect(daily.nextOccurrence(DateTime(2026, 12, 31, 9)),
        DateTime(2027, 1, 1, 9));
    expect(daily.nextOccurrence(DateTime(2026, 12, 31, 23)),
        DateTime(2027, 1, 1, 9));
    expect(daily.isRepeating, isTrue);
    expect(daily.isSchedulable(DateTime(2026, 12, 31, 23)), isTrue);
  });

  test('weekly repeats keep their weekday and time and skip elapsed occurrence',
      () {
    // October 5, 2026 is a Monday.
    final weekly =
        reminder(DateTime(2026, 10, 5, 9), repeat: ReminderRepeat.weekly);

    expect(weekly.nextOccurrence(DateTime(2026, 10, 5, 8)),
        DateTime(2026, 10, 5, 9));
    expect(weekly.nextOccurrence(DateTime(2026, 10, 5, 9)),
        DateTime(2026, 10, 12, 9));
    expect(weekly.nextOccurrence(DateTime(2026, 10, 11, 23)),
        DateTime(2026, 10, 12, 9));
    expect(weekly.isSchedulable(DateTime(2027)), isTrue);
  });

  test('repeating schedules use matching components even for a future anchor',
      () {
    final now = DateTime(2026, 10, 5, 8);
    final future = DateTime(2026, 10, 19, 9);

    expect(reminder(future, repeat: ReminderRepeat.daily).nextOccurrence(now),
        DateTime(2026, 10, 5, 9));
    expect(reminder(future, repeat: ReminderRepeat.weekly).nextOccurrence(now),
        DateTime(2026, 10, 5, 9));
  });

  test('one-time reminders retain their original instant even after it passes',
      () {
    final once = reminder(DateTime(2020, 1, 1, 9));

    expect(once.nextOccurrence(DateTime(2026)), DateTime(2020, 1, 1, 9));
    expect(once.isSchedulable(DateTime(2020, 1, 1, 8)), isTrue);
    expect(once.isSchedulable(DateTime(2020, 1, 1, 9)), isFalse);
    expect(once.isSchedulable(DateTime(2026)), isFalse);
  });
}
