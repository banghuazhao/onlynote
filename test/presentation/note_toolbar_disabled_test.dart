import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/editor_writing_previews.dart';
import 'package:onlynote/presentation/components/note_formatting_toolbar.dart';
import 'package:onlynote/presentation/components/note_writing_toolbar.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import '../support/interaction_feedback_capture.dart';

const _buttons = [
  'format-bold',
  'format-heading',
  'format-bullets',
  'format-highlight'
];

Widget _host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!),
    home: child);

void main() {
  setUpAll(loadInteractionFeedbackFonts);
  for (final writingToolbar in [false, true]) {
    testWidgets(
        'blocked ${writingToolbar ? 'writing' : 'formatting'} toolbar retains selection and style',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final controller =
            SimpleFormattingController(text: 'Saved text', styles: const [
          NoteTextStyleRange(start: 0, end: 5, kind: NoteTextStyleKind.bold),
        ]);
        final focus = FocusNode();
        final enabled = ValueNotifier(false);
        var beforeApply = 0;
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        addTearDown(enabled.dispose);
        await tester.pumpWidget(_host(ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (_, value, __) => Scaffold(
            body: TextField(controller: controller, focusNode: focus),
            bottomNavigationBar: writingToolbar
                ? NoteWritingToolbar(
                    controller: controller,
                    focusNode: focus,
                    enabled: value,
                    beforeApply: () => beforeApply++)
                : NoteFormattingToolbar(
                    controller: controller,
                    focusNode: focus,
                    enabled: value,
                    beforeApply: () => beforeApply++),
          ),
        )));
        focus.requestFocus();
        const selection = TextSelection(baseOffset: 0, extentOffset: 5);
        controller.selection = selection;
        await tester.pumpAndSettle();
        final originalStyles = controller.styles.toList();
        Color? disabledColor;
        for (final key in _buttons) {
          final button = find.byKey(ValueKey(key));
          final node = tester.getSemantics(button);
          expect(node.flagsCollection.isEnabled, Tristate.isFalse);
          expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
          final tap = tester.widget<InkWell>(
              find.descendant(of: button, matching: find.byType(InkWell)));
          expect(tap.onTap, isNull);
          await tester.tap(button);
          await tester.pump();
          expect(controller.selection, selection);
          expect(controller.styles, originalStyles);
          expect(controller.text, 'Saved text');
          expect(focus.hasFocus, isTrue);
          disabledColor ??= tester
              .widget<Icon>(
                  find.descendant(of: button, matching: find.byType(Icon)))
              .color;
        }
        expect(beforeApply, 0);
        enabled.value = true;
        await tester.pumpAndSettle();
        final bold = find.byKey(const ValueKey('format-bold'));
        expect(tester.getSemantics(bold).flagsCollection.isEnabled,
            Tristate.isTrue);
        final activeColor = tester
            .widget<Icon>(
                find.descendant(of: bold, matching: find.byType(Icon)))
            .color!;
        expect(disabledColor!.a, lessThan(activeColor.a));
        await tester.tap(bold);
        await tester.pump();
        expect(beforeApply, 1);
        expect(controller.isBold, isFalse);
        expect(controller.selection, selection);
        expect(focus.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
      'blocked writing previews expose disabled controls in every theme',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size, name) in [
      (
        editorWritingBlockedPreview,
        const Size(320, 740),
        'toolbar-blocked-light'
      ),
      (
        editorWritingBlockedDarkPreview,
        const Size(320, 740),
        'toolbar-blocked-dark'
      ),
      (
        editorWritingBlockedChinesePreview,
        const Size(280, 700),
        'toolbar-blocked-chinese'
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(KeyedSubtree(
          key: ValueKey(name),
          child: RepaintBoundary(
              key: interactionFeedbackCaptureKey,
              child: preview(
                  theme:
                      interactionFeedbackTheme(dark: name.contains('dark'))))));
      await tester.pumpAndSettle();
      final toolbar =
          tester.widget<NoteWritingToolbar>(find.byType(NoteWritingToolbar));
      expect(toolbar.enabled, isFalse);
      for (final key in _buttons) {
        final tap = tester.widget<InkWell>(find.descendant(
            of: find.byKey(ValueKey(key)), matching: find.byType(InkWell)));
        expect(tap.onTap, isNull);
      }
      expect(tester.takeException(), isNull);
      await captureInteractionFeedback(tester, name);
    }
  });
}
