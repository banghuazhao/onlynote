import 'package:flutter/material.dart';

import 'search_highlight.dart';

/// A version summary using display values only, independent of stored media.
class NoteHistoryVersionTile extends StatelessWidget {
  const NoteHistoryVersionTile({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.snippet,
    required this.mediaCounts,
    required this.onPressed,
    this.query = '',
  });

  final String title;
  final String dateLabel;
  final String snippet;
  final Widget mediaCounts;
  final VoidCallback? onPressed;
  final String query;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.restore_page_outlined),
        title: SearchHighlight(title,
            query: query, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateLabel),
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 4),
              SearchHighlight(snippet,
                  query: query, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            mediaCounts,
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onPressed,
      );
}
