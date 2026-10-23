import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-launch onboarding has been completed.
class OnboardingSettings {
  OnboardingSettings({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;
  static final OnboardingSettings instance = OnboardingSettings();

  final Future<SharedPreferences> Function() _preferences;

  static const _key = 'onboarding_completed';

  bool completed = false;

  Future<void> load() async {
    final prefs = await _preferences();
    completed = prefs.getBool(_key) ?? false;
  }

  Future<void> complete() async {
    final prefs = await _preferences();
    if (!await prefs.setBool(_key, true)) {
      throw StateError('Onboarding completion was not saved');
    }
    completed = true;
  }
}
