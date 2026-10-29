import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/today/today_agenda_content.dart';
import 'package:onlynote/presentation/screens/home/widgets/daily_note_previews.dart';
import 'package:onlynote/presentation/screens/today/today_previews.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/today_agenda.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 440.0, 600.0]) {
    testWidgets('Today library entry fits at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(libraryTopNavigationNarrowPreview());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (width >= 360) {
        await tester.tap(find.byTooltip('Today'));
      } else {
        await tester.tap(find.byTooltip(S.current.More_Options));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Today'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'Today opens the daily note and task source, and completes the selected task',
      (tester) async {
    final now = DateTime(2026, 10, 29, 10);
    final note = Note(id: 'work', title: 'Website project', todo: [
      Todo(id: 'task', title: 'Write first draft'),
    ]);
    final agenda = buildTodayAgenda(notes: [note], reminders: [], now: now);
    final opened = <String>[];
    final completed = <TodayTaskEntry>[];
    var dailyOpens = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
          body: TodayAgendaContent(
        agenda: agenda,
        now: now,
        onOpenDailyNote: () => dailyOpens++,
        onOpenNote: opened.add,
        onOpenReminders: () {},
        onCompleteTask: completed.add,
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Start today’s note'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('today-daily-note')));
    expect(dailyOpens, 1);
    await tester.scrollUntilVisible(find.text('Write first draft'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Write first draft'));
    expect(opened, ['work']);
    await tester.tap(find.byType(Checkbox));
    expect(completed.single.todo.id, 'task');
    expect(opened, ['work']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'overdue and due reminders open their notes and retain localized time',
      (tester) async {
    final now = DateTime(2026, 10, 29, 10);
    final notes = [
      Note(id: 'past', title: 'Call dentist'),
      Note(id: 'due', title: 'Evening journal')
    ];
    final opened = <String>[];
    var allReminders = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: const MediaQueryData(alwaysUse24HourFormat: true),
        child: Scaffold(
            body: TodayAgendaContent(
          agenda: buildTodayAgenda(
              notes: notes,
              reminders: [
                Reminder(
                    noteId: 'past',
                    reminderId: 1,
                    reminderDate: DateTime(2026, 10, 28, 9)),
                Reminder(
                    noteId: 'due',
                    reminderId: 2,
                    reminderDate: DateTime(2026, 10, 29, 18, 30)),
              ],
              now: now),
          now: now,
          onOpenDailyNote: () {},
          onOpenNote: opened.add,
          onOpenReminders: () => allReminders++,
          onCompleteTask: (_) {},
        )),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All reminders'));
    expect(allReminders, 1);
    await tester.scrollUntilVisible(find.text('Call dentist'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Overdue'), findsOneWidget);
    await tester.tap(find.text('Call dentist'));
    expect(opened, ['past']);
    await tester.scrollUntilVisible(find.text('Evening journal'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('18:30'), findsOneWidget);
    await tester.tap(find.text('Evening journal'));
    expect(opened, ['past', 'due']);
  });

  testWidgets('Today stays scrollable in a short landscape window',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(todayPreview());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
        find.text('Choose three photos for the homepage'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Choose three photos for the homepage'));
    await tester.pumpAndSettle();
    expect(find.text('Website refresh'), findsWidgets);
  });

  for (final preview in [
    todayPreview,
    todayDarkPreview,
    todayLargeChinesePreview,
    todayEmptyPreview
  ]) {
    testWidgets(
        'Today preview ${preview.toString()} stays usable at narrow widths and large text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var index = 0; index < 8; index++) {
        await tester.drag(find.byKey(const ValueKey('today-agenda-list')),
            const Offset(0, -280));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
