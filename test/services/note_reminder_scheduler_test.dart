import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_reminder_scheduler.dart';
import 'package:onlynote/services/reminder_snooze.dart';

import '../support/memory_preferences.dart';

class _Notifications extends NotificationService {
  _Notifications()
      : super(
            snoozeRegistry:
                ReminderSnoozeRegistry(preferences: MemoryPreferences()));
  bool permission = true;
  bool schedulingWorks = true;
  int schedules = 0;
  int replacements = 0;
  final removed = <int>[];

  @override
  Future<bool?> checkAndAskForPermission(BuildContext context) async =>
      permission;
  @override
  Future<bool> scheduleNotifications(
      {required int id,
      required String title,
      required String body,
      required DateTime time,
      required String noteId,
      ReminderRepeat repeat = ReminderRepeat.none}) async {
    schedules++;
    return schedulingWorks;
  }

  @override
  Future<void> removeNotification(Reminder reminder) async =>
      removed.add(reminder.reminderId);
  @override
  Future<bool> rescheduleReminder(Reminder original, Reminder updated,
      {required String title,
      required String body,
      required Future<void> Function() persist}) async {
    replacements++;
    if (!schedulingWorks) return false;
    try {
      await persist();
      return true;
    } catch (_) {
      return false;
    }
  }
}

void main() {
  final now = DateTime(2026, 10, 6, 14);
  final date = DateTime(2026, 10, 7, 9);
  final note = Note(id: 'note', title: 'Call tomorrow at 9am');
  late BuildContext context;
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: Builder(builder: (value) {
        context = value;
        return const Scaffold();
      }),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('new reminder removes native schedule when metadata fails',
      (tester) async {
    await mount(tester);
    final notifications = _Notifications();
    final scheduler = NoteReminderScheduler(
      notifications: notifications,
      now: () => now,
      readCurrent: (_) => null,
      readReminders: () => [],
      addReminder: (_) async => throw StateError('Disk full'),
    );
    expect(await scheduler.save(context, note, date, ReminderRepeat.none),
        NoteReminderSaveResult.failed);
    expect(notifications.schedules, 1);
    expect(notifications.removed, hasLength(1));
  });

  testWidgets('existing reminder uses rollback-aware rescheduling',
      (tester) async {
    await mount(tester);
    final notifications = _Notifications();
    final original = Reminder(
        noteId: 'note',
        reminderId: 7,
        reminderDate: date.add(const Duration(days: 1)));
    var stored = original;
    final scheduler = NoteReminderScheduler(
      notifications: notifications,
      now: () => now,
      readCurrent: (_) => stored,
      readReminders: () => [stored],
      modifyReminder: (before, after) async {
        expect(before, same(original));
        throw StateError('Disk full');
      },
    );
    expect(await scheduler.save(context, note, date, ReminderRepeat.none),
        NoteReminderSaveResult.failed);
    expect(notifications.replacements, 1);
    expect(notifications.schedules, 0);
    expect(stored, same(original));
  });

  testWidgets('permission denial cannot add or replace a reminder',
      (tester) async {
    await mount(tester);
    final notifications = _Notifications()..permission = false;
    var persisted = 0;
    final scheduler = NoteReminderScheduler(
      notifications: notifications,
      now: () => now,
      readCurrent: (_) => null,
      readReminders: () => [],
      addReminder: (_) async => persisted++,
    );
    expect(await scheduler.save(context, note, date, ReminderRepeat.none),
        NoteReminderSaveResult.denied);
    expect(persisted, 0);
    expect(notifications.schedules + notifications.replacements, 0);
  });

  testWidgets('native scheduling failure leaves metadata untouched',
      (tester) async {
    await mount(tester);
    final notifications = _Notifications()..schedulingWorks = false;
    var persisted = 0;
    final scheduler = NoteReminderScheduler(
      notifications: notifications,
      now: () => now,
      readCurrent: (_) => null,
      readReminders: () => [],
      addReminder: (_) async => persisted++,
    );
    expect(await scheduler.save(context, note, date, ReminderRepeat.none),
        NoteReminderSaveResult.failed);
    expect(persisted, 0);
  });
}
