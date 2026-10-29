import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_section_link_picker_sheet.dart';
import 'package:onlynote/presentation/components/note_section_links_section.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_section_links.dart';

@Preview(name: 'Section links', group: 'Note', size: Size(390, 650))
Widget noteSectionLinksPreview() => const _SectionLinksPreview();

@Preview(
    name: 'Section links — dark',
    group: 'Note',
    size: Size(390, 650),
    brightness: Brightness.dark)
Widget noteSectionLinksDarkPreview() => const _SectionLinksPreview(dark: true);

@Preview(
    name: 'Section links — Chinese 2×', group: 'Note', size: Size(280, 650))
Widget noteSectionLinksLargeTextPreview() =>
    const _SectionLinksPreview(locale: Locale('zh', 'HK'), textScale: 2);

@Preview(name: 'Choose a heading', group: 'Note', size: Size(390, 650))
Widget noteSectionLinkPickerPreview() =>
    const _SectionLinksPreview(pickerOnly: true);

@Preview(
    name: 'Choose a heading — dark',
    group: 'Note',
    size: Size(390, 650),
    brightness: Brightness.dark)
Widget noteSectionLinkPickerDarkPreview() =>
    const _SectionLinksPreview(dark: true, pickerOnly: true);

@Preview(
    name: 'Choose a heading — short Chinese 2×',
    group: 'Note',
    size: Size(320, 360))
Widget noteSectionLinkPickerLargeTextPreview() => const _SectionLinksPreview(
    locale: Locale('zh', 'HK'), textScale: 2, pickerOnly: true);

/// Heading metadata and callbacks are local; previews never open native APIs.
class _SectionLinksPreview extends StatefulWidget {
  const _SectionLinksPreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
    this.pickerOnly = false,
  });
  final bool dark;
  final Locale locale;
  final double textScale;
  final bool pickerOnly;

  @override
  State<_SectionLinksPreview> createState() => _SectionLinksPreviewState();
}

class _SectionLinksPreviewState extends State<_SectionLinksPreview> {
  late final bool _chinese = widget.locale.languageCode == 'zh';
  late final List<Note> _notes = [
    _note('current', _chinese ? '週末旅行' : 'Weekend trip',
        _chinese ? '行程安排' : 'Itinerary', 'itinerary'),
    _note('packing', _chinese ? '出發前的清單' : 'Before we leave',
        _chinese ? '雨衣、茶和充電器' : 'Raincoats, tea and chargers', 'packing'),
    _note('archive', _chinese ? '去年走過的路線' : 'Last year’s route',
        _chinese ? '海邊步道' : 'Coastal walk', 'coast',
        archived: true),
  ];
  late List<NoteSectionLink> _links = [
    NoteSectionLink(
        noteId: 'current',
        headingId: 'itinerary',
        headingText: _chinese ? '行程安排' : 'Itinerary'),
    NoteSectionLink(
        noteId: 'packing',
        headingId: 'packing',
        headingText: _chinese ? '要帶的東西' : 'What to bring'),
    NoteSectionLink(
        noteId: 'missing',
        headingId: 'removed',
        headingText: _chinese ? '之前保存的餐廳' : 'Previously saved restaurants'),
  ];
  String? _opened;

  Note _note(String id, String title, String heading, String anchorId,
          {bool archived = false}) =>
      Note(
          id: id,
          title: title,
          description:
              '$heading\n${_chinese ? '帶著家人，沿著海邊走一走。' : 'A quiet walk by the sea with the family.'}',
          isArchived: archived,
          textStyles: [
            NoteTextStyleRange(
                start: 0,
                end: heading.length,
                kind: NoteTextStyleKind.heading,
                anchorId: anchorId)
          ]);

  Future<void> _add(BuildContext context) async {
    final selected = await showNoteSectionLinkPickerSheet(context,
        notes: _notes, currentNoteId: 'current');
    if (!mounted || selected == null || selected.heading.anchorId == null) {
      return;
    }
    setState(() => _links = normalizeNoteSectionLinks([
          ..._links,
          NoteSectionLink(
              noteId: selected.noteId,
              headingId: selected.heading.anchorId!,
              headingText: selected.heading.text),
        ]));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: widget.dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(widget.textScale),
                disableAnimations: true),
            child: child!),
        home: Scaffold(
          backgroundColor: AppColors.parchment,
          body: SafeArea(
            child: widget.pickerOnly
                ? NoteSectionLinkPickerSheet(
                    notes: _notes, currentNoteId: 'current')
                : Builder(
                    builder: (context) => SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NoteSectionLinksSection(
                            links: _links,
                            notes: _notes,
                            onAdd: () => _add(context),
                            onRemove: (link) => setState(() => _links = _links
                                .where((value) => value != link)
                                .toList()),
                            onOpen: (link) => setState(() => _opened =
                                resolveNoteSectionLink(link, _notes)
                                    ?.heading
                                    .text),
                          ),
                          if (_opened != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(_opened!,
                                  key: const ValueKey(
                                      'section-links-preview-opened')),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      );
}
