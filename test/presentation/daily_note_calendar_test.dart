import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/daily_note_calendar_sheet.dart';
import 'package:onlynote/presentation/theme/theme.dart';

void main() {
  final today = DateTime(2026, 10, 6);
  final october = Note(
    id: 'october',
    title: 'Renamed daily note',
    description: 'A memory from Saturday.',
    dailyNoteDateKey: '2026-10-03',
  );
  final september = Note(
    id: 'september',
    title: 'Archived September note',
    dailyNoteDateKey: '2026-09-23',
    isArchived: true,
  );

  Future<void> pump(
    WidgetTester tester, {
    List<Note>? notes,
    ValueChanged<DateTime>? onOpenDay,
    VoidCallback? onOpenToday,
    DateTime? currentDay,
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
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
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: DailyNoteCalendarSheet(
              notes: notes ?? [october, september],
              today: currentDay ?? today,
              onOpenDay: onOpenDay ?? (_) {},
              onOpenToday: onOpenToday ?? () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder day(DateTime value) =>
      find.byKey(ValueKey('daily-calendar-day-${dailyNoteDateKey(value)}'));

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  void size(WidgetTester tester, Size value) {
    tester.view.physicalSize = value;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('marked dates open the exact associated day after title edits',
      (tester) async {
    final opened = <DateTime>[];
    await pump(tester, onOpenDay: opened.add);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-calendar-marker-2026-10-03')),
        findsOneWidget);
    await tap(tester, day(DateTime(2026, 10, 3)));
    expect(opened, [DateTime(2026, 10, 3)]);
    expect(find.text('Renamed daily note'), findsOneWidget);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-previous-month')));
    expect(find.text('September 2026'), findsOneWidget);
    await tap(tester, day(DateTime(2026, 9, 23)));
    expect(opened, [DateTime(2026, 10, 3), DateTime(2026, 9, 23)]);
    expect(find.text('Archived September note'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('daily-calendar-archived')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty dates show a message without opening or creating a note',
      (tester) async {
    final opened = <DateTime>[];
    var openedToday = 0;
    await pump(tester,
        notes: [october],
        onOpenDay: opened.add,
        onOpenToday: () => openedToday++);
    await tap(tester, day(DateTime(2026, 10, 4)));
    expect(opened, isEmpty);
    expect(openedToday, 0);
    expect(
        find.byKey(const ValueKey('daily-calendar-no-note')), findsOneWidget);
    expect(find.text('October 4, 2026'), findsOneWidget);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-selected-note')));
    expect(opened, isEmpty);
    expect(openedToday, 0);
  });

  testWidgets('Today returns to this month and the explicit CTA opens today',
      (tester) async {
    final opened = <DateTime>[];
    var openedToday = 0;
    await pump(tester, onOpenDay: opened.add, onOpenToday: () => openedToday++);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-previous-month')));
    expect(find.text('September 2026'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-show-today')));
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('October 6, 2026'), findsOneWidget);
    expect(opened, isEmpty);
    expect(openedToday, 0);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-open-today')));
    expect(openedToday, 1);
    expect(opened, isEmpty);
  });

  testWidgets('month and year control jumps directly to older dates',
      (tester) async {
    size(tester, const Size(390, 844));
    final opened = <DateTime>[];
    await pump(tester, onOpenDay: opened.add);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-choose-month')));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '09/23/2026');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('September 23, 2026'), findsOneWidget);
    expect(opened, isEmpty);
    await tap(tester, day(DateTime(2026, 9, 23)));
    expect(opened, [DateTime(2026, 9, 23)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('December navigation changes year and clamps selected day',
      (tester) async {
    await pump(tester, currentDay: DateTime(2026, 12, 31), notes: []);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-next-month')));
    expect(find.text('January 2027'), findsOneWidget);
    expect(find.text('January 31, 2027'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-next-month')));
    expect(find.text('February 2027'), findsOneWidget);
    expect(find.text('February 28, 2027'), findsOneWidget);
  });

  testWidgets(
      'trash and ordinary notes are excluded and updates keep the month',
      (tester) async {
    final trashed = october.copyWith(deletedAt: DateTime(2026, 10, 4));
    final ordinary = Note(
        id: 'ordinary',
        title: 'October 3, 2026',
        dateTime: DateTime(2026, 10, 3));
    await pump(tester, notes: [trashed, ordinary]);
    expect(find.byKey(const ValueKey('daily-calendar-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-calendar-marker-2026-10-03')),
        findsNothing);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-previous-month')));
    await tap(tester, day(DateTime(2026, 9, 23)));
    expect(
        find.byKey(const ValueKey('daily-calendar-no-note')), findsOneWidget);
    await pump(tester, notes: [september]);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Archived September note'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-calendar-empty')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-date semantics announce today and saved note availability',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pump(tester);
      expect(tester.getSemantics(day(DateTime(2026, 10, 3))).label,
          contains(DateFormat.yMMMMEEEEd('en').format(DateTime(2026, 10, 3))));
      expect(tester.getSemantics(day(DateTime(2026, 10, 3))).label,
          contains(S.current.Daily_Note_Calendar_Has_Note));
      expect(tester.getSemantics(day(today)).label,
          contains(S.current.Daily_Note_Calendar_Today));
      expect(tester.getSemantics(day(today)).label,
          contains(S.current.Daily_Note_Calendar_No_Note));
      expect(
          tester
              .getSemantics(day(DateTime(2026, 10, 3)))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('narrow Chinese calendar keeps all seven dates visible',
      (tester) async {
    size(tester, const Size(320, 760));
    await pump(tester,
        locale: const Locale('zh', 'HK'), textScale: 2.2, reduceMotion: true);
    final first = tester.getRect(day(DateTime(2026, 10, 4)));
    final last = tester.getRect(day(DateTime(2026, 10, 10)));
    expect(first.left, greaterThanOrEqualTo(0));
    expect(last.right, lessThanOrEqualTo(320));
    expect(first.height, greaterThanOrEqualTo(48));
    expect(last.center.dy, first.center.dy);
    expect(
        tester
            .widget<AnimatedContainer>(find
                .descendant(
                    of: day(today), matching: find.byType(AnimatedContainer))
                .first)
            .duration,
        Duration.zero);
    await tap(tester, day(DateTime(2026, 10, 3)));
    expect(find.text('Renamed daily note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape and tablet keep calendar navigation reachable',
      (tester) async {
    size(tester, const Size(760, 320));
    var todayTaps = 0;
    await pump(tester, textScale: 1.5, onOpenToday: () => todayTaps++);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-next-month')));
    expect(find.text('November 2026'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-open-today')));
    expect(todayTaps, 1);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(900, 1000);
    await tester.pumpAndSettle();
    expect(tester.getSize(day(DateTime(2026, 11, 6))).width,
        greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}
