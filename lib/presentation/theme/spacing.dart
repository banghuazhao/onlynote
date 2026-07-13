import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    this.space1 = 4,
    this.space2 = 8,
    this.space3 = 12,
    this.space4 = 16,
    this.space5 = 24,
    this.space6 = 32,
    this.radiusSmall = 12,
    this.radiusMedium = 18,
    this.radiusLarge = 28,
    this.contentMaxWidth = 760,
    this.motionFast = const Duration(milliseconds: 180),
    this.motionStandard = const Duration(milliseconds: 260),
  });

  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final double contentMaxWidth;
  final Duration motionFast;
  final Duration motionStandard;

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>()!;

  @override
  AppTokens copyWith({
    double? contentMaxWidth,
  }) =>
      AppTokens(contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth);

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      space1: lerpDouble(space1, other.space1, t),
      space2: lerpDouble(space2, other.space2, t),
      space3: lerpDouble(space3, other.space3, t),
      space4: lerpDouble(space4, other.space4, t),
      space5: lerpDouble(space5, other.space5, t),
      space6: lerpDouble(space6, other.space6, t),
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t),
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t),
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t),
      contentMaxWidth: lerpDouble(contentMaxWidth, other.contentMaxWidth, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens => AppTokens.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Legacy names retained for existing non-refactored layout code.
abstract final class AppSpacings {
  static const double s = 4;
  static const double m = 8;
  static const double l = 12;
  static const double xl = 16;
  static const double xml = 20;
  static const double xxl = 24;
}
