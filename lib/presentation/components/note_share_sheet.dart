import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/note_share_action_tile.dart';
import 'package:onlynote/services/note_export.dart';

Future<NoteShareFormat?> showNoteShareSheet(BuildContext context,
        {bool hasRecordings = false}) =>
    showAppSheet<NoteShareFormat>(
        context: context,
        builder: (_) => NoteShareSheet(hasRecordings: hasRecordings));

class NoteShareSheet extends StatelessWidget {
  const NoteShareSheet({super.key, this.hasRecordings = false});
  final bool hasRecordings;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AppSheet(
        title: s.Share,
        child: Column(children: [
          for (final format in NoteShareFormat.values)
            if (format != NoteShareFormat.audio || hasRecordings)
              NoteShareActionTile(
                key: ValueKey('note-share-${format.name}'),
                icon: switch (format) {
                  NoteShareFormat.image => Icons.image_outlined,
                  NoteShareFormat.plainText => Icons.text_snippet_outlined,
                  NoteShareFormat.markdown => Icons.code_outlined,
                  NoteShareFormat.pdf => Icons.picture_as_pdf_outlined,
                  NoteShareFormat.audio => Icons.audio_file_outlined,
                  NoteShareFormat.copyText => Icons.copy_outlined,
                },
                title: switch (format) {
                  NoteShareFormat.image => s.Share_Image,
                  NoteShareFormat.plainText => s.Share_Plain_Text,
                  NoteShareFormat.markdown => s.Share_Markdown,
                  NoteShareFormat.pdf => s.Share_PDF,
                  NoteShareFormat.audio => s.Share_Audio,
                  NoteShareFormat.copyText => s.Share_Copy_Text,
                },
                description: switch (format) {
                  NoteShareFormat.image => s.Share_Image_Description,
                  NoteShareFormat.plainText => s.Share_Text_Description,
                  NoteShareFormat.markdown => s.Share_Markdown_Description,
                  NoteShareFormat.pdf => s.Share_PDF_Description,
                  NoteShareFormat.audio => s.Share_Audio_Description,
                  NoteShareFormat.copyText => s.Share_Copy_Text_Description,
                },
                onPressed: () {
                  if (ModalRoute.of(context)?.isCurrent != true) return;
                  Navigator.pop(context, format);
                },
              ),
        ]));
  }
}
