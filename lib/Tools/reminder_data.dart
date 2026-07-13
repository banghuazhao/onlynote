import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';

class ReminderData extends ChangeNotifier {
  List<Reminder> reminders = [];

  ReminderData._privateConstructor();

  static final ReminderData shared = ReminderData._privateConstructor();

  Future<void> _saveToStorage() async {
    localStorage.setItem(
        'reminders', jsonEncode(reminders.map((e) => e.toJson()).toList()));
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
        debugPrint('Reminder found at $i');
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

  void init(List<dynamic>? items) {
    debugPrint('$items');
    if (items != null && items.isNotEmpty) {
      reminders.clear();
      for (final dynamic e in items) {
        final reminderMap = e as Map<dynamic, dynamic>;
        reminders.add(Reminder(
            reminderDate: DateTime.parse(reminderMap['reminderDate'] as String),
            reminderId: reminderMap['reminderId'] as int,
            noteId: reminderMap['noteId'] as String));
      }
    }
  }
}
