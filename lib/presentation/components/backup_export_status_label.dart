import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

/// The same saved/shared wording and device clock format on every surface.
String backupExportStatusLabel(
  BuildContext context,
  BackupExportRecord? record,
) {
  final strings = S.of(context);
  if (record == null) return strings.Backup_Export_No_Record;
  final localizations = MaterialLocalizations.of(context);
  final localDate = record.exportedAt.toLocal();
  final date = localizations.formatShortDate(localDate);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(localDate),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final label = '$date, $time';
  return switch (record.destination) {
    BackupExportDestination.saved => strings.Backup_Export_Last_Saved(label),
    BackupExportDestination.shared => strings.Backup_Export_Last_Shared(label),
  };
}
