import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';

/// Toolbar actions share the geometry of icon controls, with explicit emphasis.
class AppButton extends StatelessWidget {
  const AppButton(
      {super.key,
      required this.child,
      required this.onPressed,
      this.isLoading = false,
      this.tooltip,
      this.primary = false,
      this.destructive = false});

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? tooltip;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      style: AppButtonStyles.icon(Theme.of(context).colorScheme,
              primary: primary, destructive: destructive)
          .copyWith(
        animationDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Keep the original bounds when a save starts or finishes.
        Opacity(
            opacity: isLoading ? 0 : 1,
            child: ExcludeSemantics(excluding: isLoading, child: child)),
        if (isLoading)
          Semantics(
              label: S.of(context).Saving,
              liveRegion: true,
              child: SizedBox.square(
                  dimension: 18,
                  child: reduceMotion
                      ? const Icon(Icons.hourglass_top_rounded, size: 18)
                      : const CircularProgressIndicator(strokeWidth: 2))),
      ]),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
