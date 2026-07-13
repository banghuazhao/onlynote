import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/generated/l10n.dart';

/// Compact app-bar/action button with Material feedback and a 48dp target.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.tonal(
      onPressed: isLoading || onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(S.of(context).Saving),
                ],
              )
            : KeyedSubtree(key: const ValueKey('content'), child: child),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
