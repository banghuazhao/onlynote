import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_save_status.dart';
import 'package:onlynote/services/note_autosave.dart';

Widget _host(Widget child,
        {double width = 220,
        double scale = 1,
        Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  testWidgets('failed save is an accessible retry button', (tester) async {
    var retries = 0;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(NoteSaveStatus(
          status: AutosaveStatus.failed, onRetry: () => retries++)));
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('editor-retry-save'));
      expect(find.text('Not saved'), findsOneWidget);
      final data = tester.getSemantics(button).getSemanticsData();
      expect(data.label, 'Not saved. Retry');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await tester.tap(button);
      expect(retries, 1);
    } finally {
      semantics.dispose();
    }
  });

  for (final locale in [const Locale('en'), const Locale('zh')]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('retry fits narrow widths: $locale, text scale $scale',
          (tester) async {
        for (final width in [48.0, 92.0, 220.0]) {
          var retries = 0;
          await tester.pumpWidget(_host(
              NoteSaveStatus(
                  status: AutosaveStatus.failed, onRetry: () => retries++),
              width: width,
              scale: scale,
              locale: locale));
          await tester.pumpAndSettle();
          final button = find.byKey(const ValueKey('editor-retry-save'));
          final size = tester.getSize(button);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.width, lessThanOrEqualTo(width));
          expect(size.height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          await tester.tap(button);
          expect(retries, 1);
        }
      });
    }
  }

  testWidgets('retry stays disabled while saving', (tester) async {
    var retries = 0;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(NoteSaveStatus(
        status: AutosaveStatus.failed,
        retrying: true,
        onRetry: () => retries++,
      )));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('editor-retry-save'));
      expect(find.text('Saving…'), findsOneWidget);
      expect(tester.getSemantics(button).getSemanticsData().label, 'Saving…');
      expect(tester.getSemantics(button).flagsCollection.isEnabled,
          Tristate.isFalse);
      await tester.tap(button);
      expect(retries, 0);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('retry does not dismiss the keyboard or move the cursor',
      (tester) async {
    final focus = FocusNode();
    final controller = TextEditingController(text: 'Keep writing');
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: Column(children: [
          TextField(
            focusNode: focus,
            controller: controller,
            onTapOutside: (_) => focus.unfocus(),
          ),
          NoteSaveStatus(
              status: AutosaveStatus.failed, onRetry: () => retries++),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editor-retry-save')));
    await tester.pump();
    expect(retries, 1);
    expect(focus.hasFocus, isTrue);
    expect(controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4));
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
