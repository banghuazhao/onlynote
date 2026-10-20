import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/note_link_content_snippet.dart';
import 'package:onlynote/services/note_links.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/photo_search_index.dart';

Future<List<String>?> showNoteLinkPickerSheet(
  BuildContext context, {
  required String currentNoteId,
  required List<String> selectedIds,
  required List<Note> notes,
}) =>
    showAppSheet<List<String>>(
      context: context,
      builder: (_) => NoteLinkPickerSheet(
        currentNoteId: currentNoteId,
        selectedIds: selectedIds,
        notes: notes,
      ),
    );

/// A draft selection: closing without Done leaves existing links unchanged.
/// The list stays virtualized even with a large note library.
class NoteLinkPickerSheet extends StatefulWidget {
  const NoteLinkPickerSheet({
    super.key,
    required this.currentNoteId,
    required this.selectedIds,
    required this.notes,
  });

  final String currentNoteId;
  final List<String> selectedIds;
  final List<Note> notes;

  @override
  State<NoteLinkPickerSheet> createState() => _NoteLinkPickerSheetState();
}

class _NoteLinkPickerSheetState extends State<NoteLinkPickerSheet> {
  final _search = TextEditingController();
  final _photoSearchIndex = PhotoSearchIndex.initializedInstance;
  late final Set<String> _selected = {
    ...normalizeLinkedNoteIds(widget.selectedIds, noteId: widget.currentNoteId),
  };

  List<Note> get _available => <String, Note>{
        for (final note in widget.notes)
          if (note.id != null &&
              note.id != widget.currentNoteId &&
              !note.isDeleted)
            note.id!: note,
      }.values.toList();

  @override
  void initState() {
    super.initState();
    _photoSearchIndex?.addListener(_photoSearchUpdated);
  }

  void _photoSearchUpdated() {
    if (mounted && _search.text.trim().isNotEmpty) setState(() {});
  }

  @override
  void dispose() {
    _photoSearchIndex?.removeListener(_photoSearchUpdated);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final available = _available;
    final knownIds = available.map((note) => note.id).toSet();
    final unavailable =
        _selected.where((id) => !knownIds.contains(id)).toList();
    final matches = available
        .where((note) => matchesNoteSearch(note, _search.text, const {},
            hasReminder: false,
            photoText: _photoSearchIndex?.textsForNote(note) ?? const []))
        .toList();
    final matchingIds = matches.map((note) => note.id).toSet();
    final hiddenSelectionCount = _search.text.trim().isEmpty
        ? 0
        : _selected
            .where((id) => knownIds.contains(id) && !matchingIds.contains(id))
            .length;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      namesRoute: true,
                      header: true,
                      child: Text(strings.Choose_Linked_Notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                key: const ValueKey('note-link-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.Link_Search,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          onPressed: () => setState(_search.clear),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            if (_selected.length >= maxLinkedNotes)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(strings.Link_Limit,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
            Expanded(
              child: ListView.builder(
                key: const ValueKey('note-link-results'),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: unavailable.length +
                    matches.length +
                    (matches.isEmpty ? 1 : 0) +
                    1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.Link_Selected_Count(_selected.length),
                              key: const ValueKey('note-link-selection-count'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                            if (hiddenSelectionCount > 0)
                              Text(
                                strings.Link_Hidden_By_Search_Count(
                                    hiddenSelectionCount),
                                key: const ValueKey(
                                    'note-link-hidden-selection-count'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  index -= 1;
                  if (index < unavailable.length) {
                    final id = unavailable[index];
                    return ListTile(
                      key: ValueKey('remove-unavailable-link-$id'),
                      minVerticalPadding: 12,
                      leading: const Icon(Icons.link_off_rounded),
                      title: Text(strings.Link_Unavailable),
                      trailing: IconButton(
                        tooltip: strings.Link_Remove,
                        onPressed: () => setState(() => _selected.remove(id)),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    );
                  }
                  final matchIndex = index - unavailable.length;
                  if (matchIndex >= matches.length) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                          available.isEmpty
                              ? strings.Link_Empty
                              : strings.No_Search_Results,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    );
                  }
                  final note = matches[matchIndex];
                  final selected = _selected.contains(note.id);
                  final snippet = noteLinkContentSnippet(
                    note,
                    query: _search.text,
                    photoText:
                        _photoSearchIndex?.textsForNote(note) ?? const [],
                  );
                  return CheckboxListTile(
                    key: ValueKey('choose-note-link-${note.id}'),
                    value: selected,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text(
                      note.title?.trim().isNotEmpty == true
                          ? note.title!.trim()
                          : strings.Note_Untitled,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: snippet.isEmpty && !note.isArchived
                        ? null
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (snippet.isNotEmpty)
                                Text(
                                  snippet,
                                  key: ValueKey('note-link-snippet-${note.id}'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (note.isArchived) Text(strings.Archive),
                            ],
                          ),
                    onChanged: !selected && _selected.length >= maxLinkedNotes
                        ? null
                        : (value) => setState(() {
                              if (value == true) {
                                _selected.add(note.id!);
                              } else {
                                _selected.remove(note.id);
                              }
                            }),
                  );
                },
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: FilledButton(
                key: const ValueKey('save-note-links'),
                onPressed: () => Navigator.pop(
                    context,
                    normalizeLinkedNoteIds(_selected,
                        noteId: widget.currentNoteId)),
                child: Text(strings.Done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
