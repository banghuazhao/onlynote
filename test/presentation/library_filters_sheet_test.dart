import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/library_filters_sheet.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/saved_note_views.dart';

Future<Completer<LibraryFilterResult?>> open(
  WidgetTester tester, {
  Set<NoteSearchFilter> filters = const {},
  Set<String> selectedTags = const {},
  List<String> tags = const [],
  List<SavedNoteView> views = const [],
  Map<String, String> folderNames = const {},
  String? selectedViewId,
  NoteArchiveScope scope = NoteArchiveScope.active,
  bool trash = false,
  bool unavailable = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final result = Completer<LibraryFilterResult?>();
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale), disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  child: const Text('Open'),
                  onPressed: () async =>
                      result.complete(await showAppSheet<LibraryFilterResult>(
                    context: context,
                    builder: (_) => LibraryFiltersSheet(
                        filters: filters,
                        selectedTags: selectedTags,
                        availableTags: tags,
                        savedViews: views,
                        folderNames: folderNames,
                        selectedViewId: selectedViewId,
                        scope: scope,
                        showTrash: trash,
                        viewsUnavailable: unavailable),
                  )),
                ))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

Finder key(String value) => find.byKey(ValueKey(value));

void main() {
  testWidgets('filters tags and archive scope apply only on explicit Done',
      (tester) async {
    final original = <NoteSearchFilter>{NoteSearchFilter.photos};
    final result =
        await open(tester, filters: original, tags: ['Work', ' WORK ', '项目']);
    await tester.tap(key('library-filter-checklists'));
    await tester.tap(key('library-tag-work'));
    await tester.tap(key('library-include-archived'));
    await tester.pump();
    expect(result.isCompleted, isFalse);
    expect(original, {NoteSearchFilter.photos});
    expect(key('library-tag-work'), findsOneWidget);
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    final selection = (await result.future) as ApplyLibraryFilters;
    expect(selection.filters,
        {NoteSearchFilter.photos, NoteSearchFilter.checklists});
    expect(selection.tags, {'Work'});
    expect(selection.scope, NoteArchiveScope.all);
  });

  testWidgets('closing sheet discards in-progress filters', (tester) async {
    final result = await open(tester, tags: ['Work']);
    await tester.tap(key('library-tag-work'));
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await result.future, isNull);
  });

  testWidgets('recording and scanned document filters apply and clear together',
      (tester) async {
    final original = <NoteSearchFilter>{NoteSearchFilter.photos};
    final result = await open(tester, filters: original);
    for (final filter in ['recordings', 'scans']) {
      await tester.ensureVisible(key('library-filter-$filter'));
      await tester.tap(key('library-filter-$filter'));
      await tester.pump();
      expect(tester.widget<FilterChip>(key('library-filter-$filter')).selected,
          isTrue);
    }
    expect(original, {NoteSearchFilter.photos});
    expect(result.isCompleted, isFalse);
    await tester.ensureVisible(key('library-apply-filters'));
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    expect(((await result.future) as ApplyLibraryFilters).filters, {
      NoteSearchFilter.photos,
      NoteSearchFilter.recordings,
      NoteSearchFilter.scans,
    });

    final clearResult = await open(tester,
        filters: {NoteSearchFilter.recordings, NoteSearchFilter.scans});
    await tester.ensureVisible(key('library-clear-filters'));
    await tester.tap(key('library-clear-filters'));
    await tester.pump();
    expect(tester.widget<FilterChip>(key('library-filter-recordings')).selected,
        isFalse);
    expect(tester.widget<FilterChip>(key('library-filter-scans')).selected,
        isFalse);
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    expect(
        ((await clearResult.future) as ApplyLibraryFilters).filters, isEmpty);
  });

  testWidgets('saved view selection returns its complete criteria',
      (tester) async {
    final view = SavedNoteView(
        id: 'view',
        name: 'Follow-ups',
        query: 'call',
        tags: ['Work'],
        archiveScope: NoteArchiveScope.archived);
    final result = await open(tester, views: [view]);
    await tester.ensureVisible(key('saved-view-view'));
    await tester.tap(key('saved-view-view'));
    await tester.pumpAndSettle();
    expect(((await result.future) as ApplySavedNoteView).view, same(view));
  });

  testWidgets('saved view subtitle describes criteria without changing actions',
      (tester) async {
    final view = SavedNoteView(
      id: 'media',
      name: 'Research meeting',
      query: '  call  ',
      folderId: 'projects',
      filters: {
        NoteSearchFilter.scans,
        NoteSearchFilter.pinned,
        NoteSearchFilter.recordings,
      },
      tags: ['Work', 'Important'],
      archiveScope: NoteArchiveScope.all,
    );
    final before = view.toJson();
    final result = await open(tester,
        views: [view],
        folderNames: {'projects': 'Project notes'},
        selectedViewId: view.id);
    final description = key('saved-view-media-description');
    final strings = S.of(tester.element(description));
    expect(
        tester.widget<Text>(description).data,
        [
          'Project notes',
          strings.Saved_View_Search('call'),
          strings.Filter_Pinned,
          strings.Filter_Recordings,
          strings.Filter_Scans,
          strings.Saved_View_Tags('Work, Important'),
          strings.Include_Archived,
        ].join(' · '));
    expect(tester.widget<ListTile>(key('saved-view-media')).selected, isTrue);
    expect(
        find.descendant(
            of: key('saved-view-media'),
            matching: find.byType(PopupMenuButton<String>)),
        findsOneWidget);
    await tester.ensureVisible(key('saved-view-media'));
    await tester.tap(key('saved-view-media'));
    await tester.pumpAndSettle();
    expect(((await result.future) as ApplySavedNoteView).view, same(view));
    expect(view.toJson(), before);
  });

  testWidgets('missing folders describe the same fallback as saved-view apply',
      (tester) async {
    final view = SavedNoteView(
      id: 'deleted-folder',
      name: 'Past scans',
      query: '   ',
      folderId: 'deleted-id',
      filters: {NoteSearchFilter.scans},
      archiveScope: NoteArchiveScope.archived,
    );
    await open(tester, views: [view], folderNames: {'other-id': 'Other notes'});
    final description = key('saved-view-deleted-folder-description');
    final strings = S.of(tester.element(description));
    expect(tester.widget<Text>(description).data,
        '${strings.All_Notes} · ${strings.Filter_Scans} · ${strings.Archive}');
    expect(view.folderId, 'deleted-id');
    expect(view.withAvailableFolders({'other-id'}).folderId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Save view captures changed filters without editing stored views',
      (tester) async {
    final result = await open(tester, tags: ['Work']);
    await tester.tap(key('library-filter-unfinished'));
    await tester.tap(key('library-tag-work'));
    await tester.pump();
    await tester.ensureVisible(key('library-save-view'));
    await tester.tap(key('library-save-view'));
    await tester.pumpAndSettle();
    final selected = (await result.future) as CreateSavedNoteView;
    expect(selected.filters, {NoteSearchFilter.unfinished});
    expect(selected.tags, {'Work'});
  });

  testWidgets('rename and delete are explicit saved view actions',
      (tester) async {
    final view = SavedNoteView(id: 'view', name: 'Follow-ups');
    for (final action in ['Rename view', 'Delete view']) {
      final result = await open(tester, views: [view]);
      final menu = find.descendant(
          of: key('saved-view-view'),
          matching: find.byType(PopupMenuButton<String>));
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      final selected = await result.future;
      expect(
          selected,
          action == 'Rename view'
              ? isA<RenameSavedNoteView>()
              : isA<DeleteSavedNoteView>());
    }
  });

  testWidgets('Trash omits archive toggles and view creation', (tester) async {
    await open(tester, trash: true);
    expect(key('library-include-archived'), findsNothing);
    expect(key('library-save-view'), findsNothing);
  });

  for (final locale in [const Locale('zh'), const Locale('zh', 'HK')]) {
    testWidgets('large Chinese text and long tags remain scrollable in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester,
          tags: ['個人工作計劃' * 6],
          filters: {NoteSearchFilter.recordings, NoteSearchFilter.scans},
          folderNames: {'work': '本週重要工作項目及會議記錄'},
          views: [
            SavedNoteView(
              id: 'long',
              name: '本週重要項目及未完成工作清單',
              folderId: 'work',
              query: '長查詢內容' * 20,
              filters: {NoteSearchFilter.recordings, NoteSearchFilter.scans},
              tags: ['個人工作計劃' * 6],
              archiveScope: NoteArchiveScope.all,
            )
          ],
          locale: locale,
          textScale: 2);
      for (final filter in ['recordings', 'scans']) {
        final chip = key('library-filter-$filter');
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        expect(tester.widget<FilterChip>(chip).selected, isTrue);
        expect(tester.takeException(), isNull);
      }
      final description = key('saved-view-long-description');
      await tester.ensureVisible(description);
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(description).data!;
      final strings = S.of(tester.element(description));
      expect(text, contains('本週重要工作項目及會議記錄'));
      expect(text, contains(strings.Filter_Recordings));
      expect(text, contains(strings.Filter_Scans));
      expect(text, contains(strings.Include_Archived));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(key('library-save-view'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
