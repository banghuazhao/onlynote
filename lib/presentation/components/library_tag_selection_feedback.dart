import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Derived selection feedback without tag storage or platform dependencies.
class LibraryTagSelectionFeedback extends StatelessWidget {
  const LibraryTagSelectionFeedback({
    super.key,
    required this.selectedCount,
    required this.hiddenSelectedCount,
    required this.maxTags,
  });

  final int selectedCount;
  final int hiddenSelectedCount;
  final int maxTags;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 12, runSpacing: 4, children: [
              Text(strings.Tags_Selected_Count(selectedCount),
                  key: const ValueKey('library-tags-selected-count')),
              if (hiddenSelectedCount > 0)
                Text(strings.Tags_Hidden_By_Search_Count(hiddenSelectedCount),
                    key: const ValueKey('library-tags-hidden-count')),
            ]),
            if (selectedCount >= maxTags)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(strings.Tags_Selection_Limit_Reached(maxTags),
                    key: const ValueKey('library-tags-selection-limit')),
              ),
          ],
        ),
      ),
    );
  }
}
