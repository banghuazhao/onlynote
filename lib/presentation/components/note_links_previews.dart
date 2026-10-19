import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
Widget noteLinkPickerPreview() => const _LinkPickerPreview();

@Preview(name: 'Choose linked notes — dark', size: Size(390, 740))
Widget noteLinkPickerDarkPreview() =>
    const _LinkPickerPreview(brightness: Brightness.dark);

@Preview(name: 'Choose linked notes — narrow Chinese', size: Size(320, 640))
Widget noteLinkPickerLargeTextPreview() => const _LinkPickerPreview(
      locale: Locale('zh', 'HK'),
      textScale: 2,
    );

class _LinkPickerPreview extends StatelessWidget {
  const _LinkPickerPreview({
    this.brightness = Brightness.light,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final Brightness brightness;
  final Locale locale;
  final double textScale;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: NoteLinkPickerSheet(
            currentNoteId: 'meeting',
            selectedIds: const ['travel', 'packing', 'missing'],
            notes: previewLinkedNotes(),
          ),
        ),
      );
}
