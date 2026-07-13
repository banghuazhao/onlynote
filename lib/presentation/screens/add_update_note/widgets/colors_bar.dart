part of '../add_update_note_screen.dart';

class ColorsBar extends StatelessWidget {
  const ColorsBar({super.key, this.selectedColor, required this.onChanged});
  final Color? selectedColor;
  final Function(Color color) onChanged;

  @override
  Widget build(BuildContext context) {
    return FadeInRight(
      // delay: const Duration(milliseconds: 600),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: selectedColor,
          child: SizedBox(
            height: kToolbarHeight,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: colors
                      .map(
                        (color) => _ColorBox(
                          color: color,
                          isSelected: selectedColor == color,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(color);
                          },
                        ),
                      )
                      .toList(),
                ),
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacings.s),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Note color',
        child: InkResponse(
          radius: 28,
          onTap: onTap,
          child: AnimatedScale(
            scale: isSelected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Material(
              shape: const CircleBorder(),
              elevation: isSelected ? 3 : 0.2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                width: 40,
                margin: const EdgeInsets.all(AppSpacings.s),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onPrimary,
                          width: 2)
                      : null,
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
