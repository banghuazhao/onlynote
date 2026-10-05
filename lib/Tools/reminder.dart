import 'package:intl/intl.dart';

enum ReminderRepeat {
  none,
  daily,
  weekly;

  static ReminderRepeat fromJson(Object? value) => switch (value) {
        null || 'none' => none,
        'daily' => daily,
        'weekly' => weekly,
        _ => throw const FormatException('Invalid reminder repeat'),
      };
}

class Reminder {
  Reminder(
      {required this.reminderDate,
      required this.reminderId,
      required this.noteId,
      this.repeat = ReminderRepeat.none});

  final DateTime reminderDate;
  final int reminderId;
  final String noteId;
  final ReminderRepeat repeat;

  bool get isRepeating => repeat != ReminderRepeat.none;

  bool isSchedulable(DateTime now) => isRepeating || reminderDate.isAfter(now);

  /// Repeats are local calendar patterns, not fixed 24/168-hour intervals.
  /// The stored date supplies the time (and weekday), not a future start date.
  DateTime nextOccurrence(DateTime now) {
    if (!isRepeating) return reminderDate;
    final localNow = now.toLocal();
    final pattern = reminderDate.toLocal();
    final days = repeat == ReminderRepeat.weekly
        ? (pattern.weekday - localNow.weekday + 7) % 7
        : 0;
    DateTime occurrence(int offset) => DateTime(
          localNow.year,
          localNow.month,
          localNow.day + offset,
          pattern.hour,
          pattern.minute,
          pattern.second,
          pattern.millisecond,
          pattern.microsecond,
        );
    final next = occurrence(days);
    return next.isAfter(localNow)
        ? next
        : occurrence(days + (repeat == ReminderRepeat.weekly ? 7 : 1));
  }

  factory Reminder.fromJson(Map<dynamic, dynamic> json) => Reminder(
        reminderDate: DateTime.parse(json['reminderDate'] as String),
        reminderId: json['reminderId'] as int,
        noteId: json['noteId'] as String,
        repeat: ReminderRepeat.fromJson(json['repeat']),
      );

  String get timeString {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm");
    String string = dateFormat.format(nextOccurrence(DateTime.now()));
    return string;
  }

  Map<String, Object> toJson() => {
        "reminderDate": reminderDate.toString(),
        "reminderId": reminderId,
        "noteId": noteId,
        "repeat": repeat.name,
      };

  @override
  String toString() =>
      'name: $reminderDate, reminderId: $reminderId, noteId: $noteId, repeat: ${repeat.name}';
}
