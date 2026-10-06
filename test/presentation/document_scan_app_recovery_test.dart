import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:onlynote/Tools/shared_note_launch.dart';
import 'package:onlynote/Tools/widget_launch.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/presentation/app.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('onlynote.scan.app.test');
const _scanID = 'ca118157-a3e4-47d4-97e2-1216a77b2c4a';

class _Notes extends Fake implements NoteRepository {
  @override
  List<NoteDto> getAllNotes() => [];
}

class _Home extends Fake implements HomeBloc {
  final events = <HomeEvent>[];
  @override
  HomeState get state => const HomeState.initial();
  @override
  Stream<HomeState> get stream => const Stream.empty();
  @override
  void add(HomeEvent event) => events.add(event);
}

class _Capture extends DocumentScanCapture {
  _Capture({required super.scanner});
  int recoveries = 0;
  Completer<void>? gate;
  @override
  Future<void> recover() {
    recoveries++;
    return gate?.future ?? Future.value();
  }
}

class _Router extends AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: PageInfo(HomeRoute.name,
              builder: (_) => const Scaffold(body: Text('Library'))),
        ),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late DocumentScanner scanner;
  late _Capture capture;
  late _Home home;
  late _Router router;
  late Map<String, GoogleFontBuilder> fonts;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    await OnboardingSettings.instance.load();
    fonts = Map.of(kAppFontFamilies);
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
    messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'), (_) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget/updates'), (_) async => null);
    scanner = DocumentScanner(channel: _channel);
    DocumentScanner.configure(scanner);
    capture = _Capture(scanner: scanner);
    DocumentScanCapture.configure(capture);
    home = _Home();
    router = _Router();
    getIt.registerSingleton<AppRouter>(router);
    getIt.registerSingleton<NoteRepository>(_Notes());
  });

  tearDown(() async {
    capture.release();
    DocumentScanCapture.initializedInstance = null;
    scanner.dispose();
    await WidgetLaunch.instance.dispose();
    SharedNoteLaunch.instance.dispose();
    messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'), null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget/updates'), null);
    router.dispose();
    await getIt.reset();
    kAppFontFamilies.addAll(fonts);
    OnboardingSettings.instance.completed = false;
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
        BlocProvider<HomeBloc>.value(value: home, child: const App()));
    await tester.pumpAndSettle();
  }

  Future<void> ready() => messenger.handlePlatformMessage(
        _channel.name,
        const StandardMethodCodec()
            .encodeMethodCall(const MethodCall('scanReady', {
          'id': _scanID,
          'status': 'cancelled',
          'paths': <String>[],
        })),
        (_) {},
      );

  testWidgets(
      'native scan completion recovers global journal and refreshes Home',
      (tester) async {
    await open(tester);
    await ready();
    await tester.pumpAndSettle();
    expect(capture.recoveries, 1);
    expect(home.events, [const HomeEvent.getAllNotes()]);
    expect(find.text('Library'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('foreground resume retries document recovery and refreshes Home',
      (tester) async {
    await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(capture.recoveries, 1);
    expect(home.events, [const HomeEvent.getAllNotes()]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing App removes scan listener and ignores late recovery',
      (tester) async {
    await open(tester);
    capture.gate = Completer<void>();
    await ready();
    await tester.pump();
    expect(capture.recoveries, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    capture.gate!.complete();
    await tester.pumpAndSettle();
    await ready();
    await tester.pumpAndSettle();
    expect(capture.recoveries, 1);
    expect(home.events, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
