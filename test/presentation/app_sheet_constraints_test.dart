import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';

import '../support/interaction_feedback_capture.dart';

Future<ValueNotifier<double>> _open(WidgetTester tester,
    {Size size = const Size(740, 180),
    double scale = 2,
    Locale locale = const Locale('en'),
    double keyboard = 0,
    bool withField = false,
    required VoidCallback onApply}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final insets = ValueNotifier(0.0);
  addTearDown(insets.dispose);
  await tester.pumpWidget(RepaintBoundary(
      key: interactionFeedbackCaptureKey,
      child: MaterialApp(
        theme: interactionFeedbackTheme(dark: false),
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => ValueListenableBuilder<double>(
          valueListenable: insets,
          builder: (context, bottom, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: bottom),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
        home: Scaffold(body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => showAppSheet<void>(
              context: context,
              builder: (context) => AppSheet(
                title: S.of(context).History_Preview,
                footer: FilledButton(
                  key: const ValueKey('apply-sheet'),
                  onPressed: onApply,
                  child: Text(S.of(context).Restore),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (withField)
                      const TextField(key: ValueKey('sheet-draft-field')),
                    for (var index = 0; index < 12; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Saved content $index'),
                      ),
                  ],
                ),
              ),
            ),
            child: const Text('Open'),
          );
        })),
      )));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  if (keyboard > 0) {
    insets.value = keyboard;
    await tester.pumpAndSettle();
  }
  return insets;
}

void main() {
  setUpAll(loadInteractionFeedbackFonts);
  for (final (name, size, scale, locale, keyboard) in [
    ('landscape', const Size(740, 180), 2.0, const Locale('en'), 0.0),
    ('Chinese', const Size(280, 360), 2.0, const Locale('zh', 'HK'), 0.0),
    ('keyboard', const Size(375, 640), 2.0, const Locale('en'), 480.0),
  ]) {
    testWidgets('$name footer sheet keeps content and action reachable',
        (tester) async {
      var applied = 0;
      await _open(tester,
          size: size,
          scale: scale,
          locale: locale,
          keyboard: keyboard,
          onApply: () => applied++);
      expect(tester.takeException(), isNull);
      final body = find.text('Saved content 11');
      await tester.ensureVisible(body);
      await tester.pumpAndSettle();
      expect(body.hitTestable(), findsOneWidget);
      final apply = find.byKey(const ValueKey('apply-sheet'));
      await tester.ensureVisible(apply);
      await tester.pumpAndSettle();
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(applied, 1);
      expect(tester.takeException(), isNull);
      await captureInteractionFeedback(tester, 'compact-sheet-$name-action');
    });
  }

  testWidgets('keyboard layout changes preserve draft focus and selection',
      (tester) async {
    final insets = await _open(tester,
        size: const Size(375, 812), scale: 1, withField: true, onApply: () {});
    final field = find.byKey(const ValueKey('sheet-draft-field'));
    await tester.tap(field);
    await tester.enterText(field, 'Unsaved draft');
    await tester.pump();
    final before = tester.widget<EditableText>(find.byType(EditableText));
    const selection = TextSelection(baseOffset: 1, extentOffset: 5);
    before.controller.selection = selection;
    for (final keyboard in [650.0, 0.0, 650.0]) {
      insets.value = keyboard;
      await tester.pumpAndSettle();
      final after = tester.widget<EditableText>(find.byType(EditableText));
      expect(after.focusNode, same(before.focusNode));
      expect(after.focusNode.hasFocus, isTrue);
      expect(after.controller.text, 'Unsaved draft');
      expect(after.controller.selection, selection);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('ordinary sheets retain a fixed footer while content scrolls',
      (tester) async {
    await _open(tester, size: const Size(375, 812), scale: 1, onApply: () {});
    final apply = find.byKey(const ValueKey('apply-sheet'));
    final before = tester.getRect(apply);
    await tester.ensureVisible(find.text('Saved content 11'));
    await tester.pumpAndSettle();
    expect(tester.getRect(apply), before);
    expect(apply.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
