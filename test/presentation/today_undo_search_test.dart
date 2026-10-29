import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/today/today_agenda_content.dart';
import 'package:onlynote/presentation/screens/today/today_screen.dart';
import 'package:onlynote/presentation/screens/today/today_previews.dart';
import 'package:onlynote/services/today_agenda.dart';

import '../support/interaction_feedback_capture.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(390, 844),
    double scale = 1,
    bool dark = false,
    bool accessibleNavigation = false,
    Locale locale = const Locale('en')}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: interactionFeedbackTheme(dark: dark),
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            accessibleNavigation: accessibleNavigation),
        child: child!),
    home: RepaintBoundary(key: interactionFeedbackCaptureKey, child: child),
  ));
  await tester.pumpAndSettle();
}

Future<void> _showTaskSearch(WidgetTester tester) async {
  await tester.scrollUntilVisible(
      find.byKey(const ValueKey('today-task-search')), 250,
      scrollable:
          find.byKey(const ValueKey('today-agenda-list')).evaluate().isEmpty
              ? find.byType(Scrollable).first
              : find
                  .descendant(
                      of: find.byKey(const ValueKey('today-agenda-list')),
                      matching: find.byType(Scrollable))
                  .first);
}

void main() {
  setUpAll(loadInteractionFeedbackFonts);
  final now = DateTime(2026, 10, 29, 10);

  testWidgets(
      'task search matches title and source and leaves calendar sections intact',
      (tester) async {
    final notes = [
      Note(id: 'daily', title: 'Daily journal', dailyNoteDateKey: '2026-10-29'),
      Note(id: 'work', title: 'Website project', todo: [
        Todo(id: 'draft', title: 'Write first draft'),
        Todo(id: 'photos', title: 'Choose photos')
      ]),
      Note(
          id: 'home',
          title: 'House',
          todo: [Todo(id: 'plants', title: 'Water plants')]),
    ];
    final opened = <String>[];
    await _pump(
        tester,
        Scaffold(
            body: TodayAgendaContent(
          agenda: buildTodayAgenda(
              notes: notes,
              reminders: [
                Reminder(
                    noteId: 'home',
                    reminderId: 1,
                    reminderDate: DateTime(2026, 10, 29, 18))
              ],
              now: now),
          now: now,
          onOpenDailyNote: () {},
          onOpenNote: opened.add,
          onOpenReminders: () {},
          onCompleteTask: (_) {},
        )));
    await _showTaskSearch(tester);
    await tester.enterText(
        find.byKey(const ValueKey('today-task-search')), ' project draft ');
    await tester.pumpAndSettle();
    expect(find.text('1 of 3 unfinished tasks'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Write first draft'), 120,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Choose photos'), findsNothing);
    expect(find.text('Water plants'), findsNothing);
    await tester.tap(find.text('Write first draft'));
    expect(opened, ['work']);
    await tester.drag(
        find.byKey(const ValueKey('today-agenda-list')), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text('Daily journal'), findsOneWidget);
    expect(find.text('Due reminders · 1'), findsOneWidget);
    await _showTaskSearch(tester);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('today-task-search')))
            .controller!
            .text,
        ' project draft ');
    await tester.enterText(
        find.byKey(const ValueKey('today-task-search')), 'missing');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('No matching unfinished tasks.'), 100,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('0 of 3 unfinished tasks'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('today-task-search-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-task-search-count')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'captured search clear cannot act under another route or after disposal',
      (tester) async {
    await _pump(
        tester,
        Scaffold(
            body: TodayAgendaContent(
          agenda: const TodayAgenda(),
          now: now,
          initialTaskQuery: 'draft',
          onOpenDailyNote: () {},
          onOpenNote: (_) {},
          onOpenReminders: () {},
          onCompleteTask: (_) {},
        )));
    await _showTaskSearch(tester);
    final clear = tester
        .widget<IconButton>(
            find.byKey(const ValueKey('today-task-search-clear')))
        .onPressed!;
    final context = tester.element(find.byType(TodayAgendaContent));
    unawaited(showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Covered'))));
    await tester.pumpAndSettle();
    clear();
    await tester.pump();
    Navigator.pop(tester.element(find.byType(AlertDialog)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('today-task-search')))
            .controller!
            .text,
        'draft');
    await tester.pumpWidget(const SizedBox.shrink());
    clear();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Undo preserves new writing and rejects repeat, covered and expired actions',
      (tester) async {
    var note = Note(
        id: 'note',
        title: 'Project',
        description: 'Earlier',
        todo: [Todo(id: 'task', title: 'Write draft')]);
    var writes = 0;
    final controller = TodayAgendaController(
        readNotes: () async => [note],
        readNote: (_) async => note,
        readReminders: () => [],
        readPendingSnoozes: (_) async => {},
        saveNote: (value) async {
          writes++;
          note = value;
        },
        now: () => now);
    addTearDown(controller.dispose);
    await _pump(tester, TodayScreen(controller: controller));
    await tester.scrollUntilVisible(find.text('Write draft'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final undo = tester
        .widget<SnackBarAction>(
            find.byKey(const ValueKey('today-task-undo-action')))
        .onPressed;
    note =
        note.copyWith(description: 'Written after completing', tags: ['new']);
    unawaited(showDialog<void>(
        context: tester.element(find.byType(TodayScreen)),
        builder: (_) => const AlertDialog(title: Text('Covered'))));
    await tester.pumpAndSettle();
    undo();
    await tester.pump();
    expect(writes, 1);
    Navigator.pop(tester.element(find.byType(AlertDialog)));
    await tester.pumpAndSettle();
    undo();
    undo();
    await tester.pumpAndSettle();
    expect(writes, 2);
    expect(note.description, 'Written after completing');
    expect(note.tags, ['new']);
    expect(note.todo.single.completed, isFalse);
    undo();
    await tester.pump();
    expect(writes, 2);
    await tester.scrollUntilVisible(find.text('Write draft'), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final expired = tester
        .widget<SnackBarAction>(
            find.byKey(const ValueKey('today-task-undo-action')))
        .onPressed;
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expired();
    await tester.pump();
    expect(writes, 3);
    expect(note.todo.single.completed, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expired();
    await tester.pump();
    expect(writes, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed Undo offers a retry using current storage',
      (tester) async {
    var note = Note(
        id: 'note',
        title: 'Project',
        todo: [Todo(id: 'task', title: 'Write draft')]);
    var failed = false;
    final controller = TodayAgendaController(
        readNotes: () async => [note],
        readNote: (_) async => note,
        readReminders: () => [],
        readPendingSnoozes: (_) async => {},
        saveNote: (value) async {
          if (failed) throw StateError('Storage failed');
          note = value;
        },
        now: () => now);
    addTearDown(controller.dispose);
    await _pump(tester, TodayScreen(controller: controller));
    await tester.scrollUntilVisible(find.text('Write draft'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    failed = true;
    await tester.tap(find.byKey(const ValueKey('today-task-undo-action')));
    await tester.pumpAndSettle();
    expect(find.text('Could not undo task completion. Try again.'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(note.todo.single.completed, isTrue);
    note = note.copyWith(description: 'Latest content');
    failed = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(note.todo.single.completed, isFalse);
    expect(note.description, 'Latest content');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [false, true]) {
    testWidgets(
        'search remains usable at narrow width and large Chinese text dark=$dark',
        (tester) async {
      await _pump(
          tester,
          Scaffold(
              body: TodayAgendaContent(
            agenda: buildTodayAgenda(notes: [
              Note(
                  id: 'note',
                  title: '项目',
                  todo: [Todo(id: 'task', title: '整理周末计划')])
            ], reminders: [], now: now),
            now: now,
            initialTaskQuery: '周末',
            onOpenDailyNote: () {},
            onOpenNote: (_) {},
            onOpenReminders: () {},
            onCompleteTask: (_) {},
          )),
          size: const Size(320, 390),
          scale: 2.4,
          dark: dark,
          locale: const Locale('zh', 'HK'));
      await _showTaskSearch(tester);
      expect(find.byKey(const ValueKey('today-task-search-count')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('today-task-search-clear')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('live reminder refresh keeps the focused search field and query',
      (tester) async {
    final note = Note(
        id: 'note',
        title: 'Project',
        todo: [Todo(id: 'task', title: 'Write draft')]);
    var showReminder = false;
    var failed = false;
    var loading = false;
    late StateSetter update;
    await _pump(tester,
        Scaffold(body: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return TodayAgendaContent(
          agenda: buildTodayAgenda(
              notes: [note],
              reminders: showReminder
                  ? [
                      Reminder(
                          noteId: 'note',
                          reminderId: 1,
                          reminderDate: DateTime(2026, 10, 29, 18))
                    ]
                  : [],
              now: now),
          now: now,
          loading: loading,
          loadFailed: failed,
          onOpenDailyNote: () {},
          onOpenNote: (_) {},
          onOpenReminders: () {},
          onCompleteTask: (_) {});
    })));
    await _showTaskSearch(tester);
    final search = find.byKey(const ValueKey('today-task-search'));
    await tester.tap(search);
    await tester.enterText(search, 'draft');
    await tester.pumpAndSettle();
    final focus = tester
        .widget<EditableText>(
            find.descendant(of: search, matching: find.byType(EditableText)))
        .focusNode;
    update(() => showReminder = true);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(tester.widget<TextField>(search).controller!.text, 'draft');
    update(() => loading = true);
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    update(() {
      loading = false;
      failed = true;
    });
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(tester.widget<TextField>(search).controller!.text, 'draft');
    expect(tester.takeException(), isNull);
  });

  testWidgets('load failure remains scrollable at largest text in landscape',
      (tester) async {
    var retries = 0;
    await _pump(
        tester,
        Scaffold(
            body: TodayAgendaContent(
          agenda: const TodayAgenda(),
          now: now,
          loadFailed: true,
          onRefresh: () async => retries++,
          onOpenDailyNote: () {},
          onOpenNote: (_) {},
          onOpenReminders: () {},
          onCompleteTask: (_) {},
        )),
        size: const Size(320, 240),
        scale: 3.2);
    expect(tester.takeException(), isNull);
    await captureInteractionFeedback(tester, 'today-load-failure-large-text');
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    await _showTaskSearch(tester);
    expect(find.byKey(const ValueKey('today-task-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accessible Undo remains available until acted on or dismissed',
      (tester) async {
    var note = Note(
        id: 'note',
        title: 'Project',
        todo: [Todo(id: 'task', title: 'Write draft')]);
    final controller = TodayAgendaController(
        readNotes: () async => [note],
        readNote: (_) async => note,
        readReminders: () => [],
        readPendingSnoozes: (_) async => {},
        saveNote: (value) async => note = value,
        now: () => now);
    addTearDown(controller.dispose);
    await _pump(tester, TodayScreen(controller: controller),
        accessibleNavigation: true);
    await tester.scrollUntilVisible(find.text('Write draft'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(note.todo.single.completed, isFalse);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('interactive search preview retains completion and Undo',
      (tester) async {
    await tester.pumpWidget(todaySearchPreview());
    await tester.pumpAndSettle();
    await _showTaskSearch(tester);
    await tester.scrollUntilVisible(find.text('Review the first draft'), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('No matching unfinished tasks.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Review the first draft'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
