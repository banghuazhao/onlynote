/// Calendar-based shortcuts use local constructors so 9am stays 9am across DST.
enum ReminderShortcut {
  inOneHour,
  tomorrowMorning,
  nextWeek;

  DateTime resolve(DateTime now) => switch (this) {
        ReminderShortcut.inOneHour => now.add(const Duration(hours: 1)),
        ReminderShortcut.tomorrowMorning =>
          DateTime(now.year, now.month, now.day + 1, 9),
        ReminderShortcut.nextWeek =>
          DateTime(now.year, now.month, now.day + 7, 9),
      };
}
