import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_tags.dart';

import 'note_active_criteria_summary.dart';

@Preview(
    name: 'Selected criteria — light', group: 'Library', size: Size(390, 340))
Widget activeCriteriaLightPreview() => const _ActiveCriteriaPreview();

@Preview(
  name: 'Selected criteria — dark',
  group: 'Library',
  size: Size(390, 340),
  brightness: Brightness.dark,
)
Widget activeCriteriaDarkPreview() => const _ActiveCriteriaPreview(dark: true);

@Preview(
  name: 'Selected criteria — Chinese 2× narrow',
  group: 'Library',
  size: Size(180, 340),
)
Widget activeCriteriaChinesePreview() =>
    const _ActiveCriteriaPreview(locale: Locale('zh'), textScale: 2);

@Preview(
  name: 'Selected criteria — traditional Chinese 2× landscape',
  group: 'Library',
  size: Size(568, 180),
)
Widget activeCriteriaChineseLandscapePreview() => const _ActiveCriteriaPreview(
    dark: true, locale: Locale('zh', 'HK'), textScale: 2);

/// The fixture uses local selection state and can be reset without media IO.
class _ActiveCriteriaPreview extends StatefulWidget {
  const _ActiveCriteriaPreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final bool dark;
  final Locale locale;
  final double textScale;

  @override
  State<_ActiveCriteriaPreview> createState() => _ActiveCriteriaPreviewState();
}

class _ActiveCriteriaPreviewState extends State<_ActiveCriteriaPreview> {
  final _filters = <NoteSearchFilter>{
    NoteSearchFilter.recordings,
    NoteSearchFilter.scans,
    NoteSearchFilter.unfinished,
  };
  late final _tags = <String>{
    widget.locale.languageCode == 'zh' ? '项目资料与会议纪要' : 'Research',
    widget.locale.languageCode == 'zh' ? '需要跟进' : 'Follow-up',
  };
  bool _includeArchived = true;

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
        home: Scaffold(
          body: SafeArea(
            child: Builder(builder: (context) {
              final strings = S.of(context);
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(strings.All_Notes,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                NoteActiveCriteriaSummary(
                  filters: _filters,
                  tags: _tags,
                  includeArchived: _includeArchived,
                  onRemoveFilter: (filter) =>
                      setState(() => _filters.remove(filter)),
                  onRemoveTag: (tag) => setState(() => _tags
                      .removeWhere((value) => tagKey(value) == tagKey(tag))),
                  onRemoveIncludeArchived: () =>
                      setState(() => _includeArchived = false),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(strings.No_Search_Results,
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
              ]);
            }),
          ),
        ),
      );
}
