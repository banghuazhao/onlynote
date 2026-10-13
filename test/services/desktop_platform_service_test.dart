import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/ads_manager.dart';
import 'package:onlynote/Tools/consent_gate.dart';
import 'package:onlynote/Tools/widget_launch.dart';
import 'package:onlynote/Tools/widget_sync.dart';
import 'package:onlynote/common/platform_capabilities.dart';
import 'package:onlynote/services/document_scan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const mobileChannels = [
    'home_widget',
    'home_widget/updates',
    DocumentScanner.channelName,
    'plugins.flutter.io/google_mobile_ads',
    'plugins.flutter.io/google_mobile_ads/ump',
  ];
  late List<String> calls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    calls = [];
    for (final name in mobileChannels) {
      messenger.setMockMessageHandler(name, (_) async {
        calls.add(name);
        return null;
      });
    }
  });

  tearDown(() async {
    await WidgetLaunch.instance.dispose();
    await WidgetSync.instance.dispose();
    await ConsentGate.instance.resetForTesting();
    for (final name in mobileChannels) {
      messenger.setMockMessageHandler(name, null);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('macOS startup skips unavailable ad and mobile widget plugins',
      () async {
    await ConsentGate.instance.resetForTesting();
    await ConsentGate.instance.resolve();
    await ConsentGate.instance.showPrivacyOptionsForm();
    AdsManager.debugPrintID();
    await WidgetSync.instance.init();
    await WidgetSync.instance.sync();
    await WidgetLaunch.instance.init();
    final scanner = DocumentScanner();
    addTearDown(scanner.dispose);
    expect(await scanner.pending(), isEmpty);
    expect(
        (await scanner.scan(id: '12345678-1234-1234-1234-123456789abc')).status,
        DocumentScanStatus.unsupported);

    expect(ConsentGate.instance.isResolved, isTrue);
    expect(ConsentGate.instance.canRequestAds, isFalse);
    expect(ConsentGate.instance.isPrivacyOptionsRequired, isFalse);
    expect(AdsManager.bannerAdUnitId, isEmpty);
    expect(calls, isEmpty);
  });

  test('macOS offers native media and purchases with supported capture actions',
      () {
    expect(PlatformCapabilities.appStorePurchases, isTrue);
    expect(PlatformCapabilities.photoLibrary, isTrue);
    expect(PlatformCapabilities.photoText, isTrue);
    expect(PlatformCapabilities.voiceMemos, isTrue);
    expect(PlatformCapabilities.camera, isFalse);
    expect(PlatformCapabilities.documentScanner, isFalse);
    expect(PlatformCapabilities.homeWidgets, isFalse);
    expect(PlatformCapabilities.mobileAds, isFalse);
  });

  test('an injected document scanner can supply a desktop test adapter',
      () async {
    const channel = MethodChannel('onlynote.test/desktop-scanner');
    final invocations = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      invocations.add(call.method);
      return [];
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final scanner = DocumentScanner(channel: channel);
    addTearDown(scanner.dispose);

    expect(await scanner.pending(), isEmpty);
    expect(invocations, ['pending']);
  });
}
