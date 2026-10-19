import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_checklist_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_checklist.dart';
import 'package:onlynote/presentation/components/note_checklist_previews.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

const _copyKey = ValueKey('checklist-copy-unfinished');

Widget _app(Widget child,
        {Locale locale = const Locale('en'), double textScale = 1}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF685947),
        extensions: const [AppTokens()],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

void main() {
  late AppChecklistSettings checklistSettings;
  setUp(() {
    checklistSettings = AppChecklistSettings.memory();
    addTearDown(checklistSettings.dispose);
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
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  });

  testWidgets(
      'copies the saved unfinished order through the real clipboard API',
      (tester) async {
    final todos = [
      Todo(id: 'z', title: '  Bread  '),
      Todo(id: 'a', title: 'Already done', completed: true),
      Todo(id: 'b', title: 'Tea  bags\nfor tomorrow'),
      Todo(id: 'blank', title: ' \t\n '),
      Todo(id: 'null'),
      Todo(id: 'duplicate', title: 'Bread'),
    ];
    final original = List<Todo>.of(todos);
    final calls = <MethodCall>[];
    var toggles = 0;
    var resets = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        calls.add(call);
      }
      return null;
    });
    await tester.pumpWidget(_app(NoteChecklist(
      settings: checklistSettings,
      todos: todos,
      onToggle: (_) => toggles++,
      onReset: () => resets++,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_copyKey));
    await tester.pumpAndSettle();

    expect(calls.map((call) => call.method), ['Clipboard.setData']);
    expect(calls.single.arguments,
        {'text': 'Bread\nTea  bags\nfor tomorrow\nBread'});
    expect(find.text(S.current.Checklist_Copy_Success(3)), findsOneWidget);
    expect(todos, original);
    expect(todos.map((todo) => todo.completed),
        [false, true, false, false, false, false]);
    expect(toggles, 0);
    expect(resets, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty, completed, blank and exported checklists hide copy',
      (tester) async {
    final fixtures = [
      NoteChecklist(settings: checklistSettings, todos: const []),
      NoteChecklist(
          settings: checklistSettings,
          todos: [Todo(title: 'Done', completed: true)]),
      NoteChecklist(settings: checklistSettings, todos: [
        Todo(id: 'blank', title: ' \n '),
        Todo(id: 'null'),
      ]),
      NoteChecklist(
          settings: checklistSettings,
          todos: [Todo(title: 'Milk')],
          exportMode: true),
    ];
    for (final fixture in fixtures) {
      await tester.pumpWidget(_app(fixture));
      await tester.pumpAndSettle();
      expect(find.byKey(_copyKey), findsNothing);
      expect(
          find.byKey(const ValueKey('checklist-copy-feedback')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('read-only readers allow copying without changing completion',
      (tester) async {
    final payloads = <String>[];
    var toggles = 0;
    var resets = 0;
    await tester.pumpWidget(_app(NoteChecklist(
      settings: checklistSettings,
      todos: [
        Todo(id: 'a', title: 'Milk'),
        Todo(id: 'b', title: 'Bread', completed: true),
      ],
      readOnly: true,
      onToggle: (_) => toggles++,
      onReset: () => resets++,
      clipboardWriter: (text) async => payloads.add(text),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(_copyKey), findsOneWidget);
    expect(find.byKey(const ValueKey('checklist-reset')), findsNothing);

    await tester.tap(find.byKey(_copyKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checklist-item-a')));
    await tester.pump();

    expect(payloads, ['Milk']);
    expect(find.text('1 of 2 complete'), findsOneWidget);
    expect(toggles, 0);
    expect(resets, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'rapid taps make one write and the action re-enables on completion',
      (tester) async {
    final pending = Completer<void>();
    var writes = 0;
    await tester.pumpWidget(_app(NoteChecklist(
      settings: checklistSettings,
      todos: [Todo(title: 'Milk')],
      clipboardWriter: (_) {
        writes++;
        return pending.future;
      },
    )));
    await tester.pumpAndSettle();

    // A second tap before the disabled-state frame is also ignored.
    await tester.tap(find.byKey(_copyKey));
    await tester.tap(find.byKey(_copyKey));
    await tester.pump();
    expect(writes, 1);
    expect(tester.widget<TextButton>(find.byKey(_copyKey)).onPressed, isNull);
    expect(find.byKey(const ValueKey('checklist-copy-feedback')), findsNothing);

    pending.complete();
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextButton>(find.byKey(_copyKey)).onPressed, isNotNull);
    expect(find.text(S.current.Checklist_Copy_Success(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clipboard errors show localized feedback and allow retry',
      (tester) async {
    var attempts = 0;
    final payloads = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        attempts++;
        payloads.add((call.arguments as Map)['text'] as String);
        if (attempts == 1) {
          throw PlatformException(code: 'clipboard-unavailable');
        }
      }
      return null;
    });
    await tester.pumpWidget(_app(NoteChecklist(
        settings: checklistSettings, todos: [Todo(title: 'Milk')])));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_copyKey));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Checklist_Copy_Failed), findsOneWidget);
    expect(
        tester.widget<TextButton>(find.byKey(_copyKey)).onPressed, isNotNull);
    expect(find.text(S.current.Checklist_Copy_Success(1)), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(_copyKey));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(payloads, ['Milk', 'Milk']);
    expect(find.text(S.current.Checklist_Copy_Failed), findsNothing);
    expect(find.text(S.current.Checklist_Copy_Success(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets(
        'pending ${fails ? 'failed' : 'successful'} copy survives disposal',
        (tester) async {
      final pending = Completer<void>();
      await tester.pumpWidget(_app(NoteChecklist(
        settings: checklistSettings,
        todos: [Todo(title: 'Milk')],
        clipboardWriter: (_) => pending.future,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_copyKey));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      if (fails) {
        pending.completeError(StateError('Clipboard unavailable'));
      } else {
        pending.complete();
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('copy reflects toggled items and clears an outdated status',
      (tester) async {
    var todos = [
      Todo(id: 'a', title: 'Milk'),
      Todo(id: 'b', title: 'Bread'),
    ];
    final payloads = <String>[];
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) => NoteChecklist(
        settings: checklistSettings,
        todos: todos,
        onToggle: (id) => setState(() => todos = [
              for (final todo in todos)
                todo.id == id
                    ? todo.copyWith(completed: !todo.completed)
                    : todo,
            ]),
        clipboardWriter: (text) async => payloads.add(text),
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_copyKey));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Checklist_Copy_Success(2)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checklist-item-a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('checklist-copy-feedback')), findsNothing);
    await tester.tap(find.byKey(_copyKey));
    await tester.pumpAndSettle();
    expect(payloads, ['Milk\nBread', 'Bread']);
    expect(find.text(S.current.Checklist_Copy_Success(1)), findsOneWidget);
    expect(todos.first.completed, isTrue);
    expect(todos.last.completed, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('copy remains accessible at 280px and 2× in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(280, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        final payloads = <String>[];
        await tester.pumpWidget(_app(
          NoteChecklist(
            settings: checklistSettings,
            todos: [
              Todo(id: 'a', title: 'Bring bread and fresh fruit for tomorrow'),
              Todo(id: 'b', title: 'Milk', completed: true),
            ],
            onReset: () {},
            clipboardWriter: (text) async => payloads.add(text),
          ),
          locale: locale,
          textScale: 2,
        ));
        await tester.pumpAndSettle();
        final copy = find.byKey(_copyKey);
        await tester.ensureVisible(copy);
        expect(tester.getSize(copy).height, greaterThanOrEqualTo(48));
        expect(
            tester.getSemantics(copy),
            isSemantics(
                isButton: true,
                hasTapAction: true,
                isEnabled: true,
                hasEnabledState: true,
                label: S.current.Checklist_Copy_Unfinished));
        await tester.tap(copy);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
            find.byKey(const ValueKey('checklist-copy-feedback')));
        expect(payloads, ['Bring bread and fresh fruit for tomorrow']);
        expect(find.text(S.current.Checklist_Copy_Success(1)), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
      'isolated previews use a local clipboard in light, dark and Chinese',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var nativeWrites = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') nativeWrites++;
      return null;
    });
    for (final preview in [
      checklistCopyPreview,
      checklistCopyDarkPreview,
      checklistCopyChinesePreview,
    ]) {
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(_copyKey));
      await tester.tap(find.byKey(_copyKey));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('checklist-preview-clipboard')),
          findsOneWidget);
      final clipboard = tester.widget<Text>(
          find.byKey(const ValueKey('checklist-preview-clipboard')));
      expect(
          clipboard.data,
          preview == checklistCopyChinesePreview
              ? '帶上購物袋\n麵包和新鮮水果'
              : 'Bring shopping bags\nBread and fresh fruit');
      expect(tester.takeException(), isNull);
      // Reset local state between preview configurations.
      await tester.pumpWidget(const SizedBox());
    }
    expect(nativeWrites, 0);
  });
}
