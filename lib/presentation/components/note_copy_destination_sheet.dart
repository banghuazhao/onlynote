import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/services/note_search.dart';

/// A choice only. The screen that supplied notes owns creation and persistence.
@immutable
class NoteCopyDestination {
  const NoteCopyDestination.newNote() : noteId = null;
  const NoteCopyDestination.existing(this.noteId)
      : assert(noteId != null && noteId != '');

  final String? noteId;
  bool get isNewNote => noteId == null;
}

Future<NoteCopyDestination?> showNoteCopyDestinationPicker(
  BuildContext context, {
  required List<Note> notes,
  String? sourceNoteId,
}) =>
    showAppSheet<NoteCopyDestination>(
      context: context,
      builder: (_) => NoteCopyDestinationSheet(
        notes: notes,
        sourceNoteId: sourceNoteId,
      ),
    );

/// All dependencies are supplied so this picker also works in web previews.
class NoteCopyDestinationSheet extends StatefulWidget {
  const NoteCopyDestinationSheet({
    super.key,
    required this.notes,
    this.sourceNoteId,
  });

  final List<Note> notes;
  final String? sourceNoteId;

  @override
  State<NoteCopyDestinationSheet> createState() =>
      _NoteCopyDestinationSheetState();
}

class _NoteCopyDestinationSheetState extends State<NoteCopyDestinationSheet> {
  final _search = TextEditingController();

  List<Note> get _available => <String, Note>{
        for (final note in widget.notes)
          if (note.id?.isNotEmpty == true &&
              note.id != widget.sourceNoteId &&
              !note.isDeleted &&
              !note.isArchived)
            note.id!: note,
      }.values.toList();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final available = _available;
    final matches = available
        .where((note) =>
            matchesNoteSearch(note, _search.text, const {}, hasReminder: false))
        .toList();
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
              child: Row(children: [
                Expanded(
                  child: Semantics(
                    namesRoute: true,
                    header: true,
                    child: Text(strings.Copy_Selection_To_Note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(strings.Copy_Selection_Destination,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                key: const ValueKey('note-copy-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.Copy_Selection_Search_Notes,
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
            Expanded(
              child: ListView.builder(
                key: const ValueKey('note-copy-destinations'),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: 1 + (matches.isEmpty ? 1 : matches.length),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      key: const ValueKey('note-copy-new'),
                      minVerticalPadding: 12,
                      leading: const Icon(Icons.note_add_outlined),
                      title: Text(strings.Copy_Selection_New_Note),
                      subtitle: Text(strings.Copy_Selection_New_Note_Hint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(
                          context, const NoteCopyDestination.newNote()),
                    );
                  }
                  if (matches.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        available.isEmpty
                            ? strings.Copy_Selection_No_Notes
                            : strings.Copy_Selection_No_Matches,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  final note = matches[index - 1];
                  final body = note.description?.trim() ?? '';
                  final excerpt = body.isNotEmpty
                      ? body
                      : note.todo
                          .map((todo) => todo.title?.trim() ?? '')
                          .where((title) => title.isNotEmpty)
                          .join(' · ');
                  return ListTile(
                    key: ValueKey('note-copy-existing-${note.id}'),
                    minVerticalPadding: 12,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      note.title?.trim().isNotEmpty == true
                          ? note.title!.trim()
                          : strings.Note_Untitled,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: excerpt.isEmpty
                        ? null
                        : Text(searchExcerpt(excerpt, _search.text),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(
                        context, NoteCopyDestination.existing(note.id!)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
