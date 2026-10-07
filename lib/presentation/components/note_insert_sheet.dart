import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'app_sheet.dart';

enum NoteInsertAction { checklist, gallery, camera, scan, voice }

/// All additions share one entry point, leaving an empty note ready to write.
class NoteInsertSheet extends StatelessWidget {
  const NoteInsertSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final actions = [
      (
        NoteInsertAction.checklist,
        'editor-add-checklist',
        Icons.checklist_rounded,
        strings.Todo_list,
        null
      ),
      (
        NoteInsertAction.gallery,
        'editor-add-photo',
        Icons.photo_library_outlined,
        strings.Add_Image,
        strings.Choose_From_Gallery
      ),
      (
        NoteInsertAction.camera,
        'editor-take-photo',
        Icons.camera_alt_outlined,
        strings.Take_Photo,
        null
      ),
      (
        NoteInsertAction.scan,
        'editor-scan-document',
        Icons.document_scanner_outlined,
        strings.Document_Scan,
        null
      ),
      (
        NoteInsertAction.voice,
        'editor-record-voice',
        Icons.mic_none_rounded,
        strings.Voice_Memo,
        null
      ),
    ];
    return AppSheet(
      title: strings.Editor_Insert,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (action, key, icon, label, subtitle) in actions)
            ListTile(
              key: ValueKey(key),
              minVerticalPadding: 14,
              leading: Icon(icon),
              title: Text(label),
              subtitle: subtitle == null ? null : Text(subtitle),
              onTap: () => Navigator.pop(context, action),
            ),
        ],
      ),
    );
  }
}
