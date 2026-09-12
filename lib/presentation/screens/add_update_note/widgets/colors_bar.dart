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
        elevation: 8,
        shadowColor: Colors.black26,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            height: 64,
            child: Center(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final color = colors[index];
                  return Center(
                    child: _ColorBox(
                      color: color,
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
  });

  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Note color',
      child: InkResponse(
        radius: 28,
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? AppColors.ink.withValues(alpha: 0.7)
                    : AppColors.ink.withValues(alpha: 0.18),
                width: isSelected ? 2 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.1),
                  blurRadius: isSelected ? 6 : 3,
                  offset: Offset(0, isSelected ? 3 : 1.5),
                ),
              ],
            ),
            child: AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.ink.withValues(alpha: 0.75),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
