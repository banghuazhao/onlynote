import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_layout_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/card_style_sections.dart';
import 'package:onlynote/presentation/components/card_style_sections_previews.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

const _captureUi = bool.fromEnvironment('CAPTURE_UI');
Finder get _save => find.byKey(const ValueKey('card-style-save'));
Finder get _controls => find.descendant(
    of: find.byKey(const ValueKey('card-style-controls')),
    matching: find.byType(Scrollable));
Finder _section(CardStyleSection section) =>
    find.byKey(ValueKey('card-style-section-${section.name}'));
Finder _group(CardStyleSection section) =>
    find.byKey(ValueKey(switch (section) {
      CardStyleSection.theme => 'card-style-theme-group',
      CardStyleSection.color => 'card-style-color-group',
      CardStyleSection.text => 'card-style-text',
      CardStyleSection.layout => 'card-style-layout',
    }));

Note _note({NoteCardStyle style = const NoteCardStyle()}) => Note(
      id: 'section-note',
      title: 'A few weekend ideas',
      description: 'Walk by the coast and keep time for a cup of tea.',
      dateTime: DateTime(2026, 10, 13),
      cardStyle: style,
      color: const Color(0xFFD3EDE4),
      todo: [Todo(id: 'plan', title: 'Plan the route')],
    );

// AppTheme copies typography into component themes as well as textTheme.
// Give screenshot fixtures real Latin/CJK glyphs while retaining those metrics.
ThemeData _captureTheme(bool dark) {
  final base = dark ? AppTheme.dark : AppTheme.light;
  TextStyle? font(TextStyle? style) => style?.copyWith(
      fontFamily: 'Roboto', fontFamilyFallback: const ['DroidSansFallback']);
  ButtonStyle? button(ButtonStyle? style) => style?.copyWith(
      textStyle: WidgetStatePropertyAll(font(base.textTheme.labelLarge)));
  return base.copyWith(
    textTheme: base.textTheme
        .apply(fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']),
    primaryTextTheme: base.primaryTextTheme
        .apply(fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']),
    appBarTheme: base.appBarTheme
        .copyWith(titleTextStyle: font(base.appBarTheme.titleTextStyle)),
    textButtonTheme:
        TextButtonThemeData(style: button(base.textButtonTheme.style)),
    filledButtonTheme:
        FilledButtonThemeData(style: button(base.filledButtonTheme.style)),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: button(base.outlinedButtonTheme.style)),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: button(base.elevatedButtonTheme.style)),
    listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: font(base.listTileTheme.titleTextStyle),
        subtitleTextStyle: font(base.listTileTheme.subtitleTextStyle)),
    chipTheme:
        base.chipTheme.copyWith(labelStyle: font(base.chipTheme.labelStyle)),
    dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: font(base.dialogTheme.titleTextStyle),
        contentTextStyle: font(base.dialogTheme.contentTextStyle)),
    snackBarTheme: base.snackBarTheme
        .copyWith(contentTextStyle: font(base.snackBarTheme.contentTextStyle)),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        extendedTextStyle:
            font(base.floatingActionButtonTheme.extendedTextStyle)),
  );
}

Future<void> _open(WidgetTester tester, CardAppearanceScreen screen,
    {Locale locale = const Locale('en'),
    double textScale = 1,
    bool dark = false}) async {
  await tester.pumpWidget(RepaintBoundary(
    key: const ValueKey('appearance-sections-capture'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _captureUi
          ? _captureTheme(dark)
          : dark
              ? AppTheme.dark
              : AppTheme.light,
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale), disableAnimations: true),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen)),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open').hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, CardStyleSection section) async {
  final target = _section(section);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _tapControl(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    tester.state<ScrollableState>(_controls).position.jumpTo(0);
    await tester.pump();
  }
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 160, scrollable: _controls);
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
  final visible = tester.getRect(target).intersect(
      tester.getRect(find.byKey(const ValueKey('card-style-controls'))));
  expect(visible.isEmpty, isFalse,
      reason:
          'The control must have a visible area inside its scroll viewport.');
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
}

