import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'section_card.dart';

/// Backup export controls shared by the screen and previews without native I/O.
class BackupExportSection extends StatelessWidget {
  const BackupExportSection({
    super.key,
    required this.saveToFile,
    this.onExport,
    this.exportButtonKey,
  });

  final bool saveToFile;
  final VoidCallback? onExport;
  final Key? exportButtonKey;

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
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: exportButtonKey,
            onPressed: onExport,
            icon: Icon(
                saveToFile ? Icons.save_alt_rounded : Icons.ios_share_rounded),
            label: Text(
                saveToFile ? strings.Backup_Save_As : strings.Backup_Export),
          ),
        ),
      ],
    );
  }
}
