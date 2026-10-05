import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: Scaffold(body: Center(child: SizedBox(width: 350, child: home))),
    );

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

  testWidgets('Today shortcut stays usable with large text and opens reminders',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(_app(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: UnfinishedNotesFilter(
        selected: false,
        onChanged: (_) {},
        onOpenReminders: () => opened++,
      ),
    )));
    await tester.pumpAndSettle();
    final shortcut = find.byKey(const ValueKey('today-reminders-shortcut'));
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pumpAndSettle();
    expect(opened, 1);
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

  testWidgets(
      'Unfinished is directly tappable on Home and also available among search filters',
      (tester) async {
    var filters = <NoteSearchFilter>{};
    await tester.pumpWidget(_app(StatefulBuilder(
        builder: (_, setState) => Column(children: [
              UnfinishedNotesFilter(
                  selected: filters.contains(NoteSearchFilter.unfinished),
                  onChanged: (selected) => setState(() =>
                      filters = selected ? {NoteSearchFilter.unfinished} : {})),
              NoteSearchFilters(
                  selected: filters,
                  onChanged: (updated) => setState(() => filters = updated)),
            ]))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('unfinished-quick-filter')));
    await tester.pumpAndSettle();
    expect(filters, {NoteSearchFilter.unfinished});
    expect(
        tester
            .widget<FilterChip>(
                find.byKey(const ValueKey('unfinished-quick-filter')))
            .selected,
        isTrue);
    final searchFilter = find.widgetWithText(FilterChip, 'Unfinished').last;
    await tester.ensureVisible(searchFilter);
    await tester.tap(searchFilter);
    await tester.pumpAndSettle();
    expect(filters, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
