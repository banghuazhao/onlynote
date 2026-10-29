import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/services/note_outline.dart';

class NoteSectionLinkSelection {
  const NoteSectionLinkSelection({required this.noteId, required this.heading});
  final String noteId;
  final NoteOutlineEntry heading;
}

Future<NoteSectionLinkSelection?> showNoteSectionLinkPickerSheet(
  BuildContext context, {
  required List<Note> notes,
  required String currentNoteId,
}) =>
    showAppSheet<NoteSectionLinkSelection>(
      context: context,
      builder: (_) => NoteSectionLinkPickerSheet(
          notes: notes, currentNoteId: currentNoteId),
    );

/// Choosing a heading is read-only. The owner persists its stable identity
/// after checking the latest target, so a stale sheet cannot link wrong text.
class NoteSectionLinkPickerSheet extends StatefulWidget {
  const NoteSectionLinkPickerSheet({
    super.key,
    required this.notes,
    required this.currentNoteId,
  });
  final List<Note> notes;
  final String currentNoteId;

  @override
  State<NoteSectionLinkPickerSheet> createState() =>
      _NoteSectionLinkPickerSheetState();
}

class _NoteSectionLinkPickerSheetState
    extends State<NoteSectionLinkPickerSheet> {
  final _search = TextEditingController();
  bool _closing = false;

  void _clearSearch() {
    if (!mounted || _closing || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    setState(_search.clear);
  }

  void _finish([NoteSectionLinkSelection? result]) {
    if (!mounted || _closing || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _closing = true;
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final query = _search.text.trim().toLowerCase();
    final notes = <String, Note>{
      for (final note in widget.notes)
        if (note.id != null && !note.isDeleted) note.id!: note,
    }.values.toList()
      ..sort((a, b) {
        if (a.id == widget.currentNoteId) return -1;
        if (b.id == widget.currentNoteId) return 1;
        return (a.title ?? '').compareTo(b.title ?? '');
      });
    final rows = <(Note, NoteOutlineEntry)>[
      for (final note in notes)
        for (final heading
            in buildNoteOutline(note.description ?? '', note.textStyles))
          if (query.isEmpty ||
              heading.text.toLowerCase().contains(query) ||
              (note.title ?? '').toLowerCase().contains(query))
            (note, heading),
    ];
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
            child: Row(children: [
              Expanded(
                  child: Semantics(
                      namesRoute: true,
                      header: true,
                      child: Text(strings.Section_Link_Choose,
                          style: theme.textTheme.titleLarge))),
              IconButton(
                  onPressed: _finish,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              key: const ValueKey('section-link-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: strings.Section_Link_Search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: strings.Clear_Search,
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
          Expanded(
              child: rows.isEmpty
                  ? SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(query.isEmpty
                              ? strings.Section_Link_Empty
                              : strings.Section_Link_No_Results)))
                  : ListView.builder(
                      key: const ValueKey('section-link-results'),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final (note, heading) = rows[index];
                        final title = note.title?.trim().isNotEmpty == true
                            ? note.title!.trim()
                            : strings.Note_Untitled;
                        return ListTile(
                          key: ValueKey(
                              'section-choice-${note.id}-${heading.start}'),
                          leading: const Icon(Icons.segment_rounded),
                          title: Text(heading.text,
                              maxLines: 3, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              note.id == widget.currentNoteId
                                  ? '${strings.Section_Link_This_Note} · $title'
                                  : title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          onTap: () => _finish(NoteSectionLinkSelection(
                              noteId: note.id!, heading: heading)),
                        );
                      },
                    )),
        ]),
      ),
    );
  }
}
