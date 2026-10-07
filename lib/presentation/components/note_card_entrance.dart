import 'package:flutter/widgets.dart';

/// A short entrance animation that keeps a card's accessibility tree present.
class NoteCardEntrance extends StatelessWidget {
  const NoteCardEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        child: child,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - Curves.easeOutCubic.transform(value))),
          child: Opacity(
            opacity: (value / .65).clamp(0.0, 1.0).toDouble(),
            // Cards can move between masonry slots at zero opacity.
            // Keep their semantics attached to the new render ancestors.
            alwaysIncludeSemantics: true,
            child: child,
          ),
        ),
      );
}
