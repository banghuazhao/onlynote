import 'package:intl/intl.dart';

class Reminder {
  Reminder(
      {required this.reminderDate,
      required this.reminderId,
      required this.noteId});

  DateTime reminderDate;
  int reminderId;
  String noteId;

  String get timeString {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm");
    String string = dateFormat.format(reminderDate);
    return string;
  }

  Map<String, Object> toJson() => {
        "reminderDate": reminderDate.toString(),
        "reminderId": reminderId,
        "noteId": noteId
      };

  @override
  String toString() =>
      'name: $reminderDate, reminderId: $reminderId, noteId: $noteId';
}
