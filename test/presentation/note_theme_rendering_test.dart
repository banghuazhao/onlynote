import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';
import 'package:onlynote/presentation/components/note_theme_surface_previews.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_reorder_card.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {bool dark = false, double textScale = 1}) =>
    MaterialApp(
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        extensions: const [AppTokens()],
      ),
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
          child: Center(child: SizedBox(width: 240, child: child)),
        ),
      ),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('note-theme-preview-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-theme-$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final family in ['Roboto', 'DroidSansFallback']) {
      final font = FontLoader(family)
        ..addFont(rootBundle.load(
            'assets/fonts/$family${family == 'Roboto' ? '-Regular' : ''}.ttf'));
      await font.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCardStyleSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              fontFamily:
                  const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null,
              fontFamilyFallback: const bool.fromEnvironment('CAPTURE_UI')
                  ? const ['DroidSansFallback']
                  : null);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  test('preset paper preserves explicit note colors and dark ink contrast', () {
    const custom = Color(0xFFD6EAF8);
    for (final theme in NoteTheme.values) {
      expect(noteThemePaperColor(theme, customColor: custom), custom);
      final luminance = noteThemePaperColor(theme).computeLuminance();
      final contrast =
          (luminance + .05) / (AppColors.ink.computeLuminance() + .05);
      expect(contrast, greaterThanOrEqualTo(7), reason: theme.name);
    }
    expect(noteThemePaperColor(NoteTheme.classic), AppColors.parchment);
  });

  testWidgets('every theme preserves child geometry and taps in both modes',
      (tester) async {
    var taps = 0;
    Rect? originalRect;
    for (final dark in [false, true]) {
      for (final theme in NoteTheme.values) {
        await tester.pumpWidget(_host(
          PaperNote(
            color: noteThemePaperColor(theme),
            theme: theme,
            tilt: false,
            plainPaper: false,
            kind: PaperNoteKind.sheet,
            child: TextButton(
              key: const ValueKey('paper-child-action'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, 44)),
              onPressed: () => taps++,
              child: const Text('Read and edit'),
            ),
          ),
          dark: dark,
        ));
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('paper-child-action'));
        originalRect ??= tester.getRect(action);
        expect(tester.getRect(action), originalRect, reason: theme.name);
        expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
        await tester.tap(action.hitTestable());
        await tester.pump();
        expect(tester.takeException(), isNull, reason: theme.name);
      }
    }
    expect(taps, NoteTheme.values.length * 2);
  });

  testWidgets('plain paper removes every pattern while retaining its palette',
      (tester) async {
    for (final theme in NoteTheme.values) {
      await tester.pumpWidget(_host(PaperNote(
        color: noteThemePaperColor(theme),
        theme: theme,
        plainPaper: true,
        child: const RuledWritingArea(child: Text('Plain writing')),
      )));
      await tester.pumpAndSettle();
      final paper = find.byType(PaperNote);
      // Material paints its shape with a CustomPaint even on plain paper.
      // The decorative paper painters are leaf paints behind the content.
      expect(
          find.descendant(
              of: paper,
              matching: find.byWidgetPredicate(
                  (widget) => widget is CustomPaint && widget.child == null)),
          findsNothing,
          reason: theme.name);
      expect(
          find.descendant(
              of: find.byType(RuledWritingArea),
              matching: find.byType(CustomPaint)),
          findsNothing,
          reason: theme.name);
      final container = tester.widget<AnimatedContainer>(
          find.descendant(of: paper, matching: find.byType(AnimatedContainer)));
      expect((container.decoration! as BoxDecoration).color,
          noteThemePaperColor(theme));
      expect(find.text('Plain writing'), findsOneWidget);
    }
  });

  testWidgets('theme switching avoids overlaid legacy rules and keeps typing',
      (tester) async {
    final controller = TextEditingController(text: 'A draft stays intact');
    addTearDown(controller.dispose);
    for (final theme in [
      NoteTheme.classic,
      NoteTheme.gridPaper,
      NoteTheme.dottedJournal,
      NoteTheme.kraftNotebook,
      NoteTheme.classic,
    ]) {
      await tester.pumpWidget(_host(PaperNote(
        color: noteThemePaperColor(theme),
        theme: theme,
        plainPaper: false,
        tilt: false,
        child: RuledWritingArea(
          child: TextField(
            key: const ValueKey('theme-draft'),
            controller: controller,
            style: const TextStyle(color: AppColors.ink),
          ),
        ),
      )));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
            of: find.byType(RuledWritingArea),
            matching: find.byWidgetPredicate((widget) =>
                widget is CustomPaint && widget.child is TextField)),
        theme == NoteTheme.classic ? findsOneWidget : findsNothing,
      );
      expect(controller.text, 'A draft stays intact');
      expect(tester.takeException(), isNull);
    }
    await tester.enterText(
        find.byKey(const ValueKey('theme-draft')), 'Typing still works');
    expect(controller.text, 'Typing still works');
  });

  testWidgets('mounted cards inherit new defaults without changing overrides',
      (tester) async {
    final inherited = Note(
      id: 'inherited',
      title: 'An inherited sheet',
      dateTime: DateTime(2026, 10, 13),
      todo: [Todo(id: 'task', title: 'Keep this task')],
    );
    final explicit = inherited.copyWith(
      id: 'explicit',
      color: const Color(0xFFD6EAF8),
      cardStyle: const NoteCardStyle(noteTheme: NoteTheme.gridPaper),
    );
    await tester.pumpWidget(_host(Column(
      children: [
        NoteCard(note: inherited),
        SizedBox(height: 160, child: NoteReorderCard(note: inherited)),
        NoteCard(note: explicit),
        SizedBox(height: 160, child: NoteReorderCard(note: explicit)),
      ],
    )));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<PaperNote>(find.byType(PaperNote))
            .map((p) => p.theme),
        [
          NoteTheme.classic,
          NoteTheme.classic,
          NoteTheme.gridPaper,
          NoteTheme.gridPaper
        ]);
    await AppCardStyleSettings.instance
        .saveDefaults(const NoteCardStyle(noteTheme: NoteTheme.sticky));
    await tester.pumpAndSettle();
    final papers =
        tester.widgetList<PaperNote>(find.byType(PaperNote)).toList();
    expect(papers.map((p) => p.theme), [
      NoteTheme.sticky,
      NoteTheme.sticky,
      NoteTheme.gridPaper,
      NoteTheme.gridPaper,
    ]);
    expect(papers.take(2).map((p) => p.color),
        everyElement(noteThemePaperColor(NoteTheme.sticky)));
    expect(papers.skip(2).map((p) => p.color), everyElement(explicit.color));
    expect(inherited.cardStyle.isDefault, isTrue);
    expect(inherited.todo.single.completed, isFalse);
    expect(inherited.todo.single.title, 'Keep this task');
    expect(explicit.cardStyle.noteTheme, NoteTheme.gridPaper);
    expect(tester.takeException(), isNull);
  });

  test('all patterns safely paint tiny, empty and very tall paper', () {
    for (final theme in NoteTheme.values) {
      for (final size in [
        Size.zero,
        const Size(1, 1),
        const Size(280, 100000)
      ]) {
        final recorder = ui.PictureRecorder();
        NoteThemePainter(theme: theme, color: noteThemePaperColor(theme))
            .paint(Canvas(recorder), size);
        recorder.endRecording().dispose();
      }
    }
  });

  testWidgets('isolated stationery previews fit and switch themes locally',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final (preview, width, name) in [
      (noteThemeSurfaceLightPreview, 390.0, 'light'),
      (noteThemeSurfaceDarkPreview, 390.0, 'dark'),
      (noteThemeSurfaceLargeTextPreview, 280.0, 'english-2x'),
      (noteThemeSurfaceHongKongPreview, 280.0, 'hong-kong-2x'),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.physicalSize = Size(width, 720);
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(
          find.byType(NoteThemeSample), findsNWidgets(NoteTheme.values.length));
      final sheet = find.byKey(const ValueKey('note-theme-preview-sheet'));
      await tester.scrollUntilVisible(sheet, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.widget<ColoredBox>(sheet).color,
          noteThemePaperColor(NoteTheme.classic));
      await _capture(tester, '$name-classic');
      for (final theme in NoteTheme.values.skip(1)) {
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        final choice = find.byKey(ValueKey('preview-theme-${theme.name}'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await tester.tap(choice.hitTestable());
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(sheet, 300,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(
            tester.widget<ColoredBox>(sheet).color, noteThemePaperColor(theme));
        expect(tester.takeException(), isNull, reason: '$name ${theme.name}');
        await _capture(tester, '$name-${theme.name}');
      }
      expect(AppCardStyleSettings.instance.noteTheme, NoteTheme.classic);
    }
  });
}
