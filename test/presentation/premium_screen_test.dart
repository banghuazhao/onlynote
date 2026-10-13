import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/settings/premium_previews.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

const _buyKey = ValueKey('premium-buy');
const _restoreKey = ValueKey('premium-restore');

Widget _host(Widget screen,
        {bool dark = false,
        double scale = 1,
        Locale locale = const Locale('en')}) =>
    RepaintBoundary(
      key: const ValueKey('premium-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
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
        home: screen,
      ),
    );

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _drainFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('premium-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-premium-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
        .load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final locale in [const Locale('en'), const Locale('zh', 'HK')]) {
    testWidgets('$locale advanced theme upgrade shows its reason and benefit',
        (tester) async {
      tester.view.physicalSize = const Size(280, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fixture = PremiumTestFixture();
      await fixture.init();
      addTearDown(fixture.dispose);
      await tester.pumpWidget(_host(
          PremiumScreen(
              purchases: fixture.purchases, feature: PremiumFeature.noteThemes),
          locale: locale,
          scale: 2));
      await tester.pumpAndSettle();
      expect(
          find.text(S.current.Premium_Note_Themes_Description), findsOneWidget);
      final benefit = find.text(S.current.Premium_Note_Themes);
      await tester.ensureVisible(benefit);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(benefit).style?.fontWeight, FontWeight.w600);
      expect(fixture.store.buyCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Settings gives folders and backup the same 16pt spacing',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester
        .pumpWidget(_host(SettingsScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    final folders = find.ancestor(
        of: find.text('Manage Folders'), matching: find.byType(Card));
    final backup = find.ancestor(
        of: find.text('Backup & Restore'), matching: find.byType(Card));
    expect(tester.getTopLeft(backup).dy - tester.getBottomLeft(folders).dy, 16);
    expect(find.text('Remove Ads'), findsNothing);
    expect(find.text('Upgrade to Premium'), findsOneWidget);
    await _tap(tester, find.text('Upgrade to Premium'));
    expect(find.byType(PremiumScreen), findsOneWidget);
    expect(find.text('Unlimited notes'), findsOneWidget);
    expect(find.text('Voice memos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Premium Settings displays unlocked status and keeps restore',
      (tester) async {
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester
        .pumpWidget(_host(SettingsScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    expect(find.text('Remove Ads'), findsNothing);
    expect(find.text('Upgrade to Premium'), findsNothing);
    expect(find.text('Premium unlocked'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
    await _tap(tester, find.text('Premium unlocked'));
    expect(find.byKey(_buyKey), findsNothing);
    expect(find.byKey(_restoreKey), findsOneWidget);
  });

  testWidgets('unsupported platforms have no purchase section', (tester) async {
    final fixture = PremiumTestFixture(supported: false);
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester
        .pumpWidget(_host(SettingsScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade to Premium'), findsNothing);
    expect(find.text('Restore Purchases'), findsNothing);
  });

  testWidgets('one-time purchase unlocks benefits and removes the buy button',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_host(PremiumScreen(
        purchases: fixture.purchases, feature: PremiumFeature.voiceMemos)));
    await tester.pumpAndSettle();
    expect(find.text(r'Unlock forever for $2.99'), findsOneWidget);
    expect(find.text('Unlock this feature with Premium.'), findsOneWidget);
    await _tap(tester, find.byKey(_buyKey));
    expect(fixture.purchases.isPremium, isTrue);
    expect(fixture.storage.value, isTrue);
    expect(fixture.store.buyCalls, 1);
    expect(find.byKey(_buyKey), findsNothing);
    expect(find.text('Premium unlocked'), findsOneWidget);
    expect(find.text('Premium is unlocked.'), findsOneWidget);
    expect(find.byKey(_restoreKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
    testWidgets('$status keeps free access and enables purchase retry',
        (tester) async {
      final fixture = PremiumTestFixture();
      fixture.store.grantOnBuy = false;
      await fixture.init();
      addTearDown(fixture.dispose);
      await tester
          .pumpWidget(_host(PremiumScreen(purchases: fixture.purchases)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(_buyKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_buyKey));
      await tester.pump();
      expect(fixture.purchases.state, PurchaseState.pending);
      expect(
          tester.widget<FilledButton>(find.byKey(_buyKey)).onPressed, isNull);
      fixture.store.emit(status);
      await tester.pumpAndSettle();
      expect(fixture.purchases.isPremium, isFalse);
      expect(fixture.storage.value, isFalse);
      expect(tester.widget<FilledButton>(find.byKey(_buyKey)).onPressed,
          isNotNull);
      expect(
          find.text(status == PurchaseStatus.canceled
              ? 'Purchase cancelled.'
              : 'The purchase could not be completed. Please try again.'),
          findsOneWidget);
      await _drainFeedback(tester);
    });
  }

  testWidgets('store launch failure shows feedback and allows retry',
      (tester) async {
    final fixture = PremiumTestFixture();
    fixture.store.buyStarts = false;
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_host(PremiumScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(_buyKey));
    expect(fixture.purchases.isPremium, isFalse);
    expect(fixture.purchases.state, PurchaseState.failed);
    expect(
        tester.widget<FilledButton>(find.byKey(_buyKey)).onPressed, isNotNull);
    expect(find.text('The purchase could not be completed. Please try again.'),
        findsOneWidget);
    await _drainFeedback(tester);
    // A second failure must still produce feedback after the first is dismissed.
    await _tap(tester, find.byKey(_buyKey));
    expect(find.text('The purchase could not be completed. Please try again.'),
        findsOneWidget);
    expect(fixture.store.buyCalls, 2);
    await _drainFeedback(tester);
  });

  testWidgets(
      'offline products can be reloaded without losing the feature reason',
      (tester) async {
    final fixture = PremiumTestFixture();
    fixture.store.available = false;
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_host(PremiumScreen(
        purchases: fixture.purchases, feature: PremiumFeature.folders)));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(_buyKey)).onPressed, isNull);
    expect(
        find.text(
            'The free plan includes 3 folders. Upgrade for unlimited folders.'),
        findsOneWidget);
    fixture.store.available = true;
    await _tap(tester, find.byKey(const ValueKey('premium-retry')));
    expect(
        tester.widget<FilledButton>(find.byKey(_buyKey)).onPressed, isNotNull);
    expect(find.text(r'Unlock forever for $2.99'), findsOneWidget);
    expect(find.byKey(const ValueKey('premium-retry')), findsNothing);
  });

  testWidgets('a restored legacy purchase unlocks Premium', (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    fixture.store.grantOnRestore = true;
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_host(PremiumScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(_restoreKey));
    expect(fixture.purchases.isPremium, isTrue);
    expect(find.byKey(_buyKey), findsNothing);
    expect(find.text('Your Premium purchase was restored.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    await _drainFeedback(tester);
  });

  testWidgets('restore without purchases explains the result', (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_host(PremiumScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(_restoreKey));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(fixture.purchases.isPremium, isFalse);
    expect(
        find.text('No previous Premium purchase was found.'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byKey(_restoreKey)).onPressed,
        isNotNull);
    await _drainFeedback(tester);
  });

  for (final configuration in [
    ('narrow', const Size(180, 720), false, const Locale('en')),
    ('landscape', const Size(812, 375), true, const Locale('en')),
    ('chinese', const Size(320, 760), true, const Locale('zh', 'HK')),
  ]) {
    testWidgets('Premium scrolls without overflow at 2×: ${configuration.$1}',
        (tester) async {
      tester.view.physicalSize = configuration.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fixture = PremiumTestFixture();
      await fixture.init();
      addTearDown(fixture.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(
            PremiumScreen(
                purchases: fixture.purchases, feature: PremiumFeature.notes),
            dark: configuration.$3,
            scale: 2,
            locale: configuration.$4));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, configuration.$1);
        await tester.ensureVisible(find.byKey(_restoreKey));
        await tester.pumpAndSettle();
        expect(find.byKey(_restoreKey).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('previews buy and restore entirely in memory', (tester) async {
    await tester.pumpWidget(premiumUpgradePreview());
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(_buyKey));
    expect(find.text('Premium unlocked'), findsOneWidget);
    await _drainFeedback(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(premiumUnlockedPreview());
    await tester.pumpAndSettle();
    expect(find.byKey(_buyKey), findsNothing);
    await _tap(tester, find.byKey(_restoreKey));
    expect(find.text('Your Premium purchase was restored.'), findsOneWidget);
    await _drainFeedback(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(premiumChinesePreview());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
