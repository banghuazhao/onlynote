import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

import 'backup_export_status_label.dart';
import 'section_card.dart';

/// Backup export controls shared by the screen and previews without native I/O.
class BackupExportSection extends StatelessWidget {
  const BackupExportSection({
    super.key,
    required this.saveToFile,
    this.onExport,
    this.exportButtonKey,
    this.lastExport,
  });

  final bool saveToFile;
  final VoidCallback? onExport;
  final Key? exportButtonKey;
  final BackupExportRecord? lastExport;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return SectionCard(
      title: strings.Backup_Export,
      subtitle: saveToFile
          ? strings.Backup_Export_Desktop_Description
          : strings.Backup_Export_Description,
      icon: Icons.inventory_2_outlined,
      children: [
        Text(
          backupExportStatusLabel(context, lastExport),
          key: const ValueKey('backup-export-status'),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: exportButtonKey,
            onPressed: onExport,
            icon: Icon(
              saveToFile ? Icons.save_alt_rounded : Icons.ios_share_rounded,
            ),
            label: Text(
              saveToFile ? strings.Backup_Save_As : strings.Backup_Export,
            ),
          ),
        ),
      ],
    );
  }
}
