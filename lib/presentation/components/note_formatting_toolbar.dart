import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/colors.dart';

/// Three familiar controls, beside the writing field they act on.
///
/// The tap region and unfocusable buttons preserve the writer's selection and
/// keep the keyboard open while applying a style.
class NoteFormattingToolbar extends StatelessWidget {
  const NoteFormattingToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.beforeApply,
  });

  final SimpleFormattingController controller;
  final FocusNode focusNode;
  final VoidCallback? beforeApply;

  void _apply(VoidCallback action) {
    beforeApply?.call();
    // A new, unfocused field starts with an invalid selection. Establish its
    // cursor before a typing mode so the first focus update keeps that mode.
    if (!controller.selection.isValid) {
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }
    action();
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final strings = S.of(context);
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextFieldTapRegion(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: .045),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _FormattingButton(
                        key: const ValueKey('format-bold'),
                        label: strings.Format_Bold,
                        icon: Icons.format_bold_rounded,
                        selected: controller.isBold,
                        onPressed: () => _apply(controller.toggleBold),
                      ),
                      _FormattingButton(
                        key: const ValueKey('format-heading'),
                        label: strings.Format_Heading,
                        icon: Icons.title_rounded,
                        selected: controller.isHeading,
                        onPressed: () => _apply(controller.toggleHeading),
                      ),
                      _FormattingButton(
                        key: const ValueKey('format-bullets'),
                        label: strings.Format_Bullets,
                        icon: Icons.format_list_bulleted_rounded,
                        selected: controller.isBulleted,
                        onPressed: () => _apply(controller.toggleBullets),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _FormattingButton extends StatelessWidget {
  const _FormattingButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        onTap: onPressed,
        child: ExcludeSemantics(
          child: Tooltip(
            message: label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                canRequestFocus: false,
                borderRadius: BorderRadius.circular(7),
                onTap: onPressed,
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ink.withValues(alpha: .12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon,
                      size: 26,
                      color:
                          AppColors.ink.withValues(alpha: selected ? 1 : .66)),
                ),
              ),
            ),
          ),
        ),
      );
}
