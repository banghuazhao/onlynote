import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_links_section.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';

List<Note> previewLinkedNotes() => [
      Note(id: 'travel', title: 'Weekend trip', tags: ['Travel']),
      Note(id: 'packing', title: 'Packing list', isArchived: true),
      Note(id: 'meeting', title: 'Project meeting notes'),
    ];

void previewOpenLinkedNote(Note _) {}
void previewEditNoteLinks() {}

@Preview(name: 'Linked notes and backlinks', size: Size(390, 430))
Widget noteLinksPreview() {
  final notes = previewLinkedNotes();
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [S.delegate],
    home: Scaffold(
      backgroundColor: AppColors.parchment,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: NoteLinksSection(
          linkedNoteIds: const ['packing', 'missing'],
          notes: notes,
          backlinks: [notes.first],
          onOpen: previewOpenLinkedNote,
          onEdit: previewEditNoteLinks,
        ),
      ),
    ),
  );
}

@Preview(name: 'Choose linked notes', size: Size(390, 740))
Widget noteLinkPickerPreview() => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: NoteLinkPickerSheet(
          currentNoteId: 'meeting',
          selectedIds: const ['packing', 'missing'],
          notes: previewLinkedNotes(),
        ),
      ),
    );
