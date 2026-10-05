import 'package:flutter/widgets.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

int noteGridColumns({
  required double width,
  required TextScaler textScaler,
  required int preferredColumns,
}) {
  final preferred = width >= 600 ? preferredColumns + 1 : preferredColumns;
  final textScale = textScaler.scale(14) / 14;
  if (textScale < 1.3) return preferred;
  final available = width - 2 * AppSpacings.xl;
  final minimumCardWidth = 140 * textScale;
  final fitting =
      ((available + AppSpacings.l) / (minimumCardWidth + AppSpacings.l))
          .floor();
  return fitting.clamp(1, preferred);
}
