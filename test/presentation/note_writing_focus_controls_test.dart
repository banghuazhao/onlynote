import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_editing_actions.dart';
import 'package:onlynote/presentation/components/note_formatting_toolbar.dart';
import 'package:onlynote/presentation/components/note_writing_focus_preview.dart';

Finder _focusControl() => find.byKey(const ValueKey('note-focus-writing'));

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 700),
  double textScale = 1,
  bool dark = false,
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      colorSchemeSeed: const Color(0xFF685947),
      platform: TargetPlatform.macOS,
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: child!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

class _FocusFixture extends StatefulWidget {
  const _FocusFixture({
    this.titleController,
    this.titleFocus,
    this.bodyController,
    this.bodyFocus,
    this.onToggle,
    this.showOutline = true,
  });

  final TextEditingController? titleController;
  final FocusNode? titleFocus;
  final TextEditingController? bodyController;
  final FocusNode? bodyFocus;
  final VoidCallback? onToggle;
  final bool showOutline;

  @override
  State<_FocusFixture> createState() => _FocusFixtureState();
}

class _FocusFixtureState extends State<_FocusFixture> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          NoteEditingActions(
            onUndo: null,
            onRedo: null,
            onOutline: widget.showOutline ? () {} : null,
            writingFocused: _focused,
            onToggleFocus: () {
              widget.onToggle?.call();
              setState(() => _focused = !_focused);
            },
          ),
          if (!_focused)
            const SizedBox(
                key: ValueKey('auxiliary-tools'),
                height: 72,
                child: Text('Checklist, photos, voice, colors, tags, links')),
          if (widget.titleController != null)
            TextField(
              key: const ValueKey('title-field'),
              controller: widget.titleController,
              focusNode: widget.titleFocus,
            ),
          if (widget.bodyController != null)
            TextField(
              key: const ValueKey('body-field'),
              controller: widget.bodyController,
              focusNode: widget.bodyFocus,
              maxLines: 3,
            ),
        ],
      );
}

