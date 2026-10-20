import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_links_section.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';

List<Note> previewLinkedNotes() => [
      Note(
        id: 'travel',
        title: 'Weekend trip',
        description:
            'A quiet coastal walk, tea by the sea, and time together 👨‍👩‍👧‍👦.',
        tags: ['Travel'],
      ),
      Note(
        id: 'packing',
        title: 'Packing list',
        todo: [Todo(title: '雨衣、茶、充電器 — raincoats, tea, and chargers')],
        isArchived: true,
      ),
      Note(id: 'meeting', title: 'Project meeting notes'),
    ];

void previewOpenLinkedNote(Note _) {}
void previewEditNoteLinks() {}

@Preview(name: 'Linked notes and backlinks', size: Size(390, 700))
Widget noteLinksPreview({ThemeData? theme}) => _NoteLinksPreview(theme: theme);

@Preview(
    name: 'Linked notes and backlinks dark',
    size: Size(390, 700),
    brightness: Brightness.dark)
Widget noteLinksDarkPreview({ThemeData? theme}) =>
    _NoteLinksPreview(dark: true, theme: theme);

@Preview(name: 'Linked notes and backlinks Chinese 2×', size: Size(280, 700))
Widget noteLinksLargeTextPreview({ThemeData? theme}) => _NoteLinksPreview(
      locale: const Locale('zh', 'HK'),
      textScale: 2,
      theme: theme,
    );

/// Local metadata and callbacks keep relationship previews native-free.
class _NoteLinksPreview extends StatefulWidget {
  const _NoteLinksPreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
    this.theme,
  });

  final bool dark;
  final Locale locale;
  final double textScale;
  final ThemeData? theme;

  @override
  State<_NoteLinksPreview> createState() => _NoteLinksPreviewState();
}

class _NoteLinksPreviewState extends State<_NoteLinksPreview> {
  late final _notes = [
    ...previewLinkedNotes(),
    Note(
      id: 'voice',
      title: 'Recorded ideas',
      voiceMemos: [
        VoiceMemo(
          id: 'preview-memo',
          path: 'note_audio/unavailable-preview.m4a',
          durationMs: 1000,
          createdAt: DateTime(2026, 10, 20),
          transcript: '預訂海邊的小屋，帶著茶😀和家人 👨‍👩‍👧‍👦一起出發。',
        ),
      ],
    ),
  ];
  Note? _opened;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: widget.theme ?? (widget.dark ? AppTheme.dark : AppTheme.light),
        locale: widget.locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: AppColors.parchment,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NoteLinksSection(
                    linkedNoteIds: const ['packing', 'voice', 'missing'],
                    notes: _notes,
                    backlinks: [_notes.first],
                    onOpen: (note) => setState(() => _opened = note),
                    onEdit: previewEditNoteLinks,
                  ),
                  if (_opened != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_opened!.title ?? '',
                          key: const ValueKey('note-links-preview-opened')),
                    ),
                ],
              ),
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
