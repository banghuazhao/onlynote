import 'package:flutter/material.dart';
import 'colors.dart';

/// Shared geometry and interaction states for controls on the desk and paper.
abstract final class AppButtonStyles {
  static const radius = 12.0;
  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
  );

  static ButtonStyle base(ColorScheme colors) => ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: const WidgetStatePropertyAll(shape),
        elevation: const WidgetStatePropertyAll(0),
        tapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        animationDuration: const Duration(milliseconds: 160),
        enableFeedback: true,
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? colors.primary
                  : Colors.transparent,
              width: 1.5,
            )),
      );

  static ButtonStyle outlined(ColorScheme colors) => base(colors).copyWith(
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: .38)
                : colors.onSurface),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? colors.primary
                  : colors.outlineVariant.withValues(
                      alpha: states.contains(WidgetState.disabled) ? .4 : 1),
              width: states.contains(WidgetState.focused) ? 1.5 : 1,
            )),
        overlayColor: _overlay(colors.onSurface),
      );

  static ButtonStyle icon(ColorScheme colors,
          {bool primary = false, bool destructive = false}) =>
      _surface(
        colors,
        foreground: destructive
            ? colors.error
            : primary
                ? colors.onPrimary
                : colors.onSurface,
        background: destructive
            ? colors.errorContainer
            : primary
                ? colors.primary
                : colors.surfaceContainerHigh,
        border:
            primary || destructive ? Colors.transparent : colors.outlineVariant,
      ).copyWith(
        padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
        iconSize: const WidgetStatePropertyAll(22),
      );

  /// Paper stays light in both themes, so controls on a note use ink colors.
  static ButtonStyle paper({bool selected = false, bool destructive = false}) {
    const ink = AppColors.ink;
    return _surface(
      const ColorScheme.light(primary: ink, onSurface: ink),
      foreground: destructive
          ? AppColors.error
          : selected
              ? AppColors.parchment
              : ink,
      background: selected ? ink : AppColors.parchment,
      border: ink.withValues(alpha: .2),
    ).copyWith(
      padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
      iconSize: const WidgetStatePropertyAll(20),
    );
  }

  /// Lightweight actions inside a note, retaining generous hit areas.
  static ButtonStyle paperAction({bool destructive = false}) =>
      paper(destructive: destructive).copyWith(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? (destructive ? AppColors.error : AppColors.ink)
                  : Colors.transparent,
              width: 1.5,
            )),
      );

  static ButtonStyle _surface(ColorScheme colors,
          {required Color foreground,
          required Color background,
          required Color border}) =>
      base(colors).copyWith(
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: .38)
                : foreground),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: .08)
                : background),
        overlayColor: _overlay(foreground),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
              color: states.contains(WidgetState.focused) ? foreground : border,
              width: states.contains(WidgetState.focused) ? 1.5 : 1,
            )),
      );

  static WidgetStateProperty<Color?> _overlay(Color color) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) {
          return color.withValues(alpha: .14);
        }
        if (states.contains(WidgetState.focused)) {
          return color.withValues(alpha: .12);
        }
        if (states.contains(WidgetState.hovered)) {
          return color.withValues(alpha: .08);
        }
        return Colors.transparent;
      });
}
