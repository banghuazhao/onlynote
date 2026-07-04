import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef GoogleFontBuilder = TextStyle Function({
  TextStyle? textStyle,
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
});

/// Font families the user can pick from in Settings. Keep this list short —
/// each entry is displayed by name in the picker.
final Map<String, GoogleFontBuilder> kAppFontFamilies = {
  'Montserrat': GoogleFonts.montserrat,
  'Roboto': GoogleFonts.roboto,
  'Lato': GoogleFonts.lato,
  'Poppins': GoogleFonts.poppins,
  'Nunito': GoogleFonts.nunito,
  'Merriweather': GoogleFonts.merriweather,
};

enum AppFontSize {
  small(0.85),
  medium(1.0),
  large(1.2);

  const AppFontSize(this.scale);
  final double scale;
}

/// App-wide font family/size preference, applied everywhere note text is
/// shown (editor, detail screen, home cards). Persisted via SharedPreferences.
class AppTypographySettings extends ChangeNotifier {
  AppTypographySettings._();
  static final AppTypographySettings instance = AppTypographySettings._();

  static const _fontFamilyKey = 'app_font_family';
  static const _fontSizeKey = 'app_font_size';

  String _fontFamily = 'Montserrat';
  AppFontSize _fontSize = AppFontSize.medium;

  String get fontFamily => _fontFamily;
  AppFontSize get fontSize => _fontSize;

  GoogleFontBuilder get fontBuilder => kAppFontFamilies[_fontFamily] ?? GoogleFonts.montserrat;
  double get scale => _fontSize.scale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontFamily = prefs.getString(_fontFamilyKey) ?? _fontFamily;
    final storedSize = prefs.getString(_fontSizeKey);
    _fontSize = AppFontSize.values.firstWhere(
      (size) => size.name == storedSize,
      orElse: () => AppFontSize.medium,
    );
  }

  Future<void> setFontFamily(String fontFamily) async {
    if (!kAppFontFamilies.containsKey(fontFamily)) return;
    _fontFamily = fontFamily;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, fontFamily);
  }

  Future<void> setFontSize(AppFontSize fontSize) async {
    _fontSize = fontSize;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, fontSize.name);
  }
}
