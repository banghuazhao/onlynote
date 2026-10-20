import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/template_content_search.dart';

import 'app_sheet.dart';
import 'template_content_snippet.dart';
import 'template_name_search.dart';

@Preview(name: 'Template snippets — light', group: 'Note', size: Size(390, 700))
Widget templateContentSnippetsLightPreview() =>
    const _TemplateContentSnippetsPreview();

@Preview(
  name: 'Template snippets — dark',
  group: 'Note',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget templateContentSnippetsDarkPreview() =>
    const _TemplateContentSnippetsPreview(dark: true);

@Preview(
  name: 'Template snippets — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget templateContentSnippetsChinesePreview() =>
    const _TemplateContentSnippetsPreview(chinese: true, textScale: 2);

/// Search and selection are in memory; content never opens any media files.
class _TemplateContentSnippetsPreview extends StatefulWidget {
  const _TemplateContentSnippetsPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_TemplateContentSnippetsPreview> createState() =>
      _TemplateContentSnippetsPreviewState();
}

class _TemplateContentSnippetsPreviewState
    extends State<_TemplateContentSnippetsPreview> {
  final _search = TextEditingController();
  String? _selected;

  late final _templates = [
    CustomNoteTemplate(
      id: 'body',
      name: 'Weekly planning',
      body:
          'Projects to move forward, people to catch up with, and time to rest. '
          '${List.filled(20, 'Earlier planning ideas. ').join()}'
          'Deepbody [2026] after the long background.',
      items: const ['Review the calendar', 'Choose three priorities'],
      tags: const ['planning-tag'],
      imagePaths: const ['preview-photo.jpg'],
      voiceMemos: [
        VoiceMemo(
          id: 'planning',
          path: 'template_audio/preview-planning.m4a',
          durationMs: 250000,
          createdAt: DateTime(2026, 10, 20),
          transcript: 'Remember the microphone and bring 茶😀.',
        ),
        VoiceMemo(
          id: 'recap',
          path: 'template_audio/preview-recap.m4a',
          durationMs: 272000,
          createdAt: DateTime(2026, 10, 20),
        ),
      ],
      createdAt: DateTime(2026, 10, 20),
    ),
    CustomNoteTemplate(
      id: 'checklist',
      name: 'Weekly planning',
      items: const ['Buy fresh vegetables', 'Prepare lunches', 'Plan dinners'],
      createdAt: DateTime(2026, 10, 20),
    ),
    CustomNoteTemplate(
      id: 'title',
      name: '閱讀與研究茶😀',
      title: '閱讀筆記：觀察、問題與下一步 👨‍👩‍👧‍👦',
      createdAt: DateTime(2026, 10, 20),
    ),
    CustomNoteTemplate(
      id: 'audio',
      name: 'Audio notebook',
      voiceMemos: [
        VoiceMemo(
          id: 'audio-only',
          path: 'template_audio/preview-audio-only.m4a',
          durationMs: 65000,
          createdAt: DateTime(2026, 10, 20),
        ),
      ],
      createdAt: DateTime(2026, 10, 20),
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          brightness: widget.dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(builder: (context) {
            final matches =
                TemplateContentSearch(_search.text).filterCustom(_templates);
            return Align(
              alignment: Alignment.bottomCenter,
              child: AppSheet(
                title: S.of(context).Templates,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: TemplateNameSearchField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_search.text.trim().isNotEmpty && matches.isEmpty)
                      const TemplateNameSearchEmpty(),
                    for (final template in matches)
                      Card(
                        child: ListTile(
                          key: ValueKey(
                              'template-snippet-select-${template.id}'),
                          minVerticalPadding: 16,
                          leading: const Icon(Icons.notes_outlined),
                          title: Text(template.name),
                          subtitle: TemplateContentSubtitle(
                              template: template, query: _search.text),
                          selected: _selected == template.id,
                          onTap: () => setState(() => _selected = template.id),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}
