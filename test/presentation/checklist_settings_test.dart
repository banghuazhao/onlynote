import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_checklist_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_checklist.dart';
import 'package:onlynote/presentation/components/note_checklist_previews.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

import '../support/checklist_preferences.dart';

const _toggle = ValueKey('checklist-completed-toggle');

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(extensions: const [AppTokens()]),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

List<Todo> _todos() => [
      Todo(id: 'done', title: 'Completed task', completed: true),
      Todo(id: 'active', title: 'Unfinished task'),
    ];

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
            fontStyle: fontStyle,
          );
    }
    addTearDown(() => kAppFontFamilies.addAll(fonts));
  });

  testWidgets('a collapsed reader reopens collapsed without changing its tasks',
      (tester) async {
    final preferences = ChecklistPreferences();
    final settings = AppChecklistSettings(preferences: preferences);
    final reopened = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    addTearDown(reopened.dispose);
    final todos = _todos();
    await tester
        .pumpWidget(_app(NoteChecklist(todos: todos, settings: settings)));
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsOneWidget);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsNothing);
    expect(preferences.values[AppChecklistSettings.storageKey], isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester
        .pumpWidget(_app(NoteChecklist(todos: todos, settings: reopened)));
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsNothing);
    expect(find.text('Unfinished task'), findsOneWidget);
    expect(todos.map((todo) => todo.id), ['done', 'active']);
    expect(todos.map((todo) => todo.completed), [true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('find expansion and image export leave the saved choice intact',
      (tester) async {
    final preferences = ChecklistPreferences()
      ..values[AppChecklistSettings.storageKey] = false;
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    var forceExpand = false;
    var exportMode = false;
    late StateSetter update;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) {
        update = setState;
        return NoteChecklist(
          todos: _todos(),
          settings: settings,
          expandCompleted: forceExpand,
          exportMode: exportMode,
        );
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsNothing);
    update(() => forceExpand = true);
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsOneWidget);
    expect(tester.widget<TextButton>(find.byKey(_toggle)).onPressed, isNull);
    update(() => forceExpand = false);
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsNothing);
    update(() => exportMode = true);
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.byKey(_toggle), findsNothing);
    update(() => exportMode = false);
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsNothing);
    expect(settings.completedExpanded, isFalse);
    expect(preferences.values[AppChecklistSettings.storageKey], isFalse);
    expect(preferences.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid taps use the latest choice before the next frame',
      (tester) async {
    final settings = AppChecklistSettings.memory();
    addTearDown(settings.dispose);
    await tester
        .pumpWidget(_app(NoteChecklist(todos: _todos(), settings: settings)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_toggle));
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(settings.completedExpanded, isTrue);
    expect(find.text('Completed task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable preferences keep the reader usable', (tester) async {
    final preferences = ChecklistPreferences()
      ..failReads = true
      ..failWrites = true;
    final settings = AppChecklistSettings(preferences: preferences);
    addTearDown(settings.dispose);
    await tester
        .pumpWidget(_app(NoteChecklist(todos: _todos(), settings: settings)));
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsOneWidget);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsNothing);
    expect(find.text('Unfinished task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets('pending preference read survives disposal (failure: $fails)',
        (tester) async {
      final pending = Completer<bool?>();
      final settings = AppChecklistSettings(
          preferences: ChecklistPreferences()..pendingRead = pending);
      addTearDown(settings.dispose);
      await tester
          .pumpWidget(_app(NoteChecklist(todos: _todos(), settings: settings)));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      if (fails) {
        pending.completeError(StateError('Preferences unavailable'));
      } else {
        pending.complete(false);
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('remembered collapse preview keeps its choice when reopened',
      (tester) async {
    await tester.pumpWidget(checklistRememberCollapsePreview());
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsNothing);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checklist-preview-reopen')));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsOneWidget);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checklist-preview-reopen')));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
