import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_theme_choices.dart';
import 'package:onlynote/presentation/components/note_theme_choices_previews.dart';
import 'package:onlynote/presentation/components/note_theme_labels.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';

Finder _choice(NoteTheme? theme) =>
    find.byKey(ValueKey('note-theme-choice-${theme?.name ?? "default"}'));

Widget _host(Widget child,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(
        fontFamily: const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null,
        fontFamilyFallback: const bool.fromEnvironment('CAPTURE_UI')
            ? const ['DroidSansFallback']
            : null,
      ),
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('note-theme-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-release-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  testWidgets('free theme choices preview Premium and retain explicit IDs',
      (tester) async {
    final selected = <NoteTheme?>[];
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(NoteThemeChoices(
        selected: NoteTheme.classic,
        onSelected: selected.add,
      )));
      await tester.pumpAndSettle();
      expect(_choice(null), findsNothing);
      expect(
          find.byType(NoteThemeSample), findsNWidgets(NoteTheme.values.length));
      expect(find.text(S.current.Premium), findsNWidgets(3));
      for (final theme in NoteTheme.values) {
        final row = _choice(theme);
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(
            find.descendant(
                of: row, matching: find.text(noteThemeLabel(theme, S.current))),
            findsOneWidget);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        expect(
            tester
                .getSemantics(row)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isTrue);
        expect(
            find.descendant(
                of: row, matching: find.byIcon(Icons.lock_outline_rounded)),
            theme.isPremium ? findsOneWidget : findsNothing);
        await tester.tap(row);
        await tester.pump();
      }
      expect(selected, NoteTheme.values);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('inherited theme and Classic are distinct choices',
      (tester) async {
    final selected = <NoteTheme?>[];
    await tester.pumpWidget(_host(NoteThemeChoices(
      selected: null,
      inheritedTheme: NoteTheme.gridPaper,
      showInherited: true,
      premiumAvailable: true,
      onSelected: selected.add,
    )));
    await tester.pumpAndSettle();
    final inheritedSample = tester.widget<NoteThemeSample>(find.descendant(
        of: _choice(null), matching: find.byType(NoteThemeSample)));
    expect(inheritedSample.theme, NoteTheme.gridPaper);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    await tester.tap(_choice(null));
    await tester.tap(_choice(NoteTheme.classic));
    await tester.pump();
    expect(selected, [null, NoteTheme.classic]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'disabled choices and captured covered or detached actions do nothing',
      (tester) async {
    var changes = 0;
    NoteThemeChoices choices(bool enabled) => NoteThemeChoices(
        selected: NoteTheme.classic,
        enabled: enabled,
        onSelected: (_) => changes++);
    await tester.pumpWidget(_host(choices(false)));
    await tester.pumpAndSettle();
    final disabled = tester.widget<InkWell>(find.descendant(
        of: _choice(NoteTheme.sticky), matching: find.byType(InkWell)));
    expect(disabled.onTap, isNull);
    await tester.tap(_choice(NoteTheme.sticky));
    await tester.pump();
    expect(changes, 0);
    await tester.pumpWidget(_host(choices(true)));
    await tester.pumpAndSettle();
    final callback = tester
        .widget<InkWell>(find.descendant(
            of: _choice(NoteTheme.sticky), matching: find.byType(InkWell)))
        .onTap!;
    final context = tester.element(_choice(NoteTheme.sticky));
    showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('Covered')));
    await tester.pumpAndSettle();
    callback();
    expect(changes, 0);
    Navigator.pop(context);
    await tester.pumpAndSettle();
    callback();
    expect(changes, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    callback();
    expect(changes, 1);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets('$locale theme rows fit a 100px content width at large text',
        (tester) async {
      final changes = <NoteTheme?>[];
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 116,
              child: NoteThemeChoices(
                selected: NoteTheme.classic,
                onSelected: changes.add,
              ),
            ),
          ),
          locale: locale,
          scale: 2.4,
        ));
        await tester.pumpAndSettle();
        for (final theme in NoteTheme.values) {
          final row = _choice(theme);
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          expect(tester.getSize(row).width, 116);
          expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
          expect(tester.getSemantics(row).getSemanticsData().label,
              contains(noteThemeLabel(theme, S.current)));
          await tester.tap(row);
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        expect(changes, NoteTheme.values);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final (name, preview, size, locale, brightness) in [
    (
      'note-themes-light',
      noteThemeChoicesLightPreview,
      const Size(390, 780),
      const Locale('en'),
      Brightness.light
    ),
    (
      'note-themes-dark',
      noteThemeChoicesDarkPreview,
      const Size(390, 780),
      const Locale('en'),
      Brightness.dark
    ),
    (
      'note-themes-chinese',
      noteThemeChoicesChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light
    ),
  ]) {
    testWidgets('$name keeps local previews and readable accessible rows',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('note-theme-capture'),
          child: preview(),
        ));
        await tester.pumpAndSettle();
        final selected =
            find.byKey(const ValueKey('note-theme-preview-selected'));
        expect(Localizations.localeOf(tester.element(selected)), locale);
        expect(Theme.of(tester.element(selected)).brightness, brightness);
        expect(find.text(S.current.Note_Theme), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, '$name-initial');
        for (final theme in NoteTheme.values) {
          final row = _choice(theme);
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
          final data = tester.getSemantics(row).getSemanticsData();
          expect(data.label, contains(noteThemeLabel(theme, S.current)));
          expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
          await tester.tap(row);
          await tester.pumpAndSettle();
          expect(
              tester
                  .widget<NoteThemeChoices>(find.byType(NoteThemeChoices))
                  .selected,
              theme);
          expect(tester.takeException(), isNull);
        }
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(selected).data,
            noteThemeLabel(NoteTheme.parchment, S.current));
        await _capture(tester, '$name-premium');
        await tester.ensureVisible(_choice(null));
        await tester.pumpAndSettle();
        await tester.tap(_choice(null));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<NoteThemeChoices>(find.byType(NoteThemeChoices))
                .selected,
            isNull);
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(selected).data,
            S.current.Card_Style_Use_Default);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  }
}
