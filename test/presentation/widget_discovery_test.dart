import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/widget_discovery_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/widget_discovery_card.dart';
import 'package:onlynote/presentation/screens/home/widgets/widget_discovery_prompt.dart';
import 'package:onlynote/presentation/screens/settings/widget_guide_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  const channel = MethodChannel('home_widget');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WidgetDiscoverySettings.instance.load();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'getInstalledWidgets') return [];
      return null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('waits for pin eligibility and remembers dismissal',
      (tester) async {
    final eligible = ValueNotifier(false);
    addTearDown(eligible.dispose);
    await tester.pumpWidget(_host(ValueListenableBuilder<bool>(
      valueListenable: eligible,
      builder: (_, value, __) => WidgetDiscoveryPrompt(eligible: value),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsNothing);

    eligible.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Keep pinned notes in view'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsNothing);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('widget_discovery_handled'),
        isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(const WidgetDiscoveryPrompt(eligible: true)));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not invite people who already have a widget',
      (tester) async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => [
              {'kind': 'OnlynoteWidget', 'family': 'systemSmall'}
            ]);
    await tester.pumpWidget(_host(const WidgetDiscoveryPrompt(eligible: true)));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsNothing);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('widget_discovery_handled'),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the existing guide when widget lookup is unavailable',
      (tester) async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (call) async => throw PlatformException(code: 'unavailable'));
    await tester.pumpWidget(_host(const WidgetDiscoveryPrompt(eligible: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Home Screen'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetGuideScreen), findsOneWidget);
    expect(find.text('How to add it'), findsOneWidget);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('widget_discovery_handled'),
        isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening the guide elsewhere also handles the invitation',
      (tester) async {
    await tester.pumpWidget(_host(Column(
      children: [
        const WidgetDiscoveryPrompt(eligible: true),
        Builder(builder: (context) {
          return TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const WidgetGuideScreen())),
            child: const Text('Open widget settings'),
          );
        }),
      ],
    )));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsOneWidget);
    await tester.tap(find.text('Open widget settings'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetGuideScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WidgetDiscoveryCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invitation stays reachable with large text on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        _host(const WidgetDiscoveryPrompt(eligible: true), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Add to Home Screen'));
    await tester.tap(find.text('Add to Home Screen'));
    await tester.pumpAndSettle();
    expect(find.byType(WidgetGuideScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