void main() {
  testWidgets('focus control is optional for existing editing action callers',
      (tester) async {
    await _pump(tester, const NoteEditingActions(onUndo: null, onRedo: null));
    expect(_focusControl(), findsNothing);
    expect(find.byKey(const ValueKey('note-undo')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-redo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus toggle announces its pressed state and localized action',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var toggles = 0;
      await _pump(tester, _FocusFixture(onToggle: () => toggles++));
      expect(find.byTooltip(S.current.Note_FocusWriting), findsOneWidget);
      expect(tester.getSemantics(_focusControl()).flagsCollection.isToggled,
          Tristate.isFalse);
      expect(tester.getSize(_focusControl()), const Size(48, 48));

      await tester.tap(_focusControl());
      await tester.pumpAndSettle();
      expect(toggles, 1);
      expect(find.byKey(const ValueKey('auxiliary-tools')), findsNothing);
      expect(find.byTooltip(S.current.Note_ShowWritingTools), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);
      final node = tester.getSemantics(_focusControl());
      expect(node.label, S.current.Note_ShowWritingTools);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.flagsCollection.isToggled, Tristate.isTrue);

      await tester.tap(_focusControl());
      await tester.pumpAndSettle();
      expect(toggles, 2);
      expect(find.byKey(const ValueKey('auxiliary-tools')), findsOneWidget);
      expect(find.byTooltip(S.current.Note_FocusWriting), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final activeField in ['title', 'body']) {
    testWidgets('focus toggle retains $activeField selection and keyboard',
        (tester) async {
      final title = TextEditingController(text: 'Weekend notes');
      final body = TextEditingController(text: 'Pack tea and a warm layer');
      final titleFocus = FocusNode();
      final bodyFocus = FocusNode();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        title.dispose();
        body.dispose();
        titleFocus.dispose();
        bodyFocus.dispose();
      });
      await _pump(
          tester,
          _FocusFixture(
            titleController: title,
            titleFocus: titleFocus,
            bodyController: body,
            bodyFocus: bodyFocus,
          ));
      final field = find.byKey(ValueKey('$activeField-field'));
      final controller = activeField == 'title' ? title : body;
      final focus = activeField == 'title' ? titleFocus : bodyFocus;
      await tester.showKeyboard(field);
      controller.selection =
          const TextSelection(baseOffset: 1, extentOffset: 4);
      await tester.pump();
      final titleValue = title.value;
      final bodyValue = body.value;
      var edits = 0;
      title.addListener(() => edits++);
      body.addListener(() => edits++);

      // Mouse taps also exercise TextField's desktop tap-outside behavior.
      await tester.tap(_focusControl(), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(title.value, titleValue);
      expect(body.value, bodyValue);
      expect(edits, 0);

      await tester.tap(_focusControl());
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(title.value, titleValue);
      expect(body.value, bodyValue);
      expect(edits, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('focus toggle leaves ongoing Chinese composition intact',
      (tester) async {
    final body = TextEditingController(text: '茶');
    final focus = FocusNode();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      body.dispose();
      focus.dispose();
    });
    await _pump(tester, _FocusFixture(bodyController: body, bodyFocus: focus),
        locale: const Locale('zh'));
    await tester.showKeyboard(find.byKey(const ValueKey('body-field')));
    const composing = TextEditingValue(
      text: '茶葉',
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 1, end: 2),
    );
    tester.testTextInput.updateEditingValue(composing);
    await tester.pump();
    await tester.tap(_focusControl(), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(body.value, composing);
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('outline focus undo redo fit 320px Chinese text in $dark theme',
        (tester) async {
      await _pump(tester, const _FocusFixture(),
          size: const Size(320, 700),
          textScale: 2,
          locale: const Locale('zh', 'HK'),
          dark: dark,
          reduceMotion: true);
      expect(find.byKey(const ValueKey('note-editing-actions-wrap')),
          findsNothing);
      for (final key in [
        'note-outline',
        'note-focus-writing',
        'note-undo',
        'note-redo',
      ]) {
        final control = find.byKey(ValueKey(key));
        expect(control, findsOneWidget);
        expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
        final rect = tester.getRect(control);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
      expect(
          tester.widget<IconButton>(_focusControl()).style!.animationDuration,
          Duration.zero);
      await tester.tap(_focusControl());
      await tester.pump();
      final button = tester.widget<IconButton>(_focusControl());
      final scheme = Theme.of(tester.element(_focusControl())).colorScheme;
      expect(button.style!.foregroundColor!.resolve({WidgetState.selected}),
          scheme.onPrimaryContainer);
      expect(button.style!.backgroundColor!.resolve({WidgetState.selected}),
          scheme.primaryContainer);
      expect(tester.takeException(), isNull);
    });
  }

  for (final showOutline in [false, true]) {
    testWidgets('150px editing controls wrap with outline $showOutline',
        (tester) async {
      var toggles = 0;
      await _pump(tester,
          _FocusFixture(showOutline: showOutline, onToggle: () => toggles++),
          size: const Size(150, 700),
          textScale: 2,
          locale: const Locale('zh', 'HK'),
          reduceMotion: true);
      expect(find.byKey(const ValueKey('note-editing-actions-wrap')),
          findsOneWidget);
      for (final key in [
        if (showOutline) 'note-outline',
        'note-focus-writing',
        'note-undo',
        'note-redo',
      ]) {
        final control = find.byKey(ValueKey(key));
        expect(control, findsOneWidget);
        final rect = tester.getRect(control);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(150));
      }
      expect(tester.getTopLeft(find.byKey(const ValueKey('note-redo'))).dy,
          greaterThan(tester.getTopLeft(_focusControl()).dy));
      await tester.tap(_focusControl());
      await tester.pumpAndSettle();
      expect(toggles, 1);
      expect(tester.widget<IconButton>(_focusControl()).isSelected, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Chinese preview toggles tools while retaining writing fields',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(noteWritingFocusChinesePreview());
    await tester.pumpAndSettle();
    final title = find.byKey(const ValueKey('preview-focus-title'));
    final body = find.byKey(const ValueKey('preview-focus-body'));
    final titleValue = tester.widget<TextField>(title).controller!.value;
    final bodyValue = tester.widget<TextField>(body).controller!.value;
    final before = tester.getTopLeft(title).dy;
    expect(find.byKey(const ValueKey('preview-writing-tools')), findsOneWidget);
    await tester.tap(_focusControl());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-writing-tools')), findsNothing);
    expect(tester.getTopLeft(title).dy, lessThan(before));
    expect(tester.widget<TextField>(title).controller!.value, titleValue);
    expect(tester.widget<TextField>(body).controller!.value, bodyValue);
    expect(find.byType(NoteFormattingToolbar), findsOneWidget);
    expect(find.text(S.current.Done), findsOneWidget);
    await tester.tap(_focusControl());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-writing-tools')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
