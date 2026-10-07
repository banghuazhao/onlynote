import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/note_card_typography.dart';

/// Compact identity for dragging. Media-only notes keep a useful headline.
class NoteReorderCard extends StatelessWidget {
  const NoteReorderCard({super.key, required this.note});
  final Note note;

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
    final date = note.dateTime == null || style.showDate == false
        ? ''
        : DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(note.dateTime!);
    return PaperNote(
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
          if (date.isNotEmpty) ...[
            const SizedBox(height: AppSpacings.m),
            Text(date,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.description.copyWith(
                    fontSize: 12 * typography.scale,
                    height: 1.4,
                    color: AppColors.ink.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }
}
