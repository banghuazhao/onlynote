import 'dart:io';
import 'dart:ui' show ImageByteFormat, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/note_outline_navigation_controller.dart';
import 'package:onlynote/presentation/components/note_reader_sections_previews.dart';
import 'package:onlynote/services/note_selection.dart';

NoteTextStyleRange _heading(String text, String heading) => NoteTextStyleRange(
      start: text.indexOf(heading),
      end: text.indexOf(heading) + heading.length,
      kind: NoteTextStyleKind.heading,
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(390, 700), double textScale = 1}) async {
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
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Widget _photo(BuildContext context, String path) =>
    ColoredBox(key: ValueKey('fixture-$path'), color: Colors.blueGrey);

Finder _toggle(int offset) =>
    find.byKey(ValueKey('note-section-toggle-$offset'));

String _visibleText(WidgetTester tester) => tester
    .widgetList<FormattedNoteText>(find.byType(FormattedNoteText))
    .map((widget) => widget.text)
    .join();

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('reader-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await File('/tmp/onlynote-reader-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final family in ['Roboto', 'DroidSansFallback']) {
      final font = FontLoader(family)
        ..addFont(File(
                'assets/fonts/$family${family == 'Roboto' ? '-Regular' : ''}.ttf')
            .readAsBytes()
            .then(ByteData.sublistView));
      await font.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('folding hides section text and photos and keeps its heading',
      (tester) async {
    const text = 'Intro\nFirst\nFirst body\nSecond\nSecond body';
    final styles = [_heading(text, 'First'), _heading(text, 'Second')];
    final layouts = [
      const NoteImageLayout(path: 'intro', textOffset: 0),
      NoteImageLayout(path: 'first', textOffset: text.indexOf('Second')),
    ];
    await _pump(
      tester,
      NoteDocumentView(
        text: text,
        styles: styles,
        imagePaths: const ['intro', 'first'],
        imageLayouts: layouts,
        imageBuilder: _photo,
        style: const TextStyle(fontSize: 17),
        collapsibleSections: true,
      ),
    );
    await tester.tap(_toggle(text.indexOf('First')));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('First body\n'), findsNothing);
    expect(find.text('Second body'), findsOneWidget);
    expect(find.byKey(const ValueKey('fixture-first')), findsNothing);
    expect(find.byKey(const ValueKey('fixture-intro')), findsOneWidget);
    expect(text, 'Intro\nFirst\nFirst body\nSecond\nSecond body');
    expect(styles, [_heading(text, 'First'), _heading(text, 'Second')]);
    expect(layouts.last.textOffset, text.indexOf('Second'));
    await tester.tap(_toggle(text.indexOf('First')));
    await tester.pumpAndSettle();
    expect(find.text('First body\n'), findsOneWidget);
    expect(find.byKey(const ValueKey('fixture-first')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggle has a 48px target and accessible expanded state',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(
        tester,
        NoteDocumentView(
          text: 'Heading\nBody',
          styles: const [
            NoteTextStyleRange(
                start: 0, end: 7, kind: NoteTextStyleKind.heading),
          ],
          style: const TextStyle(fontSize: 17),
          collapsibleSections: true,
          sectionToggleLabel: (heading, expanded) =>
              '${expanded ? 'Collapse' : 'Expand'} section $heading',
        ),
      );
      final state = find.byKey(const ValueKey('note-section-state-0'));
      expect(tester.getSize(_toggle(0)), const Size(48, 48));
      var node = tester.getSemantics(state);
      expect(node.label, 'Collapse section Heading');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isExpanded, Tristate.isTrue);
      await tester.tap(_toggle(0));
      await tester.pumpAndSettle();
      node = tester.getSemantics(state);
      expect(node.label, 'Expand section Heading');
      expect(node.flagsCollection.isExpanded, Tristate.isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('outline opens a folded body and reveals its exact deep offset',
      (tester) async {
    const heading = 'First heading';
    const prefix = '$heading\n';
    final body = '$prefix${'A long wrapped paragraph with more detail.\n' * 40}'
        'Target 👩🏽‍💻 paragraph\nEnd';
    final target = body.indexOf('Target');
    final outline = NoteOutlineNavigationController();
    addTearDown(outline.dispose);
    await _pump(
      tester,
      NoteDocumentView(
        text: body,
        styles: [_heading(body, heading)],
        imagePaths: const ['photo'],
        imageLayouts: const [
          NoteImageLayout(path: 'photo', textOffset: prefix.length),
        ],
        imageBuilder: _photo,
        style: const TextStyle(fontSize: 17, height: 1.5),
        collapsibleSections: true,
        outlineController: outline,
      ),
      textScale: 1.5,
    );
    await tester.tap(_toggle(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fixture-photo')), findsNothing);
    final result = outline.jumpTo(target);
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(find.byKey(const ValueKey('fixture-photo')), findsOneWidget);
    final part = find.byWidgetPredicate((widget) =>
        widget is FormattedNoteText && widget.text.contains('Target'));
    final editable = tester.state<EditableTextState>(
        find.descendant(of: part, matching: find.byType(EditableText)));
    final render = editable.renderEditable;
    final local = render
        .getLocalRectForCaret(TextPosition(offset: target - prefix.length));
    final rect = local.shift(render.localToGlobal(Offset.zero));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabling folding for Find exposes all text and restores folds',
      (tester) async {
    const text = 'Heading\nHidden text';
    var folding = true;
    late StateSetter update;
    await _pump(
      tester,
      StatefulBuilder(builder: (context, setState) {
        update = setState;
        return NoteDocumentView(
          text: text,
          styles: const [
            NoteTextStyleRange(
                start: 0, end: 7, kind: NoteTextStyleKind.heading),
          ],
          style: const TextStyle(fontSize: 17),
          collapsibleSections: folding,
        );
      }),
    );
    await tester.tap(_toggle(0));
    await tester.pumpAndSettle();
    expect(_visibleText(tester), 'Heading');
    update(() => folding = false);
    await tester.pumpAndSettle();
    expect(_visibleText(tester), text);
    expect(_toggle(0), findsNothing);
    update(() => folding = true);
    await tester.pumpAndSettle();
    expect(_visibleText(tester), 'Heading');
    expect(tester.takeException(), isNull);
  });

  testWidgets('part builders receive original offsets and local formatting',
      (tester) async {
    const text = 'Intro\nHeading\n👩🏽‍💻 Body';
    final bodyStart = text.indexOf('👩');
    final records = <(String, List<NoteTextStyleRange>, int, int)>[];
    await _pump(
      tester,
      NoteDocumentView(
        text: text,
        styles: [
          _heading(text, 'Heading'),
          NoteTextStyleRange(
              start: bodyStart, end: text.length, kind: NoteTextStyleKind.bold),
        ],
        collapsibleSections: true,
        textBuilder: (text, styles, start, end) {
          records.add((text, styles, start, end));
          return Text(text);
        },
      ),
    );
    final body = records.lastWhere((record) => record.$1.contains('Body'));
    expect(body.$3, bodyStart);
    expect(body.$4, text.length);
    expect(body.$2.single.start, 0);
    expect(body.$2.single.end, text.length - bodyStart);
    expect(body.$2.single.kind, NoteTextStyleKind.bold);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopened sections retain links and copy local saved formatting',
      (tester) async {
    const text = 'Heading\nBefore 👩🏽‍💻 styled https://example.com';
    final styled = text.indexOf('styled');
    final copied = <NoteTextSelection>[];
    final opened = <Uri>[];
    await _pump(
      tester,
      NoteDocumentView(
        text: text,
        styles: [
          _heading(text, 'Heading'),
          NoteTextStyleRange(
              start: styled,
              end: styled + 'styled'.length,
              kind: NoteTextStyleKind.bold),
        ],
        style: const TextStyle(fontSize: 17),
        collapsibleSections: true,
        onCopySelection: copied.add,
        onOpenUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    await tester.tap(_toggle(0));
    await tester.pumpAndSettle();
    await tester.tap(_toggle(0));
    await tester.pumpAndSettle();
    final part = find.byWidgetPredicate((widget) =>
        widget is FormattedNoteText && widget.text.contains('https://'));
    final editableFinder =
        find.descendant(of: part, matching: find.byType(EditableText));
    final editable = tester.state<EditableTextState>(editableFinder);
    final localText =
        tester.widget<EditableText>(editableFinder).controller.text;
    final urlStart = localText.indexOf('https://');
    final urlBox = editable.renderEditable
        .getBoxesForSelection(
            TextSelection(baseOffset: urlStart, extentOffset: urlStart + 1))
        .first;
    await tester
        .tapAt(editable.renderEditable.localToGlobal(urlBox.toRect().center));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://example.com')]);

    final localStart = localText.indexOf('styled');
    final wordBox = editable.renderEditable
        .getBoxesForSelection(
            TextSelection(baseOffset: localStart, extentOffset: localStart + 1))
        .first;
    await tester.longPressAt(
        editable.renderEditable.localToGlobal(wordBox.toRect().center));
    await tester.pumpAndSettle();
    final native = tester.widget<EditableText>(editableFinder);
    native.controller.selection = TextSelection(
        baseOffset: localStart, extentOffset: localStart + 'styled'.length);
    await tester.pump();
    editable.hideToolbar(false);
    expect(editable.showToolbar(), isTrue);
    await tester.pumpAndSettle();
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
        find.byType(AdaptiveTextSelectionToolbar));
    toolbar.buttonItems!
        .singleWhere((item) => item.label == S.current.Copy_Selection_To_Note)
        .onPressed!();
    await tester.pumpAndSettle();
    expect(copied.single.text, 'styled');
    expect(copied.single.textStyles, const [
      NoteTextStyleRange(start: 0, end: 6, kind: NoteTextStyleKind.bold),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chinese 2x preview folds and fits a 150px screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(150, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('reader-capture'),
      child: noteReaderSectionsChinesePreview(
          fontFamily:
              const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null),
    ));
    await tester.pumpAndSettle();
    final toggle = find.byType(IconButton).first;
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(toggle), const Size(48, 48));
    await _capture(tester, 'chinese-narrow-expanded');
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.keyboard_arrow_right_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'chinese-narrow-folded');
  });

  if (const bool.fromEnvironment('CAPTURE_UI')) {
    for (final dark in [false, true]) {
      testWidgets('capture reader sections preview (dark: $dark)',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 700);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('reader-capture'),
          child: dark
              ? noteReaderSectionsDarkPreview(fontFamily: 'Roboto')
              : noteReaderSectionsPreview(fontFamily: 'Roboto'),
        ));
        await tester.pumpAndSettle();
        final mode = dark ? 'dark' : 'phone';
        await _capture(tester, '$mode-expanded');
        await tester.tap(find.byType(IconButton).first);
        await tester.pumpAndSettle();
        await _capture(tester, '$mode-folded');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'ordinary reader layout stays unchanged unless folding is enabled',
      (tester) async {
    const text = 'First\nSecond';
    await _pump(
      tester,
      const NoteDocumentView(
        text: text,
        styles: [
          NoteTextStyleRange(start: 0, end: 5, kind: NoteTextStyleKind.heading),
        ],
        style: TextStyle(fontSize: 17),
      ),
    );
    expect(find.text(text), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });
}
