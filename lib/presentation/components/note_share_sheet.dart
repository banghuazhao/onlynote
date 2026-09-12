import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/services/note_export.dart';

Future<NoteShareFormat?> showNoteShareSheet(BuildContext context) =>
    showAppSheet<NoteShareFormat>(
        context: context, builder: (_) => const NoteShareSheet());

class NoteShareSheet extends StatelessWidget {
  const NoteShareSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AppSheet(
        title: s.Share,
        child: Column(children: [
          for (final format in NoteShareFormat.values)
            ListTile(
              leading: Icon(switch (format) {
                NoteShareFormat.image => Icons.image_outlined,
                NoteShareFormat.plainText => Icons.text_snippet_outlined,
                NoteShareFormat.markdown => Icons.code_outlined,
                NoteShareFormat.pdf => Icons.picture_as_pdf_outlined,
              }),
              title: Text(switch (format) {
                NoteShareFormat.image => s.Share_Image,
                NoteShareFormat.plainText => s.Share_Plain_Text,
                NoteShareFormat.markdown => s.Share_Markdown,
                NoteShareFormat.pdf => s.Share_PDF,
              }),
              subtitle: Text(switch (format) {
                NoteShareFormat.image => s.Share_Image_Description,
                NoteShareFormat.plainText => s.Share_Text_Description,
                NoteShareFormat.markdown => s.Share_Markdown_Description,
                NoteShareFormat.pdf => s.Share_PDF_Description,
              }),
              onTap: () => Navigator.pop(context, format),
            ),
        ]));
  }
}
