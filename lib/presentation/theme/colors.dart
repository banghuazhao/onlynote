import 'package:flutter/material.dart';

/// Brand primitives. Screens should prefer semantic colors from
/// `Theme.of(context).colorScheme`.
abstract final class AppColors {
  static const ink = Color(0xFF292722);
  static const amber = Color(0xFFF4B942);
  static const parchment = Color(0xFFFFF9F0);
  static const night = Color(0xFF171612);
  static const nightSurface = Color(0xFF22201B);
  static const success = Color(0xFF16876B);
  static const warning = Color(0xFFB86E00);

  // Compatibility aliases for non-UI callers while view code migrates to
  // semantic ColorScheme roles.
  static const primary = ink;
  static const secondary = amber;
  static const info = Color(0xFF376DCE);
  static const error = Color(0xFFBA1A1A);
  static const title = ink;
  static const description = Color(0xFF69645B);
  static const white = Color(0xFFFFFFFF);
}
