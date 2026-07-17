import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-launch onboarding has been completed.
class OnboardingSettings {
  OnboardingSettings._();
  static final OnboardingSettings instance = OnboardingSettings._();

  static const _key = 'onboarding_completed';

  bool completed = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    completed = prefs.getBool(_key) ?? false;
  }

  Future<void> complete() async {
    completed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
