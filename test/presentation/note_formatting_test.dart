import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_formatting_toolbar.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/theme.dart';

const _bodyStyle = TextStyle(fontSize: 17, height: 1.55, fontFamily: 'Roboto');

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

Future<void> _pumpEditor(
  WidgetTester tester,
  SimpleFormattingController controller,
  FocusNode focusNode, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
}) =>
    _pump(
      tester,
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NoteFormattingToolbar(
                controller: controller,
                focusNode: focusNode,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                style: _bodyStyle,
              ),
            ],
          ),
        ),
      ),
      locale: locale,
      size: size,
      textScale: textScale,
    );

List<TextSpan> _leaves(InlineSpan span) {
  if (span is! TextSpan) return [];
  if (span.children?.isNotEmpty == true) {
    return span.children!.expand(_leaves).toList();
  }
  return [span];
}

void main() {
  testWidgets('bold applies to selection while retaining focus and selection',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = SimpleFormattingController(text: 'Pack snacks');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await _pumpEditor(tester, controller, focusNode);
      focusNode.requestFocus();
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 4);
      await tester.pump();

      final bold = find.byKey(const ValueKey('format-bold'));
      await tester.tap(bold);
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(controller.selection,
          const TextSelection(baseOffset: 0, extentOffset: 4));
      expect(controller.text, 'Pack snacks');
      expect(
          controller.styles.any((range) =>
              range.kind == NoteTextStyleKind.bold &&
              range.start == 0 &&
              range.end == 4),
          isTrue);
      final node = tester.getSemantics(bold);
      expect(node.label, S.current.Format_Bold);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected, Tristate.isTrue);

      await tester.tap(bold);
      await tester.pump();
      expect(controller.styles, isEmpty);
      expect(focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('bold at the cursor styles the next typed text', (tester) async {
    final controller = SimpleFormattingController(text: 'Idea');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(tester, controller, focusNode);
    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 4);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('format-bold')));
    await tester.pump();
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'Idea!',
      selection: TextSelection.collapsed(offset: 5),
    ));
    await tester.pump();

    expect(controller.text, 'Idea!');
    expect(
        controller.styles.any((range) =>
            range.kind == NoteTextStyleKind.bold &&
            range.start == 4 &&
            range.end == 5),
        isTrue);
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('heading works on the current line without selecting text',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Weekend plans\nWalk');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(tester, controller, focusNode);
    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 5);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('format-heading')));
    await tester.pump();

    expect(controller.isHeading, isTrue);
    expect(
        controller.styles.any((range) =>
            range.kind == NoteTextStyleKind.heading &&
            range.start == 0 &&
            range.end == 13),
        isTrue);
    expect(controller.text, 'Weekend plans\nWalk');
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const ValueKey('format-heading')));
    await tester.pump();
    expect(controller.isHeading, isFalse);
    expect(controller.styles, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bullets add and remove a marker without selecting text',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Snacks\nWater');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(tester, controller, focusNode);
    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('format-bullets')));
    await tester.pump();
    expect(controller.text, '• Snacks\nWater');
    expect(controller.isBulleted, isTrue);
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const ValueKey('format-bullets')));
    await tester.pump();
    expect(controller.text, 'Snacks\nWater');
    expect(controller.isBulleted, isFalse);
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader combines styles without changing the readable text',
      (tester) async {
    const text = 'Title\nBody';
    await _pump(
      tester,
      const FormattedNoteText(
        text: text,
        style: _bodyStyle,
        styles: [
          NoteTextStyleRange(start: 0, end: 5, kind: NoteTextStyleKind.heading),
          NoteTextStyleRange(start: 0, end: 5, kind: NoteTextStyleKind.bold),
        ],
      ),
    );
    final reader = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(reader.textSpan!.toPlainText(), text);
    final heading =
        _leaves(reader.textSpan!).firstWhere((span) => span.text == 'Title');
    final headingStyle = reader.textSpan!.style!.merge(heading.style);
    expect(headingStyle.fontWeight, FontWeight.w700);
    expect(headingStyle.fontSize, 19);
    expect(headingStyle.fontFamily, 'Roboto');
    expect(tester.takeException(), isNull);
  });

  testWidgets('export reader retains formatting with no selection controls',
      (tester) async {
    await _pump(
      tester,
      const FormattedNoteText(
        text: 'Readable\n• One item',
        selectable: false,
        style: _bodyStyle,
        styles: [
          NoteTextStyleRange(start: 0, end: 8, kind: NoteTextStyleKind.bold),
        ],
      ),
      dark: true,
    );
    expect(find.byType(SelectableText), findsNothing);
    final reader = tester.widget<Text>(find.byType(Text));
    expect(reader.textSpan!.toPlainText(), 'Readable\n• One item');
    expect(reader.semanticsLabel, 'Readable\n• One item');
    expect(tester.takeException(), isNull);
  });

  testWidgets('three controls fit a narrow screen with large Chinese text',
      (tester) async {
    final controller = SimpleFormattingController(text: '週末計劃\n帶上零食和外套。');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      locale: const Locale('zh', 'HK'),
      size: const Size(320, 640),
      textScale: 2,
    );

    expect(find.byType(Tooltip), findsNWidgets(3));
    expect(find.byTooltip(S.current.Format_Bold), findsOneWidget);
    expect(find.byTooltip(S.current.Format_Heading), findsOneWidget);
    expect(find.byTooltip(S.current.Format_Bullets), findsOneWidget);
    for (final control in ['format-bold', 'format-heading', 'format-bullets']) {
      expect(tester.getSize(find.byKey(ValueKey(control))), const Size(48, 48));
    }
    expect(tester.takeException(), isNull);

    // A window resize can leave much less space than a typical phone. The
    // controls must remain tappable without shrinking their touch targets.
    tester.view.physicalSize = const Size(150, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final bullets = find.byKey(const ValueKey('format-bullets'));
    await tester.ensureVisible(bullets);
    await tester.tap(bullets);
    await tester.pump();
    expect(controller.text, '週末計劃\n• 帶上零食和外套。');
    expect(tester.getSize(bullets), const Size(48, 48));
    expect(tester.takeException(), isNull);
  });
}
