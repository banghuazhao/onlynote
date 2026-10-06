import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_shortcut_launch.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ShortcutRouter extends RootStackRouter {
  _ShortcutRouter({this.onboarding = false});
  final bool onboarding;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: onboarding,
          page: PageInfo(OnboardingRoute.name,
              builder: (_) => const Scaffold(body: Text('Welcome'))),
        ),
        AutoRoute(
          initial: !onboarding,
          page: PageInfo(HomeRoute.name,
              builder: (_) => const Scaffold(body: Text('Library'))),
        ),
        AutoRoute(
          page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
            final args = data.argsAs<AddUpdateNoteRouteArgs>();
            return Scaffold(
              key: args.key,
              body: TextField(
                key: ValueKey('draft-${args.start.name}'),
                decoration: InputDecoration(labelText: args.start.name),
              ),
            );
          }),
        ),
      ];
}

Map<String, String> _request(String id, String type) =>
    {'id': id, 'type': type};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingSettings.instance.load();
  });
  tearDown(() => OnboardingSettings.instance.completed = false);

  testWidgets('cold action waits for ready router and completes first capture',
      (tester) async {
    final launch = AppShortcutLaunch(enabled: true);
    final router = _ShortcutRouter(onboarding: true);
    addTearDown(() async {
      launch.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    launch.handle(_request('cold', 'new_checklist'));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    expect(router.current.name, OnboardingRoute.name);
    launch.attach(router);
    await tester.pumpAndSettle();
    expect(router.stackData.map((route) => route.name),
        [HomeRoute.name, AddUpdateNoteRoute.name]);
    expect(find.byKey(const ValueKey('draft-checklist')), findsOneWidget);
    expect(OnboardingSettings.instance.completed, isTrue);
    expect(
        (await SharedPreferences.getInstance()).getBool('onboarding_completed'),
        isTrue);
  });

  testWidgets(
      'warm capture preserves active draft and ignores duplicate delivery',
      (tester) async {
    final launch = AppShortcutLaunch(enabled: true);
    final router = _ShortcutRouter();
    addTearDown(() async {
      launch.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    OnboardingSettings.instance.completed = true;
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    launch.attach(router);
    launch.handle(_request('first', 'new_note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep my unfinished draft');
    final original = tester.element(find.byType(TextField));
    launch.handle(_request('second', 'photo_note'));
    await tester.pumpAndSettle();
    expect(router.stackData.length, 3);
    expect(find.byKey(const ValueKey('draft-photo')), findsOneWidget);
    launch.handle(_request('second', 'photo_note'));
    await tester.pumpAndSettle();
    expect(router.stackData.length, 3);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Keep my unfinished draft'), findsOneWidget);
    expect(tester.element(find.byType(TextField)), same(original));
  });

  testWidgets('native initial and warm messages use one handler without replay',
      (tester) async {
    const channel = MethodChannel('onlynote.shortcuts.test');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'initialize');
      return _request('native-cold', 'new_note');
    });
    final launch = AppShortcutLaunch(channel: channel, enabled: true);
    final router = _ShortcutRouter();
    addTearDown(() async {
      launch.dispose();
      messenger.setMockMethodCallHandler(channel, null);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    OnboardingSettings.instance.completed = true;
    await launch.init();
    await launch.init();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    launch.attach(router);
    await tester.pumpAndSettle();
    expect(router.stackData.length, 2);
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
          MethodCall('shortcutTapped', _request('native-cold', 'new_note'))),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(router.stackData.length, 2);
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(
          'shortcutTapped', _request('native-warm', 'new_checklist'))),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(router.stackData.length, 3);
    expect(find.byKey(const ValueKey('draft-checklist')), findsOneWidget);
  });

  testWidgets('unknown actions are ignored and latest startup action wins',
      (tester) async {
    final launch = AppShortcutLaunch(enabled: true);
    final router = _ShortcutRouter();
    addTearDown(() async {
      launch.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    launch.handle(jsonDecode('{"id":"bad","type":"unrecognized"}'));
    launch.handle({'type': 'new_note'});
    launch.handle(_request('older', 'new_note'));
    launch.handle(_request('latest', 'new_checklist'));
    OnboardingSettings.instance.completed = true;
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    launch.attach(router);
    await tester.pumpAndSettle();
    expect(router.stackData.length, 2);
    expect(find.byKey(const ValueKey('draft-checklist')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('unsupported platforms do not initialize a native bridge', () async {
    const channel = MethodChannel('onlynote.shortcuts.unsupported');
    var calls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => calls++);
    final launch = AppShortcutLaunch(channel: channel, enabled: false);
    await launch.init();
    expect(calls, 0);
    launch.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('cold voice capture waits for routing and initializes one editor',
      (tester) async {
    final launch = AppShortcutLaunch(enabled: true);
    final router = _ShortcutRouter(onboarding: true);
    addTearDown(() async {
      launch.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    launch.handle(_request('voice-cold', 'voice_note'));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    launch.attach(router);
    await tester.pumpAndSettle();
    expect(router.stackData.map((route) => route.name),
        [HomeRoute.name, AddUpdateNoteRoute.name]);
    expect(find.byKey(const ValueKey('draft-voice')), findsOneWidget);
    expect(OnboardingSettings.instance.completed, isTrue);
    launch.handle(_request('voice-cold', 'voice_note'));
    await tester.pumpAndSettle();
    expect(router.stackData.length, 2);
  });

  testWidgets('warm voice capture preserves the unfinished editor underneath',
      (tester) async {
    final launch = AppShortcutLaunch(enabled: true);
    final router = _ShortcutRouter();
    addTearDown(() async {
      launch.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    OnboardingSettings.instance.completed = true;
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    launch.attach(router);
    launch.handle(_request('note', 'new_note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Do not lose this draft');
    launch.handle(_request('voice-warm', 'voice_note'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('draft-voice')), findsOneWidget);
    expect(router.stackData.length, 3);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Do not lose this draft'), findsOneWidget);
  });
}
