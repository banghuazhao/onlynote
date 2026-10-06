import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/presentation/components/note_tags_sheet.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/saved_note_views.dart';

Widget _previewApp(Widget child, {bool largeChinese = false}) => MaterialApp(
      theme: AppTheme.light,
      locale: largeChinese ? const Locale('zh') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(largeChinese ? 2 : 1),
            disableAnimations: largeChinese),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

@Preview(name: 'Library filters and saved views', size: Size(390, 700))
Widget libraryFiltersPreview() => _previewApp(LibraryFiltersSheet(
      filters: const {NoteSearchFilter.unfinished},
      selectedTags: const {'Work'},
      availableTags: const ['Work', 'Personal', 'Projects'],
      savedViews: [
        SavedNoteView(
            id: 'follow-ups',
            name: 'Project follow-ups',
            filters: {NoteSearchFilter.unfinished},
            tags: ['Work']),
        SavedNoteView(
            id: 'archive',
            name: 'Past projects',
            tags: ['Projects'],
            archiveScope: NoteArchiveScope.archived),
      ],
    ));

@Preview(name: 'Tags at large Chinese text', size: Size(320, 700))
Widget noteTagsLargeChinesePreview() => _previewApp(
      const NoteTagsSheet(
          tags: ['個人工作計劃與重要事項', '項目'], suggestions: ['旅行', '本週安排', '會議記錄']),
      largeChinese: true,
    );
