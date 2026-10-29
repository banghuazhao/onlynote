import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/today/today_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/today_agenda.dart';

Future<void> _pump(WidgetTester tester, TodayAgendaController controller) =>
    tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: TodayScreen(controller: controller),
    ));

void main() {
  testWidgets(
      'Today rejects covered, duplicate, and disposed completion callbacks',
      (tester) async {
    final now = DateTime(2026, 10, 29, 10);
    var note = Note(
        id: 'note',
        title: 'Project',
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
      now: () => now,
    );
    addTearDown(controller.dispose);
    await _pump(tester, controller);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Write draft'), 250,
        scrollable: find.byType(Scrollable).first);
    final complete = tester.widget<Checkbox>(find.byType(Checkbox)).onChanged!;
    unawaited(showDialog<void>(
      context: tester.element(find.byType(TodayScreen)),
      builder: (_) => const AlertDialog(title: Text('Another action')),
    ));
    await tester.pumpAndSettle();
    complete(true);
    complete(true);
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.text('Another action'), findsOneWidget);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();
    complete(true);
    complete(true);
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(note.todo.single.completed, isTrue);
    expect(find.text('Write draft'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    complete(true);
    await tester.pump();
    expect(writes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Today refreshes a failed load and keeps daily note identity after midnight',
      (tester) async {
    var now = DateTime(2026, 10, 29, 23, 59);
    var failed = true;
    final controller = TodayAgendaController(
      readNotes: () async {
        if (failed) throw StateError('Storage unavailable');
        return [
          Note(
              id: 'before',
              title: 'Thursday journal',
              dailyNoteDateKey: '2026-10-29'),
          Note(
              id: 'after',
              title: 'Friday journal',
              dailyNoteDateKey: '2026-10-30'),
        ];
      },
      readNote: (_) async => null,
      readReminders: () => [],
      readPendingSnoozes: (_) async => {},
      saveNote: (_) async {},
      now: () => now,
    );
    addTearDown(controller.dispose);
    await _pump(tester, controller);
    await tester.pumpAndSettle();
    expect(find.text('Could not refresh Today. Try again.'), findsOneWidget);
    failed = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday journal'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    now = DateTime(2026, 10, 30);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Friday journal'), findsOneWidget);
    expect(find.text('Thursday journal'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'source-note action pushes only one reader and refreshes on return',
      (tester) async {
    final now = DateTime(2026, 10, 29, 10);
    var note = Note(
        id: 'note',
        title: 'Project',
        todo: [Todo(id: 'task', title: 'Write draft')]);
    final controller = TodayAgendaController(
      readNotes: () async => [note],
      readNote: (_) async => note,
      readReminders: () => [],
      readPendingSnoozes: (_) async => {},
      saveNote: (_) async {},
      now: () => now,
    );
    addTearDown(controller.dispose);
    final router = _TodayRouter(controller);
    addTearDown(router.dispose);
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
    await tester.scrollUntilVisible(find.text('Write draft'), 250,
        scrollable: find.byType(Scrollable).first);
    final open = tester
        .widget<ListTile>(find.widgetWithText(ListTile, 'Write draft'))
        .onTap!;
    open();
    open();
    await tester.pumpAndSettle();
    expect(find.text('Reading note'), findsOneWidget);
    expect(router.stack.length, 2);
    note = note.copyWith(todo: [note.todo.single.copyWith(completed: true)]);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Write draft'), findsNothing);
    expect(find.text('No unfinished tasks.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _TodayRouter extends RootStackRouter {
  _TodayRouter(this.controller);
  final TodayAgendaController controller;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo('TestTodayRoute',
                builder: (_) => TodayScreen(controller: controller))),
        AutoRoute(
            page: PageInfo(NoteDetailRoute.name,
                builder: (data) => Scaffold(
                    appBar: AppBar(),
                    body: Text(
                        'Reading ${data.argsAs<NoteDetailRouteArgs>().noteId}')))),
      ];
}
