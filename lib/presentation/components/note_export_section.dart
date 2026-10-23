import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_bulk_export.dart';

import 'section_card.dart';
import 'settings_choice.dart';

String noteBulkExportFormatLabel(NoteBulkExportFormat format, S strings) =>
    switch (format) {
      NoteBulkExportFormat.markdown => strings.Share_Markdown,
      NoteBulkExportFormat.plainText => strings.Share_Plain_Text,
      NoteBulkExportFormat.pdf => strings.Share_PDF,
    };

String noteBulkExportFormatHint(NoteBulkExportFormat format, S strings) =>
    switch (format) {
      NoteBulkExportFormat.markdown => strings.Export_Notes_Markdown_Hint,
      NoteBulkExportFormat.plainText => strings.Export_Notes_Plain_Text_Hint,
      NoteBulkExportFormat.pdf => strings.Export_Notes_PDF_Hint,
    };

/// Readable-export controls shared by the screen and previews without native
/// I/O, so the format choice and its button states are testable on their own.
class NoteExportSection extends StatelessWidget {
  const NoteExportSection({
    super.key,
    required this.saveToFile,
    required this.format,
    required this.onFormatChanged,
    this.onExport,
    this.exportButtonKey,
  });

  final bool saveToFile;
  final NoteBulkExportFormat format;
  final ValueChanged<NoteBulkExportFormat> onFormatChanged;
  final VoidCallback? onExport;
  final Key? exportButtonKey;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return SectionCard(
      title: strings.Export_Notes,
      subtitle: saveToFile
          ? strings.Export_Notes_Desktop_Description
          : strings.Export_Notes_Description,
      icon: Icons.drive_file_move_outline,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(strings.Export_Notes_Format,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        SettingsChoice<NoteBulkExportFormat>(
          values: NoteBulkExportFormat.values,
          selected: format,
          keyOf: (value) => ValueKey('note-export-format-${value.name}'),
          label: (value) => noteBulkExportFormatLabel(value, strings),
          enabled: onExport != null,
          onSelected: onFormatChanged,
        ),
        const SizedBox(height: 8),
        Text(
          noteBulkExportFormatHint(format, strings),
          key: const ValueKey('note-export-format-hint'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: exportButtonKey,
            onPressed: onExport,
            icon: Icon(
                saveToFile ? Icons.save_alt_rounded : Icons.ios_share_rounded),
            label: Text(saveToFile
                ? strings.Export_Notes_Save_As
                : strings.Export_Notes),
          ),
        ),
      ],
    );
  }
}
