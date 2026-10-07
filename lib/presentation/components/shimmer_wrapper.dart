import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWrapper extends StatelessWidget {
  const ShimmerWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      enabled: !MediaQuery.disableAnimationsOf(context),
      highlightColor: colors.surfaceContainerHighest,
      baseColor: colors.surfaceContainerLow,
      child: child,
    );
  }
}
