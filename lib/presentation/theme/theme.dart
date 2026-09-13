import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'button_styles.dart';
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
      onPrimary: dark ? AppColors.ink : AppColors.parchment,
      primaryContainer:
          dark ? const Color(0xFF514126) : const Color(0xFFF6E4B9),
      onPrimaryContainer: dark ? const Color(0xFFFFE3AA) : AppColors.ink,
      onSurface: dark ? const Color(0xFFF1E8DA) : AppColors.ink,
      onSurfaceVariant:
          dark ? const Color(0xFFCCC1B1) : const Color(0xFF625C51),
      surfaceContainerLowest: dark ? AppColors.night : const Color(0xFFFFFCF7),
      surfaceContainerLow: dark ? AppColors.nightSurface : AppColors.parchment,
      surfaceContainer:
          dark ? const Color(0xFF2B2822) : const Color(0xFFF7EEDD),
      surfaceContainerHigh:
          dark ? const Color(0xFF332F28) : const Color(0xFFF1E6D4),
      surfaceContainerHighest:
          dark ? const Color(0xFF3D382F) : const Color(0xFFE9DDC8),
      outlineVariant: dark ? const Color(0xFF514B40) : const Color(0xFFD6C8B2),
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
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashColor: scheme.primary.withValues(alpha: .12),
      hoverColor: scheme.primary.withValues(alpha: .06),
      focusColor: scheme.primary.withValues(alpha: .12),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle:
            (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
          statusBarColor: Colors.transparent,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: AppButtonStyles.base(scheme)
            .copyWith(textStyle: WidgetStatePropertyAll(textTheme.labelLarge)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.icon(scheme, primary: true)
            .copyWith(textStyle: WidgetStatePropertyAll(textTheme.labelLarge)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.outlined(scheme)
            .copyWith(textStyle: WidgetStatePropertyAll(textTheme.labelLarge)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: AppButtonStyles.base(scheme)
            .copyWith(textStyle: WidgetStatePropertyAll(textTheme.labelLarge)),
      ),
      iconButtonTheme: IconButtonThemeData(style: AppButtonStyles.icon(scheme)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 1,
        shape: AppButtonStyles.shape,
        extendedTextStyle: textTheme.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
            borderRadius: mediumRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: mediumRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: mediumRadius,
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
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
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        iconColor: scheme.secondary,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle:
            textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        dragHandleSize: const Size(36, 4),
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(maxWidth: 640),
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(tokens.radiusLarge)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: scheme.primaryContainer,
        headerForegroundColor: scheme.onPrimaryContainer,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surface,
        dialBackgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: mediumShape,
      ),
      chipTheme: ChipThemeData(
        shape: AppButtonStyles.shape,
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.onSurface.withValues(alpha: .08),
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
