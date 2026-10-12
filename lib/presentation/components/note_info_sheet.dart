import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_statistics.dart';

import 'app_sheet.dart';

Future<void> showNoteInfoSheet({
  required BuildContext context,
  required NoteStatistics statistics,
}) =>
    showAppSheet<void>(
      context: context,
      builder: (_) => NoteInfoSheet(statistics: statistics),
    );

/// A compact, read-only summary of the saved note or current editor draft.
class NoteInfoSheet extends StatelessWidget {
  const NoteInfoSheet({super.key, required this.statistics});

  final NoteStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final readingTime = switch (statistics.estimatedReadingSeconds) {
      0 => strings.Note_Info_Reading_Empty,
      < 60 => strings.Note_Info_Reading_Less_Than_Minute,
      _ =>
        strings.Note_Info_Reading_Minutes(statistics.estimatedReadingMinutes),
    };
    return AppSheet(
      title: strings.Note_Info,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatisticRow(
              id: 'words',
              label: strings.Note_Info_Words,
              value: numbers.format(statistics.wordCount),
            ),
            _StatisticRow(
              id: 'characters',
              label: strings.Note_Info_Characters,
              value: numbers.format(statistics.characterCount),
            ),
            _StatisticRow(
              id: 'reading-time',
              label: strings.Note_Info_Reading_Time,
              value: readingTime,
            ),
            _StatisticRow(
              id: 'checklist-progress',
              label: strings.Note_Info_Checklist_Progress,
              value: strings.Checklist_Progress(
                statistics.checklistCompletedCount,
                statistics.checklistTotalCount,
              ),
            ),
            _StatisticRow(
              id: 'checklist-remaining',
              label: strings.Note_Info_Checklist_Remaining,
              value: numbers.format(statistics.checklistRemainingCount),
            ),
            _StatisticRow(
              id: 'photos',
              label: strings.Note_Info_Photos,
              value: numbers.format(statistics.photoCount),
            ),
            _StatisticRow(
              id: 'scanned-pages',
              label: strings.Note_Info_Scanned_Pages,
              value: numbers.format(statistics.scannedPageCount),
            ),
            _StatisticRow(
              id: 'recordings',
              label: strings.Note_Info_Recordings,
              value: numbers.format(statistics.recordingCount),
            ),
            _StatisticRow(
              id: 'recording-duration',
              label: strings.Note_Info_Recording_Duration,
              value: _formatRecordingDuration(statistics.recordingDurationMs),
            ),
            const SizedBox(height: 12),
            Text(
              strings.Note_Info_Counting_Hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches the player's minutes:seconds display without capping combined time.
String _formatRecordingDuration(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _StatisticRow extends StatelessWidget {
  const _StatisticRow({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Semantics(
        key: ValueKey('note-info-$id'),
        label: '$label: $value',
        excludeSemantics: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final stacked = constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(16) >= 24;
          final labelWidget = Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
          final valueWidget = Text(
            value,
            key: ValueKey('note-info-$id-value'),
            style: theme.textTheme.titleMedium,
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 4), valueWidget],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: 16),
              Flexible(child: valueWidget),
            ],
          );
        }),
      ),
    );
  }
}
