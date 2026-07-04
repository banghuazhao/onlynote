import 'package:flutter/rendering.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';

import 'colors.dart';

class AppTypography {
  AppTypography._();

  static GoogleFontBuilder get _font => AppTypographySettings.instance.fontBuilder;
  static double get _scale => AppTypographySettings.instance.scale;

  static TextStyle get cardTitle => _font(
        fontWeight: FontWeight.w600,
        fontSize: 30 * _scale,
        color: AppColors.title,
      );

  static TextStyle get headline1 => _font(
        fontWeight: FontWeight.bold,
        fontSize: 34 * _scale,
        color: AppColors.title,
      );

  static TextStyle get headline2 => _font(
        fontWeight: FontWeight.bold,
        fontSize: 32 * _scale,
        color: AppColors.title,
      );

  static TextStyle get headline3 => _font(
        fontWeight: FontWeight.bold,
        fontSize: 30 * _scale,
        color: AppColors.title,
      );

  static TextStyle get headline4 => _font(
        fontWeight: FontWeight.bold,
        fontSize: 22 * _scale,
        color: AppColors.title,
      );

  static TextStyle get headline5 => _font(
        fontWeight: FontWeight.bold,
        fontSize: 20 * _scale,
        color: AppColors.title,
      );

  static TextStyle get headline6 => _font(
        fontWeight: FontWeight.w600,
        fontSize: 18 * _scale,
        color: AppColors.title,
      );

  static TextStyle get title => _font(
        fontWeight: FontWeight.w600,
        fontSize: 14 * _scale,
        color: AppColors.title,
      );

  static TextStyle get description => _font(
        fontWeight: FontWeight.w400,
        fontSize: 14 * _scale,
        color: AppColors.description,
      );

  static TextStyle get buttonLink => _font(
        fontWeight: FontWeight.w600,
        fontSize: 13 * _scale,
        color: AppColors.title,
      );

  static TextStyle get textButton => _font(
        fontWeight: FontWeight.w600,
        fontSize: 17 * _scale,
        color: AppColors.title,
      );

  static TextStyle get caption => _font(
        fontWeight: FontWeight.w400,
        fontSize: 14 * _scale,
        color: AppColors.title,
      );

  static TextStyle get formText => _font(
        fontWeight: FontWeight.w400,
        fontSize: 17 * _scale,
        color: AppColors.title,
      );
}
