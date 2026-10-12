import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Recovery actions only change the current query and filters. The caller owns
/// the library scope and keeps folders, Archive and Trash unchanged.
class NoteSearchRecovery extends StatelessWidget {
  const NoteSearchRecovery({
    super.key,
    this.onClearSearch,
    this.onClearFilters,
  });

  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (onClearSearch != null)
          FilledButton(
            key: const ValueKey('home-clear-search'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onClearSearch,
            child: Text(strings.Clear_Search),
          ),
        if (onClearFilters != null)
          OutlinedButton(
            key: const ValueKey('home-clear-filters'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onClearFilters,
            child: Text(strings.Clear_Filters),
          ),
      ],
    );
  }
}

/// Uses the already-filtered list length rather than library or folder totals.
class NoteSearchResultCount extends StatelessWidget {
  const NoteSearchResultCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          S.of(context).Search_Results_Count(count),
          key: const ValueKey('home-search-result-count'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
