import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/components/note_outline_navigation_controller.dart';
import 'package:onlynote/presentation/components/note_selection_menu.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_checklist.dart';

Future<EditableTextState> _menu(
  WidgetTester tester,
  TextEditingController controller, {
  ValueChanged<NoteTextSelection>? onCopy,
  ValueChanged<NoteTextSelection>? onChecklist,
}) async {
  final original = controller.value;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: TextField(
        controller: controller,
        maxLines: 5,
        contextMenuBuilder: (context, state) => buildNoteSelectionContextMenu(
          context,
          state,
          onCopySelection: onCopy,
          onAddSelectionToChecklist: onChecklist,
        ),
      ),
    ),
  ));
  await tester.longPress(find.byType(TextField));
  await tester.pumpAndSettle();
  controller.value = original;
  await tester.pump();
  final state = tester.state<EditableTextState>(find.byType(EditableText));
  state.hideToolbar(false);
  expect(state.showToolbar(), isTrue);
  await tester.pumpAndSettle();
  return state;
}

AdaptiveTextSelectionToolbar _toolbar(WidgetTester tester) =>
    tester.widget<AdaptiveTextSelectionToolbar>(
        find.byType(AdaptiveTextSelectionToolbar));

Future<void> _pumpBody(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [S.delegate],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('native checklist action retains copy and native menu actions',
      (tester) async {
    const text = '• Coffee\n2. Tea';
    final controller = TextEditingController.fromValue(const TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    ));
    addTearDown(controller.dispose);
    final copied = <NoteTextSelection>[];
    final added = <NoteTextSelection>[];
    final state = await _menu(tester, controller,
        onCopy: copied.add, onChecklist: added.add);
    final items = _toolbar(tester).buttonItems!;
    expect(items.map((item) => item.type),
        containsAll(state.contextMenuButtonItems.map((item) => item.type)));
    expect(items.where((item) => item.label == 'Copy to note'), hasLength(1));
    items.singleWhere((item) => item.label == 'Add to checklist').onPressed!();
    await tester.pumpAndSettle();
    expect(added.single.text, text);
    expect(parseNoteSelectionChecklist(added.single.text).titles,
        ['Coffee', 'Tea']);
    expect(copied, isEmpty);
    expect(controller.text, text);
  });

  testWidgets(
      'checklist-only callback works and snapshots before callback blur',
      (tester) async {
    const text = 'Coffee\nTea';
    final controller = TextEditingController.fromValue(const TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    ));
    addTearDown(controller.dispose);
    final added = <NoteTextSelection>[];
    await _menu(tester, controller, onChecklist: (snapshot) {
      controller.clear();
      added.add(snapshot);
    });
    expect(
        _toolbar(tester)
            .buttonItems!
            .where((item) => item.label == 'Copy to note'),
        isEmpty);
    _toolbar(tester)
        .buttonItems!
        .singleWhere((item) => item.label == 'Add to checklist')
        .onPressed!();
    await tester.pumpAndSettle();
    expect(added.single.text, text);
  });

  testWidgets(
      'empty marker-only and composing selections hide checklist action',
      (tester) async {
    for (final value in const [
      TextEditingValue(
          text: 'Coffee', selection: TextSelection.collapsed(offset: 1)),
      TextEditingValue(
          text: '•\n- [ ]',
          selection: TextSelection(baseOffset: 0, extentOffset: 7)),
      TextEditingValue(
        text: 'Coffee\nTea',
        selection: TextSelection(baseOffset: 0, extentOffset: 10),
        composing: TextRange(start: 0, end: 6),
      ),
    ]) {
      final controller = TextEditingController.fromValue(value);
      await _menu(tester, controller,
          onChecklist: (_) => fail('Unexpected checklist action'));
      expect(
          _toolbar(tester)
              .buttonItems!
              .where((item) => item.label == 'Add to checklist'),
          isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets('oversized selection reaches callback for localized rejection',
      (tester) async {
    final text = 'Coffee\n${'😀' * 51}';
    final controller = TextEditingController.fromValue(TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    ));
    addTearDown(controller.dispose);
    final added = <NoteTextSelection>[];
    await _menu(tester, controller, onChecklist: added.add);
    _toolbar(tester)
        .buttonItems!
        .singleWhere((item) => item.label == 'Add to checklist')
        .onPressed!();
    await tester.pumpAndSettle();
    expect(parseNoteSelectionChecklist(added.single.text).status,
        NoteSelectionChecklistStatus.tooLong);
    expect(controller.text, text);
  });

  testWidgets(
      'reader checklist callback captures its formatted local selection',
      (tester) async {
    const text = '• Coffee\n2. Tea';
    final added = <NoteTextSelection>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FormattedNoteText(
          text: text,
          styles: const [
            NoteTextStyleRange(start: 2, end: 8, kind: NoteTextStyleKind.bold),
          ],
          onAddSelectionToChecklist: added.add,
        ),
      ),
    ));
    await tester.tap(find.byType(SelectableText));
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.selection =
        const TextSelection(baseOffset: 0, extentOffset: text.length);
    await tester.pump();
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await tester.pumpAndSettle();
    _toolbar(tester)
        .buttonItems!
        .singleWhere((item) => item.label == 'Add to checklist')
        .onPressed!();
    await tester.pumpAndSettle();
    expect(added.single.text, text);
    expect(added.single.textStyles, const [
      NoteTextStyleRange(start: 2, end: 8, kind: NoteTextStyleKind.bold),
    ]);
  });

  testWidgets(
      'inline editor action uses local selection and keeps global styles',
      (tester) async {
    const body = 'Before\n• Coffee\n2. Tea';
    const styles = [
      NoteTextStyleRange(start: 9, end: 15, kind: NoteTextStyleKind.bold),
    ];
    final controller = SimpleFormattingController(text: body, styles: styles);
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    final added = <NoteTextSelection>[];
    await _pumpBody(
      tester,
      NoteBodyEditor(
        controller: controller,
        focusNode: focus,
        imagePaths: const ['photo'],
        imageLayouts: const [NoteImageLayout(path: 'photo', textOffset: 7)],
        imageBuilder: (context, path) => const SizedBox(height: 40),
        onImageLayoutsChanged: (_) {},
        onRemoveImage: (_) {},
        onAddSelectionToChecklist: added.add,
      ),
    );
    final field = find.byKey(const ValueKey('note-body-end'));
    await tester.ensureVisible(field);
    await tester.tap(field);
    final editable =
        find.descendant(of: field, matching: find.byType(EditableText));
    tester.widget<EditableText>(editable).controller.selection =
        const TextSelection(baseOffset: 0, extentOffset: 15);
    await tester.pump();
    tester.state<EditableTextState>(editable).showToolbar();
    await tester.pumpAndSettle();
    _toolbar(tester)
        .buttonItems!
        .singleWhere(
            (item) => item.label == S.current.Add_Selection_To_Checklist)
        .onPressed!();
    await tester.pumpAndSettle();
    expect(added.single.text, '• Coffee\n2. Tea');
    expect(added.single.textStyles, const [
      NoteTextStyleRange(start: 2, end: 8, kind: NoteTextStyleKind.bold),
    ]);
    expect(controller.text, body);
    expect(controller.styles, styles);
  });

  testWidgets('silent editor restore places caret without opening keyboard',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    final focus = FocusNode();
    final navigation = NoteOutlineNavigationController();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    addTearDown(navigation.dispose);
    await _pumpBody(
      tester,
      NoteBodyEditor(
        controller: controller,
        focusNode: focus,
        imagePaths: const [],
        imageLayouts: const [],
        onImageLayoutsChanged: (_) {},
        onRemoveImage: (_) {},
        outlineController: navigation,
      ),
    );
    final restoration = navigation.restoreTo(8);
    await tester.pumpAndSettle();
    expect(await restoration, isTrue);
    expect(controller.selection, const TextSelection.collapsed(offset: 8));
    expect(focus.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(controller.text, 'Before\nAfter');
    final before = controller.value;
    expect(await navigation.restoreTo(0, canRestore: () => false), isFalse);
    expect(controller.value, before);
    controller.value =
        controller.value.copyWith(composing: const TextRange(start: 0, end: 3));
    expect(await navigation.restoreTo(0), isFalse);
    expect(controller.value.composing, const TextRange(start: 0, end: 3));
    controller.clearComposing();
    var canRestore = true;
    final lateRestoration =
        navigation.restoreTo(3, canRestore: () => canRestore);
    canRestore = false;
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pumpAndSettle();
    expect(await lateRestoration, isFalse);
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final focusedValue = controller.value;
    expect(await navigation.restoreTo(0), isFalse);
    expect(controller.value, focusedValue);
  });
}
