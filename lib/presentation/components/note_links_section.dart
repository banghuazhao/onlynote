import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_link_content_snippet.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/services/note_links.dart';

/// Note relationships rendered with ink on the editor's or reader's paper.
/// Navigation and persistence are supplied by the screen that owns the note.
class NoteLinksSection extends StatelessWidget {
  const NoteLinksSection({
    super.key,
    required this.linkedNoteIds,
    required this.notes,
    this.backlinks = const [],
    this.onOpen,
    this.onEdit,
    this.exportMode = false,
  });

  final List<String> linkedNoteIds;
  final List<Note> notes;
  final List<Note> backlinks;
  final ValueChanged<Note>? onOpen;
  final VoidCallback? onEdit;
  final bool exportMode;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final links = linkedNoteIds.toSet().toList();
    final incoming = <String, Note>{
      for (final note in backlinks)
        if (note.id != null && !note.isDeleted) note.id!: note,
    }.values.toList();
    if (links.isEmpty && incoming.isEmpty && (onEdit == null || exportMode)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (links.isNotEmpty || (onEdit != null && !exportMode)) ...[
          _heading(context, strings.Linked_Notes, editable: true),
          for (final id in links)
            _row(context, availableLinkedNote(id, notes),
                key: 'linked-note-$id'),
        ],
        if (incoming.isNotEmpty) ...[
          if (links.isNotEmpty || (onEdit != null && !exportMode))
            const SizedBox(height: 16),
          _heading(context, strings.Linked_From),
          for (final note in incoming)
            _row(context, note, key: 'backlink-note-${note.id}'),
        ],
      ],
    );
  }

  Widget _heading(BuildContext context, String title, {bool editable = false}) {
    final heading = Semantics(
      header: true,
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: AppColors.ink.withValues(alpha: .72))),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 2,
        children: [
          heading,
          if (editable && onEdit != null && !exportMode)
            TextButton.icon(
              key: const ValueKey('edit-note-links'),
              onPressed: onEdit,
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: Text(S.of(context).Link_Note),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Note? note, {required String key}) {
    final strings = S.of(context);
    final title = note == null
        ? strings.Link_Unavailable
        : note.title?.trim().isNotEmpty == true
            ? note.title!.trim()
            : strings.Note_Untitled;
    final interactive = note != null && onOpen != null && !exportMode;
    final snippet =
        note == null || exportMode ? '' : noteLinkContentSnippet(note);
    final ink = AppColors.ink.withValues(alpha: note == null ? .48 : .88);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(note == null ? Icons.link_off_rounded : Icons.link_rounded,
                size: 20, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: ink)),
                  if (snippet.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(snippet,
                          key: ValueKey('$key-snippet'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.ink.withValues(alpha: .68))),
                    ),
                  if (note?.isArchived == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(strings.Archive,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: AppColors.ink.withValues(alpha: .6))),
                    ),
                ],
              ),
            ),
            if (interactive) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 20, color: ink),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      key: ValueKey(key),
      button: interactive,
      enabled: note != null,
      hint: interactive ? strings.Open_Linked_Note : null,
      child: interactive
          ? Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpen!(note),
                child: content,
              ),
            )
          : content,
    );
  }
}
