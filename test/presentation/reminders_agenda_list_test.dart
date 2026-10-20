import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
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
    bool dark = false,
    String searchQuery = '',
    Size size = const Size(390, 844),
    ValueChanged<ReminderAgendaEntry>? onOpen,
    ValueChanged<ReminderAgendaEntry>? onSnooze,
    ValueChanged<ReminderAgendaEntry>? onReschedule}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
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
        searchQuery: searchQuery,
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
  testWidgets('matching snippets show the field behind unrelated note text',
      (tester) async {
    final entry = ReminderAgendaEntry(
      reminder: _entries.first.reminder,
      dueDate: _entries.first.dueDate,
      note: Note(
          id: 'past',
          title: 'Routine',
          description: 'Unrelated body',
          todo: [
            Todo(id: 'todo', title: 'Collect C++ [2026] notes')
          ],
          tags: [
            'priority'
          ],
          voiceMemos: [
            VoiceMemo(
                id: 'memo',
                path: 'note_audio/unavailable.m4a',
                durationMs: 1000,
                createdAt: _now,
                transcript: 'Discuss 閱讀茶😀 tomorrow'),
          ]),
    );
    final snippet = find.byKey(const ValueKey('reminder-search-snippet-1'));
    for (final (query, expected) in [
      ('UNRELATED', 'Unrelated body'),
      (' c++ [2026] ', '…C++ [2026] notes'),
      ('茶😀', '…茶😀 tomorrow'),
      ('PRIORITY', 'priority'),
    ]) {
      await _pumpAgenda(tester, entries: [entry], searchQuery: query);
      expect(find.text('Routine'), findsOneWidget);
      final text = tester.widget<Text>(snippet);
      expect(text.data, expected);
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    }
    for (final query in ['Routine', '.*', 'missing', '', '  \t ']) {
      await _pumpAgenda(tester, entries: [entry], searchQuery: query);
      expect(find.text('Routine'), findsOneWidget);
      expect(snippet, findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('body and checklist title fallbacks avoid duplicate snippet text',
      (tester) async {
    for (final note in [
      Note(id: 'past', description: 'Call dentist'),
      Note(id: 'past', todo: [Todo(id: 'todo', title: 'Call dentist')]),
    ]) {
      await _pumpAgenda(tester,
          entries: [
            ReminderAgendaEntry(
              reminder: _entries.first.reminder,
              dueDate: _entries.first.dueDate,
              note: note,
            ),
          ],
          searchQuery: 'Call');
      expect(find.text('Call dentist'), findsOneWidget);
      expect(find.byKey(const ValueKey('reminder-search-snippet-1')),
          findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'narrow large-text snippets keep actions usable in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
      final entry = ReminderAgendaEntry(
        reminder: _entries.first.reminder,
        dueDate: _entries.first.dueDate,
        note: Note(
          id: 'past',
          title: '閱讀清單與研究計畫',
          description: '記得帶閱讀茶😀的研究筆記與投影設備，準備明天的討論會議。',
        ),
      );
      final opened = <ReminderAgendaEntry>[];
      final snoozed = <ReminderAgendaEntry>[];
      final rescheduled = <ReminderAgendaEntry>[];
      await _pumpAgenda(tester,
          entries: [entry],
          locale: const Locale('zh', 'HK'),
          size: const Size(320, 640),
          textScale: 2,
          dark: dark,
          searchQuery: '茶😀',
          onOpen: opened.add,
          onSnooze: snoozed.add,
          onReschedule: rescheduled.add);
      final snippet = find.byKey(const ValueKey('reminder-search-snippet-1'));
      expect(snippet, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('open-reminder-1')));
      for (final action in ['snooze', 'reschedule']) {
        final button = find.byKey(ValueKey('$action-reminder-1'));
        await tester.ensureVisible(button);
        await tester.tap(button);
      }
      expect(opened.single, same(entry));
      expect(snoozed.single, same(entry));
      expect(rescheduled.single, same(entry));
      expect(tester.takeException(), isNull);
    });
  }

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
