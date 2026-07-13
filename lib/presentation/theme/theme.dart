import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.amber,
      brightness: brightness,
      primary: dark ? const Color(0xFFFFD275) : AppColors.ink,
      secondary: dark ? const Color(0xFFF2C66D) : const Color(0xFF805600),
      surface: dark ? AppColors.nightSurface : AppColors.parchment,
      error: dark ? const Color(0xFFFFB4AB) : AppColors.error,
    );
    final baseText =
        dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = baseText
        .copyWith(
          displaySmall:
              baseText.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          headlineMedium:
              baseText.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          headlineSmall:
              baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge:
              baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium:
              baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: baseText.bodyLarge?.copyWith(height: 1.45),
          bodyMedium: baseText.bodyMedium?.copyWith(height: 1.4),
          labelLarge:
              baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    const tokens = AppTokens();
    final mediumRadius = BorderRadius.circular(tokens.radiusMedium);
    final mediumShape = RoundedRectangleBorder(borderRadius: mediumRadius);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.night : AppColors.parchment,
      textTheme: textTheme,
      extensions: const [tokens],
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: mediumShape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: mediumShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: mediumShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: mediumShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
            borderRadius: mediumRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: mediumRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: mediumRadius, borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        shape: mediumShape,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(tokens.radiusLarge)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: mediumShape,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          border: OutlineInputBorder(
              borderRadius: mediumRadius, borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: mediumRadius, borderSide: BorderSide.none),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
