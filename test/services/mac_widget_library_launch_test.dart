import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/desktop_commands.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/widget_launch.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/presentation/routes/routes.dart';

class _LibraryRouter extends AppRouter {
  final editor = TextEditingController();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(HomeRoute.name,
              builder: (_) => const Scaffold(body: Text('Library'))),
        ),
        AutoRoute(
          page: PageInfo(AddUpdateNoteRoute.name,
              builder: (_) => Scaffold(body: TextField(controller: editor))),
        ),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('onlynote.test/mac-widget-library');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late DesktopCommands commands;
  late WidgetLaunch launch;

  setUp(() {
    OnboardingSettings.instance.completed = true;
    commands = DesktopCommands();
    launch = WidgetLaunch(
      platform: MacWidgetLaunchPlatform(channel: channel),
      desktopCommands: commands,
    );
  });

  tearDown(() async {
    await launch.dispose();
    commands.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    OnboardingSettings.instance.completed = false;
  });

  Future<_LibraryRouter> openEditor(WidgetTester tester) async {
    final previous =
        getIt.isRegistered<AppRouter>() ? getIt<AppRouter>() : null;
    if (previous != null) await getIt.unregister<AppRouter>();
    final router = _LibraryRouter();
    getIt.registerSingleton<AppRouter>(router);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await getIt.unregister<AppRouter>();
      if (previous != null) getIt.registerSingleton<AppRouter>(previous);
      router.editor.dispose();
      router.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    unawaited(router.push(AddUpdateNoteRoute()));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> warmOpen(WidgetTester tester) async {
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall(
          'widgetTapped', 'onlynote://open?homeWidget=true')),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('Mac library link waits for a dirty save and selects Home once',
      (tester) async {
    final router = await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    final save = Completer<bool>();
    var flushes = 0;
    String? persisted;
    commands.registerEditor(() async {
      flushes++;
      final text = router.editor.text;
      final saved = await save.future;
      if (saved) persisted = text;
      return saved;
    });
    messenger.setMockMethodCallHandler(channel,
        (_) async => 'onlynote://open?homeWidget=true');

    await launch.init();
    await tester.pump();
    await warmOpen(tester);
    expect(flushes, 1);
    expect(router.current.name, AddUpdateNoteRoute.name);
    expect(router.editor.text, 'Keep this draft');

    save.complete(true);
    await tester.pumpAndSettle();

    expect(persisted, 'Keep this draft');
    expect(router.current.name, HomeRoute.name);
    expect(router.stackData, hasLength(1));
    expect(find.text('Library'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Mac library link keeps the editor intact after a failed save',
      (tester) async {
    final router = await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'Unsaved text');
    commands.registerEditor(() async => false);
    messenger.setMockMethodCallHandler(channel,
        (_) async => 'onlynote://open?homeWidget=true');

    await launch.init();
    await tester.pumpAndSettle();

    expect(router.current.name, AddUpdateNoteRoute.name);
    expect(router.stackData, hasLength(2));
    expect(find.text('Unsaved text'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Mac warm library link removes a settings route after saving',
      (tester) async {
    final router = await openEditor(tester);
    var saved = false;
    commands.registerEditor(() async {
      saved = true;
      return true;
    });
    unawaited(router.navigatorKey.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Settings overlay')))));
    await tester.pumpAndSettle();
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await launch.init();

    await warmOpen(tester);
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(router.current.name, HomeRoute.name);
    expect(router.stackData, hasLength(1));
    expect(find.text('Settings overlay'), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
