import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

int noteGridColumns({
  required double width,
  required TextScaler textScaler,
  required int preferredColumns,
  double appFontScale = 1,
}) {
  final preferred = width >= 600 ? preferredColumns + 1 : preferredColumns;
  // A card preference is a maximum density. Keep its content and 48px actions
  // readable even in a narrow window, or when both font settings are enlarged.
  final textScale = (textScaler.scale(14 * appFontScale) / 14).clamp(1.0, 10.0);
  final available = width - 2 * AppSpacings.xl;
  final minimumCardWidth = 144 * textScale;
  final fitting =
      ((available + AppSpacings.l) / (minimumCardWidth + AppSpacings.l))
          .floor();
  return fitting.clamp(1, preferred);
}

/// Drag tiles reserve room for three headline lines and a localized date.
double noteReorderAspectRatio({
  required double width,
  required int columns,
  required TextScaler textScaler,
  double appFontScale = 1,
}) {
  final cardWidth =
      (width - 2 * AppSpacings.xl - (columns - 1) * AppSpacings.l) / columns;
  final headlineHeight = textScaler.scale(20 * appFontScale) * 1.28 * 3;
  final dateHeight = textScaler.scale(12 * appFontScale) * 1.4 * 2;
  final minimumHeight = 44 + AppSpacings.m + headlineHeight + dateHeight;
  return cardWidth / math.max(cardWidth / 1.3, minimumHeight);
}
