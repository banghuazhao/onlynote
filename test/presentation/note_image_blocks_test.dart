import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_body_editor.dart';
import 'package:onlynote/presentation/components/note_document_view.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Widget _photo(BuildContext context, String path) => ColoredBox(
      key: ValueKey('fixture-$path'),
      color: Colors.teal,
    );

class _Host extends StatefulWidget {
  const _Host({super.key, required this.controller, required this.layouts});
  final SimpleFormattingController controller;
  final List<NoteImageLayout> layouts;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final focus = FocusNode();
  late List<NoteImageLayout> layouts = widget.layouts;
  late List<String> paths = layouts.map((layout) => layout.path).toList();
  int layoutChanges = 0;
  void replaceLayouts(List<NoteImageLayout> value) => setState(() {
        layouts = value;
        paths = value.map((layout) => layout.path).toList();
      });
  void replaceDocument(String body, List<NoteImageLayout> value) {
    widget.controller.setDocument(body, const []);
    replaceLayouts(value);
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: NoteBodyEditor(
          controller: widget.controller,
          focusNode: focus,
          imagePaths: paths,
          imageLayouts: layouts,
          onImageLayoutsChanged: (value) => setState(() {
            layoutChanges++;
            layouts = value;
          }),
          onRemoveImage: (path) => setState(() {
            paths = paths.where((item) => item != path).toList();
            layouts = layouts.where((item) => item.path != path).toList();
          }),
          imageBuilder: _photo,
        ),
      );
}

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(390, 844), bool chinese = false}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _field(String key) => find.byKey(ValueKey('note-body-$key'));

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
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  testWidgets(
      'selected image resizes proportionally and tools hide on text tap',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(key: host, controller: controller, layouts: const [
          NoteImageLayout(
              path: 'a', textOffset: 7, widthFactor: .7, aspectRatio: 2)
        ]));
    expect(find.byKey(const ValueKey('image-resize-a')), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('image-select-a')));
    final original = host.currentState!.layouts.single;
    await tester.drag(
        find.byKey(const ValueKey('image-resize-a')), const Offset(-45, 0));
    await tester.pumpAndSettle();
    final resized = host.currentState!.layouts.single;
    expect(resized.widthFactor, lessThan(original.widthFactor));
    expect(resized.aspectRatio, 2);
    final photo = tester.getSize(find.byKey(const ValueKey('fixture-a')));
    expect(photo.width / photo.height, closeTo(2, .01));
    await _tap(tester, _field('end'));
    expect(find.byKey(const ValueKey('image-resize-a')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'formatting in text after a photo keeps local selection and keyboard',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nPack snacks');
    addTearDown(controller.dispose);
    await _pump(
        tester,
        _Host(
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 7)]));
    await _tap(tester, _field('end'));
    final field = tester.widget<TextField>(_field('end'));
    field.controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4));
    expect(
        controller.styles,
        contains(const NoteTextStyleRange(
            start: 7, end: 11, kind: NoteTextStyleKind.bold)));
    expect(controller.text, 'Before\nPack snacks');
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing between same-anchor photos preserves their sides',
      (tester) async {
    final controller = SimpleFormattingController(text: '');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(key: host, controller: controller, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 0),
          NoteImageLayout(path: 'b', textOffset: 0)
        ]));
    await tester.enterText(_field('before:b'), 'Middle');
    await tester.pumpAndSettle();
    expect(controller.text, 'Middle');
    expect(host.currentState!.layouts.first.textOffset, 0);
    expect(host.currentState!.layouts.last.textOffset, 6);
    expect(tester.widget<TextField>(_field('before:b')).controller!.text,
        'Middle');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'typing after trailing photo maintains separator and IME composition',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(
            key: host,
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 6)]));
    await _tap(tester, _field('end'));
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '香港',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2)));
    await tester.pump();
    expect(controller.text, 'Before\n香港');
    expect(host.currentState!.layouts.single.textOffset, 7);
    expect(tester.widget<TextField>(_field('end')).controller!.value.composing,
        const TextRange(start: 0, end: 2));
    expect(controller.value.composing, const TextRange(start: 7, end: 9));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'move buttons move between paragraphs and reorder image-only notes',
      (tester) async {
    final controller = SimpleFormattingController(text: 'One\nTwo');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(
            key: host,
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 7)]));
    await _tap(tester, find.byKey(const ValueKey('image-select-a')));
    await _tap(tester, find.byKey(const ValueKey('image-earlier-a')));
    expect(host.currentState!.layouts.single.textOffset, 4);
    await _tap(tester, find.byKey(const ValueKey('image-earlier-a')));
    expect(host.currentState!.layouts.single.textOffset, 0);
    await _tap(tester, find.byKey(const ValueKey('image-later-a')));
    expect(host.currentState!.layouts.single.textOffset, 4);
    expect(controller.text, 'One\nTwo');
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding first photo gives each segment its own focus node',
      (tester) async {
    final controller = SimpleFormattingController(text: 'One\nTwo');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester, _Host(key: host, controller: controller, layouts: const []));
    expect(tester.widget<TextField>(find.byType(TextField)).minLines, 6);
    host.currentState!
        .replaceLayouts(const [NoteImageLayout(path: 'a', textOffset: 4)]);
    await tester.pumpAndSettle();
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));
    expect(fields.first.focusNode, isNot(same(fields.last.focusNode)));
    await _tap(tester, _field('end'));
    expect(fields.last.focusNode!.hasFocus, isTrue);
    expect(fields.first.focusNode!.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image reader uses relative width and horizontal alignment',
      (tester) async {
    await _pump(
        tester,
        const Padding(
            padding: EdgeInsets.all(20),
            child: NoteDocumentView(
              text: 'One\nTwo',
              imagePaths: ['a'],
              imageLayouts: [
                NoteImageLayout(
                    path: 'a',
                    textOffset: 4,
                    widthFactor: .5,
                    xFactor: 1,
                    aspectRatio: 2)
              ],
              imageBuilder: _photo,
            )));
    final photo = find.byKey(const ValueKey('fixture-a'));
    expect(tester.getSize(photo), const Size(175, 87.5));
    expect(tester.getTopLeft(photo).dx, 195);
    expect(find.text('One\n'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected image tools fit a narrow Chinese screen',
      (tester) async {
    final controller = SimpleFormattingController(text: '');
    addTearDown(controller.dispose);
    await _pump(
        tester,
        _Host(
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 0)]),
        size: const Size(150, 600),
        chinese: true);
    await _tap(tester, find.byKey(const ValueKey('image-select-a')));
    expect(find.byKey(const ValueKey('image-remove-a')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Return before a photo preserves an intentional blank line',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(
            key: host,
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 7)]));
    await _tap(tester, _field('before:a'));
    final field = tester.widget<TextField>(_field('before:a'));
    field.controller!.selection = const TextSelection.collapsed(offset: 6);
    await tester.pump();
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'Before\n', selection: TextSelection.collapsed(offset: 7)));
    await tester.pump();
    expect(controller.text, 'Before\n\nAfter');
    expect(host.currentState!.layouts.single.textOffset, 8);
    expect(field.controller!.text, 'Before\n');
    expect(field.controller!.selection.extentOffset, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('heading at the end before a photo stays in that paragraph',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    addTearDown(controller.dispose);
    await _pump(
        tester,
        _Host(
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 7)]));
    await _tap(tester, _field('before:a'));
    final field = tester.widget<TextField>(_field('before:a'));
    field.controller!.selection = const TextSelection.collapsed(offset: 6);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('format-heading')));
    expect(
        controller.styles,
        contains(const NoteTextStyleRange(
            start: 0, end: 6, kind: NoteTextStyleKind.heading)));
    expect(controller.styles.any((style) => style.start >= 7), isFalse);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('formatting an empty field after a photo targets new text only',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before');
    addTearDown(controller.dispose);
    await _pump(
        tester,
        _Host(
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 6)]));
    await _tap(tester, _field('end'));
    await _tap(tester, find.byKey(const ValueKey('format-heading')));
    expect(controller.text, 'Before\n');
    expect(controller.styles, isEmpty);
    await tester.enterText(_field('end'), 'After');
    await tester.pump();
    expect(controller.text, 'Before\nAfter');
    expect(
        controller.styles,
        contains(const NoteTextStyleRange(
            start: 7, end: 12, kind: NoteTextStyleKind.heading)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated formatting taps do not add extra empty paragraphs',
      (tester) async {
    final controller = SimpleFormattingController(text: 'After');
    addTearDown(controller.dispose);
    await _pump(
        tester,
        _Host(
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 0)]));
    await _tap(tester, _field('before:a'));
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    await _tap(tester, find.byKey(const ValueKey('format-bold')));
    await _tap(tester, find.byKey(const ValueKey('format-heading')));
    expect(controller.text, '\nAfter');
    expect(controller.styles, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external document adoption does not overwrite supplied layouts',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before\nAfter');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(
            key: host,
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 7)]));
    host.currentState!.replaceDocument('Short',
        const [NoteImageLayout(path: 'a', textOffset: 0, widthFactor: .5)]);
    await tester.pump();
    expect(host.currentState!.layoutChanges, 0);
    expect(host.currentState!.layouts.single.textOffset, 0);
    expect(tester.widget<TextField>(_field('end')).controller!.text, 'Short');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'identical document adoption does not suppress the next anchor edit',
      (tester) async {
    final controller = SimpleFormattingController(text: 'Before');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(
            key: host,
            controller: controller,
            layouts: const [NoteImageLayout(path: 'a', textOffset: 6)]));
    controller.selection = const TextSelection.collapsed(offset: 0);
    controller.setDocument(controller.text, controller.styles);
    await tester.pump();
    await tester.enterText(_field('before:a'), 'Before again');
    await tester.pump();
    expect(controller.text, 'Before again');
    expect(host.currentState!.layouts.single.textOffset, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-frame corner drag uses vertical and horizontal movement',
      (tester) async {
    final controller = SimpleFormattingController(text: '');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(key: host, controller: controller, layouts: const [
          NoteImageLayout(
              path: 'a', textOffset: 0, widthFactor: .7, aspectRatio: 2)
        ]));
    await _tap(tester, find.byKey(const ValueKey('image-select-a')));
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('image-resize-a'))));
    await gesture.moveBy(const Offset(-25, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    final horizontal = host.currentState!.layouts.single.widthFactor;
    await gesture.moveBy(const Offset(0, -25));
    await tester.pump();
    expect(host.currentState!.layouts.single.widthFactor, lessThan(horizontal));
    expect(host.currentState!.layouts.single.aspectRatio, 2);
    await gesture.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'multi-frame photo drag accumulates alignment and drops at a paragraph',
      (tester) async {
    final controller = SimpleFormattingController(text: 'One\nTwo');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(key: host, controller: controller, layouts: const [
          NoteImageLayout(
              path: 'a', textOffset: 4, widthFactor: .5, xFactor: .1)
        ]));
    await _tap(tester, find.byKey(const ValueKey('image-select-a')));
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('image-select-a'))));
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    final first = host.currentState!.layouts.single.xFactor;
    await gesture.moveBy(const Offset(15, 0));
    await tester.pump();
    expect(host.currentState!.layouts.single.xFactor, greaterThan(first));
    await gesture
        .moveTo(tester.getCenter(find.byKey(const ValueKey('image-drop-0'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(host.currentState!.layouts.single.textOffset, 0);
    expect(find.byKey(const ValueKey('image-drop-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top drop target places a photo before its same-anchor siblings',
      (tester) async {
    final controller = SimpleFormattingController(text: '');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(key: host, controller: controller, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 0, widthFactor: .35),
          NoteImageLayout(path: 'b', textOffset: 0, widthFactor: .35)
        ]));
    await _tap(tester, find.byKey(const ValueKey('image-select-b')));
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('image-select-b'))));
    await gesture.moveBy(const Offset(0, -25));
    await tester.pump();
    await gesture
        .moveTo(tester.getCenter(find.byKey(const ValueKey('image-drop-0'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(host.currentState!.layouts.map((layout) => layout.path), ['b', 'a']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging at the viewport edge scrolls a long note',
      (tester) async {
    final controller = SimpleFormattingController(
        text: List.generate(45, (index) => 'Paragraph $index').join('\n'));
    addTearDown(controller.dispose);
    await _pump(
        tester,
        _Host(controller: controller, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 0, widthFactor: .35)
        ]));
    await _tap(tester, find.byKey(const ValueKey('image-select-a')));
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('image-select-a'))));
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();
    await gesture.moveTo(const Offset(195, 830));
    await tester.pump(const Duration(milliseconds: 400));
    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropping before the dragged photo preserves sibling order',
      (tester) async {
    final controller = SimpleFormattingController(text: '');
    addTearDown(controller.dispose);
    final host = GlobalKey<_HostState>();
    await _pump(
        tester,
        _Host(key: host, controller: controller, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 0, widthFactor: .3),
          NoteImageLayout(path: 'b', textOffset: 0, widthFactor: .3),
          NoteImageLayout(path: 'c', textOffset: 0, widthFactor: .3),
        ]));
    await _tap(tester, find.byKey(const ValueKey('image-select-b')));
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('image-select-b'))));
    await gesture.moveBy(const Offset(0, -25));
    await tester.pump();
    await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('image-drop-0-before-b'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(host.currentState!.layouts.map((layout) => layout.path),
        ['a', 'b', 'c']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tall photo selection keeps resize and remove controls near its top',
      (tester) async {
    final controller = SimpleFormattingController(text: '');
    addTearDown(controller.dispose);
    await _pump(
        tester,
        _Host(controller: controller, layouts: const [
          NoteImageLayout(path: 'a', textOffset: 0, aspectRatio: .1)
        ]));
    await tester.tapAt(
        tester.getTopLeft(find.byKey(const ValueKey('image-select-a'))) +
            const Offset(25, 25));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('image-resize-a'))).dy,
        lessThan(300));
    expect(tester.getTopLeft(find.byKey(const ValueKey('image-remove-a'))).dy,
        lessThan(200));
    expect(tester.takeException(), isNull);
  });
}
