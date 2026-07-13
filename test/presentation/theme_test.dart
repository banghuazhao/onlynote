import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/theme.dart';

void main() {
  test('design system provides Material 3 light and dark themes', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.useMaterial3, isTrue);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<AppTokens>(), isNotNull);
    expect(dark.extension<AppTokens>(), isNotNull);
    expect(light.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(light.filledButtonTheme.style?.minimumSize?.resolve({}),
        const Size(48, 48));
  });

  test('tokens remain on the 4dp spacing grid', () {
    const tokens = AppTokens();
    for (final spacing in [
      tokens.space1,
      tokens.space2,
      tokens.space3,
      tokens.space4,
      tokens.space5,
      tokens.space6,
    ]) {
      expect(spacing % 4, 0);
    }
  });
}
