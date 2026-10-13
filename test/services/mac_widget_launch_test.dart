import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/widget_launch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('onlynote.test/mac-widget-launch');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late WidgetLaunch launch;
  late List<Uri> taps;
  late int initializations;

  setUp(() {
    taps = [];
    initializations = 0;
    launch = WidgetLaunch(
      platform: MacWidgetLaunchPlatform(channel: channel),
      onTap: taps.add,
    );
  });

  tearDown(() async {
    await launch.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> nativeTap(Object? value) async {
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall('widgetTapped', value)),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  test('Mac delivers a cold widget URI once and receives warm taps', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'initialize');
      initializations++;
      return 'onlynote://note?id=saved-note&homeWidget=true';
    });

    await launch.init();
    await launch.init();
    await nativeTap('onlynote://new?homeWidget=true');
    await nativeTap('onlynote://voice?homeWidget=true');

    expect(initializations, 1);
    expect(taps.map((uri) => uri.host), ['note', 'new', 'voice']);
    expect(taps.first.queryParameters['id'], 'saved-note');
  });

  test('Mac attaches warm delivery before releasing the initial URI', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      initializations++;
      await nativeTap('onlynote://voice?homeWidget=true');
      return 'onlynote://new?homeWidget=true';
    });

    await launch.init();

    expect(taps.map((uri) => uri.host), ['voice', 'new']);
  });

  test('Mac ignores non-widget schemes, hosts, flags and invalid payloads',
      () async {
    messenger.setMockMethodCallHandler(channel, (_) async =>
        'onlynote://note?id=not-a-widget');
    await launch.init();
    for (final value in [
      'https://new?homeWidget=true',
      'onlynote://settings?homeWidget=true',
      'onlynote://new?homeWidget=false',
      'onlynote://voice',
      42,
      null,
    ]) {
      await nativeTap(value);
    }

    expect(taps, isEmpty);
  });

  test('Mac launch tolerates unavailable native widget integration', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'app_group_unavailable');
    });

    await launch.init();
    await nativeTap('onlynote://new?homeWidget=true');

    expect(taps.map((uri) => uri.host), ['new']);
  });
}
