import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/widget_discovery_card.dart';
import 'package:onlynote/presentation/screens/settings/widget_guide_content.dart';
import 'package:onlynote/presentation/screens/settings/widget_guide_previews.dart';
import 'package:onlynote/presentation/screens/settings/widget_guide_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget screen,
        {Locale locale = const Locale('en'), double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
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
    );

void main() {
  const channel = MethodChannel('home_widget');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() =>
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

  testWidgets(
      'native Mac guide explains desktop setup, note selection and color',
      (tester) async {
    final calls = <String>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call.method);
      return true;
    });
    await tester.pumpWidget(_host(const WidgetGuideScreen()));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Widget_macOS_Title), findsOneWidget);
    expect(find.text(S.current.Widget_Description_macOS), findsOneWidget);
    expect(find.text(S.current.Widget_Choose_Note_macOS), findsOneWidget);
    expect(find.text(S.current.Widget_Style_macOS), findsOneWidget);
    expect(find.text(S.current.Widget_Step_iOS_1), findsNothing);
    expect(find.text(S.current.Widget_Step_Android_1), findsNothing);
    expect(find.text(S.current.Widget_Add_To_Home), findsNothing);
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('$platform guide keeps its original platform steps',
        (tester) async {
      await tester.pumpWidget(_host(WidgetGuideContent(platform: platform)));
      await tester.pumpAndSettle();
      expect(
          find.text(platform == TargetPlatform.iOS
              ? S.current.Widget_Step_iOS_1
              : S.current.Widget_Step_Android_1),
          findsOneWidget);
      expect(find.text(S.current.Widget_Step_macOS_1), findsNothing);
      expect(find.text(S.current.Widget_Style_macOS), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Mac guide remains scrollable with large Chinese text in a small window',
      (tester) async {
    tester.view.physicalSize = const Size(560, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(
        const WidgetGuideContent(platform: TargetPlatform.macOS),
        locale: const Locale('zh', 'HK'),
        scale: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(S.current.Widget_Style_macOS));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(S.current.Widget_Tip_macOS));
    await tester.pumpAndSettle();
    expect(find.text(S.current.Widget_Tip_macOS).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Mac discovery preview opens its guide and dismisses without native APIs',
      (tester) async {
    await tester.pumpWidget(macWidgetDiscoveryPreview());
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.Widget_Add_To_Desktop));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetGuideContent), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
