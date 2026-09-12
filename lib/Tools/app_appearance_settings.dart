import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appearance preferences are local to this device.
class AppAppearanceSettings extends ChangeNotifier {
  AppAppearanceSettings();
  static final instance = AppAppearanceSettings();

  ThemeMode _themeMode = ThemeMode.system;
  bool _plainPaper = false;
  ThemeMode get themeMode => _themeMode;
  bool get plainPaper => _plainPaper;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == prefs.getString('app_theme_mode'),
      orElse: () => ThemeMode.system,
    );
    _plainPaper = prefs.getBool('app_plain_paper') ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('app_theme_mode', mode.name)) {
      throw StateError('Could not save appearance');
    }
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setPlainPaper(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('app_plain_paper', value)) {
      throw StateError('Could not save appearance');
    }
    _plainPaper = value;
    notifyListeners();
  }
}
