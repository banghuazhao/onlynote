import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

import 'backup_export_status_label.dart';

/// Settings navigation with optional metadata, without native storage or I/O.
class BackupSettingsTile extends StatelessWidget {
  const BackupSettingsTile({super.key, this.lastExport, this.onTap});

  final BackupExportRecord? lastExport;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          key: const ValueKey('settings-backup'),
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(S.of(context).Backup_Title),
          subtitle: Text(
            backupExportStatusLabel(context, lastExport),
            key: const ValueKey('settings-backup-status'),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}
