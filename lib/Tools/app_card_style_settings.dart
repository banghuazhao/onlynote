import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/services/note_theme_access.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_appearance_settings.dart';
import 'app_layout_settings.dart';
import 'app_typography_settings.dart';

/// Card-specific defaults reuse the existing typography and layout preferences.
class AppCardStyleSettings extends ChangeNotifier {
  AppCardStyleSettings();
  static final instance = AppCardStyleSettings();

  static const _paperStyleKey = 'app_note_card_paper_style';
  static const _showDateKey = 'app_note_card_show_date';
  static const _noteThemeKey = 'app_note_theme';
  NoteCardPaperStyle? _paperStyle;
  bool _showDate = true;
  NoteTheme _noteTheme = NoteTheme.classic;
  Future<void>? _tail;

  NoteCardPaperStyle? get paperStyle => _paperStyle;
  bool get showDate => _showDate;
  NoteTheme get noteTheme => _noteTheme;

  NoteCardStyle get defaults => NoteCardStyle(
        fontFamily: AppTypographySettings.instance.fontFamily,
        fontSize: AppTypographySettings.instance.fontSize,
        cardSize: AppLayoutSettings.instance.cardSize,
        paperStyle: _paperStyle ??
            (AppAppearanceSettings.instance.plainPaper
                ? NoteCardPaperStyle.plain
                : NoteCardPaperStyle.textured),
        showDate: _showDate,
        noteTheme: _noteTheme,
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _paperStyle = NoteCardPaperStyle.values
        .where((style) => style.name == prefs.getString(_paperStyleKey))
        .firstOrNull;
    _showDate = prefs.getBool(_showDateKey) ?? true;
    final storedTheme = prefs.get(_noteThemeKey);
    _noteTheme = NoteTheme.values
            .where((theme) => theme.name == storedTheme)
            .firstOrNull ??
        NoteTheme.classic;
    notifyListeners();
  }

  Future<void> saveDefaults(NoteCardStyle style,
      {PremiumAccess? premiumAccess}) async {
    final previous = _tail;
    final completion = Completer<void>();
    _tail = completion.future;
    try {
      if (previous != null) await previous;
      await _saveDefaults(style, premiumAccess: premiumAccess);
    } finally {
      // Release completed work before resolving callers, including test zones.
      if (identical(_tail, completion.future)) _tail = null;
      completion.complete();
    }
  }

  Future<void> _saveDefaults(NoteCardStyle style,
      {PremiumAccess? premiumAccess}) async {
    final current = defaults;
    // Older partial callers omit themes; preserve the current default.
    final proposed = style.copyWith(noteTheme: style.noteTheme ?? _noteTheme);
    final required =
        requiredNoteStyleFeature(current, proposed, isGlobalDefault: true);
    if (required != null) {
      (premiumAccess ?? PremiumAccess.instance).require(required);
    }
    final family = style.fontFamily ?? current.fontFamily!;
    if (!kAppFontFamilies.containsKey(family)) {
      throw ArgumentError.value(family, 'fontFamily');
    }
    final prefs = await SharedPreferences.getInstance();
    final changes = <String, Object?>{
      'app_font_family': family,
      'app_font_size': (style.fontSize ?? current.fontSize!).name,
      'app_note_card_size': (style.cardSize ?? current.cardSize!).name,
      _paperStyleKey: style.paperStyle?.name,
      _showDateKey: style.showDate ?? current.showDate!,
      _noteThemeKey: proposed.noteTheme!.name,
    };
    final before = {for (final key in changes.keys) key: prefs.get(key)};
    Future<bool> write(String key, Object? value) => switch (value) {
          String value => prefs.setString(key, value),
          bool value => prefs.setBool(key, value),
          _ => prefs.remove(key),
        };
    try {
      // Publish only after every preference has been written successfully.
      for (final entry in changes.entries) {
        if (!await write(entry.key, entry.value)) {
          throw StateError('Could not save card style');
        }
      }
    } catch (_) {
      for (final entry in before.entries) {
        try {
          await write(entry.key, entry.value);
        } catch (_) {
          // Keep the original failure; the previously published defaults stay.
        }
      }
      rethrow;
    }
    await AppTypographySettings.instance.load();
    await AppLayoutSettings.instance.load();
    _paperStyle = style.paperStyle;
    _showDate = style.showDate ?? current.showDate!;
    _noteTheme = proposed.noteTheme!;
    // Legacy listeners also refresh when their preferences change here.
    await AppTypographySettings.instance.load(notify: true);
    await AppLayoutSettings.instance.load(notify: true);
    notifyListeners();
  }
}
