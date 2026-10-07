import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onlynote/domain/model/note_card_style.dart';

export 'package:onlynote/domain/model/note_card_style.dart' show AppFontSize;

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
  'Caveat': GoogleFonts.caveat,
  'Kalam': GoogleFonts.kalam,
  'Patrick Hand': GoogleFonts.patrickHand,
};

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

  GoogleFontBuilder get fontBuilder =>
      kAppFontFamilies[_fontFamily] ?? GoogleFonts.montserrat;
  double get scale => _fontSize.scale;

  Future<void> load({bool notify = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedFamily = prefs.getString(_fontFamilyKey);
    _fontFamily = kAppFontFamilies.containsKey(storedFamily)
        ? storedFamily!
        : 'Montserrat';
    final storedSize = prefs.getString(_fontSizeKey);
    _fontSize = AppFontSize.values.firstWhere(
      (size) => size.name == storedSize,
      orElse: () => AppFontSize.medium,
    );
    if (notify) notifyListeners();
  }

  Future<void> setFontFamily(String fontFamily) async {
    if (!kAppFontFamilies.containsKey(fontFamily)) return;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_fontFamilyKey, fontFamily)) {
      throw StateError('Could not save typography');
    }
    _fontFamily = fontFamily;
    notifyListeners();
  }

  Future<void> setFontSize(AppFontSize fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_fontSizeKey, fontSize.name)) {
      throw StateError('Could not save typography');
    }
    _fontSize = fontSize;
    notifyListeners();
  }
}
