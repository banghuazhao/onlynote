import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/voice_memo_service.dart';

import '../support/premium_test_fakes.dart';

class _VoicePlatform implements VoiceMemoPlatform {
  final calls = <String>[];
  @override
  Stream<Object?> get states => const Stream.empty();
  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    calls.add(method);
    if (method == 'transcribe') return 'Existing transcript';
    return {'phase': 'idle', 'durationMs': 1000};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = '/app/note_audio/keep.m4a';

  test('free plan blocks new recordings before native microphone calls',
      () async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    final platform = _VoicePlatform();
    final service =
        VoiceMemoService(platform: platform, premiumAccess: fixture.access);
    addTearDown(service.dispose);
    addTearDown(fixture.dispose);
    await expectLater(
        service.startRecording(path), throwsA(isA<PremiumRequired>()));
    expect(platform.calls, isEmpty);
    await service.play(path);
    expect(await service.transcribe(path), 'Existing transcript');
    expect(platform.calls, containsAll(['play', 'transcribe']));
    expect(platform.calls, isNot(contains('startRecording')));
  });

  test('Premium upgrade unlocks new recording with the same service', () async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    final platform = _VoicePlatform();
    final service =
        VoiceMemoService(platform: platform, premiumAccess: fixture.access);
    addTearDown(service.dispose);
    addTearDown(fixture.dispose);
    await expectLater(
        service.startRecording(path), throwsA(isA<PremiumRequired>()));
    await fixture.purchases.buyPremium();
    await pumpEventQueue();
    await service.startRecording(path);
    await service.stopRecording();
    expect(platform.calls, ['startRecording', 'stopRecording']);
    expect(fixture.access.isPremium, isTrue);
  });
}
