import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_outline.dart';

import 'app_sheet.dart';

Future<NoteOutlineEntry?> showNoteOutlineSheet({
  required BuildContext context,
  required List<NoteOutlineEntry> entries,
  int? currentOffset,
}) =>
    showAppSheet<NoteOutlineEntry>(
      context: context,
      builder: (_) => NoteOutlineSheet(
        entries: entries,
        currentOffset: currentOffset,
      ),
    );

class NoteOutlineSheet extends StatelessWidget {
  const NoteOutlineSheet({
    super.key,
    required this.entries,
    this.currentOffset,
    this.onEntrySelected,
  });

  final List<NoteOutlineEntry> entries;
  final int? currentOffset;
  final ValueChanged<NoteOutlineEntry>? onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final current = currentOffset == null
        ? null
        : currentNoteOutlineEntry(entries, currentOffset!);
    return AppSheet(
      title: strings.Note_Outline,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(strings.Note_Outline_Hint,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: ListTile(
                key: ValueKey('note-outline-entry-${entry.start}'),
                minVerticalPadding: 14,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                selected: identical(entry, current),
                selectedTileColor: colors.primaryContainer,
                selectedColor: colors.onPrimaryContainer,
                leading: const Icon(Icons.short_text_rounded),
                title: Text(entry.text),
                subtitle: identical(entry, current)
                    ? Text(strings.Note_Outline_Current)
                    : null,
                trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
                onTap: () => onEntrySelected != null
                    ? onEntrySelected!(entry)
                    : Navigator.pop(context, entry),
              ),
            ),
        ],
      ),
    );
  }
}
