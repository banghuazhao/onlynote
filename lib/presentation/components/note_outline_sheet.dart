import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_outline.dart';

import 'app_sheet.dart';
import 'search_highlight.dart';
import 'search_result_summary.dart';

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

class NoteOutlineSheet extends StatefulWidget {
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
  State<NoteOutlineSheet> createState() => _NoteOutlineSheetState();
}

class _NoteOutlineSheetState extends State<NoteOutlineSheet> {
  final _search = TextEditingController();
  bool _closing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(NoteOutlineEntry entry) {
    if (!mounted || _closing || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (widget.onEntrySelected != null) {
      widget.onEntrySelected!(entry);
    } else {
      _closing = true;
      Navigator.pop(context, entry);
    }
  }

  void _clearSearch() {
    if (!mounted || _closing || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    setState(_search.clear);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final colors = Theme.of(context).colorScheme;
    // The current section belongs to the complete outline even when search
    // hides it. Filtering must never assign that indicator to another heading.
    final current = widget.currentOffset == null
        ? null
        : currentNoteOutlineEntry(widget.entries, widget.currentOffset!);
    final query = _search.text.trim().toLowerCase();
    final entries = query.isEmpty
        ? widget.entries
        : widget.entries
            .where((entry) => entry.text.toLowerCase().contains(query))
            .toList();
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              key: const ValueKey('note-outline-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: strings.Note_Outline_Search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('note-outline-search-clear'),
                        tooltip: strings.Clear_Search,
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear_rounded),
                      ),
              ),
            ),
          ),
          if (query.isNotEmpty)
            SearchResultSummary(
              key: const ValueKey('note-outline-search-count'),
              label: strings.Note_Outline_Search_Count(
                  entries.length, widget.entries.length),
            ),
          if (query.isNotEmpty && entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  strings.Note_Outline_Search_Empty,
                  key: const ValueKey('note-outline-search-empty'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
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
                title: SearchHighlight(entry.text,
                    query: _search.text, overflow: TextOverflow.clip),
                subtitle: identical(entry, current)
                    ? Text(strings.Note_Outline_Current)
                    : null,
                trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
                onTap: () => _select(entry),
              ),
            ),
        ],
      ),
    );
  }
}
