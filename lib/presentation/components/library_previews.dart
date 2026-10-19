import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/presentation/components/note_tags_sheet.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_sort.dart';
import 'package:onlynote/services/saved_note_views.dart';

ThemeData _previewTheme() {
  final theme = AppTheme.light;
  const fallback = ['DroidSansFallback'];
  final textTheme = theme.textTheme.apply(fontFamilyFallback: fallback);
  final buttonText = WidgetStatePropertyAll(textTheme.labelLarge);
  // Component themes retain their own text styles, so give their fixture text
  // the same CJK fallback as the surrounding preview.
  return theme.copyWith(
    textTheme: textTheme,
    chipTheme: theme.chipTheme.copyWith(
      labelStyle:
          theme.chipTheme.labelStyle?.copyWith(fontFamilyFallback: fallback),
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      titleTextStyle: theme.listTileTheme.titleTextStyle
          ?.copyWith(fontFamilyFallback: fallback),
      subtitleTextStyle: theme.listTileTheme.subtitleTextStyle
          ?.copyWith(fontFamilyFallback: fallback),
    ),
    textButtonTheme: TextButtonThemeData(
      style: theme.textButtonTheme.style?.copyWith(textStyle: buttonText),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(textStyle: buttonText),
    ),
  );
}

Widget _previewApp(Widget child, {bool largeChinese = false}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _previewTheme(),
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
      sort: NoteSortOrder.titleAsc,
      filters: const {NoteSearchFilter.unfinished, NoteSearchFilter.recordings},
      selectedTags: const {'Work'},
      tagUsageCounts: const {
        'work': 12,
        'personal': 1,
        'projects': 27,
        'reading': 3,
        'research': 18,
        'meetings': 5,
        'travel': 4,
        'shopping': 2,
        'recipes': 6,
        'c++': 1,
        'follow-ups': 8,
        'ideas': 14,
      },
      availableTags: const [
        'Work',
        'Personal',
        'Projects',
        'Reading',
        'Research',
        'Meetings',
        'Travel',
        'Shopping',
        'Recipes',
        'C++',
        'Follow-ups',
        'Ideas',
      ],
      folderNames: const {'work': 'Work'},
      savedViews: [
        SavedNoteView(
            id: 'follow-ups',
            name: 'Project follow-ups',
            query: 'meeting',
            folderId: 'work',
            filters: {NoteSearchFilter.unfinished},
            tags: ['Work']),
        SavedNoteView(
            id: 'archive',
            name: 'Past projects',
            filters: {NoteSearchFilter.scans},
            tags: ['Projects'],
            archiveScope: NoteArchiveScope.archived),
      ],
    ));

@Preview(name: 'Library filters at large Chinese text', size: Size(320, 700))
Widget libraryFiltersLargeChinesePreview() => _previewApp(
      LibraryFiltersSheet(
        filters: const {NoteSearchFilter.recordings, NoteSearchFilter.scans},
        selectedTags: const {'項目'},
        tagUsageCounts: const {
          '項目': 2003,
          '個人工作計劃與重要事項': 27,
          '閱讀': 1,
          '研究': 18,
          '會議記錄': 5,
          '旅行': 4,
          '購物': 2,
          '食譜': 6,
          '本週安排': 1,
          '家庭': 8,
          '靈感': 14,
          'c++': 1,
        },
        availableTags: const [
          '項目',
          '個人工作計劃與重要事項',
          '閱讀',
          '研究',
          '會議記錄',
          '旅行',
          '購物',
          '食譜',
          '本週安排',
          '家庭',
          '靈感',
          'C++',
        ],
        folderNames: const {'work': '工作項目與會議記錄'},
        selectedViewId: 'research',
        savedViews: [
          SavedNoteView(
            id: 'research',
            name: '本週會議錄音及掃描文件',
            query: '項目會議',
            folderId: 'work',
            filters: {NoteSearchFilter.recordings, NoteSearchFilter.scans},
            tags: ['項目', '重要'],
            archiveScope: NoteArchiveScope.all,
          ),
          SavedNoteView(
            id: 'past',
            name: '已封存工作資料',
            folderId: 'removed-folder',
            filters: {NoteSearchFilter.scans},
            archiveScope: NoteArchiveScope.archived,
          ),
        ],
      ),
      largeChinese: true,
    );

@Preview(name: 'Tags at large Chinese text', size: Size(320, 700))
Widget noteTagsLargeChinesePreview() => _previewApp(
      const NoteTagsSheet(
          tags: ['個人工作計劃與重要事項', '項目'], suggestions: ['旅行', '本週安排', '會議記錄']),
      largeChinese: true,
    );
