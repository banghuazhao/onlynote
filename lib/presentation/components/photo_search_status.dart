import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Quiet feedback while existing photos become available to search.
class PhotoSearchStatus extends StatelessWidget {
  const PhotoSearchStatus({super.key, required this.indexing});

  final bool indexing;

  @override
  Widget build(BuildContext context) {
    if (!indexing) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Padding(
        key: const ValueKey('photo-search-status'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.image_search_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.of(context).Photo_Search_Indexing,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
