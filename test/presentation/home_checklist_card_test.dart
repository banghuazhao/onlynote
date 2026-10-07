import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:screenshot/screenshot.dart';

class _PausedCaptureController extends ScreenshotController {
  final result = Completer<Uint8List?>();
  bool called = false;

  @override
  Future<Uint8List?> capture({
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) {
    called = true;
    return result.future;
  }
}

Widget _app(Widget home,
        {double width = 350, Locale locale = const Locale('en')}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: Scaffold(body: Center(child: SizedBox(width: width, child: home))),
    );

bool _isHorizontalScrollView(Widget widget) =>
    widget is SingleChildScrollView &&
        widget.scrollDirection == Axis.horizontal ||
    widget is ScrollView && widget.scrollDirection == Axis.horizontal;

void main() {
  setUp(() {
    final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
    addTearDown(() => kAppFontFamilies.addAll(fonts));
  });

  for (final configuration in [
    (width: 320.0, locale: const Locale('en')),
    (width: 390.0, locale: const Locale('en')),
    (width: 320.0, locale: const Locale('zh', 'HK')),
  ]) {
    testWidgets(
        'filter button fits ${configuration.width} with large ${configuration.locale} text and announces its active count',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var libraryOpened = 0;
        var filterCount = 2;
        late StateSetter rebuild;
        await tester.pumpWidget(_app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.4)),
            child: StatefulBuilder(builder: (context, setState) {
              rebuild = setState;
              return SizedBox(
                key: const ValueKey('filter-button-area'),
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LibraryFiltersButton(
                    key: const ValueKey('library-filters-shortcut'),
                    onPressed: () => libraryOpened++,
                    count: filterCount,
                  ),
                ),
              );
            }),
          ),
          width: configuration.width,
          locale: configuration.locale,
        ));
        await tester.pumpAndSettle();
        final library = find.byKey(const ValueKey('library-filters-shortcut'));
        final strings = S.of(tester.element(library));
        expect(
            find.descendant(
                of: library,
                matching: find.byWidgetPredicate(_isHorizontalScrollView)),
            findsNothing);
        final bounds =
            tester.getRect(find.byKey(const ValueKey('filter-button-area')));
        final rect = tester.getRect(library);
        expect(rect.left, bounds.left);
        expect(rect.right, lessThanOrEqualTo(bounds.right));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        final data = tester.getSemantics(library).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(tester.getSemantics(library).label,
            '${strings.Library_Filters} (2)');
        expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
        expect(find.text('2'), findsOneWidget);

        await tester.tap(library);
        await tester.pumpAndSettle();
        expect(libraryOpened, 1);

        rebuild(() => filterCount = 0);
        await tester.pumpAndSettle();
        expect(
            tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
        expect(tester.getSemantics(library).label, strings.Library_Filters);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
      'search filters stay in one row with large text and preserve selection and clear actions',
      (tester) async {
    var selected = <NoteSearchFilter>{};
    await tester.pumpWidget(_app(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.4)),
        child: StatefulBuilder(
          builder: (context, setState) => NoteSearchFilters(
            selected: selected,
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      ),
      width: 320,
    ));
    await tester.pumpAndSettle();
    final filters = find.byType(NoteSearchFilters);
    expect(find.byType(LibraryFiltersButton), findsNothing);
    expect(find.byKey(const ValueKey('search-library-filters')), findsNothing);
    expect(
        find.descendant(
            of: filters,
            matching: find.byWidgetPredicate(_isHorizontalScrollView)),
        findsOneWidget);
    for (final chip in find.byType(FilterChip).evaluate()) {
      final finder = find.byWidget(chip.widget);
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
      final bounds = tester.getRect(filters);
      final rect = tester.getRect(finder);
      expect(rect.center.dy, closeTo(bounds.center.dy, .1));
    }
    final unfinished = find.widgetWithText(FilterChip, 'Unfinished');
    await tester.ensureVisible(unfinished);
    await tester.pumpAndSettle();
    await tester.tap(unfinished);
    await tester.pumpAndSettle();
    expect(selected, {NoteSearchFilter.unfinished});
    expect(tester.widget<FilterChip>(unfinished).selected, isTrue);
    await tester.tap(unfinished);
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    await tester.tap(unfinished);
    await tester.pumpAndSettle();
    expect(selected, {NoteSearchFilter.unfinished});
    final clear = find.text('Clear filters');
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Home item tap toggles once without opening the note; other content still opens it',
      (tester) async {
    var note = Note(
        id: 'note', title: 'Shopping', todo: [Todo(id: 'a', title: 'Milk')]);
    var opened = 0;
    final changes = <String>[];
    await tester.pumpWidget(_app(StatefulBuilder(
        builder: (_, setState) => NoteCard(
            note: note,
            onTap: () => opened++,
            onTodoToggle: (id) {
              changes.add(id);
              setState(() => note = note.copyWith(
                  todo: [note.todo.single.copyWith(completed: true)]));
            }))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('card-todo-a')));
    await tester.pumpAndSettle();
    expect(changes, ['a']);
    expect(opened, 0);
    expect(
        tester
            .widget<PaperChecklistRow>(
                find.byKey(const ValueKey('card-todo-a')))
            .completed,
        isTrue);
    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'selection and trash retain the card tap instead of mutating checklist items',
      (tester) async {
    for (final mode in ['selection', 'trash']) {
      var opened = 0;
      var toggles = 0;
      await tester.pumpWidget(_app(NoteCard(
          note: Note(
              id: 'note',
              title: 'Shopping',
              deletedAt: mode == 'trash' ? DateTime.now() : null,
              todo: [Todo(id: 'a', title: 'Milk')]),
          selectionMode: mode == 'selection',
          onTap: () => opened++,
          onTodoToggle: (_) => toggles++)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('card-todo-a')));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(toggles, 0);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('long-press on an interactive item retains the card context menu',
      (tester) async {
    var menus = 0;
    var toggles = 0;
    await tester.pumpWidget(_app(NoteCard(
        note: Note(
            id: 'note',
            title: 'Shopping',
            todo: [Todo(id: 'a', title: 'Milk')]),
        onLongPress: () => menus++,
        onTodoToggle: (_) => toggles++)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('card-todo-a')));
    await tester.pumpAndSettle();
    expect(menus, 1);
    expect(toggles, 0);
  });

  testWidgets(
      'Unfinished cards reveal pending items and reduced-motion completion is immediate',
      (tester) async {
    final todos = [
      for (var i = 0; i < 4; i++)
        Todo(id: '$i', title: 'Completed $i', completed: true),
      Todo(id: 'pending', title: 'Milk'),
    ];
    await tester.pumpWidget(_app(MediaQuery(
        data: const MediaQueryData(
            disableAnimations: true, textScaler: TextScaler.linear(2)),
        child: NoteCard(
            note: Note(id: 'note', title: 'Shopping', todo: todos),
            unfinishedOnly: true,
            onTodoToggle: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('card-todo-pending')), findsOneWidget);
    expect(find.text('Completed 0'), findsNothing);
    final row = find.byKey(const ValueKey('card-todo-pending'));
    expect(tester.getSize(row).height, greaterThanOrEqualTo(44));
    final animation = find.descendant(
        of: row, matching: find.byType(AnimatedDefaultTextStyle));
    expect(tester.widget<AnimatedDefaultTextStyle>(animation).duration,
        Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'image capture keeps row geometry, disables taps, and restores after failure',
      (tester) async {
    final controller = _PausedCaptureController();
    final cardKey = GlobalKey<NoteCardState>();
    var toggles = 0;
    var opened = 0;
    await tester.pumpWidget(_app(NoteCard(
        key: cardKey,
        note: Note(
            id: 'note',
            title: 'Shopping',
            todo: [Todo(id: 'a', title: 'Milk')]),
        screenshotController: controller,
        onTodoToggle: (_) => toggles++,
        onTap: () => opened++)));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('card-todo-a'));
    final rowSize = tester.getSize(row);
    final paperSize = tester.getSize(find.byType(PaperNote));
    expect(rowSize.height, greaterThanOrEqualTo(44));

    final capture = cardKey.currentState!.captureImage();
    final failure = expectLater(capture, throwsStateError);
    await tester.pump();
    expect(controller.called, isTrue);
    expect(tester.getSize(row), rowSize);
    expect(tester.getSize(find.byType(PaperNote)), paperSize);
    expect(tester.widget<PaperChecklistRow>(row).exportMode, isTrue);
    expect(
        find.descendant(of: row, matching: find.byType(InkWell)), findsNothing);
    await tester.tap(row, warnIfMissed: false);
    expect(toggles, 0);
    expect(opened, 0);

    controller.result.completeError(StateError('Capture failed'));
    await failure;
    await tester.pumpAndSettle();
    expect(tester.widget<PaperChecklistRow>(row).exportMode, isFalse);
    expect(tester.getSize(row), rowSize);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(toggles, 1);
    expect(opened, 0);
    expect(tester.takeException(), isNull);
  });
}
