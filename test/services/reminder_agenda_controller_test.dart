import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/reminder_agenda_controller.dart';

void main() {
  final now = DateTime(2026, 10, 6, 14);
  late List<Reminder> reminders;
  late Note? note;
  late ReminderAgendaController controller;
  late bool failLoad;
  late int saves;

  setUp(() {
    reminders = [
      Reminder(reminderDate: now, reminderId: 42, noteId: 'note'),
    ];
    note = Note(id: 'note', title: 'Original');
    failLoad = false;
    saves = 0;
    controller = ReminderAgendaController(
      readReminders: () => reminders,
      readNotes: () async {
        if (failLoad) throw StateError('Storage unavailable');
        return [if (note != null) note!];
      },
      readNote: (_) async => note,
      readPendingSnoozes: (_) async => {},
      snoozeReminder: (_, __) async => false,
      rescheduleReminder: (entry, date, repeat) async {
        saves++;
        reminders = [
          Reminder(
            reminderDate: date,
            reminderId: entry.reminder.reminderId,
            noteId: entry.reminder.noteId,
            repeat: repeat,
          )
        ];
        return true;
      },
      now: () => now,
    );
  });
  tearDown(() => controller.dispose());

  test('successful reschedule reloads persisted time and current note',
      () async {
    await controller.refresh();
    final entry = controller.entries.single;
    note = note!.copyWith(title: 'Edited title');
    final date = now.add(const Duration(days: 1));
    expect(await controller.reschedule(entry, date, ReminderRepeat.none),
        ReminderAgendaActionResult.saved);
    expect(controller.entries.single.dueDate, date);
    expect(controller.entries.single.note.title, 'Edited title');
    expect(saves, 1);
    expect(controller.busyReminderId, isNull);
  });

  test('failed native action retains entries and re-enables controls',
      () async {
    await controller.refresh();
    final original = controller.entries.single;
    expect(await controller.snooze(original, const Duration(minutes: 10)),
        ReminderAgendaActionResult.failed);
    expect(controller.entries.single, same(original));
    expect(controller.busyReminderId, isNull);
    expect(saves, 0);
  });

  test('a trashed note cannot be acted on from an older row', () async {
    await controller.refresh();
    final original = controller.entries.single;
    note = note!.copyWith(deletedAt: now);
    expect(
        await controller.reschedule(
            original, now.add(const Duration(hours: 1)), ReminderRepeat.none),
        ReminderAgendaActionResult.unavailable);
    expect(saves, 0);
  });

  test('an edited reminder rejects a stale picker result and refreshes',
      () async {
    await controller.refresh();
    final original = controller.entries.single;
    final newTime = now.add(const Duration(days: 3));
    reminders = [
      Reminder(reminderDate: newTime, reminderId: 42, noteId: 'note'),
    ];
    expect(
        await controller.reschedule(
            original, now.add(const Duration(hours: 1)), ReminderRepeat.none),
        ReminderAgendaActionResult.changed);
    expect(saves, 0);
    expect(controller.entries.single.dueDate, newTime);
  });

  test('failed reload keeps the previous agenda available with retry state',
      () async {
    await controller.refresh();
    final original = controller.entries.single;
    failLoad = true;
    await controller.refresh();
    expect(controller.loadFailed, isTrue);
    expect(controller.loading, isFalse);
    expect(controller.entries.single, same(original));
    failLoad = false;
    await controller.refresh();
    expect(controller.loadFailed, isFalse);
  });

  test('a busy agenda prevents a second mutation until the first finishes',
      () async {
    controller.dispose();
    final started = Completer<void>();
    final finish = Completer<bool>();
    controller = ReminderAgendaController(
      readReminders: () => reminders,
      readNotes: () async => [note!],
      readNote: (_) async => note,
      readPendingSnoozes: (_) async => {},
      snoozeReminder: (_, __) async {
        started.complete();
        return finish.future;
      },
      rescheduleReminder: (_, __, ___) async {
        saves++;
        return true;
      },
      now: () => now,
    );
    await controller.refresh();
    final entry = controller.entries.single;
    final first = controller.snooze(entry, const Duration(minutes: 10));
    await started.future;
    expect(controller.busyReminderId, 42);
    expect(
        await controller.reschedule(
            entry, now.add(const Duration(hours: 1)), ReminderRepeat.none),
        ReminderAgendaActionResult.busy);
    expect(saves, 0);
    finish.complete(true);
    expect(await first, ReminderAgendaActionResult.saved);
    expect(controller.busyReminderId, isNull);
  });
}
