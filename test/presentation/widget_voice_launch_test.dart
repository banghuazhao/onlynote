import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/widget_launch.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/add_update_note/add_update_note_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _WidgetRouter extends AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            initial: true,
            page: PageInfo(HomeRoute.name,
                builder: (_) => const Scaffold(body: Text('Library')))),
        AutoRoute(
            page: PageInfo(AddUpdateNoteRoute.name, builder: (data) {
          final args = data.argsAs<AddUpdateNoteRouteArgs>();
          return Scaffold(
              body: TextField(key: ValueKey('draft-${args.start.name}')));
        })),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  const updates = MethodChannel('home_widget/updates');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    await OnboardingSettings.instance.load();
    messenger.setMockMethodCallHandler(updates, (_) async => null);
  });
  tearDown(() async {
    await WidgetLaunch.instance.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(updates, null);
    OnboardingSettings.instance.completed = false;
  });

  Future<_WidgetRouter> open(WidgetTester tester) async {
    final previous =
        getIt.isRegistered<AppRouter>() ? getIt<AppRouter>() : null;
    if (previous != null) await getIt.unregister<AppRouter>();
    final router = _WidgetRouter();
    getIt.registerSingleton<AppRouter>(router);
    addTearDown(() async {
      await WidgetLaunch.instance.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await getIt.unregister<AppRouter>();
      if (previous != null) getIt.registerSingleton<AppRouter>(previous);
      router.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('cold widget voice URL opens the voice editor after its frame',
      (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'initiallyLaunchedFromHomeWidget');
      return 'onlynote://voice?homeWidget=true';
    });
    final router = await open(tester);
    await WidgetLaunch.instance.init();
    await tester.pumpAndSettle();
    expect(router.current.name, AddUpdateNoteRoute.name);
    expect(find.byKey(const ValueKey('draft-voice')), findsOneWidget);
  });

  testWidgets('warm widget voice URL preserves a draft on the stack',
      (tester) async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    final router = await open(tester);
    router.push(AddUpdateNoteRoute(start: NoteEditorStart.quickNote));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep this unfinished note');
    await WidgetLaunch.instance.init();
    await messenger.handlePlatformMessage(
        updates.name,
        const StandardMethodCodec()
            .encodeSuccessEnvelope('onlynote://voice?homeWidget=true'),
        (_) {});
    await tester.pumpAndSettle();
    expect(router.stackData.length, 3);
    expect(find.byKey(const ValueKey('draft-voice')), findsOneWidget);
    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Keep this unfinished note'), findsOneWidget);
  });
}
