import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/reminders/reminders_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/reminder_agenda_controller.dart';

Future<void> _pumpScreen(
        WidgetTester tester, ReminderAgendaController controller) async =>
    tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RemindersScreen(controller: controller),
    ));

void main() {
  testWidgets('agenda snooze sheet sends selected delay and refreshes due time',
      (tester) async {
    final now = DateTime(2026, 10, 6, 14);
    var reminders = [
      Reminder(
          reminderDate: now.subtract(const Duration(hours: 1)),
          reminderId: 42,
          noteId: 'note'),
    ];
    final note = Note(id: 'note', title: 'Call the dentist');
    Duration? selected;
    final controller = ReminderAgendaController(
      readReminders: () => reminders,
      readNotes: () async => [note],
      readNote: (_) async => note,
      readPendingSnoozes: (_) async => {},
      now: () => now,
      snoozeReminder: (entry, delay) async {
        selected = delay;
        reminders = [
          Reminder(
              reminderDate: now.add(delay),
              reminderId: entry.reminder.reminderId,
              noteId: entry.reminder.noteId),
        ];
        return true;
      },
      rescheduleReminder: (_, __, ___) async => false,
    );
    addTearDown(controller.dispose);
    await _pumpScreen(tester, controller);
    await tester.pumpAndSettle();
    expect(find.text('Overdue'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('snooze-reminder-42')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Reminder_Snooze_10_Minutes));
    await tester.pumpAndSettle();
    expect(selected, const Duration(minutes: 10));
    expect(controller.entries.single.dueDate,
        now.add(const Duration(minutes: 10)));
    expect(find.text('Overdue'), findsNothing);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Snoozed'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'failed agenda reschedule keeps original reminder and shows error',
      (tester) async {
    final now = DateTime(2026, 10, 6, 14);
    final original =
        Reminder(reminderDate: now, reminderId: 42, noteId: 'note');
    final note = Note(id: 'note', title: 'Buy groceries');
    DateTime? attemptedDate;
    final controller = ReminderAgendaController(
      readReminders: () => [original],
      readNotes: () async => [note],
      readNote: (_) async => note,
      readPendingSnoozes: (_) async => {},
      now: () => now,
      snoozeReminder: (_, __) async => false,
      rescheduleReminder: (_, date, repeat) async {
        attemptedDate = date;
        expect(repeat, ReminderRepeat.none);
        return false;
      },
    );
    addTearDown(controller.dispose);
    await _pumpScreen(tester, controller);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reschedule-reminder-42')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Delete), findsNothing);
    await tester.tap(find.text(S.current.Reminder_In_One_Hour));
    await tester.pumpAndSettle();
    expect(attemptedDate, isNotNull);
    expect(controller.entries.single.reminder, same(original));
    expect(controller.entries.single.dueDate, now);
    expect(controller.busyReminderId, isNull);
    expect(find.text(S.current.Reminder_Save_Failed), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
