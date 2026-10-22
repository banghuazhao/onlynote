import 'package:flutter/material.dart';

/// Display-only search feedback; callers provide counts from existing results.
class SearchResultSummary extends StatelessWidget {
  const SearchResultSummary({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Semantics(
        liveRegion: true,
        label: label,
        excludeSemantics: true,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
