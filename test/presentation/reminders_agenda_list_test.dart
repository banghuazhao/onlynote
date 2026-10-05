import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/reminders/reminders_agenda_list.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/reminder_agenda.dart';

final _now = DateTime(2026, 10, 6, 14);
final _entries = buildReminderAgenda(
  reminders: [
    Reminder(
        reminderDate: DateTime(2026, 10, 6, 9), reminderId: 1, noteId: 'past'),
    Reminder(
        reminderDate: DateTime(2026, 10, 6, 18),
        reminderId: 2,
        noteId: 'today'),
    Reminder(
        reminderDate: DateTime(2024, 1, 3, 9),
        reminderId: 3,
        noteId: 'future',
        repeat: ReminderRepeat.weekly),
  ],
  notes: [
    Note(id: 'past', title: 'Call the dentist'),
    Note(id: 'today', title: 'Buy groceries'),
    Note(id: 'future', title: 'Weekly planning'),
  ],
  now: _now,
);

Future<void> _pumpAgenda(WidgetTester tester,
    {List<ReminderAgendaEntry>? entries,
    int? busyReminderId,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(390, 844),
    ValueChanged<ReminderAgendaEntry>? onOpen,
    ValueChanged<ReminderAgendaEntry>? onSnooze,
    ValueChanged<ReminderAgendaEntry>? onReschedule}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true,
          textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: RemindersAgendaList(
        entries: entries ?? _entries,
        now: _now,
        busyReminderId: busyReminderId,
        onOpen: onOpen ?? (_) {},
        onSnooze: onSnooze ?? (_) {},
        onReschedule: onReschedule ?? (_) {},
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('grouped reminder rows open notes and expose distinct actions',
      (tester) async {
    final opened = <int>[];
    final snoozed = <int>[];
    final rescheduled = <int>[];
    await _pumpAgenda(tester,
        onOpen: (entry) => opened.add(entry.reminder.reminderId),
        onSnooze: (entry) => snoozed.add(entry.reminder.reminderId),
        onReschedule: (entry) => rescheduled.add(entry.reminder.reminderId));
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-reminder-1')));
    await tester.tap(find.byKey(const ValueKey('snooze-reminder-1')));
    await tester.tap(find.byKey(const ValueKey('reschedule-reminder-1')));
    expect(opened, [1]);
    expect(snoozed, [1]);
    expect(rescheduled, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('upcoming row shows next occurrence and reschedule',
      (tester) async {
    await _pumpAgenda(tester, entries: [_entries.last]);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Overdue'), findsNothing);
    expect(find.textContaining('Oct 7'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.byKey(const ValueKey('snooze-reminder-3')), findsNothing);
    expect(find.byKey(const ValueKey('reschedule-reminder-3')), findsOneWidget);
  });

  testWidgets('busy saving prevents duplicate row actions', (tester) async {
    final tapped = <int>[];
    await _pumpAgenda(tester,
        busyReminderId: 1,
        onOpen: (entry) => tapped.add(entry.reminder.reminderId),
        onSnooze: (entry) => tapped.add(entry.reminder.reminderId),
        onReschedule: (entry) => tapped.add(entry.reminder.reminderId));
    await tester.tap(find.byKey(const ValueKey('open-reminder-1')));
    await tester.tap(find.byKey(const ValueKey('snooze-reminder-1')));
    await tester.tap(find.byKey(const ValueKey('reschedule-reminder-2')));
    expect(tapped, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty agenda explains how to add reminders', (tester) async {
    await _pumpAgenda(tester, entries: []);
    expect(find.text('Nothing on your schedule'), findsOneWidget);
    expect(
        find.text('Add a reminder to a note to see it here.'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('narrow Chinese agenda stays usable with large text',
      (tester) async {
    final tapped = <int>[];
    await _pumpAgenda(tester,
        entries: [_entries.first],
        locale: const Locale('zh'),
        size: const Size(320, 640),
        textScale: 2,
        onReschedule: (entry) => tapped.add(entry.reminder.reminderId));
    expect(tester.takeException(), isNull);
    final action = find.byKey(const ValueKey('reschedule-reminder-1'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    expect(tapped, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snoozed repeat visibly retains repeat and snooze metadata',
      (tester) async {
    final reminder = Reminder(
        reminderDate: DateTime(2024, 1, 1, 18),
        reminderId: 1,
        noteId: 'repeat',
        repeat: ReminderRepeat.daily);
    await _pumpAgenda(tester, entries: [
      ReminderAgendaEntry(
        reminder: reminder,
        note: Note(id: 'repeat', title: 'Evening plan'),
        dueDate: _now.add(const Duration(minutes: 10)),
        snoozed: true,
      ),
    ]);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Snoozed'), findsOneWidget);
    expect(find.byKey(const ValueKey('snooze-reminder-1')), findsOneWidget);
  });
}
