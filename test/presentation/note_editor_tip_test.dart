import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/note_editor_tip.dart';
import 'package:onlynote/presentation/theme/theme.dart';

const _message = '點一下照片即可調整大小，長按即可移動照片。';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(320, 640),
  double textScale = 1,
  bool dark = false,
  Locale locale = const Locale('zh', 'HK'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('zh', 'HK')],
    localizationsDelegates: const [
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

void main() {
  for (final width in [180.0, 320.0]) {
    for (final dark in [false, true]) {
      testWidgets('tip wraps at $width with large Chinese text, dark=$dark',
          (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          var dismissed = false;
          await _pump(
            tester,
            SingleChildScrollView(
              child: NoteEditorTip(
                message: _message,
                onDismiss: () => dismissed = true,
              ),
            ),
            size: Size(width, 640),
            textScale: 2,
            dark: dark,
          );

          expect(find.text(_message), findsOneWidget);
          final close = find.byKey(const ValueKey('note-editor-tip-dismiss'));
          expect(tester.getSize(close).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
          final tooltip = MaterialLocalizations.of(tester.element(close))
              .closeButtonTooltip;
          expect(find.byTooltip(tooltip), findsOneWidget);
          final node = tester.getSemantics(close);
          expect(node.flagsCollection.isButton, isTrue);
          // Flutter exposes Tooltip's accessible name in the tooltip field,
          // separately from the button label.
          expect(node.tooltip, contains(tooltip));
          await tester.tap(close);
          await tester.pump();
          expect(dismissed, isTrue);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('dismissal removes the tip immediately and retains writing focus',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var visible = true;
    await _pump(
      tester,
      StatefulBuilder(builder: (context, setState) {
        return Column(
          children: [
            if (visible)
              NoteEditorTip(
                message: 'Use the buttons below to format selected text.',
                onDismiss: () => setState(() => visible = false),
              ),
            TextField(focusNode: focus),
          ],
        );
      }),
      locale: const Locale('en'),
    );
    focus.requestFocus();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('note-editor-tip-dismiss')));
    await tester.pump();

    expect(find.byType(NoteEditorTip), findsNothing);
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });
}
