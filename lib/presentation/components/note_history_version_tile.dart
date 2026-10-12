import 'package:flutter/material.dart';

/// A version summary using display values only, independent of stored media.
class NoteHistoryVersionTile extends StatelessWidget {
  const NoteHistoryVersionTile({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.snippet,
    required this.mediaCounts,
    required this.onPressed,
  });

  final String title;
  final String dateLabel;
  final String snippet;
  final Widget mediaCounts;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.restore_page_outlined),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateLabel),
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            mediaCounts,
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onPressed,
      );
}
