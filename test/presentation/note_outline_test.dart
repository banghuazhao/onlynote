import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/note_outline_navigation_controller.dart';
import 'package:onlynote/presentation/components/note_outline_preview.dart';
import 'package:onlynote/presentation/components/note_outline_sheet.dart';
import 'package:onlynote/presentation/components/note_search_text.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_outline.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(390, 700),
    double textScale = 1,
    bool disableAnimations = true}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

Future<bool> _jump(WidgetTester tester,
    NoteOutlineNavigationController controller, int offset) async {
  final result = controller.jumpTo(offset);
  await tester.pumpAndSettle();
  return result;
}

Rect _caretRect(WidgetTester tester, Finder field, int offset) {
  final editableFinder =
      find.descendant(of: field, matching: find.byType(EditableText));
  final state = tester.state<EditableTextState>(editableFinder);
  final render = state.renderEditable;
  final rect = render.getLocalRectForCaret(TextPosition(offset: offset));
  return rect.shift(render.localToGlobal(Offset.zero));
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

  testWidgets('outline choice cannot pop the page twice or after cancellation',
      (tester) async {
    const entry = NoteOutlineEntry(text: 'Heading', start: 0, end: 7);
    final results = <NoteOutlineEntry?>[];
    await _pump(
        tester,
        Builder(
            builder: (context) => TextButton(
                  child: const Text('Open outline'),
                  onPressed: () async => results.add(await showNoteOutlineSheet(
                      context: context, entries: [entry])),
                )),
        disableAnimations: false);
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    final choose = tester
        .widget<ListTile>(find.byKey(const ValueKey('note-outline-entry-0')))
        .onTap!;
    choose();
    choose();
    await tester.pumpAndSettle();
    choose();
    expect(results, [entry]);
    expect(results.single, same(entry));
    expect(find.text('Open outline'), findsOneWidget);
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    final cancelled = tester
        .widget<ListTile>(find.byKey(const ValueKey('note-outline-entry-0')))
        .onTap!;
    await tester.tap(find.byTooltip('Close'));
    cancelled();
    await tester.pumpAndSettle();
    cancelled();
    expect(results, [entry, null]);
    expect(find.text('Open outline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'covered outline rejects captured selection and preserves callback previews',
      (tester) async {
    const entry = NoteOutlineEntry(text: 'Heading', start: 0, end: 7);
    final selected = <NoteOutlineEntry>[];
    await _pump(tester,
        NoteOutlineSheet(entries: [entry], onEntrySelected: selected.add));
    final choose = tester
        .widget<ListTile>(find.byKey(const ValueKey('note-outline-entry-0')))
        .onTap!;
    showDialog<void>(
        context: tester.element(find.byType(NoteOutlineSheet)),
        builder: (_) => const AlertDialog(content: Text('Covered')));
    await tester.pumpAndSettle();
    choose();
    expect(selected, isEmpty);
    Navigator.pop(tester.element(find.text('Covered')));
    await tester.pumpAndSettle();
    choose();
    choose();
    expect(selected, [entry, entry]);
    await tester.pumpWidget(const SizedBox.shrink());
    choose();
    expect(selected, [entry, entry]);
    expect(tester.takeException(), isNull);
  });

  test('stale detach cannot remove a newly attached document', () async {
    final controller = NoteOutlineNavigationController();
    addTearDown(controller.dispose);
    final first = Object();
    final second = Object();
    final detach = controller.attach(owner: first, jump: (_) async => false);
    controller.attach(owner: second, jump: (offset) async => offset == 20);
    detach();
    expect(await controller.jumpTo(20), isTrue);
    expect(await controller.jumpTo(-1), isFalse);
    controller.dispose();
    expect(await controller.jumpTo(20), isFalse);
  });

  testWidgets(
      'sheet returns the selected heading and identifies current section',
      (tester) async {
    const entries = [
      NoteOutlineEntry(text: 'Ideas', start: 0, end: 5),
      NoteOutlineEntry(text: 'Next steps', start: 100, end: 110),
    ];
    NoteOutlineEntry? selected;
    await _pump(
        tester,
        Builder(
            builder: (context) => TextButton(
                  onPressed: () async => selected = await showNoteOutlineSheet(
                      context: context, entries: entries, currentOffset: 30),
                  child: const Text('Open outline'),
                )));
    await tester.tap(find.text('Open outline'));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Note_Outline_Current), findsOneWidget);
    expect(
        tester
            .widget<ListTile>(
                find.byKey(const ValueKey('note-outline-entry-0')))
            .selected,
        isTrue);
    await tester.tap(find.byKey(const ValueKey('note-outline-entry-100')));
    await tester.pumpAndSettle();
    expect(selected, same(entries.last));
    expect(find.byType(NoteOutlineSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'editor jump focuses the heading caret without changing composition text',
      (tester) async {
    final body = '${'A paragraph\n' * 40}最後一章\nBody';
    final offset = body.indexOf('最後一章');
    final styles = [
      NoteTextStyleRange(
          start: offset, end: offset + 4, kind: NoteTextStyleKind.heading)
    ];
    final text = SimpleFormattingController(text: body, styles: styles);
    final focus = FocusNode();
    final outline = NoteOutlineNavigationController();
    final scroll = ScrollController();
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    addTearDown(outline.dispose);
    addTearDown(scroll.dispose);
    await _pump(
        tester,
        SingleChildScrollView(
          controller: scroll,
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: NoteBodyEditor(
                controller: text,
                focusNode: focus,
                imagePaths: const [],
                imageLayouts: const [],
                onImageLayoutsChanged: (_) {},
                onRemoveImage: (_) {},
                outlineController: outline,
              )),
        ));
    text.value = text.value.copyWith(
        selection: const TextSelection.collapsed(offset: 4),
        composing: const TextRange(start: 0, end: 4));
    await tester.pump();
    expect(await _jump(tester, outline, offset), isTrue);
    expect(text.text, body);
    expect(text.styles, styles);
    expect(text.selection, TextSelection.collapsed(offset: offset));
    expect(text.value.composing, TextRange.empty);
    expect(focus.hasFocus, isTrue);
    expect(scroll.offset, greaterThan(0));
    final rect = _caretRect(tester, find.byType(TextField), offset);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(700));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(await outline.jumpTo(offset), isFalse);
  });

  testWidgets('editor jumps inside a later text field below an inline photo',
      (tester) async {
    const prefix = 'First heading\nIntro paragraph\n';
    final body = '$prefix${'Later paragraph\n' * 35}Second heading\nEnd';
    final offset = body.indexOf('Second heading');
    final text = SimpleFormattingController(text: body, styles: [
      const NoteTextStyleRange(
          start: 0, end: 13, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(
          start: offset, end: offset + 14, kind: NoteTextStyleKind.heading),
    ]);
    final focus = FocusNode();
    final outline = NoteOutlineNavigationController();
    var layoutWrites = 0;
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    addTearDown(outline.dispose);
    await _pump(
        tester,
        SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: NoteBodyEditor(
            controller: text,
            focusNode: focus,
            imagePaths: const ['photo'],
            imageLayouts: [
              NoteImageLayout(path: 'photo', textOffset: prefix.length)
            ],
            onImageLayoutsChanged: (_) => layoutWrites++,
            onRemoveImage: (_) {},
            imageBuilder: (_, __) => const ColoredBox(color: Colors.blue),
            outlineController: outline,
          ),
        )),
        textScale: 1.5);
    expect(await _jump(tester, outline, offset), isTrue);
    final field = find.byKey(const ValueKey('note-body-end'));
    final native = tester.widget<TextField>(field);
    expect(native.focusNode!.hasFocus, isTrue);
    expect(native.controller!.selection.extentOffset, offset - prefix.length);
    expect(text.selection.extentOffset, offset);
    expect(text.text, body);
    expect(layoutWrites, 0);
    final rect = _caretRect(tester, field, offset - prefix.length);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(700));
    expect(tester.takeException(), isNull);
  });

  for (final searchActive in [false, true]) {
    testWidgets(
        'reader reveals exact wrapped heading below photos (find: $searchActive)',
        (tester) async {
      const prefix = 'First heading\nIntro\n';
      final body = '$prefix${'長い本文の段落、さらに説明。\n' * 35}Second heading\nEnd';
      final offset = body.indexOf('Second heading');
      final outline = NoteOutlineNavigationController();
      final search = NoteSearchController()
        ..setFields([NoteSearchField('body', body)])
        ..setQuery(searchActive ? 'heading' : '');
      final scroll = ScrollController();
      addTearDown(outline.dispose);
      addTearDown(search.dispose);
      addTearDown(scroll.dispose);
      await _pump(
          tester,
          SingleChildScrollView(
            controller: scroll,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: NoteDocumentView(
                  text: body,
                  styles: [
                    NoteTextStyleRange(
                        start: offset,
                        end: offset + 14,
                        kind: NoteTextStyleKind.heading)
                  ],
                  style: const TextStyle(fontSize: 17, height: 1.5),
                  imagePaths: const ['photo'],
                  imageLayouts: [
                    NoteImageLayout(path: 'photo', textOffset: prefix.length)
                  ],
                  imageBuilder: (_, __) => const ColoredBox(color: Colors.blue),
                  outlineController: outline,
                  textBuilder: searchActive
                      ? (text, styles, start, end) => NoteSearchText(
                          controller: search,
                          fieldId: 'body',
                          text: text,
                          textOffset: start,
                          styles: styles,
                          style: const TextStyle(fontSize: 17, height: 1.5))
                      : null,
                )),
          ),
          size: const Size(320, 700),
          textScale: 2);
      expect(await _jump(tester, outline, offset), isTrue);
      expect(scroll.offset, greaterThan(0));
      final rendered = searchActive
          ? tester.renderObject<RenderParagraph>(find
              .byWidgetPredicate((widget) =>
                  widget is RichText &&
                  widget.text.toPlainText().startsWith('長い本文'))
              .last)
          : tester
              .state<EditableTextState>(find.byType(EditableText).last)
              .renderEditable;
      final localOffset = offset - prefix.length;
      final Rect rect;
      if (rendered is RenderEditable) {
        rect = rendered.getLocalRectForCaret(TextPosition(offset: localOffset));
      } else {
        rect = (rendered as RenderParagraph)
            .getBoxesForSelection(TextSelection(
                baseOffset: localOffset, extentOffset: localOffset + 1))
            .first
            .toRect();
      }
      final global =
          rect.shift((rendered as RenderBox).localToGlobal(Offset.zero));
      expect(global.top, greaterThanOrEqualTo(0));
      expect(global.bottom, lessThanOrEqualTo(700));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('outline preview handles narrow large Chinese text and selection',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(noteOutlineLargeTextPreview());
    await tester.pumpAndSettle();
    final last = find.byKey(const ValueKey('note-outline-entry-400'));
    await tester.ensureVisible(last);
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(last).selected, isTrue);
    expect(find.text(S.current.Note_Outline_Current), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
