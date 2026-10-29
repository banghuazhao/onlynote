import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/services/note_section_links.dart';

class NoteSectionLinksSection extends StatelessWidget {
  const NoteSectionLinksSection(
      {super.key,
      required this.links,
      required this.notes,
      this.onAdd,
      this.onRemove,
      this.onOpen,
      this.exportMode = false});
  final List<NoteSectionLink> links;
  final List<Note> notes;
  final VoidCallback? onAdd;
  final ValueChanged<NoteSectionLink>? onRemove;
  final ValueChanged<NoteSectionLink>? onOpen;
  final bool exportMode;

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty && (onAdd == null || exportMode)) {
      return const SizedBox.shrink();
    }
    final strings = S.of(context);
    final theme = Theme.of(context);
    final ink = AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Semantics(
                  header: true,
                  child: Text(strings.Section_Links,
                      style: theme.textTheme.titleSmall?.copyWith(color: ink))),
              if (onAdd != null && !exportMode)
                TextButton.icon(
                    key: const ValueKey('add-section-link'),
                    onPressed:
                        links.length >= maxNoteSectionLinks ? null : onAdd,
                    style: TextButton.styleFrom(
                        foregroundColor: ink, minimumSize: const Size(44, 44)),
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: Text(strings.Section_Link_Add)),
            ]),
        for (final link in links)
          Builder(builder: (context) {
            final target = resolveNoteSectionLink(link, notes);
            final available = target != null;
            final noteTitle = target?.note.title?.trim();
            return ListTile(
              key: ValueKey('section-link-${link.noteId}-${link.headingId}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              textColor: ink.withValues(alpha: available ? .88 : .55),
              iconColor: ink.withValues(alpha: .72),
              leading: Icon(
                  available ? Icons.segment_rounded : Icons.link_off_rounded),
              title: Text(target?.heading.text ?? link.headingText,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  available
                      ? (noteTitle?.isNotEmpty == true
                          ? noteTitle!
                          : strings.Note_Untitled)
                      : strings.Section_Link_Unavailable,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              onTap: !exportMode && available && onOpen != null
                  ? () => onOpen!(link)
                  : null,
              trailing: !exportMode && onRemove != null
                  ? IconButton(
                      tooltip: strings.Section_Link_Remove,
                      onPressed: () => onRemove!(link),
                      icon: const Icon(Icons.close_rounded))
                  : !exportMode && available && onOpen != null
                      ? const Icon(Icons.chevron_right_rounded)
                      : null,
            );
          }),
        if (!exportMode && links.length >= maxNoteSectionLinks)
          Text(strings.Section_Link_Limit,
              style: theme.textTheme.bodySmall?.copyWith(color: ink)),
      ]),
    );
  }
}
