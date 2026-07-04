import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  final Widget? child;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: AppTypography.buttonLink.copyWith(color: AppColors.white),
      child: GestureDetector(
        onTapDown: widget.onPressed == null ? null : (_) => _setPressed(true),
        onTapUp: widget.onPressed == null ? null : (_) => _setPressed(false),
        onTapCancel: widget.onPressed == null ? null : () => _setPressed(false),
        onTap: widget.onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onPressed!();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedSwitcher(
            duration: animationDuration,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacings.m),
              height: 40,
              constraints: const BoxConstraints(minWidth: 40),
              decoration: BoxDecoration(
                color: const Color(0xff444444),
                borderRadius: BorderRadius.circular(AppSpacings.l),
              ),
              child: Center(
                key: ValueKey(widget.isLoading),
                child: widget.isLoading
                    ? Text(' ' + S.of(context).Saving + '.. ')
                    : widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
