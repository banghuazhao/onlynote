import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'app_sheet.dart';
import 'note_history_search.dart';
import 'note_history_version_tile.dart';

@Preview(name: 'History search — light', group: 'Note', size: Size(390, 700))
Widget noteHistorySearchLightPreview() => const _HistorySearchPreview();

@Preview(
  name: 'History search — dark',
  group: 'Note',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget noteHistorySearchDarkPreview() =>
    const _HistorySearchPreview(dark: true);

@Preview(
  name: 'History search — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget noteHistorySearchChinesePreview() =>
    const _HistorySearchPreview(chinese: true, textScale: 2);

/// The search and summaries use display data only: no repository or media I/O.
class _HistorySearchPreview extends StatefulWidget {
  const _HistorySearchPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_HistorySearchPreview> createState() => _HistorySearchPreviewState();
}

class _HistorySearchPreviewState extends State<_HistorySearchPreview> {
  final _search = TextEditingController();
  ({String id, String title, String text})? _selected;
  static const _versions = [
    (
      id: 'review',
      title: 'Release review [draft]',
      text: 'Review the checklist and keep this recorded thought. 茶😀',
    ),
    (id: 'tea', title: 'Tea plan', text: 'Plan the afternoon walk. 茶室😀'),
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
          fontFamily: 'Roboto',
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
            final matches = filterNoteHistoryVersions(_versions, _search.text,
                searchableText: (version) => [version.title, version.text]);
            final selected = _selected;
            return Align(
              alignment: Alignment.bottomCenter,
              child: AppSheet(
                title: selected == null
                    ? strings.History_Title
                    : strings.History_Preview,
                child: selected == null
                    ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: NoteHistorySearchField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (matches.isEmpty)
                            NoteHistorySearchEmpty(
                                onClear: () => setState(_search.clear))
                          else
                            for (final version in matches)
                              NoteHistoryVersionTile(
                                key: ValueKey(
                                    'history-search-version-${version.id}'),
                                title: version.title,
                                dateLabel: widget.chinese
                                    ? '2026年10月20日 上午10:00'
                                    : 'Oct 20, 2026, 10:00 AM',
                                snippet: version.text,
                                mediaCounts: const SizedBox.shrink(),
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _selected = version);
                                },
                              ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextButton.icon(
                              key:
                                  const ValueKey('history-search-preview-back'),
                              onPressed: () => setState(() => _selected = null),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(strings.History_Title),
                            ),
                            SelectableText(selected.title),
                            const SizedBox(height: 12),
                            SelectableText(selected.text),
                          ],
                        ),
                      ),
              ),
            );
          }),
        ),
      );
}
