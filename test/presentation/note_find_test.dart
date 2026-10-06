import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_find_bar.dart';
import 'package:onlynote/presentation/components/note_find_preview.dart';
import 'package:onlynote/presentation/components/note_search_text.dart';
import 'package:onlynote/services/note_find.dart';

Widget _bar(NoteSearchController controller, {VoidCallback? close}) =>
    NoteFindBar(
      controller: controller,
      hintText: 'Find in note',
      noMatchesText: 'No matches',
      previousTooltip: 'Previous match',
      nextTooltip: 'Next match',
      closeTooltip: 'Close find',
      onClose: close ?? () {},
    );

List<TextSpan> _spans(InlineSpan span) => [
      if (span is TextSpan) span,
      if (span is TextSpan)
        for (final child in span.children ?? <InlineSpan>[]) ..._spans(child),
    ];

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

  testWidgets(
      'find bar searches, wraps, reports no results and closes on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = NoteSearchController()
      ..setFields([const NoteSearchField('body', 'tea TEA')]);
    addTearDown(controller.dispose);
    var closed = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Align(
                alignment: Alignment.topCenter,
                child: _bar(controller, close: () => closed = true)))));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'tea');
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-find-previous')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-find-next')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'absent');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('note-find-next')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const ValueKey('note-find-close')));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'highlights retain heading and bold styles and closing query restores selection',
      (tester) async {
    final controller = NoteSearchController()
      ..setFields([const NoteSearchField('body', 'Tea heading\nTea bold')]);
    addTearDown(controller.dispose);
    controller.setQuery('tea');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: NoteSearchText(
      controller: controller,
      fieldId: 'body',
      text: 'Tea heading\nTea bold',
      style: const TextStyle(fontSize: 17),
      styles: const [
        NoteTextStyleRange(start: 0, end: 11, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(start: 12, end: 20, kind: NoteTextStyleKind.bold),
      ],
    ))));
    final spans = tester
        .widgetList<RichText>(find.byType(RichText))
        .expand((text) => _spans(text.text))
        .where((span) => span.text == 'Tea')
        .toList();
    expect(spans, hasLength(2));
    expect(spans[0].style?.fontSize, 19);
    expect(spans[0].style?.fontWeight, FontWeight.w600);
    expect(spans[1].style?.fontWeight, FontWeight.w700);
    expect(spans.every((span) => span.style?.backgroundColor != null), isTrue);
    controller.setQuery('');
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets(
      'draft preview includes title tasks transcripts and exact navigation below photos',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final body =
        'Opening paragraph\n${List.generate(90, (index) => 'Walking notes from day $index.\n').join()}target near the end\nFinal target';
    final note = Note(
      title: 'A target title',
      description: body,
      todo: [Todo(id: 'done', title: 'Completed target task', completed: true)],
      imagePaths: ['landscape'],
      imageLayouts: const [
        NoteImageLayout(
            path: 'landscape',
            textOffset: 18,
            widthFactor: .75,
            aspectRatio: 1.5)
      ],
      voiceMemos: [
        VoiceMemo(
            id: 'memo',
            path: 'note_audio/memo.m4a',
            durationMs: 10,
            createdAt: DateTime(2026),
            transcript: 'A target transcript')
      ],
    );
    final controller = NoteSearchController()
      ..setFields(noteSearchFields(note));
    final scroll = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
            body: Column(children: [
          _bar(controller),
          Expanded(
              child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            child: NoteFindPreview(
                note: note,
                controller: controller,
                imageBuilder: (_, path) =>
                    const ColoredBox(color: Colors.teal)),
          )),
        ]))));
    await tester.enterText(
        find.byKey(const ValueKey('note-find-query')), 'target');
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-find-next')));
    await tester.pumpAndSettle();
    expect(controller.currentMatch?.fieldId, 'todo:done');
    await tester.tap(find.byKey(const ValueKey('note-find-next')));
    await tester.pumpAndSettle();
    expect(controller.currentMatch?.fieldId, 'body');
    expect(scroll.offset, greaterThan(1800));
    final part = find.byWidgetPredicate((widget) =>
        widget is NoteSearchText &&
        widget.fieldId == 'body' &&
        widget.text.contains('target near'));
    final rich = find.descendant(of: part, matching: find.byType(RichText));
    final paragraph = tester.renderObject<RenderParagraph>(rich);
    final textWidget = tester.widget<NoteSearchText>(part);
    final current = controller.currentMatch!;
    final rect = paragraph
        .getBoxesForSelection(TextSelection(
            baseOffset: current.start - textWidget.textOffset,
            extentOffset: current.end - textWidget.textOffset))
        .first
        .toRect();
    final global = paragraph.localToGlobal(rect.topLeft);
    final viewportTop = tester.getBottomLeft(find.byType(NoteFindBar)).dy;
    expect(global.dy, greaterThanOrEqualTo(viewportTop));
    expect(global.dy, lessThan(680));
    await tester.tap(find.byKey(const ValueKey('note-find-next')));
    await tester.tap(find.byKey(const ValueKey('note-find-next')));
    await tester.pumpAndSettle();
    expect(controller.currentMatch?.fieldId, 'voice:memo');
    expect(note.description, body);
    expect(note.imageLayouts.single.widthFactor, .75);
    expect(note.todo.single.completed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
