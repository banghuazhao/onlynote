import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/premium_theme_showcase.dart';
import 'package:onlynote/presentation/screens/settings/premium_previews.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/premium_access.dart';

import '../support/premium_test_fakes.dart';

ThemeData? _captureTheme(Brightness brightness) {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return null;
  final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
  TextStyle? fontStyle(TextStyle? style) => style?.copyWith(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['DroidSansFallback'],
      );
  ButtonStyle? buttonStyle(ButtonStyle? style) => style?.copyWith(
        textStyle: WidgetStatePropertyAll(fontStyle(base.textTheme.labelLarge)),
      );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['DroidSansFallback'],
    ),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: fontStyle(base.appBarTheme.titleTextStyle),
    ),
    filledButtonTheme:
        FilledButtonThemeData(style: buttonStyle(base.filledButtonTheme.style)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonStyle(base.outlinedButtonTheme.style)),
    textButtonTheme:
        TextButtonThemeData(style: buttonStyle(base.textButtonTheme.style)),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('premium-showcase-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
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
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    for (final feature in [
      PremiumFeature.voiceMemos,
      PremiumFeature.repeatingReminders,
      PremiumFeature.individualCardStyle,
    ]) {
      testWidgets('$locale $feature explains the requested upgrade',
          (tester) async {
        final fixture = PremiumTestFixture();
        await fixture.init();
        addTearDown(fixture.dispose);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: PremiumScreen(purchases: fixture.purchases, feature: feature),
        ));
        await tester.pumpAndSettle();
        final strings = S.of(tester.element(find.byType(PremiumScreen)));
        final reason = switch (feature) {
          PremiumFeature.voiceMemos => strings.Premium_Voice_Memos_Description,
          PremiumFeature.repeatingReminders =>
            strings.Premium_Repeating_Reminders_Description,
          _ => strings.Premium_Card_Style_Description,
        };
        expect(find.text(reason), findsOneWidget);
        expect(find.text(strings.Premium_Feature_Required), findsNothing);
        final buy = find.byKey(const ValueKey('premium-buy'));
        expect(buy.hitTestable(), findsOneWidget);
        expect(tester.getTopLeft(buy).dy,
            lessThan(tester.getTopLeft(find.byType(PremiumThemeShowcase)).dy));
        expect(
            tester.getTopLeft(buy).dy,
            lessThan(tester
                .getTopLeft(find.text(strings.Premium_Benefits_Title))
                .dy));
        expect(fixture.store.buyCalls, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final (name, preview, size, locale, brightness) in [
    (
      'premium-showcase-light',
      premiumUpgradePreview,
      const Size(390, 844),
      const Locale('en'),
      Brightness.light,
    ),
    (
      'premium-showcase-dark',
      premiumDarkUpgradePreview,
      const Size(390, 844),
      const Locale('en'),
      Brightness.dark,
    ),
    (
      'premium-showcase-english-large-text',
      premiumLargeTextPreview,
      const Size(280, 760),
      const Locale('en'),
      Brightness.light,
    ),
    (
      'premium-showcase-chinese-large-text',
      premiumChinesePreview,
      const Size(320, 760),
      const Locale('zh', 'HK'),
      Brightness.light,
    ),
    (
      'premium-showcase-simplified-large-text',
      premiumSimplifiedChinesePreview,
      const Size(320, 760),
      const Locale('zh'),
      Brightness.light,
    ),
    (
      'premium-showcase-mac',
      premiumDesktopPreview,
      const Size(1100, 720),
      const Locale('en'),
      Brightness.light,
    ),
  ]) {
    testWidgets('$name keeps real paper samples local and readable',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('premium-showcase-capture'),
        child: preview(theme: _captureTheme(brightness)),
      ));
      await tester.pumpAndSettle();
      final screen = tester.widget<PremiumScreen>(find.byType(PremiumScreen));
      final context = tester.element(find.byType(PremiumScreen));
      final strings = S.of(context);
      expect(Localizations.localeOf(context), locale);
      expect(Theme.of(context).brightness, brightness);
      expect(screen.purchases!.isPremium, isFalse);
      expect(find.text(strings.Premium_Showcase_Note_Title), findsOneWidget);
      expect(find.text(strings.Premium_Showcase_Note_Body), findsOneWidget);
      expect(
          find.text(strings.Premium_Showcase_Checklist_Title), findsOneWidget);
      expect(
          find.text(strings.Premium_Showcase_Checklist_Item), findsOneWidget);
      final samples = tester.widgetList<PaperNote>(find.descendant(
          of: find.byType(PremiumThemeShowcase),
          matching: find.byType(PaperNote)));
      expect(samples.map((sample) => sample.theme),
          [NoteTheme.dottedJournal, NoteTheme.kraftNotebook]);
      for (final sample in samples) {
        expect(sample.plainPaper, isFalse);
        expect(sample.tilt, isFalse);
      }
      await _capture(tester, '$name-offer');
      await tester.ensureVisible(find.byType(PremiumThemeShowcase));
      await tester.pumpAndSettle();
      await _capture(tester, '$name-samples');
      await tester.tap(
          find.byKey(const ValueKey('premium-showcase-dottedJournal')),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(screen.purchases!.isPremium, isFalse);
      await tester.ensureVisible(find.byKey(const ValueKey('premium-restore')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('premium-restore')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
