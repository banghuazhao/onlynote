import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_selection_menu.dart';
import 'package:onlynote/services/note_selection.dart';

Future<EditableTextState> _showMenu(
  WidgetTester tester, {
  required TextEditingController controller,
  required ValueChanged<NoteTextSelection> onCopySelection,
}) async {
  final originalValue = controller.value;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: TextField(
        controller: controller,
        autofocus: true,
        contextMenuBuilder: (context, state) => buildNoteSelectionContextMenu(
          context,
          state,
          textStyles: const [
            NoteTextStyleRange(start: 7, end: 13, kind: NoteTextStyleKind.bold),
          ],
          onCopySelection: onCopySelection,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  // Focus with a real gesture so Flutter creates its selection overlay. An
  // already valid selection combined with autofocus does not create one.
  await tester.longPress(find.byType(TextField));
  await tester.pumpAndSettle();
  controller.value = originalValue;
  await tester.pump();
  final state = tester.state<EditableTextState>(find.byType(EditableText));
  state.hideToolbar(false);
  expect(state.showToolbar(), isTrue);
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('custom item retains native actions and captures before blur',
      (tester) async {
    final controller = TextEditingController.fromValue(const TextEditingValue(
      text: 'Before styled after',
      selection: TextSelection(baseOffset: 7, extentOffset: 13),
    ));
    addTearDown(controller.dispose);
    final results = <NoteTextSelection>[];
    final state = await _showMenu(tester, controller: controller,
        onCopySelection: (snapshot) {
      controller.clear();
      results.add(snapshot);
    });
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
        find.byType(AdaptiveTextSelectionToolbar));
    final items = toolbar.buttonItems!;
    expect(items.map((item) => item.type),
        containsAll(state.contextMenuButtonItems.map((item) => item.type)));
    final action = items.singleWhere((item) => item.label == 'Copy to note');
    action.onPressed!();
    await tester.pumpAndSettle();
    expect(results.single.text, 'styled');
    expect(results.single.textStyles, const [
      NoteTextStyleRange(start: 0, end: 6, kind: NoteTextStyleKind.bold),
    ]);
    expect(controller.text, isEmpty);
  });

  testWidgets('active composition hides copy-to-note action', (tester) async {
    final controller = TextEditingController.fromValue(const TextEditingValue(
      text: 'Before styled after',
      selection: TextSelection(baseOffset: 7, extentOffset: 13),
      composing: TextRange(start: 7, end: 13),
    ));
    addTearDown(controller.dispose);
    await _showMenu(tester,
        controller: controller,
        onCopySelection: (_) => fail('Unexpected copy'));
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
        find.byType(AdaptiveTextSelectionToolbar));
    expect(toolbar.buttonItems!.where((item) => item.label == 'Copy to note'),
        isEmpty);
  });

  testWidgets('collapsed and whitespace selections hide copy-to-note action',
      (tester) async {
    for (final value in const [
      TextEditingValue(
        text: 'Before styled after',
        selection: TextSelection.collapsed(offset: 3),
      ),
      TextEditingValue(
        text: 'Before   styled after',
        selection: TextSelection(baseOffset: 6, extentOffset: 9),
      ),
    ]) {
      final controller = TextEditingController.fromValue(value);
      await _showMenu(tester,
          controller: controller,
          onCopySelection: (_) => fail('Unexpected copy'));
      final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
          find.byType(AdaptiveTextSelectionToolbar));
      expect(toolbar.buttonItems!.where((item) => item.label == 'Copy to note'),
          isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets('reader selection clips formatting from its local text slice',
      (tester) async {
    final results = <NoteTextSelection>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FormattedNoteText(
          text: 'Before styled after',
          styles: const [
            NoteTextStyleRange(
                start: 7, end: 13, kind: NoteTextStyleKind.highlight),
          ],
          onCopySelection: results.add,
        ),
      ),
    ));
    await tester.tap(find.byType(SelectableText));
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.selection =
        const TextSelection(baseOffset: 8, extentOffset: 12);
    await tester.pump();
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await tester.pumpAndSettle();
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
        find.byType(AdaptiveTextSelectionToolbar));
    toolbar.buttonItems!
        .singleWhere((item) => item.label == 'Copy to note')
        .onPressed!();
    await tester.pumpAndSettle();
    expect(results.single.text, 'tyle');
    expect(results.single.textStyles, const [
      NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.highlight),
    ]);
  });
}
