import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/services/note_text_format.dart';

/// Familiar controls, beside the writing field they act on.
///
/// The tap region and unfocusable buttons preserve the writer's selection and
/// keep the keyboard open while applying a style.
class NoteFormattingToolbar extends StatelessWidget {
  const NoteFormattingToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.beforeApply,
    this.useSurfaceColors = false,
  });

  final SimpleFormattingController controller;
  final FocusNode focusNode;
  final VoidCallback? beforeApply;
  final bool useSurfaceColors;

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
          final scheme = Theme.of(context).colorScheme;
          final foreground =
              useSurfaceColors ? scheme.onSurface : AppColors.ink;
          final selectedColor =
              useSurfaceColors ? scheme.primaryContainer : null;
          final selectedForeground =
              useSurfaceColors ? scheme.onPrimaryContainer : null;
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextFieldTapRegion(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: .045),
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
                        foregroundColor: foreground,
                        selectedColor: selectedColor,
                        selectedForegroundColor: selectedForeground,
                        onPressed: () => _apply(controller.toggleBold),
                      ),
                      _FormattingButton(
                        key: const ValueKey('format-heading'),
                        label: strings.Format_Heading,
                        icon: Icons.title_rounded,
                        selected: controller.isHeading,
                        foregroundColor: foreground,
                        selectedColor: selectedColor,
                        selectedForegroundColor: selectedForeground,
                        onPressed: () => _apply(controller.toggleHeading),
                      ),
                      _FormattingButton(
                        key: const ValueKey('format-bullets'),
                        label: strings.Format_Bullets,
                        icon: Icons.format_list_bulleted_rounded,
                        selected: controller.isBulleted,
                        foregroundColor: foreground,
                        selectedColor: selectedColor,
                        selectedForegroundColor: selectedForeground,
                        onPressed: () => _apply(controller.toggleBullets),
                      ),
                      _FormattingButton(
                        key: const ValueKey('format-highlight'),
                        label: !controller.canHighlight
                            ? strings.Format_Select_To_Highlight
                            : controller.isHighlighted
                                ? strings.Format_Remove_Highlight
                                : strings.Format_Highlight,
                        icon: Icons.border_color_rounded,
                        selected: controller.isHighlighted,
                        foregroundColor: foreground,
                        selectedColor: noteHighlightColor,
                        selectedForegroundColor: noteHighlightedTextColor,
                        onPressed: controller.canHighlight
                            ? () => _apply(controller.toggleHighlight)
                            : null,
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
    required this.foregroundColor,
    this.selectedColor,
    this.selectedForegroundColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;
  final Color? selectedColor;
  final Color? selectedForegroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        enabled: onPressed != null,
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
                        ? selectedColor ??
                            foregroundColor.withValues(alpha: .12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon,
                      size: 26,
                      color: (selected && selectedForegroundColor != null
                              ? selectedForegroundColor!
                              : foregroundColor)
                          .withValues(
                              alpha: onPressed == null
                                  ? .3
                                  : selected
                                      ? 1
                                      : .66)),
                ),
              ),
            ),
          ),
        ),
      );
}
