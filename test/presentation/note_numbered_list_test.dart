import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';

void _nativeValue(SimpleFormattingController controller, String text,
    {int? cursor, TextRange composing = TextRange.empty}) {
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor ?? text.length),
    composing: composing,
  );
}

Future<void> _pumpEditor(
    WidgetTester tester, SimpleFormattingController controller,
    {UndoHistoryController? undoController}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: TextField(
        controller: controller,
        undoController: undoController,
        maxLines: null,
      ),
    ),
  ));
  await tester.showKeyboard(find.byType(TextField));
  await tester.pump();
}

Future<void> _return(WidgetTester tester) async {
  // A real engine inserts the newline before delivering the newline action.
  // sendKeyEvent only reaches the framework, so emulate the native editing
  // update through TextInput rather than bypassing EditableText's input path.
  final before =
      tester.widget<TextField>(find.byType(TextField)).controller!.value;
  final selection = before.selection;
  tester.testTextInput.updateEditingValue(TextEditingValue(
    text: before.text.replaceRange(selection.start, selection.end, '\n'),
    selection: TextSelection.collapsed(offset: selection.start + 1),
  ));
  await tester.testTextInput.receiveAction(TextInputAction.newline);
  await tester.pump();
}

Future<void> _undoShortcut(WidgetTester tester, {bool redo = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (redo) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
  if (redo) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pump();
}

void main() {
  testWidgets('typed marker and native Return continue then exit the list',
      (tester) async {
    final controller = SimpleFormattingController();
    addTearDown(controller.dispose);
    await _pumpEditor(tester, controller);
    for (final text in ['1', '1.', '1. ', '1. Tea']) {
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ));
      await tester.pump();
      expect(controller.text, text);
    }
    await _return(tester);
    expect(controller.text, '1. Tea\n2. ');
    expect(controller.selection.extentOffset, 10);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '1. Tea\n2. Milk',
      selection: TextSelection.collapsed(offset: 14),
    ));
    await tester.pump();
    await _return(tester);
    expect(controller.text, '1. Tea\n2. Milk\n3. ');
    await _return(tester);
    expect(controller.text, '1. Tea\n2. Milk\n');
    expect(controller.selection.extentOffset, 15);
    await _return(tester);
    expect(controller.text, '1. Tea\n2. Milk\n\n');
    expect(tester.takeException(), isNull);
  });

  testWidgets('native Return splits an item without cutting an emoji',
      (tester) async {
    const before = '1. 👩‍💻ébread';
    final controller = SimpleFormattingController(text: before);
    addTearDown(controller.dispose);
    await _pumpEditor(tester, controller);
    controller.selection = const TextSelection.collapsed(offset: 10);
    await tester.pump();
    await _return(tester);
    expect(controller.text, '1. 👩‍💻é\n2. bread');
    expect(controller.selection.extentOffset, 14);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native undo and redo restore the numbered edit and its styles',
      (tester) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      const before = '1. Milkbread';
      const initialStyles = [
        NoteTextStyleRange(start: 0, end: 12, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(start: 0, end: 12, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(
            start: 3, end: 12, kind: NoteTextStyleKind.highlight),
      ];
      final controller =
          SimpleFormattingController(text: before, styles: initialStyles);
      final history = UndoHistoryController();
      addTearDown(controller.dispose);
      addTearDown(history.dispose);
      await _pumpEditor(tester, controller, undoController: history);
      controller.selection = const TextSelection.collapsed(offset: 7);
      await tester.pump(const Duration(seconds: 1));
      await _return(tester);
      const after = '1. Milk\n2. bread';
      expect(controller.text, after);
      final splitStyles = controller.styles;
      expect(splitStyles, const [
        NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(start: 3, end: 7, kind: NoteTextStyleKind.highlight),
        NoteTextStyleRange(
            start: 11, end: 16, kind: NoteTextStyleKind.highlight),
      ]);
      await tester.pump(const Duration(seconds: 1));
      expect(history.value.canUndo, isTrue);
      await _undoShortcut(tester);
      expect(controller.text, before);
      expect(controller.styles, const [
        NoteTextStyleRange(start: 0, end: 12, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(start: 0, end: 12, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(
            start: 3, end: 12, kind: NoteTextStyleKind.highlight),
      ]);
      await _undoShortcut(tester, redo: true);
      expect(controller.text, after);
      expect(controller.styles, splitStyles);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  test('native composition and its commit never rewrite list text or range',
      () {
    final controller = SimpleFormattingController(text: '1. ');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 3);
    const composing = TextEditingValue(
      text: '1. 茶\n',
      selection: TextSelection.collapsed(offset: 5),
      composing: TextRange(start: 3, end: 5),
    );
    controller.value = composing;
    expect(controller.value, composing);
    final committed = composing.copyWith(composing: TextRange.empty);
    controller.value = committed;
    expect(controller.value, committed);
    _nativeValue(controller, '1. 茶\nbody');
    expect(controller.text, '1. 茶\nbody');
  });

  test('paste and ordinary numbers stay literal without automatic rewriting',
      () {
    final controller = SimpleFormattingController(text: '1. Tea');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 6);
    const pasted = '1. Tea\n2. Milk\n9. Bread';
    _nativeValue(controller, pasted);
    expect(controller.text, pasted);
    _nativeValue(controller, '$pasted\n');
    expect(controller.text, '$pasted\n10. ');
    for (final ordinary in ['1.5 litres', '1.', '01. Tea', 'Plan 1. Tea']) {
      controller.setDocument(ordinary, []);
      controller.selection = TextSelection.collapsed(offset: ordinary.length);
      _nativeValue(controller, '$ordinary\n');
      expect(controller.text, '$ordinary\n', reason: ordinary);
    }
  });

  test('Return inside a marker or replacing a selection leaves text literal',
      () {
    final controller = SimpleFormattingController(text: '1. Tea');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 1);
    _nativeValue(controller, '1\n. Tea', cursor: 2);
    expect(controller.text, '1\n. Tea');
    controller.setDocument('1. Tea', []);
    controller.selection = const TextSelection(baseOffset: 3, extentOffset: 6);
    _nativeValue(controller, '1. \n', cursor: 4);
    expect(controller.text, '1. \n');
  });

  test('segment Return uses the native caret before repeated separators', () {
    const before = '1. Tea\n1. Tea\nAfter';
    final controller = SimpleFormattingController(text: before, styles: const [
      NoteTextStyleRange(start: 7, end: 13, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 14, end: 19, kind: NoteTextStyleKind.highlight),
    ]);
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 6);
    controller.applySegmentValue(
      const TextEditingValue(
        text: '1. Tea\n\n1. Tea\nAfter',
        selection: TextSelection.collapsed(offset: 7),
      ),
      editedPartStart: 0,
      editedPartEnd: 6,
    );
    expect(controller.text, '1. Tea\n2. \n1. Tea\nAfter');
    expect(controller.selection.extentOffset, 10);
    expect(controller.styles, const [
      NoteTextStyleRange(start: 11, end: 17, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 18, end: 23, kind: NoteTextStyleKind.highlight),
    ]);
    controller.applySegmentValue(
      const TextEditingValue(
        text: before,
        selection: TextSelection.collapsed(offset: 6),
      ),
      editedPartStart: 0,
      editedPartEnd: 10,
    );
    expect(controller.styles, const [
      NoteTextStyleRange(start: 7, end: 13, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 14, end: 19, kind: NoteTextStyleKind.highlight),
    ]);
    controller.applySegmentValue(
      const TextEditingValue(
        text: '1. Tea\n2. \n1. Tea\nAfter',
        selection: TextSelection.collapsed(offset: 10),
      ),
      editedPartStart: 0,
      editedPartEnd: 6,
    );
    expect(controller.styles, const [
      NoteTextStyleRange(start: 11, end: 17, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 18, end: 23, kind: NoteTextStyleKind.highlight),
    ]);
  });

  test('empty first item exits and native text undo restores the marker', () {
    final controller = SimpleFormattingController(text: '1. ');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 3);
    _nativeValue(controller, '1. \n');
    expect(controller.text, '');
    expect(controller.selection.extentOffset, 0);
    _nativeValue(controller, '1. ');
    expect(controller.text, '1. ');
    _nativeValue(controller, '');
    expect(controller.text, '');
  });
}
