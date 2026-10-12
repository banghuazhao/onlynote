import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_tags.dart';

import 'app_sheet.dart';
import 'library_tag_selection_feedback.dart';
import 'saved_view_name_search.dart';

@Preview(name: 'Library search feedback — light', size: Size(390, 700))
Widget librarySearchFeedbackLightPreview() => const _LibrarySearchPreview();

@Preview(
  name: 'Library search feedback — dark',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget librarySearchFeedbackDarkPreview() =>
    const _LibrarySearchPreview(dark: true);

@Preview(name: 'Library search feedback — English 2×', size: Size(280, 700))
Widget librarySearchFeedbackLargeTextPreview() =>
    const _LibrarySearchPreview(textScale: 2);

@Preview(name: 'Library search feedback — Chinese 2×', size: Size(280, 700))
Widget librarySearchFeedbackChinesePreview() =>
    const _LibrarySearchPreview(locale: Locale('zh'), textScale: 2);

@Preview(name: 'Library search feedback — Hong Kong 2×', size: Size(280, 700))
Widget librarySearchFeedbackHongKongPreview() =>
    const _LibrarySearchPreview(locale: Locale('zh', 'HK'), textScale: 2);

/// Every action changes only local fixture state; no saved-view store is loaded.
class _LibrarySearchPreview extends StatefulWidget {
  const _LibrarySearchPreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final bool dark;
  final Locale locale;
  final double textScale;

  @override
  State<_LibrarySearchPreview> createState() => _LibrarySearchPreviewState();
}

class _LibrarySearchPreviewState extends State<_LibrarySearchPreview> {
  final _tagSearch = TextEditingController(text: 'C++');
  final _viewSearch = TextEditingController();
  final _tags = {for (var i = 1; i <= maxNoteTags; i++) 'Work $i'};
  String _selectedView = 'work';
  static const _views = [
    (id: 'work', name: 'Project follow-ups'),
    (id: 'meetings', name: 'Meeting recordings'),
    (id: 'literal', name: 'C++ [2026]'),
    (id: 'unicode', name: 'Ångström research'),
    (id: 'chinese', name: '項目會議與閱讀資料'),
  ];

  @override
  void dispose() {
    _tagSearch.dispose();
    _viewSearch.dispose();
    super.dispose();
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
        home: Scaffold(body: Builder(builder: (context) {
          final strings = S.of(context);
          final query = tagKey(_tagSearch.text);
          final tags = [
            for (var i = 1; i <= maxNoteTags; i++) 'Work $i',
            'C++',
          ].where((tag) => tagKey(tag).contains(query));
          final views = filterSavedViewNames(_views, _viewSearch.text,
              nameOf: (view) => view.name);
          return Align(
            alignment: Alignment.bottomCenter,
            child: AppSheet(
              title: strings.Library_Filters,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      key: const ValueKey('preview-tag-search'),
                      controller: _tagSearch,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: strings.Search_Tags,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _tagSearch.text.isEmpty
                            ? null
                            : IconButton(
                                key: const ValueKey('preview-clear-tag-search'),
                                tooltip: strings.Clear_Search,
                                onPressed: () => setState(_tagSearch.clear),
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  LibraryTagSelectionFeedback(
                    selectedCount: _tags.length,
                    hiddenSelectedCount: _tags
                        .where((tag) => !tagKey(tag).contains(query))
                        .length,
                    maxTags: maxNoteTags,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(spacing: 8, runSpacing: 4, children: [
                      for (final tag in tags)
                        FilterChip(
                          key: ValueKey('preview-tag-${tagKey(tag)}'),
                          label: Text(tag),
                          selected: _tags.contains(tag),
                          onSelected:
                              _tags.contains(tag) || _tags.length < maxNoteTags
                                  ? (selected) => setState(() {
                                        if (selected) {
                                          _tags.add(tag);
                                        } else {
                                          _tags.remove(tag);
                                        }
                                      })
                                  : null,
                        ),
                    ]),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(strings.Saved_Views),
                  ),
                  SavedViewNameSearch(
                    controller: _viewSearch,
                    onChanged: (_) => setState(() {}),
                    hasMatches: views.isNotEmpty,
                  ),
                  for (final view in views)
                    ListTile(
                      key: ValueKey('preview-saved-view-${view.id}'),
                      leading: const Icon(Icons.bookmark_border_rounded),
                      title: Text(view.name),
                      selected: view.id == _selectedView,
                      onTap: () => setState(() => _selectedView = view.id),
                    ),
                ],
              ),
            ),
          );
        })),
      );
}
