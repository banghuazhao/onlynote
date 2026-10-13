import 'package:flutter/material.dart';
import 'package:onlynote/Tools/app_card_style_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note_card_style.dart';

import 'colors.dart';

NoteCardStyle resolveNoteCardStyle(NoteCardStyle style) {
  final defaults = AppCardStyleSettings.instance.defaults;
  return NoteCardStyle(
    fontFamily: kAppFontFamilies.containsKey(style.fontFamily)
        ? style.fontFamily
        : defaults.fontFamily,
    fontSize: style.fontSize ?? defaults.fontSize,
    cardSize: style.cardSize ?? defaults.cardSize,
    paperStyle: style.paperStyle ?? defaults.paperStyle,
    showDate: style.showDate ?? defaults.showDate,
    noteTheme: style.noteTheme ?? defaults.noteTheme,
  );
}

/// Card typography is scoped to one note; it never changes the app's font.
class NoteCardTypography {
  NoteCardTypography(NoteCardStyle style)
      : _font = kAppFontFamilies[style.fontFamily] ??
            AppTypographySettings.instance.fontBuilder,
        scale = (style.fontSize ?? AppFontSize.medium).scale;

  final GoogleFontBuilder _font;
  final double scale;

  TextStyle get title => _font(
        fontWeight: FontWeight.w600,
        fontSize: 20 * scale,
        color: AppColors.title,
      ).copyWith(height: 1.28, letterSpacing: -0.2);

  TextStyle get body => _font(
        fontWeight: FontWeight.w400,
        fontSize: 14 * scale,
        color: AppColors.ink.withValues(alpha: .78),
      ).copyWith(height: 1.4);

  TextStyle get description => _font(
        fontWeight: FontWeight.w400,
        fontSize: 14 * scale,
        color: AppColors.title,
      );
}
