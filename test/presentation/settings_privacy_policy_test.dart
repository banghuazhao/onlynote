import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';
import 'package:onlynote/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/url_launcher');
const _policyKey = ValueKey('settings-privacy-policy');

class _StatusStore extends BackupExportStatusStore {
  @override
  Future<BackupExportRecord?> read() async => null;
}

Widget _host(PurchaseService purchases,
        {GlobalKey<NavigatorState>? navigatorKey}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: navigatorKey,
      home: SettingsScreen(
        purchases: purchases,
        backupStatusStore: _StatusStore(),
      ),
    );

Future<void> _showPolicyTile(WidgetTester tester,
    {GlobalKey<NavigatorState>? navigatorKey}) async {
  final purchases = PurchaseService(isIOS: false);
  addTearDown(purchases.dispose);
  await tester.pumpWidget(_host(purchases, navigatorKey: navigatorKey));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(_policyKey));
  await tester.pumpAndSettle();
}

Future<void> _drainFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  late Future<Object?> Function(MethodCall) launch;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    launch = (_) async => true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) {
      calls.add(call);
      expect(call.method, 'launch');
      return launch(call);
    });
  });
  tearDown(() =>
      binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null));

  for (final throws in [false, true]) {
    testWidgets('privacy launch ${throws ? 'error' : 'false'} can retry',
        (tester) async {
      launch = (_) async {
        if (throws) throw PlatformException(code: 'unavailable');
        return false;
      };
      await _showPolicyTile(tester);
      await tester.tap(find.byKey(_policyKey));
      await tester.pumpAndSettle();
      expect(find.text(S.current.Privacy_Policy_Failed), findsOneWidget);
      expect(tester.widget<ListTile>(find.byKey(_policyKey)).enabled, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.arguments, containsPair('url', kPrivacyPolicyUrl));
      expect(calls.single.arguments, containsPair('useSafariVC', false));
      expect(calls.single.arguments, containsPair('useWebView', false));
      expect(tester.takeException(), isNull);
      await _drainFeedback(tester);

      launch = (_) async => true;
      await tester.tap(find.byKey(_policyKey));
      await tester.pumpAndSettle();
      expect(calls, hasLength(2));
      expect(find.text(S.current.Privacy_Policy_Failed), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pending privacy launch blocks duplicate callbacks and taps',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final pending = Completer<Object?>();
      launch = (_) => pending.future;
      await _showPolicyTile(tester);
      final callback = tester.widget<ListTile>(find.byKey(_policyKey)).onTap!;
      callback();
      callback();
      await tester.pump();
      expect(calls, hasLength(1));
      expect(tester.widget<ListTile>(find.byKey(_policyKey)).enabled, isFalse);
      final node = tester.getSemantics(find.byKey(_policyKey));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
          find.descendant(
              of: find.byKey(_policyKey),
              matching: find.byType(CircularProgressIndicator)),
          findsOneWidget);
      await tester.tap(find.byKey(_policyKey));
      await tester.pump();
      expect(calls, hasLength(1));
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(find.byKey(_policyKey)).enabled, isTrue);
      expect(find.text(S.current.Privacy_Policy_Failed), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final throws in [false, true]) {
    testWidgets(
        'late privacy ${throws ? 'error' : 'false'} after disposal is safe',
        (tester) async {
      final pending = Completer<Object?>();
      launch = (_) => pending.future;
      await _showPolicyTile(tester);
      await tester.tap(find.byKey(_policyKey));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      if (throws) {
        pending.completeError(PlatformException(code: 'unavailable'));
      } else {
        pending.complete(false);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('late privacy failure does not show feedback over another route',
      (tester) async {
    final pending = Completer<Object?>();
    final navigatorKey = GlobalKey<NavigatorState>();
    launch = (_) => pending.future;
    await _showPolicyTile(tester, navigatorKey: navigatorKey);
    final callback = tester.widget<ListTile>(find.byKey(_policyKey)).onTap!;
    callback();
    await tester.pump();
    unawaited(navigatorKey.currentState!.push<void>(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another route')))));
    await tester.pumpAndSettle();
    pending.completeError(PlatformException(code: 'unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Another route'), findsOneWidget);
    expect(find.text(S.current.Privacy_Policy_Failed), findsNothing);
    callback();
    await tester.pump();
    expect(calls, hasLength(1));
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(find.byKey(_policyKey)).enabled, isTrue);
    expect(find.text(S.current.Privacy_Policy_Failed), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
