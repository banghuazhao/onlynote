import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/generated/l10n.dart';

/// Flat metadata from a decoded and validated backup, with no media access.
class BackupRestoreMetadata {
  const BackupRestoreMetadata({
    required this.createdAt,
    required this.noteCount,
    required this.activeNoteCount,
    required this.archivedNoteCount,
    required this.trashedNoteCount,
    required this.folderCount,
    required this.photoCount,
    required this.templateCount,
    required this.recordingFileCount,
    required this.savedViewCount,
    required this.historyVersionCount,
  });

  final DateTime createdAt;
  final int noteCount;
  final int activeNoteCount;
  final int archivedNoteCount;
  final int trashedNoteCount;
  final int folderCount;
  final int photoCount;
  final int templateCount;
  final int recordingFileCount;
  final int savedViewCount;
  final int historyVersionCount;
}

/// Read-only details for the restore confirmation, separate from native IO.
class BackupRestorePreview extends StatelessWidget {
  const BackupRestorePreview({super.key, required this.metadata});

  final BackupRestoreMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final numbers = NumberFormat.decimalPattern(locale);
    final createdAt =
        DateFormat.yMMMd(locale).add_jm().format(metadata.createdAt.toLocal());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetadataRow(
          id: 'created',
          label: strings.Backup_Created,
          value: createdAt,
          stacked: true,
        ),
        const SizedBox(height: 8),
        Text(
          strings.Backup_Contents(
            numbers.format(metadata.noteCount),
            numbers.format(metadata.folderCount),
            numbers.format(metadata.photoCount),
          ),
          key: const ValueKey('backup-preview-contents'),
        ),
        const SizedBox(height: 8),
        _MetadataRow(
          id: 'active-notes',
          label: strings.Backup_Active_Notes,
          value: numbers.format(metadata.activeNoteCount),
        ),
        _MetadataRow(
          id: 'archived-notes',
          label: strings.Backup_Archived_Notes,
          value: numbers.format(metadata.archivedNoteCount),
        ),
        _MetadataRow(
          id: 'trashed-notes',
          label: strings.Backup_Trashed_Notes,
          value: numbers.format(metadata.trashedNoteCount),
        ),
        _MetadataRow(
          id: 'templates',
          label: strings.My_Templates,
          value: numbers.format(metadata.templateCount),
        ),
        _MetadataRow(
          id: 'recording-files',
          label: strings.Backup_Recording_Files,
          value: numbers.format(metadata.recordingFileCount),
        ),
        _MetadataRow(
          id: 'saved-views',
          label: strings.Backup_Saved_Views,
          value: numbers.format(metadata.savedViewCount),
        ),
        _MetadataRow(
          id: 'history-versions',
          label: strings.Backup_History_Versions,
          value: numbers.format(metadata.historyVersionCount),
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.id,
    required this.label,
    required this.value,
    this.stacked = false,
  });

  final String id;
  final String label;
  final String value;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // AlertDialog measures this content intrinsically, so avoid LayoutBuilder
    // here. Stack at narrow window widths or when large text needs more room.
    final useStacked = stacked ||
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(16) >= 24;
    final labelWidget = Text(
      label,
      key: ValueKey('backup-preview-$id-label'),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final valueWidget = Text(
      value,
      key: ValueKey('backup-preview-$id-value'),
      style: theme.textTheme.bodyMedium,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: useStacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [labelWidget, const SizedBox(height: 4), valueWidget],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: labelWidget),
                  const SizedBox(width: 12),
                  Flexible(child: valueWidget),
                ],
              ),
      ),
    );
  }
}
