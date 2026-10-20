import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
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
  for (final withSearch in [false, true]) {
    testWidgets(
        'agenda snooze sheet sends delay and refreshes${withSearch ? ' while searching' : ''}',
        (tester) async {
      final now = DateTime(2026, 10, 6, 14);
      var reminders = [
        Reminder(
            reminderDate: now.subtract(const Duration(hours: 1)),
            reminderId: 42,
            noteId: 'note'),
      ];
      final note = Note(id: 'note', title: 'Phone call', tags: ['Dentist']);
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
      if (withSearch) {
        await tester.enterText(
            find.byKey(const ValueKey('reminders-search')), '  DENTIST  ');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
      }
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
      expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('reminders-search')))
              .controller!
              .text,
          withSearch ? '  DENTIST  ' : '');
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'failed agenda reschedule keeps reminder${withSearch ? ' while searching' : ''}',
        (tester) async {
      final now = DateTime(2026, 10, 6, 14);
      final original =
          Reminder(reminderDate: now, reminderId: 42, noteId: 'note');
      final note = Note(id: 'note', title: 'Errands', voiceMemos: [
        VoiceMemo(
            id: 'errands',
            path: 'note_audio/errands.m4a',
            durationMs: 1000,
            createdAt: now,
            transcript: 'Buy groceries'),
      ]);
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
      if (withSearch) {
        await tester.enterText(
            find.byKey(const ValueKey('reminders-search')), 'groceries');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
      }
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
      expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('reminders-search')))
              .controller!
              .text,
          withSearch ? 'groceries' : '');
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('refresh failure and retry retain the current reminder search',
      (tester) async {
    final now = DateTime(2026, 10, 20, 14);
    final reminder =
        Reminder(reminderDate: now, reminderId: 42, noteId: 'note');
    var note = Note(id: 'note', title: 'Errands', tags: ['Dentist']);
    var fail = false;
    final controller = ReminderAgendaController(
      readReminders: () => [reminder],
      readNotes: () async {
        if (fail) throw StateError('Read failed');
        return [note];
      },
      readNote: (_) async => note,
      readPendingSnoozes: (_) async => {},
      now: () => now,
      snoozeReminder: (_, __) async => false,
      rescheduleReminder: (_, __, ___) async => false,
    );
    addTearDown(controller.dispose);
    await _pumpScreen(tester, controller);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('reminders-search')), 'dentist');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    fail = true;
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(find.text(S.current.Reminders_Load_Failed), findsOneWidget);
    expect(find.text('Errands'), findsOneWidget);
    fail = false;
    note = Note(id: 'note', title: 'New appointment', voiceMemos: [
      VoiceMemo(
          id: 'appointment',
          path: 'note_audio/appointment.m4a',
          durationMs: 1000,
          createdAt: now,
          transcript: 'Call the dentist'),
    ]);
    await tester.tap(find.text(S.current.Retry));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Reminders_Load_Failed), findsNothing);
    expect(find.text('New appointment'), findsOneWidget);
    expect(find.text(S.current.Reminders_Search_Empty_Title), findsNothing);
    note = Note(id: 'note', title: 'Other task');
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Other task'), findsNothing);
    expect(find.text(S.current.Reminders_Search_Empty_Title), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('reminders-search')))
            .controller!
            .text,
        'dentist');
    await tester.tap(find.byKey(const ValueKey('reminders-clear-search')));
    await tester.pump();
    expect(find.text('Other task'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
