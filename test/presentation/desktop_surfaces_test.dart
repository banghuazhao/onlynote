import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/desktop_capture_previews.dart';
import 'package:onlynote/presentation/components/note_insert_sheet.dart';
import 'package:onlynote/presentation/screens/home/more_apps_page.dart';
import 'package:onlynote/presentation/screens/settings/premium_previews.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/premium_test_fakes.dart';

Widget _host(Widget screen) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Mac Insert keeps photos and voice without camera or scanner',
      (tester) async {
    await tester.pumpWidget(_host(const Scaffold(body: NoteInsertSheet())));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editor-add-photo')), findsOneWidget);
    expect(find.text(S.current.Choose_Image_File), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-record-voice')), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-add-checklist')), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-take-photo')), findsNothing);
    expect(find.byKey(const ValueKey('editor-scan-document')), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('$platform Insert retains camera, scanner and gallery',
        (tester) async {
      await tester.pumpWidget(_host(const Scaffold(body: NoteInsertSheet())));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('editor-take-photo')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('editor-scan-document')), findsOneWidget);
      expect(find.text(S.current.Choose_From_Gallery), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(platform));
  }

  testWidgets(
      'Mac Settings exposes desktop widgets and keeps core configuration',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester
        .pumpWidget(_host(SettingsScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Widget), findsNothing);
    expect(find.text(S.current.Widget_macOS_Title), findsOneWidget);
    expect(find.text(S.current.More_Apps), findsNothing);
    expect(find.text(S.current.Default_Card_Style), findsOneWidget);
    expect(find.text(S.current.Manage_Folders), findsOneWidget);
    expect(find.text(S.current.Backup_Title), findsOneWidget);
    expect(find.text(S.current.Restore_Purchases), findsOneWidget);
    expect(find.text(S.current.Premium_Desktop_Description), findsOneWidget);
    expect(find.text(S.current.Premium_Description), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Mac Premium sells features without an ad-removal benefit',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(_host(PremiumScreen(purchases: fixture.purchases)));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Premium_No_Ads), findsNothing);
    expect(find.text(S.current.Premium_Existing_Purchase), findsNothing);
    expect(
        find.text(S.current.Premium_Desktop_Existing_Purchase), findsOneWidget);
    expect(find.text(S.current.Premium_Notes), findsOneWidget);
    expect(find.text(S.current.Premium_Voice_Memos), findsOneWidget);
    expect(find.byKey(const ValueKey('premium-buy')), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('More Apps never offers phone-store promotions on Mac',
      (tester) async {
    await tester.pumpWidget(_host(const MoreAppsPage()));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Mac backup preview acknowledges saves without native APIs',
      (tester) async {
    tester.view.physicalSize = const Size(900, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(desktopBackupSavePreview());
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(FilledButton, S.current.Backup_Save_As));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Backup_Export_Saved), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Mac Premium preview shows correct unlocked copy',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(premiumDesktopUnlockedPreview());
    await tester.pumpAndSettle();
    expect(find.text(S.current.Premium_Desktop_Description), findsOneWidget);
    expect(find.text(S.current.Premium_No_Ads), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
