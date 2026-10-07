import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';

/// Compact identity for dragging. Media-only notes keep a useful headline.
class NoteReorderCard extends StatelessWidget {
  const NoteReorderCard({super.key, required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
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
    final date = note.dateTime == null
        ? ''
        : DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(note.dateTime!);
    return PaperNote(
      color: note.color ?? AppColors.parchment,
      seed: note.id?.hashCode ?? 0,
      pinned: note.isPinned,
      tilt: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(headline,
                style: AppTypography.cardTitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 3),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: AppSpacings.m),
            Text(date,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.description.copyWith(
                    fontSize: 12 * AppTypographySettings.instance.scale,
                    height: 1.4,
                    color: AppColors.ink.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }
}
