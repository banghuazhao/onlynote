import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Saving feedback without storage or platform dependencies.
class SavedViewSaveAction extends StatelessWidget {
  const SavedViewSaveAction({
    super.key,
    required this.viewCount,
    required this.maxViews,
    required this.onSave,
  });

  final int viewCount;
  final int maxViews;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final atCapacity = viewCount >= maxViews;
    return ListTile(
      key: const ValueKey('library-save-view'),
      leading: const Icon(Icons.bookmark_add_outlined),
      title: Text(strings.Save_Current_View),
      subtitle: atCapacity
          ? Semantics(
              liveRegion: true,
              child: Text(
                strings.Saved_View_Limit_Reached(maxViews),
                key: const ValueKey('library-saved-view-limit'),
              ),
            )
          : null,
      enabled: !atCapacity,
      onTap: atCapacity ? null : onSave,
    );
  }
}
