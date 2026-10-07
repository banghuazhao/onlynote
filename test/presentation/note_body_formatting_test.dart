import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/components/note_body_formatting_controller.dart';
import 'package:onlynote/presentation/components/note_formatting_toolbar.dart';
import 'package:onlynote/presentation/components/note_writing_toolbar.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_text_format.dart';

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    required this.body,
    required this.formatting,
    this.layouts = const [],
  });

  final SimpleFormattingController body;
  final NoteBodyFormattingController formatting;
  final List<NoteImageLayout> layouts;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final bodyFocus = FocusNode();
  final titleFocus = FocusNode();
  late List<NoteImageLayout> layouts = widget.layouts;
  late NoteBodyFormattingController formatting = widget.formatting;
  bool showEditor = true;

  void replaceFormatting(NoteBodyFormattingController replacement) =>
      setState(() => formatting = replacement);

  void removePhotos() => setState(() => layouts = []);

  void removeEditor() => setState(() => showEditor = false);

  @override
  void dispose() {
    bodyFocus.dispose();
    titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(key: const ValueKey('title'), focusNode: titleFocus),
              if (showEditor)
                NoteBodyEditor(
                  controller: widget.body,
                  focusNode: bodyFocus,
                  formattingController: formatting,
                  showFormattingToolbar: false,
                  imagePaths: layouts.map((layout) => layout.path).toList(),
                  imageLayouts: layouts,
                  onImageLayoutsChanged: (value) =>
                      setState(() => layouts = value),
                  onRemoveImage: (_) => removePhotos(),
                  imageBuilder: (_, path) =>
                      const ColoredBox(color: Colors.teal),
                ),
            ],
          ),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: formatting,
          builder: (context, _) => formatting.hasFocus
              ? NoteWritingToolbar(
                  controller: widget.body,
                  focusNode: formatting.activeFocusNode ?? bodyFocus,
                  beforeApply: formatting.prepareFormattingSelection,
                )
              : const SizedBox.shrink(),
        ),
      );
}

Future<void> _pump(WidgetTester tester, Widget child,
    {bool dark = false, Size size = const Size(390, 844)}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: child,
  ));
  await tester.pumpAndSettle();
}

