import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';

final LocalStorage localStorage = LocalStorage(
  'reminderList.json',
);

class ReminderData extends ChangeNotifier {
  List<Reminder> reminders = [];

  ReminderData._privateConstructor();

  static final ReminderData shared = ReminderData._privateConstructor();

  Future<void> _saveToStorage() async {
    await localStorage.setItem('reminders', reminders.map((e) => e.toJson()).toList());
  }

  Future<void> addReminder(Reminder reminder) async {
    reminders.add(reminder);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> deleteReminder(Reminder reminder) async {
    reminders.remove(reminder);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> modifyReminder(Reminder original, Reminder newReminder) async {
    for (int i = 0; i < reminders.length; i++) {
      if (reminders[i].reminderId == original.reminderId) {
        print('Reminder found at $i');
        reminders[i] = newReminder;
        break;
      }
    }

    await _saveToStorage();
    notifyListeners();
  }

  int get reminderCount {
    return reminders.length;
  }

  Reminder? getCurrentReminder(Note note) {
    for (Reminder reminder in reminders) {
      if (note.id == reminder.noteId) {
        return reminder;
      }
    }
    return null;
  }

  void init(item) {
    print(item);
    if (item != null && item.length > 0) {
      reminders.clear();
      for (Map e in item) {
        reminders.add(Reminder(
            reminderDate: DateTime.parse(e['reminderDate']),
            reminderId: e['reminderId'],
            noteId: e['noteId']));
      }
    }
  }
}
