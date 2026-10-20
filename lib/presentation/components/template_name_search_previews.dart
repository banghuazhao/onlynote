import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_templates.dart';
import 'package:onlynote/services/template_content_search.dart';

import 'app_sheet.dart';
import 'template_name_search.dart';
import 'template_content_snippet.dart';

@Preview(
    name: 'Template content search — light',
    group: 'Note',
    size: Size(390, 700))
Widget templateNameSearchLightPreview() => const _TemplateNameSearchPreview();

@Preview(
  name: 'Template content search — dark',
  group: 'Note',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget templateNameSearchDarkPreview() =>
    const _TemplateNameSearchPreview(dark: true);

@Preview(
  name: 'Template content search — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget templateNameSearchChinesePreview() =>
    const _TemplateNameSearchPreview(chinese: true, textScale: 2);

/// Uses the picker search helper with local metadata and selection state.
class _TemplateNameSearchPreview extends StatefulWidget {
  const _TemplateNameSearchPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_TemplateNameSearchPreview> createState() =>
      _TemplateNameSearchPreviewState();
}

class _TemplateNameSearchPreviewState
    extends State<_TemplateNameSearchPreview> {
  final _controller = TextEditingController();
  String? _selected;

  late final _custom = [
    CustomNoteTemplate(
      id: 'work',
      name: 'Work routine',
      title: 'Weekly review',
      body: 'Prepare quarterly budget and review next steps.',
      items: const ['Contact the supplier'],
      tags: const ['finance'],
      voiceMemos: [
        VoiceMemo(
          id: 'preview-recording',
          path: 'template_audio/unavailable.m4a',
          durationMs: 1000,
          createdAt: DateTime(2026, 10, 20),
          transcript: 'Remember the projector for the meeting',
        ),
      ],
      createdAt: DateTime(2026, 10, 20),
    ),
    CustomNoteTemplate(
      id: 'literal',
      name: 'C++ [2026]',
      body: 'Literal syntax: .* stays literal',
      createdAt: DateTime(2026, 10, 20),
    ),
    CustomNoteTemplate(
      id: 'cjk',
      name: '閱讀與研究茶😀',
      body: '閱讀筆記與觀察 👨‍👩‍👧‍👦',
      createdAt: DateTime(2026, 10, 20),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
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
            final strings = S.of(context);
            final search = TemplateContentSearch(_controller.text);
            final customMatches = search.filterCustom(_custom);
            final starterMatches =
                search.filterBuiltIn(NoteTemplate.values, strings);
            Widget heading(String label) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Semantics(
                    header: true,
                    child: Text(label,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                );
            Widget row(String key, String name, Widget subtitle) => ListTile(
                  key: ValueKey(key),
                  minVerticalPadding: 16,
                  leading: const Icon(Icons.notes_outlined),
                  title: Text(name),
                  subtitle: subtitle,
                  onTap: () => setState(() => _selected = name),
                );
            return Align(
              alignment: Alignment.bottomCenter,
              child: AppSheet(
                title: strings.Templates,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: TemplateNameSearchField(
                        controller: _controller,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_controller.text.trim().isNotEmpty &&
                        customMatches.isEmpty &&
                        starterMatches.isEmpty)
                      const TemplateNameSearchEmpty(),
                    heading(strings.My_Templates),
                    for (final template in customMatches)
                      row(
                          'custom-template-${template.id}',
                          template.name,
                          TemplateContentSubtitle(
                              template: template, query: _controller.text)),
                    heading(strings.Starter_Templates),
                    for (final template in starterMatches)
                      row(
                          'template-${template.name}',
                          template.content(strings).title,
                          Text(
                              starterTemplateContentSnippet(
                                  template.content(strings),
                                  query: _controller.text),
                              key: ValueKey(
                                  'template-starter-snippet-${template.name}'),
                              maxLines:
                                  _controller.text.trim().isEmpty ? null : 2,
                              overflow: TextOverflow.ellipsis)),
                    if (_selected != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_selected!,
                            key: const ValueKey('template-search-selected')),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}
