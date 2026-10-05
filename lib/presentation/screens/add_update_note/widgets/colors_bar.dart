part of '../add_update_note_screen.dart';

class ColorsBar extends StatelessWidget {
  const ColorsBar({super.key, this.selectedColor, required this.onChanged});
  final Color? selectedColor;
  final Function(Color color) onChanged;

  @override
  Widget build(BuildContext context) {
    return FadeInRight(
      child: Material(
        color: DeskSurface.colorOf(context),
        elevation: 0,
        shadowColor: Colors.black26,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            height: 64,
            child: Center(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final color = colors[index];
                  return Center(
                    child: _ColorBox(
                      color: color,
                      label: S.of(context).Note_Color(index + 1),
                      isSelected: selectedColor == color,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(color);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorBox extends StatelessWidget {
  const _ColorBox({
    this.isSelected = false,
    this.onTap,
    required this.color,
    required this.label,
  });

  final bool isSelected;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      isSelected: isSelected,
      onPressed: onTap,
      style: AppButtonStyles.paper().copyWith(
        backgroundColor: WidgetStatePropertyAll(color),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
              color: AppColors.ink.withValues(
                  alpha: isSelected || states.contains(WidgetState.focused)
                      ? .85
                      : .25),
              width: isSelected || states.contains(WidgetState.focused) ? 2 : 1,
            )),
        animationDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
      ),
      icon: const SizedBox.square(dimension: 20),
      selectedIcon: const Icon(Icons.check_rounded, size: 20),
    );
  }
}
