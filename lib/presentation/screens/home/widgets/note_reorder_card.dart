import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/note_card_typography.dart';
import 'package:onlynote/services/note_dates.dart';

/// Compact identity for dragging. Media-only notes keep a useful headline.
class NoteReorderCard extends StatelessWidget {
  const NoteReorderCard({
    super.key,
    required this.note,
    this.showReorderControls = false,
    this.onMoveEarlier,
    this.onMoveLater,
  });
  final Note note;
  final bool showReorderControls;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final style = resolveNoteCardStyle(note.cardStyle);
    final typography = NoteCardTypography(style);
    final content = [
      note.title ?? '',
      note.description ?? '',
      ...note.todo.map((todo) => todo.title ?? ''),
      ...note.voiceMemos.map((memo) => memo.transcript ?? ''),
    ].where((text) => text.trim().isNotEmpty).firstOrNull;
    final headline = content ??
        (note.hasVoiceMemos
            ? strings.Voice_Memo
            : note.hasImages
                ? strings.History_Photos(note.imagePaths.length)
                : strings.notes);
    final date = noteCardDateLabel(
      locale: Localizations.localeOf(context).toString(),
      showDate: style.showDate != false,
      movedToTrashLabel: strings.Card_Moved_To_Trash_On,
      dateTime: note.dateTime,
      deletedAt: note.deletedAt,
    );
    return Semantics(
      container: true,
      hint: showReorderControls ? strings.Reorder_Hint : null,
      customSemanticsActions: {
        if (onMoveEarlier != null)
          CustomSemanticsAction(label: strings.Reorder_Move_Earlier):
              onMoveEarlier!,
        if (onMoveLater != null)
          CustomSemanticsAction(label: strings.Reorder_Move_Later):
              onMoveLater!,
      },
      child: PaperNote(
        color: note.color ?? AppColors.parchment,
        seed: note.id?.hashCode ?? 0,
        pinned: note.isPinned,
        tilt: false,
        plainPaper: style.paperStyle == NoteCardPaperStyle.plain,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(headline,
                  style: typography.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3),
            ),
            if (date != null) ...[
              const SizedBox(height: AppSpacings.m),
              Text(date,
                  key: const ValueKey('reorder-card-date'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.description.copyWith(
                      fontSize: 12 * typography.scale,
                      height: 1.4,
                      color: AppColors.ink.withValues(alpha: 0.7))),
            ],
            if (showReorderControls) ...[
              const SizedBox(height: AppSpacings.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.drag_indicator_rounded,
                      size: 20, color: AppColors.ink.withValues(alpha: .5)),
                  PopupMenuButton<_ReorderAction>(
                    key: ValueKey('reorder-move-${note.id}'),
                    tooltip: strings.Reorder,
                    icon: const Icon(Icons.more_horiz_rounded, size: 20),
                    onSelected: (action) => switch (action) {
                      _ReorderAction.earlier => onMoveEarlier?.call(),
                      _ReorderAction.later => onMoveLater?.call(),
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _ReorderAction.earlier,
                        enabled: onMoveEarlier != null,
                        child: Row(children: [
                          const Icon(Icons.arrow_upward_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(strings.Reorder_Move_Earlier),
                        ]),
                      ),
                      PopupMenuItem(
                        value: _ReorderAction.later,
                        enabled: onMoveLater != null,
                        child: Row(children: [
                          const Icon(Icons.arrow_downward_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(strings.Reorder_Move_Later),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ReorderAction { earlier, later }
