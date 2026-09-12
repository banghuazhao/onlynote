import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/reminder_shortcuts.dart';

void main() {
  test('one hour preserves elapsed time including seconds', () {
    final now = DateTime(2026, 9, 13, 23, 45, 30);
    expect(ReminderShortcut.inOneHour.resolve(now),
        now.add(const Duration(hours: 1)));
  });
  test('tomorrow is 9am on the next calendar day, including year rollover', () {
    expect(
        ReminderShortcut.tomorrowMorning
            .resolve(DateTime(2026, 12, 31, 23, 59)),
        DateTime(2027, 1, 1, 9));
  });
  test('a week uses seven calendar days and resolves to 9am', () {
    expect(ReminderShortcut.nextWeek.resolve(DateTime(2026, 9, 27, 18)),
        DateTime(2026, 10, 4, 9));
  });
}
