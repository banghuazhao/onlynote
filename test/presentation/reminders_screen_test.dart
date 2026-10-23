import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/reminder_picker_sheet.dart';
import 'package:onlynote/presentation/screens/reminders/reminders_screen.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/reminder_agenda_controller.dart';

Future<void> _pumpScreen(
        WidgetTester tester, ReminderAgendaController controller,
        {NavigatorObserver? observer}) async =>
    tester.pumpWidget(MaterialApp(
      navigatorObservers: [if (observer != null) observer],
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RemindersScreen(controller: controller),
    ));

class _AgendaObserver extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
    super.didPop(route, previousRoute);
  }
}

class _AgendaRouter extends RootStackRouter {
  _AgendaRouter(this.controller);
  final ReminderAgendaController controller;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo('TestAgendaRoute',
                builder: (_) => RemindersScreen(controller: controller))),
        AutoRoute(
            page: PageInfo(NoteDetailRoute.name,
                builder: (data) => Scaffold(
                    body: Text(
                        'Reading ${data.argsAs<NoteDetailRouteArgs>().noteId}')))),
      ];
}

void main() {
  for (final action in ['snooze', 'reschedule']) {
    testWidgets(
        'agenda $action ignores covered, duplicate and disposed callbacks',
        (tester) async {
      final now = DateTime(2026, 10, 20, 14);
      final note = Note(id: 'note', title: 'Appointment');
      var writes = 0;
      final controller = ReminderAgendaController(
        readReminders: () =>
            [Reminder(reminderDate: now, reminderId: 42, noteId: 'note')],
        readNotes: () async => [note],
        readNote: (_) async => note,
        readPendingSnoozes: (_) async => {},
        now: () => now,
        snoozeReminder: (_, __) async {
          writes++;
          return true;
        },
        rescheduleReminder: (_, __, ___) async {
          writes++;
          return true;
        },
      );
      addTearDown(controller.dispose);
      await _pumpScreen(tester, controller);
      await tester.pumpAndSettle();
      final callback = tester
          .widget<TextButton>(find.byKey(ValueKey('$action-reminder-42')))
          .onPressed!;
      unawaited(showDialog<void>(
        context: tester.element(find.byType(RemindersScreen)),
        builder: (_) => const AlertDialog(title: Text('Another action')),
      ));
      await tester.pumpAndSettle();
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(find.text('Another action'), findsOneWidget);
      expect(find.byType(AppSheet), findsNothing);
      expect(writes, 0);
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pumpAndSettle();
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(find.byType(AppSheet), findsOneWidget);
      expect(find.byType(ReminderPickerSheet),
          action == 'reschedule' ? findsOneWidget : findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      callback();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final covered in [false, true]) {
    testWidgets(
        'snooze choice rejects repeated and covered callbacks: $covered',
        (tester) async {
      final now = DateTime(2026, 10, 20, 14);
      final note = Note(id: 'note', title: 'Appointment');
      final selected = <Duration>[];
      final observer = _AgendaObserver();
      final controller = ReminderAgendaController(
        readReminders: () =>
            [Reminder(reminderDate: now, reminderId: 42, noteId: 'note')],
        readNotes: () async => [note],
        readNote: (_) async => note,
        readPendingSnoozes: (_) async => {},
        now: () => now,
        snoozeReminder: (_, delay) async {
          selected.add(delay);
          return true;
        },
        rescheduleReminder: (_, __, ___) async => false,
      );
      addTearDown(controller.dispose);
      await _pumpScreen(tester, controller, observer: observer);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('snooze-reminder-42')));
      await tester.pumpAndSettle();
      final choose = tester
          .widget<ListTile>(find.widgetWithText(
              ListTile, S.current.Reminder_Snooze_10_Minutes))
          .onTap!;
      if (covered) {
        unawaited(showDialog<void>(
          context: tester.element(find.byType(AppSheet)),
          builder: (_) => const AlertDialog(title: Text('Another action')),
        ));
        await tester.pumpAndSettle();
        choose();
        await tester.pumpAndSettle();
        expect(find.text('Another action'), findsOneWidget);
        expect(selected, isEmpty);
        expect(observer.pops, 0);
        Navigator.of(tester.element(find.byType(AlertDialog))).pop();
        await tester.pumpAndSettle();
      }
      choose();
      choose();
      await tester.pumpAndSettle();
      choose();
      expect(selected, [const Duration(minutes: 10)]);
      expect(observer.pops, covered ? 2 : 1);
      expect(find.byType(RemindersScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('late snooze error does not show feedback on a covering route',
      (tester) async {
    final now = DateTime(2026, 10, 20, 14);
    final note = Note(id: 'note', title: 'Appointment');
    final pending = Completer<bool>();
    final controller = ReminderAgendaController(
      readReminders: () =>
          [Reminder(reminderDate: now, reminderId: 42, noteId: 'note')],
      readNotes: () async => [note],
      readNote: (_) async => note,
      readPendingSnoozes: (_) async => {},
      now: () => now,
      snoozeReminder: (_, __) => pending.future,
      rescheduleReminder: (_, __, ___) async => false,
    );
    addTearDown(controller.dispose);
    await _pumpScreen(tester, controller);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('snooze-reminder-42')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Reminder_Snooze_10_Minutes));
    await tester.pump(const Duration(milliseconds: 400));
    unawaited(showDialog<void>(
      context: tester.element(find.byType(RemindersScreen)),
      builder: (_) => const AlertDialog(title: Text('Another action')),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Another action'), findsOneWidget);
    expect(find.text(S.current.Reminders_Snooze_Failed), findsNothing);
    expect(controller.busyReminderId, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final covered in [false, true]) {
    testWidgets(
        'slow note lookup ${covered ? 'cannot navigate under another sheet' : 'opens one reader after repeated taps'}',
        (tester) async {
      final now = DateTime(2026, 10, 20, 14);
      final note = Note(id: 'note', title: 'Appointments');
      final lookup = Completer<Note?>();
      var reads = 0;
      final controller = ReminderAgendaController(
        readReminders: () =>
            [Reminder(reminderDate: now, reminderId: 42, noteId: 'note')],
        readNotes: () async => [note],
        readNote: (_) {
          reads++;
          return lookup.future;
        },
        readPendingSnoozes: (_) async => {},
        now: () => now,
        snoozeReminder: (_, __) async => false,
        rescheduleReminder: (_, __, ___) async => false,
      );
      final router = _AgendaRouter(controller);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        controller.dispose();
      });
      await tester.pumpWidget(MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router.config(),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ));
      await tester.pumpAndSettle();
      final open = tester
          .widget<InkWell>(find.byKey(const ValueKey('open-reminder-42')))
          .onTap!;
      open();
      open();
      expect(reads, 1);
      if (covered) {
        unawaited(showDialog<void>(
            context: tester.element(find.byType(RemindersScreen)),
            builder: (_) => const AlertDialog(title: Text('Another action'))));
        await tester.pumpAndSettle();
      }
      lookup.complete(note);
      await tester.pumpAndSettle();
      if (covered) {
        expect(find.text('Another action'), findsOneWidget);
        expect(find.text('Reading note'), findsNothing);
        expect(
            router.stack.where((route) => route.name == NoteDetailRoute.name),
            isEmpty);
        Navigator.of(tester.element(find.byType(AlertDialog))).pop();
        await tester.pumpAndSettle();
        open();
        await tester.pumpAndSettle();
      }
      expect(find.text('Reading note'), findsOneWidget);
      expect(router.stack.where((route) => route.name == NoteDetailRoute.name),
          hasLength(1));
      await router.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(RemindersScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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
