import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
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

  VoiceMemo recording(String id, {int durationMs = 0, String? transcript}) =>
      VoiceMemo(
          id: id,
          path: 'note_audio/unavailable-$id.m4a',
          durationMs: durationMs,
          createdAt: today,
          transcript: transcript);

  Future<void> pump(
    WidgetTester tester, {
    List<Note>? notes,
    ValueChanged<DateTime>? onOpenDay,
    VoidCallback? onOpenToday,
    DateTime? currentDay,
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool reduceMotion = false,
    bool dark = false,
  }) async {
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

  Finder getMonthlySavedDays() =>
      find.byKey(const ValueKey('daily-calendar-month-saved-days'));

  void expectMonthlySavedDays(WidgetTester tester, int count) {
    expect(tester.widget<Text>(getMonthlySavedDays()).data,
        S.current.Daily_Note_Calendar_Month_Saved_Days(count));
  }

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

  testWidgets(
      'selected preview uses body then checklist then stored transcripts',
      (tester) async {
    final original = Note(
      id: 'today',
      title: 'Saved voice thoughts',
      description: '  Body first  ',
      todo: [Todo(title: '  Checklist first  '), Todo(title: 'Next item')],
      dailyNoteDateKey: '2026-10-06',
      voiceMemos: [
        recording('empty', transcript: ' \t '),
        recording('first', transcript: '  First voice\nthought  '),
        recording('second', transcript: '\t Second thought  '),
      ],
    );
    final snippet =
        find.byKey(const ValueKey('daily-calendar-selected-snippet'));
    await pump(tester, notes: [original]);
    expect(tester.widget<Text>(snippet).data, 'Body first');
    final checklistOnly = original.copyWith(description: ' \n ');
    await pump(tester, notes: [checklistOnly]);
    expect(tester.widget<Text>(snippet).data, 'Checklist first, Next item');
    final audioOnly =
        checklistOnly.copyWith(todo: [Todo(title: '  ')], isArchived: true);
    await pump(tester, notes: [audioOnly]);
    expect(tester.widget<Text>(snippet).data,
        'First voice thought Second thought');
    expect(
        find.byKey(const ValueKey('daily-calendar-archived')), findsOneWidget);
    expect(tester.widget<Text>(snippet).maxLines, 2);
    expect(tester.widget<Text>(snippet).overflow, TextOverflow.ellipsis);
    expect(original.description, '  Body first  ');
    expect(original.todo.first.title, '  Checklist first  ');
    expect(original.voiceMemos[1].transcript, '  First voice\nthought  ');
    expect(tester.takeException(), isNull);
  });

  testWidgets('transcript prefixes preserve graphemes and remain bounded',
      (tester) async {
    const family = '👨‍👩‍👧‍👦';
    final transcript = '  ${family * 161}  ';
    await pump(tester, notes: [
      Note(
          id: 'today',
          dailyNoteDateKey: '2026-10-06',
          voiceMemos: [recording('long', transcript: transcript)]),
    ]);
    final snippet = tester.widget<Text>(
        find.byKey(const ValueKey('daily-calendar-selected-snippet')));
    expect(snippet.data, '${family * 160}…');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'media-only preview counts declared attachments without reading files',
      (tester) async {
    final opened = <DateTime>[];
    final saved = Note(
      id: 'today',
      title: 'Media memory',
      dailyNoteDateKey: '2026-10-06',
      imagePaths: [
        'unavailable/photo-1.jpg',
        'unavailable/photo-2.jpg',
        'unavailable/page.jpg',
        'unavailable/page.jpg',
      ],
      imageLayouts: const [
        NoteImageLayout(
            path: 'unavailable/page.jpg', textOffset: 0, isDocumentPage: true),
        NoteImageLayout(
            path: 'unavailable/page.jpg', textOffset: 4, isDocumentPage: true),
        NoteImageLayout(
            path: 'detached/page.jpg', textOffset: 0, isDocumentPage: true),
        NoteImageLayout(path: 'unavailable/photo-1.jpg', textOffset: 0),
      ],
      voiceMemos: [
        recording('one', durationMs: 61200),
        recording('two', durationMs: 1000),
        recording('invalid', durationMs: -500),
      ],
      isArchived: true,
    );
    await pump(tester, notes: [saved], onOpenDay: opened.add);
    expect(find.byKey(const ValueKey('daily-calendar-selected-snippet')),
        findsNothing);
    expect(find.text('2 photos'), findsOneWidget);
    expect(find.text('1 scanned page'), findsOneWidget);
    expect(find.text('3 recordings · 1:02'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('daily-calendar-archived')), findsOneWidget);
    expect(opened, isEmpty);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-selected-note')));
    expect(opened, [today]);
    expect(saved.imagePaths, hasLength(4));
    expect(saved.imageLayouts, hasLength(4));
    expect(saved.voiceMemos.last.durationMs, -500);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero media and detached scan layouts are omitted',
      (tester) async {
    final saved = Note(
        id: 'today',
        title: 'Text note',
        dailyNoteDateKey: '2026-10-06',
        imageLayouts: const [
          NoteImageLayout(
              path: 'detached/page.jpg', textOffset: 0, isDocumentPage: true),
        ]);
    await pump(tester, notes: [saved]);
    expect(find.byKey(const ValueKey('daily-calendar-media-summary')),
        findsNothing);
    expect(find.byKey(const ValueKey('daily-calendar-selected-snippet')),
        findsNothing);
    await pump(tester, notes: [
      saved.copyWith(voiceMemos: [recording('zero', transcript: '\n \t')]),
    ]);
    expect(find.byKey(const ValueKey('daily-calendar-photos')), findsNothing);
    expect(find.byKey(const ValueKey('daily-calendar-scans')), findsNothing);
    expect(find.text('1 recording · 0:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-calendar-selected-snippet')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected media and transcripts refresh when the note changes',
      (tester) async {
    final saved = Note(
      id: 'today',
      title: 'Original media',
      dailyNoteDateKey: '2026-10-06',
      voiceMemos: [recording('one', durationMs: 1000, transcript: 'Original')],
    );
    await pump(tester, notes: [saved]);
    expect(find.text('1 recording · 0:01'), findsOneWidget);
    final updated = saved.copyWith(
      imagePaths: ['unavailable/new-photo.jpg'],
      voiceMemos: [
        recording('two', durationMs: 125000, transcript: 'Latest thoughts'),
      ],
      isArchived: true,
    );
    await pump(tester, notes: [updated]);
    expect(find.text('Original'), findsNothing);
    expect(find.text('Latest thoughts'), findsOneWidget);
    expect(find.text('1 photo'), findsOneWidget);
    expect(find.text('1 recording · 2:05'), findsOneWidget);
    expect(find.text('October 6, 2026'), findsOneWidget);
    await pump(tester, notes: [updated.copyWith(deletedAt: today)]);
    expect(find.byKey(const ValueKey('daily-calendar-media-summary')),
        findsNothing);
    expect(find.byKey(const ValueKey('daily-calendar-selected-snippet')),
        findsNothing);
    expect(
        find.byKey(const ValueKey('daily-calendar-no-note')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly saved-day totals follow the displayed month and Today',
      (tester) async {
    final opened = <DateTime>[];
    var openedToday = 0;
    await pump(tester,
        notes: [
          october,
          october.copyWith(id: 'duplicate', isArchived: true),
          september,
          Note(id: 'second', dailyNoteDateKey: '2026-10-20', isArchived: true),
          Note(id: 'trash', dailyNoteDateKey: '2026-10-21', deletedAt: today),
          Note(id: 'invalid', dailyNoteDateKey: '2026-10-32'),
        ],
        onOpenDay: opened.add,
        onOpenToday: () => openedToday++);
    expectMonthlySavedDays(tester, 2);
    expect(find.text('2 saved days this month'), findsOneWidget);
    await tap(tester, day(DateTime(2026, 10, 4)));
    expectMonthlySavedDays(tester, 2);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-next-month')));
    expectMonthlySavedDays(tester, 0);
    expect(find.text('0 saved days this month'), findsOneWidget);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-previous-month')));
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-previous-month')));
    expectMonthlySavedDays(tester, 1);
    expect(find.text('1 saved day this month'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('daily-calendar-show-today')));
    expectMonthlySavedDays(tester, 2);
    expect(opened, isEmpty);
    expect(openedToday, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly totals follow saved-day jumps and live note updates',
      (tester) async {
    final second = Note(id: 'second', dailyNoteDateKey: '2026-10-05');
    await pump(tester, notes: [october, second, september]);
    expectMonthlySavedDays(tester, 2);
    final previous =
        find.byKey(const ValueKey('daily-calendar-previous-saved'));
    await tap(tester, previous);
    expectMonthlySavedDays(tester, 2);
    await tap(tester, previous);
    expectMonthlySavedDays(tester, 2);
    await tap(tester, previous);
    expect(find.text('September 2026'), findsOneWidget);
    expectMonthlySavedDays(tester, 1);
    await pump(tester, notes: [
      october,
      second,
      september,
      Note(id: 'new', dailyNoteDateKey: '2026-09-25'),
    ]);
    expect(find.text('September 2026'), findsOneWidget);
    expectMonthlySavedDays(tester, 2);
    await pump(tester, notes: [october, second]);
    expect(find.text('September 2026'), findsOneWidget);
    expectMonthlySavedDays(tester, 0);
    expect(tester.takeException(), isNull);
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
    expectMonthlySavedDays(tester, 1);
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

  testWidgets('saved-note controls browse sparse dates without opening a note',
      (tester) async {
    final opened = <DateTime>[];
    var openedToday = 0;
    final nextYear = Note(
        id: 'next-year', title: 'A new year', dailyNoteDateKey: '2027-01-01');
    await pump(tester,
        notes: [nextYear, october, september],
        onOpenDay: opened.add,
        onOpenToday: () => openedToday++);
    final previous =
        find.byKey(const ValueKey('daily-calendar-previous-saved'));
    final next = find.byKey(const ValueKey('daily-calendar-next-saved'));
    await tap(tester, previous);
    expect(find.text('October 3, 2026'), findsOneWidget);
    expect(find.text('Renamed daily note'), findsOneWidget);
    await tap(tester, previous);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('September 23, 2026'), findsOneWidget);
    expect(find.text('Archived September note'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
    await tap(tester, next);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('October 3, 2026'), findsOneWidget);
    await tap(tester, next);
    expect(find.text('January 2027'), findsOneWidget);
    expect(find.text('January 1, 2027'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
    expect(opened, isEmpty);
    expect(openedToday, 0);
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-selected-note')));
    expect(opened, [DateTime(2027, 1, 1)]);
    expect(openedToday, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved-note navigation starts strictly around an empty date',
      (tester) async {
    final opened = <DateTime>[];
    await pump(tester, onOpenDay: opened.add);
    await tap(tester, day(DateTime(2026, 10, 1)));
    await tap(tester, find.byKey(const ValueKey('daily-calendar-next-saved')));
    expect(find.text('October 3, 2026'), findsOneWidget);
    await tap(tester, day(DateTime(2026, 10, 2)));
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-previous-saved')));
    expect(find.text('September 23, 2026'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(opened, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and single-date calendars disable unavailable directions',
      (tester) async {
    final opened = <DateTime>[];
    var openedToday = 0;
    await pump(tester,
        notes: [], onOpenDay: opened.add, onOpenToday: () => openedToday++);
    final previous =
        find.byKey(const ValueKey('daily-calendar-previous-saved'));
    final next = find.byKey(const ValueKey('daily-calendar-next-saved'));
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
    await pump(tester,
        notes: [october],
        onOpenDay: opened.add,
        onOpenToday: () => openedToday++);
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNotNull);
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
    await tap(tester, previous);
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
    await pump(tester,
        notes: [october.copyWith(deletedAt: today)],
        onOpenDay: opened.add,
        onOpenToday: () => openedToday++);
    expect(find.text('October 3, 2026'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('daily-calendar-no-note')), findsOneWidget);
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
    expect(opened, isEmpty);
    expect(openedToday, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved navigation reaches year boundaries without wrapping',
      (tester) async {
    final opened = <DateTime>[];
    await pump(tester,
        notes: [
          Note(id: 'first', title: 'First', dailyNoteDateKey: '0001-01-01'),
          Note(id: 'last', title: 'Last', dailyNoteDateKey: '9999-12-31'),
        ],
        onOpenDay: opened.add);
    final previous =
        find.byKey(const ValueKey('daily-calendar-previous-saved'));
    final next = find.byKey(const ValueKey('daily-calendar-next-saved'));
    await tap(tester, previous);
    expect(find.byKey(const ValueKey('daily-calendar-day-0001-01-01')),
        findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('daily-calendar-previous-month')))
            .onPressed,
        isNull);
    await tap(tester, next);
    expect(find.byKey(const ValueKey('daily-calendar-day-9999-12-31')),
        findsOneWidget);
    expect(find.text('Last'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('daily-calendar-next-month')))
            .onPressed,
        isNull);
    expect(opened, isEmpty);
    expect(tester.takeException(), isNull);
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
    expectMonthlySavedDays(tester, 1);
    final countBounds = tester.getRect(getMonthlySavedDays());
    expect(countBounds.left, greaterThanOrEqualTo(0));
    expect(countBounds.right, lessThanOrEqualTo(320));
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
    final previous =
        find.byKey(const ValueKey('daily-calendar-previous-saved'));
    await tap(tester, previous);
    expect(find.text('Archived September note'), findsOneWidget);
    expect(tester.getRect(previous).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(previous).right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved controls wrap on a narrow dark calendar at large text',
      (tester) async {
    size(tester, const Size(320, 760));
    await pump(tester, dark: true, textScale: 2.2, reduceMotion: true);
    for (final key in [
      'daily-calendar-previous-saved',
      'daily-calendar-next-saved'
    ]) {
      final button = find.byKey(ValueKey(key));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      final bounds = tester.getRect(button);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(320));
      expect(bounds.height, greaterThanOrEqualTo(48));
    }
    await tap(
        tester, find.byKey(const ValueKey('daily-calendar-previous-saved')));
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