Future<void> _exerciseShortPanel(
    WidgetTester tester, CardStyleSection section) async {
  switch (section) {
    case CardStyleSection.theme:
      await _tapControl(
          tester, find.byKey(const ValueKey('note-theme-choice-legalPad')));
      expect(
          tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
          NoteTheme.legalPad);
    case CardStyleSection.color:
      await _tapControl(tester,
          find.byKey(ValueKey('card-style-color-${colors[7].toARGB32()}')));
      expect(
          tester.widget<NoteCard>(find.byType(NoteCard)).note.color, colors[7]);
      await _tapControl(
          tester,
          find.byKey(
              ValueKey('card-style-color-${_note().color!.toARGB32()}')));
    case CardStyleSection.text:
      await _tapControl(
          tester, find.byKey(const ValueKey('card-style-text-large')));
      expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.fontSize,
          AppFontSize.large);
    case CardStyleSection.layout:
      await _tapControl(
          tester, find.byKey(const ValueKey('card-style-card-large')));
      expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.cardSize,
          NoteCardSize.large);
  }
  await _tapControl(tester, find.byKey(const ValueKey('card-style-reset')));
  expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle,
      AppCardStyleSettings.instance.defaults);
  expect(
      tester.widget<NoteCard>(find.byType(NoteCard)).note.color, _note().color);
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Future<PremiumTestFixture> _premium(WidgetTester tester) async {
  final fixture = PremiumTestFixture(premium: true);
  await fixture.init();
  addTearDown(() async {
    await _dispose(tester);
    await fixture.dispose();
  });
  return fixture;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!_captureUi) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('appearance-sections-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-card-sections-$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  final originalFonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    await initializeDateFormatting();
    if (!_captureUi) return;
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
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    await AppCardStyleSettings.instance.load();
    for (final family in originalFonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily: _captureUi ? 'Roboto' : family,
              fontFamilyFallback: const ['DroidSansFallback'],
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(originalFonts));

  testWidgets(
      'only the selected group is mounted and changing it resets scroll',
      (tester) async {
    await _open(
        tester,
        CardAppearanceScreen(
            note: _note(), onSaveAppearance: (_, __) async {}));
    expect(
        tester
            .widget<CardStyleSections>(find.byType(CardStyleSections))
            .selected,
        CardStyleSection.theme);
    for (final section in CardStyleSection.values) {
      await _select(tester, section);
      for (final candidate in CardStyleSection.values) {
        expect(_group(candidate),
            candidate == section ? findsOneWidget : findsNothing);
      }
      expect(tester.state<ScrollableState>(_controls).position.pixels, 0);
    }
    await _select(tester, CardStyleSection.theme);
    await _tapControl(
        tester, find.byKey(const ValueKey('note-theme-choice-parchment')));
    expect(tester.state<ScrollableState>(_controls).position.pixels,
        greaterThan(0));
    await _select(tester, CardStyleSection.text);
    expect(tester.state<ScrollableState>(_controls).position.pixels, 0);
    expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
        NoteTheme.parchment);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('switching sections retains staged theme color text and layout',
      (tester) async {
    final fixture = await _premium(tester);
    final original = _note();
    NoteCardStyle? saved;
    Color? savedColor;
    var saves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
          note: original,
          premiumAccess: fixture.access,
          onSaveAppearance: (style, color) async {
            saved = style;
            savedColor = color;
            saves++;
          },
        ));
    await _tapControl(
        tester, find.byKey(const ValueKey('note-theme-choice-legalPad')));
    await _select(tester, CardStyleSection.color);
    await _tapControl(tester,
        find.byKey(ValueKey('card-style-color-${colors[7].toARGB32()}')));
    await _select(tester, CardStyleSection.text);
    await _tapControl(
        tester, find.byKey(const ValueKey('card-style-text-large')));
    await _select(tester, CardStyleSection.layout);
    await _tapControl(
        tester, find.byKey(const ValueKey('card-style-card-small')));
    await _tapControl(
        tester, find.byKey(const ValueKey('card-style-paper-plain')));
    for (final section in CardStyleSection.values) {
      await _select(tester, section);
      final preview = tester.widget<NoteCard>(find.byType(NoteCard));
      expect(preview.cardStyle!.noteTheme, NoteTheme.legalPad);
      expect(preview.cardStyle!.fontSize, AppFontSize.large);
      expect(preview.cardStyle!.cardSize, NoteCardSize.small);
      expect(preview.cardStyle!.paperStyle, NoteCardPaperStyle.plain);
      expect(preview.note.color, colors[7]);
      expect(saves, 0);
    }
    expect(original.cardStyle.isDefault, isTrue);
    expect(original.color, const Color(0xFFD3EDE4));
    await tester.tap(_save.hitTestable());
    await tester.pumpAndSettle();
    expect(
        saved,
        const NoteCardStyle(
            noteTheme: NoteTheme.legalPad,
            fontSize: AppFontSize.large,
            cardSize: NoteCardSize.small,
            paperStyle: NoteCardPaperStyle.plain));
    expect(savedColor, colors[7]);
    expect(saves, 1);
    expect(fixture.store.buyCalls, 0);
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('section navigation alone leaves Back free of discard prompts',
      (tester) async {
    var saves = 0;
    final original = _note();
    await _open(
        tester,
        CardAppearanceScreen(
            note: original, onSaveAppearance: (_, __) async => saves++));
    for (final section in CardStyleSection.values.reversed) {
      await _select(tester, section);
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(find.text(S.current.Card_Style_Discard_Title), findsNothing);
    expect(saves, 0);
    expect(original.cardStyle.isDefault, isTrue);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets(
      'common reset clears every style override from any active section',
      (tester) async {
    final fixture = await _premium(tester);
    const before = NoteCardStyle(
        noteTheme: NoteTheme.kraftNotebook,
        fontFamily: 'Roboto',
        fontSize: AppFontSize.large,
        cardSize: NoteCardSize.small,
        paperStyle: NoteCardPaperStyle.plain,
        showDate: false);
    for (final section in CardStyleSection.values) {
      await _dispose(tester);
      NoteCardStyle? saved;
      Color? savedColor;
      var saves = 0;
      await _open(
          tester,
          CardAppearanceScreen(
            note: _note(style: before),
            premiumAccess: fixture.access,
            onSaveAppearance: (style, color) async {
              saved = style;
              savedColor = color;
              saves++;
            },
          ));
      await _select(tester, section);
      await _tapControl(tester, find.byKey(const ValueKey('card-style-reset')));
      expect(
          tester
              .widget<CardStyleSections>(find.byType(CardStyleSections))
              .selected,
          section);
      await tester.tap(_save.hitTestable());
      await tester.pumpAndSettle();
      expect(saved!.isDefault, isTrue, reason: section.name);
      expect(savedColor, const Color(0xFFD3EDE4));
      expect(saves, 1);
      expect(find.byType(CardAppearanceScreen), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'pending save blocks section switches and stale disposed callbacks',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    var saves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
          note: _note(),
          onSaveAppearance: (_, __) async {
            saves++;
            await gate.future;
          },
        ));
    await _tapControl(
        tester, find.byKey(const ValueKey('note-theme-choice-sticky')));
    final selected =
        tester.widget<CardStyleSections>(find.byType(CardStyleSections));
    final callback = selected.onSelected;
    final chipCallback =
        tester.widget<ChoiceChip>(_section(CardStyleSection.text)).onSelected!;
    await tester.tap(_save.hitTestable());
    await tester.pump();
    expect(saves, 1);
    expect(
        tester
            .widget<CardStyleSections>(find.byType(CardStyleSections))
            .enabled,
        isFalse);
    callback(CardStyleSection.text);
    chipCallback(true);
    await tester.pump();
    expect(
        tester
            .widget<CardStyleSections>(find.byType(CardStyleSections))
            .selected,
        CardStyleSection.theme);
    expect(_group(CardStyleSection.text), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    callback(CardStyleSection.layout);
    chipCallback(true);
    gate.complete();
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered section callbacks cannot replace the staged panel',
      (tester) async {
    var saves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
            note: _note(), onSaveAppearance: (_, __) async => saves++));
    await _tapControl(
        tester, find.byKey(const ValueKey('note-theme-choice-sticky')));
    final callback = tester
        .widget<CardStyleSections>(find.byType(CardStyleSections))
        .onSelected;
    final chipCallback =
        tester.widget<ChoiceChip>(_section(CardStyleSection.text)).onSelected!;
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(S.current.Card_Style_Discard_Title), findsOneWidget);
    callback(CardStyleSection.text);
    chipCallback(true);
    await tester.pump();
    expect(
        tester
            .widget<CardStyleSections>(find.byType(CardStyleSections))
            .selected,
        CardStyleSection.theme);
    await tester.tap(find.text(S.current.Cancel).hitTestable());
    await tester.pumpAndSettle();
    expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.noteTheme,
        NoteTheme.sticky);
    expect(saves, 0);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('Color is omitted for defaults and legacy style-only callbacks',
      (tester) async {
    for (final screen in [
      const CardAppearanceScreen(),
      CardAppearanceScreen(note: _note(), onSave: (_) async {}),
    ]) {
      await _dispose(tester);
      await _open(tester, screen);
      expect(_section(CardStyleSection.color), findsNothing);
      expect(
          tester
              .widget<CardStyleSections>(find.byType(CardStyleSections))
              .sections,
          [
            CardStyleSection.theme,
            CardStyleSection.text,
            CardStyleSection.layout
          ]);
      await _select(tester, CardStyleSection.layout);
      expect(_group(CardStyleSection.layout), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CardAppearanceScreen), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await _dispose(tester);
  });

  for (final (locale, size, dark, name) in [
    (const Locale('en'), const Size(280, 760), false, 'english-2x'),
    (const Locale('zh'), const Size(280, 760), false, 'chinese-2x'),
    (const Locale('zh', 'HK'), const Size(280, 760), true, 'hong-kong-dark-2x'),
    (const Locale('en'), const Size(812, 375), true, 'landscape-dark-2x'),
    (const Locale('en'), const Size(568, 180), false, 'short-landscape-2x'),
  ]) {
    testWidgets('horizontal sections stay usable and semantic: $name',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        var saves = 0;
        await _open(
            tester,
            CardAppearanceScreen(
                note: _note(), onSaveAppearance: (_, __) async => saves++),
            locale: locale,
            textScale: 2,
            dark: dark);
        for (final section in CardStyleSection.values) {
          await _select(tester, section);
          final target = _section(section);
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          expect(
              tester
                  .getSemantics(target)
                  .getSemanticsData()
                  .flagsCollection
                  .isSelected,
              ui.Tristate.isTrue);
          expect(
              tester
                  .getSemantics(target)
                  .getSemanticsData()
                  .flagsCollection
                  .isButton,
              isTrue);
          expect(_group(section), findsOneWidget);
          expect(tester.takeException(), isNull, reason: section.name);
          await _capture(tester, '$name-${section.name}');
          if (name == 'short-landscape-2x') {
            await _exerciseShortPanel(tester, section);
            expect(tester.takeException(), isNull, reason: section.name);
          }
        }
        await tester.tap(find.byType(BackButton).hitTestable());
        await tester.pumpAndSettle();
        expect(saves, 0);
        expect(find.byType(CardAppearanceScreen), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
        await _dispose(tester);
      }
    });
  }

  testWidgets('pure section previews switch locally in light dark and CJK',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final defaults = AppCardStyleSettings.instance.defaults;
    for (final (preview, size, name) in [
      (cardStyleSectionsLightPreview, const Size(390, 700), 'pure-light'),
      (cardStyleSectionsDarkPreview, const Size(390, 700), 'pure-dark'),
      (cardStyleSectionsChinesePreview, const Size(280, 700), 'pure-cjk-2x'),
    ]) {
      await _dispose(tester);
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('appearance-sections-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<CardStyleSections>(find.byType(CardStyleSections))
              .selected,
          CardStyleSection.theme);
      for (final section in CardStyleSection.values) {
        await _select(tester, section);
        final feedback = tester.widget<Text>(
            find.byKey(const ValueKey('card-style-preview-selected')));
        expect(feedback.data, cardStyleSectionLabel(section, S.current));
        expect(find.byKey(ValueKey('card-style-preview-panel-${section.name}')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, '$name-${section.name}');
      }
      expect(AppCardStyleSettings.instance.defaults, defaults);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    }
    await _dispose(tester);
  });
}
