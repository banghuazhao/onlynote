import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';

NoteTextStyleRange bold(int start, int end) => NoteTextStyleRange(
      start: start,
      end: end,
      kind: NoteTextStyleKind.bold,
    );
NoteTextStyleRange heading(int start, int end) => NoteTextStyleRange(
      start: start,
      end: end,
      kind: NoteTextStyleKind.heading,
    );

void typeValue(SimpleFormattingController controller, String text, int cursor) {
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor),
  );
}

void main() {
  test('selection bold toggles preserve text and directional selection', () {
    final controller =
        SimpleFormattingController(text: 'abcd', styles: [bold(0, 4)]);
    addTearDown(controller.dispose);
    const selection =
        TextSelection(baseOffset: 3, extentOffset: 1, isDirectional: true);
    controller.selection = selection;
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.toggleBold();
    expect(controller.text, 'abcd');
    expect(controller.selection, selection);
    expect(controller.styles, [bold(0, 1), bold(3, 4)]);
    expect(controller.isBold, isFalse);
    expect(notifications, 1);
    controller.toggleBold();
    expect(controller.styles, [bold(0, 4)]);
  });

  test(
      'bold before initial body focus survives native selection initialization',
      () {
    final controller = SimpleFormattingController();
    addTearDown(controller.dispose);
    controller.toggleBold();
    expect(controller.styles, isEmpty);
    controller.selection = const TextSelection.collapsed(offset: 0);
    expect(controller.isBold, isTrue);
    typeValue(controller, '你好', 2);
    expect(controller.styles, [bold(0, 2)]);
    controller.toggleBold();
    typeValue(controller, '你好 body', 7);
    expect(controller.styles, [bold(0, 2)]);
  });

  test('moving to another paragraph resets temporary typing mode', () {
    final controller = SimpleFormattingController(text: 'one\ntwo');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 3);
    controller.toggleBold();
    controller.selection = const TextSelection.collapsed(offset: 7);
    expect(controller.isBold, isFalse);
    typeValue(controller, 'one\ntwo!', 8);
    expect(controller.styles, isEmpty);
  });

  test('empty heading formats future typing and Return exits the heading', () {
    final controller = SimpleFormattingController();
    addTearDown(controller.dispose);
    controller.toggleHeading();
    controller.selection = const TextSelection.collapsed(offset: 0);
    expect(controller.isHeading, isTrue);
    typeValue(controller, 'Title', 5);
    expect(controller.styles, [heading(0, 5)]);
    typeValue(controller, 'Title\n', 6);
    expect(controller.isHeading, isFalse);
    typeValue(controller, 'Title\nbody', 10);
    expect(controller.styles, [heading(0, 5)]);
  });

  test('heading operates on current or selected paragraphs excluding next line',
      () {
    final controller = SimpleFormattingController(text: 'one\ntwo\nthree');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 8);
    controller.toggleHeading();
    expect(controller.styles, [heading(0, 3), heading(4, 7)]);
    controller.toggleHeading();
    expect(controller.styles, isEmpty);
  });

  test('bullets normalize mixed selected lines and retain selected content',
      () {
    final controller = SimpleFormattingController(text: 'one\n• two\nthree');
    addTearDown(controller.dispose);
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    controller.toggleBullets();
    expect(controller.text, '• one\n• two\n• three');
    expect(controller.isBulleted, isTrue);
    expect(controller.selection.baseOffset, 2);
    expect(controller.selection.extentOffset, controller.text.length);
    controller.toggleBullets();
    expect(controller.text, 'one\ntwo\nthree');
    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, controller.text.length);
  });

  test('bullet prefix edits move existing body formatting', () {
    final controller = SimpleFormattingController(
      text: 'one\ntwo',
      styles: [bold(0, 3), heading(4, 7)],
    );
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    controller.toggleBullets();
    expect(controller.text, '• one\n• two');
    expect(controller.styles, [bold(2, 5), heading(6, 11)]);
    controller.toggleBullets();
    expect(controller.styles, [bold(0, 3), heading(4, 7)]);
  });

  test('Return continues bullets and Return on an empty bullet exits the list',
      () {
    final controller = SimpleFormattingController(text: '• milk');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 6);
    typeValue(controller, '• milk\n', 7);
    expect(controller.text, '• milk\n• ');
    expect(controller.selection.extentOffset, 9);
    typeValue(controller, '• milk\n• \n', 10);
    expect(controller.text, '• milk\n');
    expect(controller.selection.extentOffset, 7);
    expect(controller.isBulleted, isFalse);
  });

  test('pasted multiline text is retained without automatic bullet insertion',
      () {
    final controller = SimpleFormattingController(text: '• milk');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 6);
    typeValue(controller, '• milk\nbread\neggs', 17);
    expect(controller.text, '• milk\nbread\neggs');
  });

  test('composition text and range are never rewritten by controls', () {
    final controller =
        SimpleFormattingController(text: '你好', styles: [bold(0, 2)]);
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 2);
    const composed = TextEditingValue(
      text: '你好世',
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 2, end: 3),
    );
    controller.value = composed;
    controller.toggleBullets();
    controller.toggleHeading();
    controller.toggleBold();
    expect(controller.value, composed);
    expect(controller.styles, [bold(0, 3)]);
  });

  test('setDocument resets typing modes and inserts appendages as plain text',
      () {
    final controller =
        SimpleFormattingController(text: 'bold', styles: [bold(0, 4)]);
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 4);
    controller.toggleBold();
    controller.setDocument('bold OCR', controller.styles);
    controller.selection = const TextSelection.collapsed(offset: 8);
    expect(controller.styles, [bold(0, 4)]);
    expect(controller.isBold, isFalse);
    controller.setDocument('😀', [bold(1, 2)]);
    expect(controller.styles, [bold(0, 2)]);
  });

  test('identical document replacements notify their new revision', () {
    final controller =
        SimpleFormattingController(text: 'body', styles: [bold(0, 4)]);
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 4);
    final revisions = <int>[];
    controller.addListener(() => revisions.add(controller.documentRevision));
    controller.setDocument('body', [bold(0, 4)]);
    controller.setDocument('body', [bold(0, 4)]);
    expect(revisions, [1, 2]);
    typeValue(controller, 'body!', 5);
    expect(revisions, [1, 2, 2]);
    expect(controller.styles, [bold(0, 5)]);
  });

  test('segment edits move styles on repeated text and retain native undo', () {
    final controller =
        SimpleFormattingController(text: 'A\nA\n', styles: [bold(2, 3)]);
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 1);
    controller.applySegmentValue(
      const TextEditingValue(
          text: 'A\nA\nA\n', selection: TextSelection.collapsed(offset: 3)),
      editedPartStart: 0,
      editedPartEnd: 1,
    );
    expect(controller.styles, [bold(4, 5)]);
    expect(controller.selection.extentOffset, 3);
    controller.applySegmentValue(
      const TextEditingValue(
          text: 'A\nA\n', selection: TextSelection.collapsed(offset: 1)),
      editedPartStart: 0,
      editedPartEnd: 3,
    );
    expect(controller.styles, [bold(2, 3)]);
    controller.applySegmentValue(
      const TextEditingValue(
          text: 'A\nA\nA\n', selection: TextSelection.collapsed(offset: 3)),
      editedPartStart: 0,
      editedPartEnd: 1,
    );
    expect(controller.styles, [bold(4, 5)]);
  });

  test('segment typing preserves pending bold and native composition', () {
    final controller = SimpleFormattingController(text: 'A\nA');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 1);
    controller.toggleBold();
    const composed = TextEditingValue(
      text: 'A👩‍💻\nA',
      selection: TextSelection.collapsed(offset: 6),
      composing: TextRange(start: 1, end: 6),
    );
    controller.applySegmentValue(composed,
        editedPartStart: 0, editedPartEnd: 1);
    expect(controller.value, composed);
    expect(controller.styles, [bold(1, 6)]);
  });

  test('Return before a structural separator exits heading and continues list',
      () {
    final headingController = SimpleFormattingController(
        text: 'Title\nAfter', styles: [heading(0, 5), bold(6, 11)]);
    addTearDown(headingController.dispose);
    headingController.selection = const TextSelection.collapsed(offset: 5);
    headingController.applySegmentValue(
      const TextEditingValue(
          text: 'Title\n\nAfter',
          selection: TextSelection.collapsed(offset: 6)),
      editedPartStart: 0,
      editedPartEnd: 5,
    );
    expect(headingController.styles, [heading(0, 5), bold(7, 12)]);
    expect(headingController.isHeading, isFalse);

    final bulletController = SimpleFormattingController(
        text: '• milk\nAfter', styles: [bold(7, 12)]);
    addTearDown(bulletController.dispose);
    bulletController.selection = const TextSelection.collapsed(offset: 6);
    bulletController.applySegmentValue(
      const TextEditingValue(
          text: '• milk\n\nAfter',
          selection: TextSelection.collapsed(offset: 7)),
      editedPartStart: 0,
      editedPartEnd: 6,
    );
    expect(bulletController.text, '• milk\n• \nAfter');
    expect(bulletController.selection.extentOffset, 9);
    expect(bulletController.styles, [bold(10, 15)]);
  });

  test('native text undo and redo restore their companion style snapshots', () {
    final controller =
        SimpleFormattingController(text: 'word', styles: [bold(0, 4)]);
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 4);
    typeValue(controller, '', 0);
    expect(controller.styles, isEmpty);
    typeValue(controller, 'word', 4);
    expect(controller.styles, [bold(0, 4)]);
    typeValue(controller, '', 0);
    expect(controller.styles, isEmpty);
  });

  test('grouped native undo preserves styles and explicit new typing wins', () {
    final controller = SimpleFormattingController();
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 0);
    controller.toggleBold();
    typeValue(controller, 'a', 1);
    typeValue(controller, 'ab', 2);
    typeValue(controller, 'abc', 3);
    controller.toggleBold();
    expect(controller.isBold, isFalse);
    typeValue(controller, '', 0);
    expect(controller.styles, isEmpty);
    typeValue(controller, 'abc', 3);
    expect(controller.styles, [bold(0, 3)]);

    controller.setDocument('ab', []);
    controller.selection = const TextSelection.collapsed(offset: 2);
    typeValue(controller, 'abc', 3);
    typeValue(controller, 'ab', 2);
    controller.toggleBold();
    typeValue(controller, 'abc', 3);
    expect(controller.styles, [bold(2, 3)]);
  });
}
