import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/reminders/reminders_agenda_search.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/reminder_agenda.dart';

final _now = DateTime(2026, 10, 20, 14);

ReminderAgendaEntry _entry(int id,
    {String? title,
    String? description,
    List<Todo> todos = const [],
    List<String> tags = const [],
    List<VoiceMemo> voiceMemos = const [],
    DateTime? due}) {
  final date = due ?? _now;
  return ReminderAgendaEntry(
    reminder: Reminder(reminderId: id, noteId: '$id', reminderDate: date),
    note: Note(
        id: '$id',
        title: title,
        description: description,
        todo: todos,
        tags: tags,
        voiceMemos: voiceMemos),
    dueDate: date,
  );
}

VoiceMemo _memo(String? transcript) => VoiceMemo(
    id: 'private-recording-id',
    path: 'note_audio/private-recording-path.m4a',
    durationMs: 1000,
    createdAt: _now,
    transcript: transcript);

Future<void> _pumpAgenda(
  WidgetTester tester, {
  required List<ReminderAgendaEntry> entries,
  ValueChanged<ReminderAgendaEntry>? onOpen,
  ValueChanged<ReminderAgendaEntry>? onSnooze,
  ValueChanged<ReminderAgendaEntry>? onReschedule,
  Future<void> Function()? onRefresh,
  bool loading = false,
  bool narrow = false,
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize =
      narrow ? const Size(320, 640) : const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: narrow ? const Locale('zh', 'HK') : const Locale('en'),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(narrow ? 2 : 1),
        viewInsets: EdgeInsets.only(bottom: narrow ? 220 : 0),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: SearchableRemindersAgenda(
        entries: entries,
        now: _now,
        loading: loading,
        onOpen: onOpen ?? (_) {},
        onSnooze: onSnooze ?? (_) {},
        onReschedule: onReschedule ?? (_) {},
        onRefresh: onRefresh,
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  test('agenda search matches title, body and visible checklist fallback', () {
    final entries = [
      _entry(1, title: 'Dentist appointment'),
      _entry(2, title: 'Errands', description: 'Call the DENTIST'),
      _entry(3, todos: [Todo(id: 'todo', title: 'Book dentist')]),
      _entry(4, title: 'Other'),
      _entry(5),
    ];
    expect(filterReminderAgenda(entries, '  dentist  '), entries.take(3));
    expect(filterReminderAgenda(entries, ''), entries);
    expect(filterReminderAgenda(entries, '  \t '), entries);
  });

  test('agenda search treats punctuation literally and supports Unicode', () {
    final entries = [
      _entry(1, title: 'C++ [2026]'),
      _entry(2, description: '閱讀茶😀'),
      _entry(3, title: 'Plain schedule'),
    ];
    expect(filterReminderAgenda(entries, 'c++ [2026]'), [entries.first]);
    expect(filterReminderAgenda(entries, '['), [entries.first]);
    expect(filterReminderAgenda(entries, '茶😀'), [entries[1]]);
    expect(filterReminderAgenda(entries, '.*'), isEmpty);
    expect(filterReminderAgenda(entries, 'no match'), isEmpty);
    expect(entries.length, 3);
  });

  test('agenda search matches tags and transcripts without duplicating entries',
      () {
    final entries = [
      _entry(1, title: 'Errands', tags: ['Dentist']),
      _entry(2,
          title: 'Appointments',
          description: 'Bring paperwork',
          voiceMemos: [_memo('Call the DENTIST')]),
      _entry(3,
          title: 'Dentist',
          description: 'dentist',
          todos: [Todo(id: 'todo', title: 'dentist')],
          tags: ['dentist', 'DENTIST'],
          voiceMemos: [_memo('dentist'), _memo('Another dentist')]),
      _entry(4, voiceMemos: [_memo(null), _memo(''), _memo('  ')]),
    ];
    final matches = filterReminderAgenda(entries, '  dEnTiSt  ');
    expect(matches, entries.take(3));
    for (var i = 0; i < matches.length; i++) {
      expect(matches[i], same(entries[i]));
    }
    expect(filterReminderAgenda(entries, '\t  '), same(entries));
  });

  test('metadata search supports literal punctuation and Unicode', () {
    final entries = [
      _entry(1, title: 'Errands', tags: ['C++ [2026]', '閱讀茶😀']),
      _entry(2,
          title: 'Appointments',
          voiceMemos: [_memo('Review C++ [2026] and 閱讀茶😀')]),
    ];
    for (final query in [' c++ [2026] ', '[', '茶😀']) {
      expect(filterReminderAgenda(entries, query), entries);
    }
    expect(filterReminderAgenda(entries, '.*'), isEmpty);
  });

  test('recording paths and IDs are not searchable content', () {
    final entry = _entry(7654321,
        title: 'Errands', voiceMemos: [_memo(null), _memo(''), _memo('  ')]);
    for (final query in [
      '7654321',
      'private-recording-id',
      'private-recording-path',
      'note_audio',
      '.m4a',
    ]) {
      expect(filterReminderAgenda([entry], query), isEmpty);
    }
  });

  testWidgets('search preserves agenda grouping, order, and matching actions',
      (tester) async {
    final entries = [
      _entry(1,
          title: 'Phone call',
          tags: ['Dentist'],
          due: _now.subtract(const Duration(hours: 2))),
      _entry(2, title: 'Other errands'),
      _entry(3,
          title: 'Appointments',
          voiceMemos: [_memo('Book dentist')],
          due: _now.add(const Duration(hours: 2))),
      _entry(4,
          title: 'Checkup',
          tags: ['Dentist'],
          voiceMemos: [_memo('Confirm dentist')],
          due: _now.add(const Duration(days: 1))),
    ];
    final opened = <int>[];
    final snoozed = <int>[];
    final rescheduled = <int>[];
    await _pumpAgenda(tester,
        entries: entries,
        onOpen: (entry) => opened.add(entry.reminder.reminderId),
        onSnooze: (entry) => snoozed.add(entry.reminder.reminderId),
        onReschedule: (entry) => rescheduled.add(entry.reminder.reminderId));
    await tester.enterText(
        find.byKey(const ValueKey('reminders-search')), 'dentist');
    await tester.pump();
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Other errands'), findsNothing);
    expect(find.text('1'), findsNWidgets(3));
    await tester.tap(find.byKey(const ValueKey('open-reminder-1')));
    await tester.tap(find.byKey(const ValueKey('snooze-reminder-1')));
    await tester.tap(find.byKey(const ValueKey('reschedule-reminder-3')));
    expect(opened, [1]);
    expect(snoozed, [1]);
    expect(rescheduled, [3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no matches remains refreshable and clear recovers all notes',
      (tester) async {
    var refreshes = 0;
    final entries = [
      _entry(1, title: 'Phone call', tags: ['Dentist'])
    ];
    await _pumpAgenda(tester,
        entries: entries, onRefresh: () async => refreshes++);
    await tester.enterText(
        find.byKey(const ValueKey('reminders-search')), 'not found');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text(S.current.Reminders_Search_Empty_Title), findsOneWidget);
    expect(find.text(S.current.Reminders_Empty_Title), findsNothing);
    await tester.drag(
        find.byKey(const Key('reminders-agenda-list')), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('reminders-search')))
            .controller!
            .text,
        'not found');
    await tester
        .tap(find.byKey(const ValueKey('reminders-empty-clear-search')));
    await tester.pump();
    expect(find.text('Phone call'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminders-search-empty')), findsNothing);
    expect(find.byKey(const ValueKey('reminders-clear-search')), findsNothing);
  });

  testWidgets('query stays through loading, new data, and an empty schedule',
      (tester) async {
    await _pumpAgenda(tester, entries: [
      _entry(1, title: 'Phone call', tags: ['Dentist'])
    ]);
    await tester.enterText(
        find.byKey(const ValueKey('reminders-search')), 'dentist');
    await tester.pump();
    await _pumpAgenda(tester, entries: [], loading: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('reminders-search')))
            .controller!
            .text,
        'dentist');
    await _pumpAgenda(tester, entries: [
      _entry(2,
          title: 'New appointment', voiceMemos: [_memo('Call the dentist')]),
      _entry(3, title: 'Unrelated'),
    ]);
    expect(find.text('New appointment'), findsOneWidget);
    expect(find.text('Unrelated'), findsNothing);
    await _pumpAgenda(tester, entries: []);
    expect(find.text(S.current.Reminders_Search_Empty_Title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminders-clear-search')));
    await tester.pump();
    expect(find.text(S.current.Reminders_Empty_Title), findsOneWidget);
  });

  testWidgets('narrow large-text search stays scrollable above the keyboard',
      (tester) async {
    await _pumpAgenda(tester,
        entries: [_entry(1, title: '閱讀茶😀')], narrow: true, dark: true);
    await tester.enterText(
        find.byKey(const ValueKey('reminders-search')), 'unknown');
    await tester.pump();
    expect(tester.takeException(), isNull);
    final clear = find.byKey(const ValueKey('reminders-empty-clear-search'));
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    expect(clear.hitTestable(), findsOneWidget);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('閱讀茶😀'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