Finder _segment(String key) => find.byKey(ValueKey('note-body-$key'));
Finder get _plainBody => find.descendant(
    of: find.byType(NoteBodyEditor), matching: find.byType(TextField));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUp(() {
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          );
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  for (final dark in [false, true]) {
    testWidgets(
        'photo text segments keep the first cursor clear in ${dark ? 'dark' : 'light'} theme',
        (tester) async {
      final body = SimpleFormattingController(text: 'After');
      final formatting = NoteBodyFormattingController();
      addTearDown(body.dispose);
      addTearDown(formatting.dispose);
      await _pump(
        tester,
        _Host(body: body, formatting: formatting, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 0),
        ]),
        dark: dark,
      );

      for (final key in ['before:a', 'end']) {
        final segment = _segment(key);
        expect(
            Theme.of(tester.element(segment))
                .inputDecorationTheme
                .focusedBorder,
            isA<OutlineInputBorder>());
        await _tap(tester, segment);
        final field = tester.widget<TextField>(segment);
        const selection = TextSelection.collapsed(offset: 0);
        field.controller!.selection = selection;
        await tester.pumpAndSettle();

        // Inspect the themed decoration used for rendering, not the field input.
        final decorator = tester.widget<InputDecorator>(find.descendant(
            of: segment, matching: find.byType(InputDecorator)));
        expect(decorator.isFocused, isTrue);
        final decoration = decorator.decoration;
        for (final border in [
          decoration.border,
          decoration.enabledBorder,
          decoration.focusedBorder,
          decoration.disabledBorder,
          decoration.errorBorder,
          decoration.focusedErrorBorder,
        ]) {
          expect(border, InputBorder.none);
        }

        final editable = tester.state<EditableTextState>(
            find.descendant(of: segment, matching: find.byType(EditableText)));
        final render = editable.renderEditable;
        final cursor = render
            .getLocalRectForCaret(const TextPosition(offset: 0))
            .shift(render.localToGlobal(Offset.zero));
        final frame = tester.getRect(segment).inflate(1);
        expect(frame.contains(cursor.topLeft), isTrue);
        expect(frame.contains(cursor.bottomRight), isTrue);
        expect(field.focusNode!.hasFocus, isTrue);
        expect(field.controller!.selection, selection);
        expect(formatting.activeFocusNode, same(field.focusNode));
        expect(tester.testTextInput.isVisible, isTrue);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('external toolbar tracks plain body focus and retains selection',
      (tester) async {
    final body = SimpleFormattingController(text: 'Pack snacks');
    final formatting = NoteBodyFormattingController();
    addTearDown(body.dispose);
    addTearDown(formatting.dispose);
    await _pump(tester, _Host(body: body, formatting: formatting));
    expect(formatting.hasFocus, isFalse);
    expect(find.byType(NoteFormattingToolbar), findsNothing);
    await _tap(tester, _plainBody);
    final field = tester.widget<TextField>(_plainBody);
    const selection = TextSelection(baseOffset: 0, extentOffset: 4);
    body.selection = selection;
    await tester.pump();
    expect(formatting.activeFocusNode, same(field.focusNode));
    expect(find.byType(NoteFormattingToolbar), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(body.selection, selection);
    expect(
        body.styles,
        contains(const NoteTextStyleRange(
            start: 0, end: 4, kind: NoteTextStyleKind.bold)));
    await _tap(tester, find.byKey(const ValueKey('title')));
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('title')))
            .focusNode!
            .hasFocus,
        isTrue);
    expect(formatting.hasFocus, isFalse);
    expect(find.byType(NoteFormattingToolbar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external toolbar follows photo segments and their local ranges',
      (tester) async {
    final body = SimpleFormattingController(text: 'Before\nPack snacks');
    final formatting = NoteBodyFormattingController();
    addTearDown(body.dispose);
    addTearDown(formatting.dispose);
    await _pump(
        tester,
        _Host(body: body, formatting: formatting, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 7),
        ]));
    await _tap(tester, _segment('end'));
    final after = tester.widget<TextField>(_segment('end'));
    const selection = TextSelection(baseOffset: 4, extentOffset: 0);
    after.controller!.selection = selection;
    await tester.pump();
    expect(formatting.activeFocusNode, same(after.focusNode));
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    expect(after.focusNode!.hasFocus, isTrue);
    expect(after.controller!.selection, selection);
    expect(
        body.selection, const TextSelection(baseOffset: 11, extentOffset: 7));
    expect(
        body.styles,
        contains(const NoteTextStyleRange(
            start: 7, end: 11, kind: NoteTextStyleKind.bold)));

    await _tap(tester, _segment('before:a'));
    final before = tester.widget<TextField>(_segment('before:a'));
    before.controller!.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    expect(formatting.activeFocusNode, same(before.focusNode));
    await _tap(tester, find.byKey(const ValueKey('format-heading')));
    expect(before.focusNode!.hasFocus, isTrue);
    expect(after.focusNode!.hasFocus, isFalse);
    expect(
        body.styles,
        contains(const NoteTextStyleRange(
            start: 0, end: 6, kind: NoteTextStyleKind.heading)));
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external formatting in an empty photo segment targets new text',
      (tester) async {
    final body = SimpleFormattingController(text: 'Before');
    final formatting = NoteBodyFormattingController();
    addTearDown(body.dispose);
    addTearDown(formatting.dispose);
    await _pump(
        tester,
        _Host(body: body, formatting: formatting, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 6),
        ]));
    await _tap(tester, _segment('end'));
    await _tap(tester, find.byKey(const ValueKey('format-heading')));
    expect(body.text, 'Before\n');
    expect(body.styles, isEmpty);
    await tester.enterText(_segment('end'), 'After');
    await tester.pump();
    expect(body.text, 'Before\nAfter');
    expect(
        body.styles,
        contains(const NoteTextStyleRange(
            start: 7, end: 12, kind: NoteTextStyleKind.heading)));
    expect(formatting.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller replacement and removal detach retired native fields',
      (tester) async {
    final body = SimpleFormattingController(text: 'Before\nAfter');
    final formatting = NoteBodyFormattingController();
    final replacement = NoteBodyFormattingController();
    addTearDown(body.dispose);
    addTearDown(formatting.dispose);
    addTearDown(replacement.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(
            key: host,
            body: body,
            formatting: formatting,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 7)]));
    await _tap(tester, _segment('end'));
    host.currentState!.replaceFormatting(replacement);
    await tester.pumpAndSettle();
    expect(formatting.activeFocusNode, isNull);
    expect(replacement.hasFocus, isTrue);
    host.currentState!.removePhotos();
    await tester.pumpAndSettle();
    expect(replacement.activeFocusNode, same(host.currentState!.bodyFocus));
    await _tap(tester, _plainBody);
    expect(replacement.hasFocus, isTrue);
    host.currentState!.removeEditor();
    await tester.pumpAndSettle();
    expect(replacement.activeFocusNode, isNull);
    replacement.prepareFormattingSelection();
    expect(tester.takeException(), isNull);
  });

  testWidgets('surface toolbar stays readable in dark mode and narrow widths',
      (tester) async {
    final body = SimpleFormattingController(text: 'Selected text');
    final focus = FocusNode();
    addTearDown(body.dispose);
    addTearDown(focus.dispose);
    body.selection = const TextSelection(baseOffset: 0, extentOffset: 8);
    body.toggleBold();
    await _pump(
      tester,
      Scaffold(
        body: NoteFormattingToolbar(
            controller: body, focusNode: focus, useSurfaceColors: true),
      ),
      dark: true,
      size: const Size(150, 640),
    );
    final boldIcon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey('format-bold')),
        matching: find.byType(Icon)));
    expect(boldIcon.color, AppTheme.dark.colorScheme.onPrimaryContainer);
    final headingIcon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey('format-heading')),
        matching: find.byType(Icon)));
    expect(headingIcon.color,
        AppTheme.dark.colorScheme.onSurface.withValues(alpha: .66));
    body.toggleHighlight();
    await tester.pump();
    final highlightIcon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey('format-highlight')),
        matching: find.byType(Icon)));
    expect(highlightIcon.color, noteHighlightedTextColor);
    for (final control in ['bold', 'heading', 'bullets', 'highlight']) {
      expect(tester.getSize(find.byKey(ValueKey('format-$control'))),
          const Size(48, 48));
    }
    expect(tester.takeException(), isNull);
  });
}
