import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/onboarding_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends Fake implements SharedPreferences {
  final pending = Completer<bool>();
  final writes = <(String, bool)>[];

  @override
  Future<bool> setBool(String key, bool value) {
    writes.add((key, value));
    return pending.future;
  }
}

void main() {
  test('completed becomes true only after preferences confirm the write',
      () async {
    final prefs = _Preferences();
    final settings = OnboardingSettings(preferences: () async => prefs);
    final complete = settings.complete();
    await Future<void>.delayed(Duration.zero);
    expect(settings.completed, isFalse);
    expect(prefs.writes, [('onboarding_completed', true)]);
    prefs.pending.complete(true);
    await complete;
    expect(settings.completed, isTrue);
  });

  for (final throwError in [false, true]) {
    test('rejected preference write retains incomplete state: $throwError',
        () async {
      final prefs = _Preferences();
      final settings = OnboardingSettings(preferences: () async => prefs);
      final completion = expectLater(settings.complete(), throwsStateError);
      if (throwError) {
        prefs.pending.completeError(StateError('Unavailable'));
      } else {
        prefs.pending.complete(false);
      }
      await completion;
      expect(settings.completed, isFalse);
    });
  }

  test('preference initialization failure can be retried', () async {
    var attempts = 0;
    SharedPreferences.setMockInitialValues({});
    final settings = OnboardingSettings(preferences: () async {
      if (attempts++ == 0) throw StateError('Unavailable');
      return SharedPreferences.getInstance();
    });
    await expectLater(settings.complete(), throwsStateError);
    expect(settings.completed, isFalse);
    await settings.complete();
    expect(settings.completed, isTrue);
    expect(
        (await SharedPreferences.getInstance()).getBool('onboarding_completed'),
        isTrue);
  });
}
