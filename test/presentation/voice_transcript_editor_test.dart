import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_player.dart';

Finder _input() => find.byKey(const ValueKey('voice-transcript-editor-input'));

Future<void> _open(
  WidgetTester tester, {
  required String initial,
  TextSelection? selection,
  required ValueChanged<String?> onClosed,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(platform: TargetPlatform.macOS),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onClosed(await showVoiceTranscriptEditor(
            context,
            initial: initial,
            selection: selection,
          )),
          child: const Text('Edit transcript'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit transcript'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search match opens focused and selected before saving edits',
      (tester) async {
    String? result;
    const initial = 'Bring tea and a coat';
    const selection = TextSelection(baseOffset: 6, extentOffset: 9);
    await _open(tester,
        initial: initial,
        selection: selection,
        onClosed: (value) => result = value);
    final field = tester.widget<TextField>(_input());
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller!.text, initial);
    expect(field.controller!.selection, selection);
    expect(editable.focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'Bring coffee and a coat',
      selection: TextSelection.collapsed(offset: 12),
    ));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, S.current.Voice_Save));
    await tester.pumpAndSettle();
    expect(result, 'Bring coffee and a coat');
    expect(_input(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary transcript editing waits for focus and cancels cleanly',
      (tester) async {
    var closed = false;
    String? result = 'not closed';
    await _open(tester, initial: 'Bring tea and a coat', onClosed: (value) {
      closed = true;
      result = value;
    });
    final field = tester.widget<TextField>(_input());
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.autofocus, isFalse);
    expect(editable.focusNode.hasFocus, isFalse);
    expect(field.controller!.text, 'Bring tea and a coat');
    await tester.tap(find.widgetWithText(TextButton, S.current.Voice_Cancel));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
