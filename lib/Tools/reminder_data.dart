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

  Future<void> replaceAll(List<Reminder> values) async {
    final previous = reminders;
    reminders = List.of(values);
    try {
      await _saveToStorage();
    } catch (_) {
      reminders = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) =>
      replaceAll([...reminders, reminder]);

  Future<void> deleteReminder(Reminder reminder) => replaceAll(
        reminders.where((r) => r.reminderId != reminder.reminderId).toList(),
      );

  Future<void> modifyReminder(Reminder original, Reminder newReminder) =>
      replaceAll([
        for (final reminder in reminders)
          reminder.reminderId == original.reminderId ? newReminder : reminder,
      ]);

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
    reminders = [
      for (final item in items ?? [])
        Reminder.fromJson(item as Map<dynamic, dynamic>),
    ];
  }
}
