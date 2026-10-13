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
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_previews.dart';
import 'package:onlynote/presentation/screens/card_appearance/card_appearance_screen.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

const _captureUi = bool.fromEnvironment('CAPTURE_UI');

Widget _host(Widget screen,
        {bool dark = false,
        double scale = 1,
        Locale locale = const Locale('en')}) =>
    RepaintBoundary(
      key: const ValueKey('appearance-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: Center(
                    child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => screen)),
                        child: const Text('Open'))))),
      ),
    );

Note _note({NoteCardStyle style = const NoteCardStyle()}) => Note(
      id: 'trip',
      title: 'Trip planning',
      description:
          'Take the coastal route and stop for tea. Save a few ideas for the weekend.',
      dateTime: DateTime(2026, 10, 7),
      cardStyle: style,
      todo: [
        Todo(id: 'route', title: 'Plan the route'),
        Todo(id: 'book', title: 'Book lunch', completed: true),
        Todo(id: 'bag', title: 'Pack a light bag')
      ],
      imagePaths: ['preview/coast.jpg'],
    );

Widget _thumbnail(BuildContext context, String path) => const ColoredBox(
    color: Color(0xFFADC9BA),
    child: Center(child: Icon(Icons.landscape_rounded, size: 48)));

Future<void> _open(WidgetTester tester, Widget screen,
    {bool dark = false,
    double scale = 1,
    Locale locale = const Locale('en')}) async {
  await tester
      .pumpWidget(_host(screen, dark: dark, scale: scale, locale: locale));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder _controls() => find.descendant(
    of: find.byKey(const ValueKey('card-style-controls')),
    matching: find.byType(Scrollable));

Finder _choice(String title, String label) {
  final group = title == S.current.Font_Size
      ? 'card-style-font-size'
      : title == S.current.Card_Size
          ? 'card-style-size'
          : 'card-style-paper';
  return find.descendant(
      of: find.byKey(ValueKey(group)),
      matching: find.widgetWithText(ChoiceChip, label));
}

Finder _color(Color color) =>
    find.byKey(ValueKey('card-style-color-${color.toARGB32()}'));

Future<void> _selectSection(WidgetTester tester, String section) async {
  final tab = find.byKey(ValueKey('card-style-section-$section'));
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _revealControl(WidgetTester tester, Finder target,
    {String? section}) async {
  if (section != null) await _selectSection(tester, section);
  if (target.evaluate().isEmpty) {
    tester.state<ScrollableState>(_controls()).position.jumpTo(0);
    await tester.pump();
  }
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
  } else {
    await tester.scrollUntilVisible(target, 150, scrollable: _controls());
  }
  await tester.pumpAndSettle();
}

Future<void> _tapControl(WidgetTester tester, Finder target,
    {String? section}) async {
  await _revealControl(tester, target, section: section);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!_captureUi) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('appearance-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-card-appearance-$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    await initializeDateFormatting();
    if (_captureUi) {
      for (final family in ['Roboto', 'DroidSansFallback']) {
        await (FontLoader(family)
              ..addFont(rootBundle.load(
                  'assets/fonts/$family${family == 'Roboto' ? '-Regular' : ''}.ttf')))
            .load();
      }
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    await AppAppearanceSettings.instance.load();
    await AppCardStyleSettings.instance.load();
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily: _captureUi ? 'Roboto' : family,
              fontFamilyFallback:
                  _captureUi ? const ['DroidSansFallback'] : null,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('color-only save stays free and keeps an existing custom style',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    const originalColor = Color(0xFF14283C);
    const style = NoteCardStyle(fontSize: AppFontSize.small);
    NoteCardStyle? savedStyle;
    Color? savedColor;
    var legacySaves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
          premiumAccess: fixture.access,
          note: _note(style: style).copyWith(color: originalColor),
          thumbnailBuilder: _thumbnail,
          onSave: (_) async => legacySaves++,
          onSaveAppearance: (style, color) async {
            savedStyle = style;
            savedColor = color;
          },
        ));
    await _revealControl(tester, _color(originalColor), section: 'color');
    final swatch = tester.widget<IconButton>(find.descendant(
        of: _color(originalColor), matching: find.byType(IconButton)));
    expect(swatch.isSelected, isTrue);
    expect(swatch.style!.foregroundColor!.resolve({}), Colors.white);
    expect(tester.getSize(_color(originalColor)), const Size(48, 48));
    await _tapControl(tester, _color(colors[7]), section: 'color');
    expect(
        tester.widget<NoteCard>(find.byType(NoteCard)).note.color, colors[7]);
    await _capture(tester, 'color-light');
    expect(savedStyle, isNull);
    expect(savedColor, isNull);
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(savedStyle, style);
    expect(savedColor, colors[7]);
    expect(legacySaves, 0);
    expect(fixture.store.buyCalls, 0);
    expect(find.byType(PremiumScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('color is staged until Save and discard never publishes it',
      (tester) async {
    var saves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
          note: _note().copyWith(color: colors[2]),
          thumbnailBuilder: _thumbnail,
          onSaveAppearance: (_, color) async => saves++,
        ));
    await _tapControl(tester, _color(colors[8]), section: 'color');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(S.current.Card_Style_Discard_Title), findsOneWidget);
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NoteCard>(find.byType(NoteCard)).note.color, colors[8]);
    expect(saves, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Card_Style_Discard));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.byType(CardAppearanceScreen), findsNothing);
  });

  testWidgets('default color saves null and style reset preserves staged color',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    NoteCardStyle? savedStyle;
    Color? savedColor = colors.first;
    await _open(
        tester,
        CardAppearanceScreen(
          premiumAccess: fixture.access,
          note: _note(style: const NoteCardStyle(showDate: false))
              .copyWith(color: colors[1]),
          thumbnailBuilder: _thumbnail,
          onSaveAppearance: (style, color) async {
            savedStyle = style;
            savedColor = color;
          },
        ));
    await _tapControl(tester, _color(colors[8]), section: 'color');
    await _tapControl(tester, find.byKey(const ValueKey('card-style-reset')));
    expect(
        tester.widget<NoteCard>(find.byType(NoteCard)).note.color, colors[8]);
    expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.showDate,
        isTrue);
    await _tapControl(
        tester, find.byKey(const ValueKey('card-style-color-default')),
        section: 'color');
    expect(tester.widget<NoteCard>(find.byType(NoteCard)).note.color, isNull);
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(savedStyle!.isDefault, isTrue);
    expect(savedColor, isNull);
    expect(find.byType(PremiumScreen), findsNothing);
  });

  testWidgets('color remains staged when a custom style upgrade is cancelled',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    var saves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
          premiumAccess: fixture.access,
          note: _note(),
          thumbnailBuilder: _thumbnail,
          onSaveAppearance: (_, color) async => saves++,
        ));
    await _tapControl(tester, _color(colors[3]), section: 'color');
    await _tapControl(
        tester, find.byKey(const ValueKey('card-style-text-large')),
        section: 'text');
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsOneWidget);
    expect(saves, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final preview = tester.widget<NoteCard>(find.byType(NoteCard));
    expect(preview.note.color, colors[3]);
    expect(preview.cardStyle!.fontSize, AppFontSize.large);
    expect(saves, 0);
    expect(find.text(S.current.Card_Style_Save_Failed), findsNothing);
  });

  testWidgets('grouped controls keep date inheritance explicit',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    NoteCardStyle? saved;
    await _open(
        tester,
        CardAppearanceScreen(
          premiumAccess: fixture.access,
          note: _note(),
          thumbnailBuilder: _thumbnail,
          onSaveAppearance: (style, color) async => saved = style,
        ));
    await _revealControl(
        tester, find.byKey(const ValueKey('card-style-color-group')),
        section: 'color');
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('card-style-color-group')),
            matching: find.text(S.current.Card_Style_Color)),
        findsOneWidget);
    await _tapControl(tester, find.byKey(const ValueKey('card-style-font')),
        section: 'text');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await _revealControl(tester, find.byKey(const ValueKey('card-style-text')),
        section: 'text');
    expect(find.byKey(const ValueKey('card-style-text')), findsOneWidget);
    await _tapControl(tester, find.byKey(const ValueKey('card-style-date')),
        section: 'layout');
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const ValueKey('card-style-date')))
            .value,
        isFalse);
    expect(find.byKey(const ValueKey('card-date')), findsNothing);
    await _tapControl(
        tester, find.byKey(const ValueKey('card-style-date-default')),
        section: 'layout');
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const ValueKey('card-style-date')))
            .value,
        isTrue);
    expect(find.byKey(const ValueKey('card-style-date-default')), findsNothing);
    // Change only the color so the inherited date choice is persisted for free.
    await _tapControl(tester, _color(colors[5]), section: 'color');
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(saved!.showDate, isNull);
    expect(saved!.isDefault, isTrue);
  });

  testWidgets('default and legacy style screens hide unsavable color controls',
      (tester) async {
    await _open(
        tester,
        CardAppearanceScreen(
          note: _note().copyWith(color: colors[2]),
          thumbnailBuilder: _thumbnail,
          onSave: (_) async {},
        ));
    expect(find.byKey(const ValueKey('card-style-color-group')), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _open(tester, CardAppearanceScreen(onSave: (_) async {}));
    expect(find.byKey(const ValueKey('card-style-color-group')), findsNothing);
    await _revealControl(tester, find.byKey(const ValueKey('card-style-text')),
        section: 'text');
    expect(find.byKey(const ValueKey('card-style-text')), findsOneWidget);
    await _tapControl(tester, find.byKey(const ValueKey('card-style-date')),
        section: 'layout');
    expect(find.byKey(const ValueKey('card-style-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('card-style-date-default')), findsNothing);
  });

  testWidgets('free users preview custom styles, cancel upgrade, then reset',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    NoteCardStyle? saved;
    await _open(
        tester,
        CardAppearanceScreen(
            premiumAccess: fixture.access,
            note:
                _note(style: const NoteCardStyle(fontSize: AppFontSize.small)),
            thumbnailBuilder: _thumbnail,
            onSave: (style) async => saved = style));
    await _tapControl(tester, _choice(S.current.Font_Size, S.current.Large),
        section: 'text');
    expect(saved, isNull);
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsOneWidget);
    expect(saved, isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.fontSize,
        AppFontSize.large);
    expect(find.text(S.current.Card_Style_Save_Failed), findsNothing);
    await _tapControl(tester, find.byKey(const ValueKey('card-style-reset')));
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(saved!.isDefault, isTrue);
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(fixture.store.buyCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buying Premium resumes staged custom card save', (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    NoteCardStyle? saved;
    await _open(
        tester,
        CardAppearanceScreen(
            premiumAccess: fixture.access,
            note: _note(),
            thumbnailBuilder: _thumbnail,
            onSave: (style) async => saved = style));
    await _tapControl(tester, _choice(S.current.Font_Size, S.current.Large),
        section: 'text');
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    final buy = find.byKey(const ValueKey('premium-buy'));
    await tester.ensureVisible(buy);
    await tester.tap(buy);
    await tester.pumpAndSettle();
    expect(fixture.access.isPremium, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(saved!.fontSize, AppFontSize.large);
    expect(find.byType(CardAppearanceScreen), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing custom cards and default style stay usable for free',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    var saves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
            premiumAccess: fixture.access,
            note:
                _note(style: const NoteCardStyle(fontSize: AppFontSize.small)),
            thumbnailBuilder: _thumbnail,
            onSave: (_) async => saves++));
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsNothing);
    expect(saves, 0);
    await _open(
        tester,
        CardAppearanceScreen(
            premiumAccess: fixture.access,
            thumbnailBuilder: _thumbnail,
            onSave: (_) async => saves++));
    await _tapControl(tester, _choice(S.current.Font_Size, S.current.Large),
        section: 'text');
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsNothing);
    expect(saves, 1);
    expect(fixture.store.buyCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'current card previews every option without publishing before save',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    NoteCardStyle? saved;
    await _open(
        tester,
        CardAppearanceScreen(
            note: _note(),
            thumbnailBuilder: _thumbnail,
            onSave: (style) async => saved = style));
    await _capture(tester, 'light');
    expect(find.text('Trip planning'), findsOneWidget);
    final initialWidth = tester
        .getSize(find.byKey(const ValueKey('card-style-preview-width')))
        .width;
    await _tapControl(tester, find.byKey(const ValueKey('card-style-font')),
        section: 'text');
    await tester.tap(find.text('Kalam'));
    await tester.pumpAndSettle();
    var title = tester.widget<SearchHighlight>(
        find.widgetWithText(SearchHighlight, 'Trip planning'));
    expect(title.style!.fontFamily, _captureUi ? 'Roboto' : 'Kalam');
    await _tapControl(tester, _choice(S.current.Font_Size, S.current.Large),
        section: 'text');
    title = tester.widget<SearchHighlight>(
        find.widgetWithText(SearchHighlight, 'Trip planning'));
    expect(title.style!.fontSize, 24);
    final row =
        tester.widget<PaperChecklistRow>(find.byType(PaperChecklistRow).first);
    expect(row.textStyle!.fontFamily, _captureUi ? 'Roboto' : 'Kalam');
    expect(row.textStyle!.fontSize, 16.8);
    await _tapControl(tester, _choice(S.current.Card_Size, S.current.Large),
        section: 'layout');
    expect(
        tester
            .getSize(find.byKey(const ValueKey('card-style-preview-width')))
            .width,
        greaterThan(initialWidth));
    await _tapControl(
        tester, _choice(S.current.Card_Style_Paper, S.current.Card_Style_Plain),
        section: 'layout');
    expect(tester.widget<PaperNote>(find.byType(PaperNote)).plainPaper, isTrue);
    await _tapControl(tester, find.byKey(const ValueKey('card-style-date')),
        section: 'layout');
    expect(find.byKey(const ValueKey('card-date')), findsNothing);
    expect(saved, isNull);
    expect(AppTypographySettings.instance.fontFamily, 'Montserrat');
    expect(AppLayoutSettings.instance.cardSize, NoteCardSize.medium);
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(
        saved,
        const NoteCardStyle(
            fontFamily: 'Kalam',
            fontSize: AppFontSize.large,
            cardSize: NoteCardSize.large,
            paperStyle: NoteCardPaperStyle.plain,
            showDate: false));
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back keeps edits on cancel and discards without saving',
      (tester) async {
    var saves = 0;
    await _open(
        tester,
        CardAppearanceScreen(
            note: _note(),
            thumbnailBuilder: _thumbnail,
            onSave: (_) async => saves++));
    await _tapControl(tester, _choice(S.current.Font_Size, S.current.Small),
        section: 'text');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Card_Style_Discard_Title), findsOneWidget);
    await tester.tap(find.text(S.current.Cancel));
    await tester.pumpAndSettle();
    expect(find.byType(CardAppearanceScreen), findsOneWidget);
    expect(tester.widget<NoteCard>(find.byType(NoteCard)).cardStyle!.fontSize,
        AppFontSize.small);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Card_Style_Discard));
    await tester.pumpAndSettle();
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid unchanged Save taps close only the appearance screen',
      (tester) async {
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Notes'))));
    await tester.pumpAndSettle();
    var saves = 0;
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => CardAppearanceScreen(
            note: _note(),
            thumbnailBuilder: _thumbnail,
            onSave: (_) async => saves++)));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('card-style-save'));
    await tester.tap(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(find.text('Notes'), findsOneWidget);
    expect(navigator.canPop(), isTrue);
    expect(saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reset restores inheritance instead of copying the current defaults',
      (tester) async {
    NoteCardStyle? saved;
    await _open(
        tester,
        CardAppearanceScreen(
            note: _note(
                style: const NoteCardStyle(
                    fontFamily: 'Kalam',
                    fontSize: AppFontSize.small,
                    cardSize: NoteCardSize.large,
                    paperStyle: NoteCardPaperStyle.plain,
                    showDate: false)),
            thumbnailBuilder: _thumbnail,
            onSave: (style) async => saved = style));
    await _tapControl(tester, find.byKey(const ValueKey('card-style-reset')));
    final preview = tester.widget<NoteCard>(find.byType(NoteCard));
    expect(preview.cardStyle!.fontFamily, 'Montserrat');
    expect(preview.cardStyle!.showDate, isTrue);
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(saved!.isDefault, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps the preview editable and allows retry',
      (tester) async {
    var attempts = 0;
    await _open(
        tester,
        CardAppearanceScreen(
            note: _note(),
            thumbnailBuilder: _thumbnail,
            onSave: (_) async {
              if (++attempts == 1) throw StateError('Unavailable');
            }));
    await _tapControl(tester, _choice(S.current.Font_Size, S.current.Large),
        section: 'text');
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Card_Style_Save_Failed), findsWidgets);
    expect(find.byType(CardAppearanceScreen), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('card-style-save')))
            .onPressed,
        isNotNull);
    await tester.tap(find.byKey(const ValueKey('card-style-save')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(CardAppearanceScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (size, dark, locale, label) in [
    (const Size(180, 700), false, const Locale('en'), 'narrow'),
    (const Size(812, 375), true, const Locale('en'), 'landscape-dark'),
    (const Size(320, 760), true, const Locale('zh', 'HK'), 'chinese-dark'),
  ]) {
    testWidgets('preview and controls remain usable at large text: $label',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        var saved = false;
        await _open(
            tester,
            CardAppearanceScreen(
                note: _note(),
                thumbnailBuilder: _thumbnail,
                onSaveAppearance: (_, color) async => saved = true),
            dark: dark,
            scale: 2.4,
            locale: locale);
        await _capture(tester, label);
        await _tapControl(tester,
            _choice(S.current.Card_Style_Paper, S.current.Card_Style_Plain),
            section: 'layout');
        await tester.tap(find.byKey(const ValueKey('card-style-save')));
        await tester.pumpAndSettle();
        expect(saved, isTrue);
        expect(find.byType(CardAppearanceScreen), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
      'interactive appearance previews remain local and reopen after save',
      (tester) async {
    for (final preview in [
      defaultCardStylePreview,
      darkCardStylePreview,
      chineseCardStylePreview
    ]) {
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(find.byType(CardAppearanceScreen), findsOneWidget);
      await _tapControl(tester, _choice(S.current.Font_Size, S.current.Small),
          section: 'text');
      await tester.tap(find.byKey(const ValueKey('card-style-save')));
      await tester.pumpAndSettle();
      expect(find.byType(CardAppearanceScreen), findsNothing);
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.style_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(CardAppearanceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
