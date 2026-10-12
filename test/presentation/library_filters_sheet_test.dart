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
  ValueNotifier<List<SavedNoteView>>? viewUpdates,
  Map<String, String> folderNames = const {},
  String? selectedViewId,
  NoteArchiveScope scope = NoteArchiveScope.active,
  bool trash = false,
  bool unavailable = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
  double keyboardInset = 0,
}) async {
  final result = Completer<LibraryFilterResult?>();
  LibraryFiltersSheet sheet(List<SavedNoteView> currentViews) =>
      LibraryFiltersSheet(
          filters: filters,
          selectedTags: selectedTags,
          availableTags: tags,
          savedViews: currentViews,
          folderNames: folderNames,
          selectedViewId: selectedViewId,
          scope: scope,
          showTrash: trash,
          viewsUnavailable: unavailable);
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
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
          disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  child: const Text('Open'),
                  onPressed: () async =>
                      result.complete(await showAppSheet<LibraryFilterResult>(
                    context: context,
                    builder: (_) => viewUpdates == null
                        ? sheet(views)
                        : ValueListenableBuilder<List<SavedNoteView>>(
                            valueListenable: viewUpdates,
                            builder: (_, currentViews, __) =>
                                sheet(currentViews),
                          ),
                  )),
                ))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

Finder key(String value) => find.byKey(ValueKey(value));

List<SavedNoteView> _savedViews(int count) => [
      for (var index = 0; index < count; index++)
        SavedNoteView(id: 'view-$index', name: 'View ${index + 1}'),
    ];

Future<void> searchTags(WidgetTester tester, String query) async {
  final field = key('library-search-tags');
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, query);
  await tester.pumpAndSettle();
}

Future<void> searchViews(WidgetTester tester, String query) async {
  final field = key('library-search-saved-views');
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, query);
  await tester.pumpAndSettle();
}

void expectTagCounts(WidgetTester tester, int selected, int hidden) {
  final count = key('library-tags-selected-count');
  final strings = S.of(tester.element(count));
  expect(
      tester.widget<Text>(count).data, strings.Tags_Selected_Count(selected));
  if (hidden == 0) {
    expect(key('library-tags-hidden-count'), findsNothing);
  } else {
    expect(tester.widget<Text>(key('library-tags-hidden-count')).data,
        strings.Tags_Hidden_By_Search_Count(hidden));
  }
  if (selected >= 20) {
    expect(tester.widget<Text>(key('library-tags-selection-limit')).data,
        strings.Tags_Selection_Limit_Reached(20));
  } else {
    expect(key('library-tags-selection-limit'), findsNothing);
  }
}

void main() {
  for (final count in [19, 20]) {
    testWidgets('tag feedback counts all $count selections hidden by search',
        (tester) async {
      final original = {for (var i = 0; i < count; i++) 'Tag $i'};
      final result = await open(tester,
          selectedTags: original, tags: [...original, 'New tag']);
      expectTagCounts(tester, count, 0);
      await searchTags(tester, 'New');
      expectTagCounts(tester, count, count);
      final newTag = key('library-tag-new tag');
      expect(tester.widget<FilterChip>(newTag).onSelected,
          count == 20 ? isNull : isNotNull);
      await tester.ensureVisible(newTag);
      await tester.tap(newTag);
      await tester.pump();
      expectTagCounts(tester, 20, count);

      final clear = key('library-clear-tag-search');
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expectTagCounts(tester, 20, 0);
      final firstTag = key('library-tag-tag 0');
      await tester.ensureVisible(firstTag);
      expect(tester.widget<FilterChip>(firstTag).onSelected, isNotNull);
      await tester.tap(firstTag);
      await tester.pump();
      expectTagCounts(tester, 19, 0);
      await tester.ensureVisible(key('library-apply-filters'));
      await tester.tap(key('library-apply-filters'));
      await tester.pumpAndSettle();
      final selected = (await result.future) as ApplyLibraryFilters;
      expect(selected.tags, hasLength(19));
      expect(selected.tags, isNot(contains('Tag 0')));
      expect(selected.tags.contains('New tag'), count == 19);
      expect(original, hasLength(count));
      expect(original, contains('Tag 0'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('saved-view search matches names literally and preserves order',
      (tester) async {
    final views = [
      SavedNoteView(id: 'z', name: 'Work', query: 'only-search-query'),
      SavedNoteView(id: 'a', name: 'WORK meetings'),
      SavedNoteView(id: 'literal', name: 'C++ [2026]'),
      SavedNoteView(id: 'chinese', name: '項目閱讀與研究'),
      SavedNoteView(id: 'unicode', name: 'Ångström'),
    ];
    final result = await open(tester, views: views, selectedViewId: 'z');
    expect(tester.testTextInput.hasAnyClients, isFalse);
    await searchViews(tester, '  wOrK  ');
    expect(key('saved-view-z'), findsOneWidget);
    expect(key('saved-view-a'), findsOneWidget);
    expect(key('saved-view-literal'), findsNothing);
    expect(tester.getTopLeft(key('saved-view-z')).dy,
        lessThan(tester.getTopLeft(key('saved-view-a')).dy));
    expect(tester.widget<ListTile>(key('saved-view-z')).selected, isTrue);

    for (final (query, id) in [
      ('++', 'literal'),
      ('[2026]', 'literal'),
      ('  研究  ', 'chinese'),
      ('ångström', 'unicode'),
    ]) {
      await searchViews(tester, query);
      expect(key('saved-view-$id'), findsOneWidget);
      expect(key('library-saved-views-search-empty'), findsNothing);
    }
    await searchViews(tester, '.*');
    expect(key('library-saved-views-search-empty'), findsOneWidget);
    expect(key('saved-view-literal'), findsNothing);
    await searchViews(tester, 'only-search-query');
    expect(key('library-saved-views-search-empty'), findsOneWidget);
    expect(key('saved-view-z'), findsNothing);
    expect(result.isCompleted, isFalse);

    final clear = key('library-clear-saved-view-search');
    expect(tester.widget<IconButton>(clear).tooltip, S.current.Clear_Search);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(key('library-saved-views-search-empty'), findsNothing);
    expect(key('library-clear-saved-view-search'), findsNothing);
    for (final view in views) {
      expect(key('saved-view-${view.id}'), findsOneWidget);
    }
    expect(tester.widget<ListTile>(key('saved-view-z')).selected, isTrue);
    expect(views.map((view) => view.id),
        ['z', 'a', 'literal', 'chinese', 'unicode']);
    await searchViews(tester, ' \t ');
    expect(key('library-saved-views-search-empty'), findsNothing);
    expect(key('saved-view-z'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searched saved views retain original apply, rename and delete',
      (tester) async {
    final target = SavedNoteView(
        id: 'literal',
        name: 'C++ [2026]',
        query: 'Keep query',
        filters: {NoteSearchFilter.recordings},
        tags: ['Research'],
        folderId: 'work',
        archiveScope: NoteArchiveScope.all);
    final views = [SavedNoteView(id: 'other', name: 'Other'), target];
    for (final action in ['apply', 'rename', 'delete']) {
      final result = await open(tester, views: views);
      await searchViews(tester, '[2026]');
      final row = key('saved-view-literal');
      expect(key('saved-view-other'), findsNothing);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      if (action == 'apply') {
        await tester.tap(row);
      } else {
        final menu = find.descendant(
            of: row, matching: find.byType(PopupMenuButton<String>));
        await tester.tap(menu);
        await tester.pumpAndSettle();
        final strings = S.of(tester.element(menu));
        await tester.tap(find.text(
            action == 'rename' ? strings.Rename_View : strings.Delete_View));
      }
      await tester.pumpAndSettle();
      final selected = await result.future;
      switch (action) {
        case 'apply':
          expect((selected as ApplySavedNoteView).view, same(target));
        case 'rename':
          expect((selected as RenameSavedNoteView).view, same(target));
        case 'delete':
          expect((selected as DeleteSavedNoteView).view, same(target));
      }
      expect(target.query, 'Keep query');
      expect(target.tags, ['Research']);
      expect(target.filters, {NoteSearchFilter.recordings});
      expect(target.folderId, 'work');
      expect(target.archiveScope, NoteArchiveScope.all);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('all 30 query-hidden views still disable saving', (tester) async {
    final views = _savedViews(30);
    final result = await open(tester, views: views);
    await searchViews(tester, 'missing');
    expect(key('saved-view-view-0'), findsNothing);
    expect(key('library-saved-views-search-empty'), findsOneWidget);
    expect(find.text(S.current.Saved_View_Empty), findsNothing);
    final save = key('library-save-view');
    expect(tester.widget<ListTile>(save).enabled, isFalse);
    expect(tester.widget<ListTile>(save).onTap, isNull);
    expect(key('library-saved-view-limit'), findsOneWidget);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(result.isCompleted, isFalse);
    expect(views, hasLength(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved-view updates retain the query and refresh visible matches',
      (tester) async {
    final target = SavedNoteView(id: 'target', name: 'Work meetings');
    final updates = ValueNotifier([target]);
    addTearDown(updates.dispose);
    await open(tester, viewUpdates: updates, selectedViewId: target.id);
    await searchViews(tester, 'Work');
    expect(key('saved-view-target'), findsOneWidget);
    updates.value = [SavedNoteView(id: 'target', name: 'Personal')];
    await tester.pump();
    expect(key('saved-view-target'), findsNothing);
    expect(key('library-saved-views-search-empty'), findsOneWidget);
    updates.value = [target, SavedNoteView(id: 'new', name: 'Work archive')];
    await tester.pump();
    expect(key('saved-view-target'), findsOneWidget);
    expect(key('saved-view-new'), findsOneWidget);
    expect(tester.widget<ListTile>(key('saved-view-target')).selected, isTrue);
    expect(
        tester
            .widget<TextField>(key('library-search-saved-views'))
            .controller!
            .text,
        'Work');
    updates.value = [];
    await tester.pump();
    expect(key('library-search-saved-views'), findsNothing);
    expect(key('library-saved-views-search-empty'), findsNothing);
    expect(find.text(S.current.Saved_View_Empty), findsOneWidget);
    updates.value = [target];
    await tester.pump();
    expect(key('saved-view-target'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(key('library-search-saved-views'))
            .controller!
            .text,
        'Work');
    expect(tester.takeException(), isNull);
  });

  for (final saveView in [false, true]) {
    testWidgets(
        'view search leaves ${saveView ? 'Save' : 'Done'} criteria intact',
        (tester) async {
      final result = await open(tester,
          views: [SavedNoteView(id: 'view', name: 'Reference')],
          selectedTags: {'Work'},
          tags: ['Work', 'Personal'],
          filters: {NoteSearchFilter.scans},
          scope: NoteArchiveScope.all);
      await searchTags(tester, 'Personal');
      expectTagCounts(tester, 1, 1);
      await searchViews(tester, 'missing');
      final action =
          key(saveView ? 'library-save-view' : 'library-apply-filters');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      final selected = (await result.future) as ApplyLibraryFilters;
      expect(selected.tags, {'Work'});
      expect(selected.filters, {NoteSearchFilter.scans});
      expect(selected.scope, NoteArchiveScope.all);
      expect(
          selected,
          saveView
              ? isA<CreateSavedNoteView>()
              : isNot(isA<CreateSavedNoteView>()));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('clear criteria resets tag feedback but retains view name search',
      (tester) async {
    final result = await open(tester,
        views: [SavedNoteView(id: 'view', name: 'Reference')],
        selectedTags: {'Work'},
        tags: ['Work'],
        filters: {NoteSearchFilter.scans},
        scope: NoteArchiveScope.all);
    await searchTags(tester, 'missing');
    await searchViews(tester, 'missing');
    await tester.ensureVisible(key('library-clear-filters'));
    await tester.tap(key('library-clear-filters'));
    await tester.pumpAndSettle();
    expectTagCounts(tester, 0, 0);
    expect(
        tester.widget<TextField>(key('library-search-tags')).controller!.text,
        isEmpty);
    expect(
        tester
            .widget<TextField>(key('library-search-saved-views'))
            .controller!
            .text,
        'missing');
    expect(key('library-saved-views-search-empty'), findsOneWidget);
    await tester.ensureVisible(key('library-apply-filters'));
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    final selected = (await result.future) as ApplyLibraryFilters;
    expect(selected.tags, isEmpty);
    expect(selected.filters, isEmpty);
    expect(selected.scope, NoteArchiveScope.active);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing both searches discards edits and reopens empty searches',
      (tester) async {
    final originalTags = {'Work'};
    final views = [SavedNoteView(id: 'view', name: 'Reference')];
    final result = await open(tester,
        views: views, selectedTags: originalTags, tags: ['Work', 'Personal']);
    await searchTags(tester, 'Personal');
    await tester.ensureVisible(key('library-tag-personal'));
    await tester.tap(key('library-tag-personal'));
    await tester.pump();
    await searchViews(tester, 'missing');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await result.future, isNull);
    expect(originalTags, {'Work'});
    expect(views, hasLength(1));
    await open(tester,
        views: views, selectedTags: originalTags, tags: ['Work', 'Personal']);
    expectTagCounts(tester, 1, 0);
    for (final field in ['library-search-tags', 'library-search-saved-views']) {
      expect(tester.widget<TextField>(key(field)).controller!.text, isEmpty);
    }
    expect(key('saved-view-view'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty, unavailable and Trash preserve their search distinctions',
      (tester) async {
    final empty = await open(tester);
    expect(key('library-search-saved-views'), findsNothing);
    expect(key('library-saved-views-search-empty'), findsNothing);
    expect(find.text(S.current.Saved_View_Empty), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await empty.future, isNull);

    final views = [SavedNoteView(id: 'view', name: 'Reference')];
    final unavailable = await open(tester, views: views, unavailable: true);
    expect(key('library-search-saved-views'), findsNothing);
    expect(key('library-saved-views-search-empty'), findsNothing);
    expect(find.text(S.current.Saved_View_Failed), findsOneWidget);
    expect(key('library-save-view'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await unavailable.future, isNull);

    final trash = await open(tester, views: views, trash: true);
    expect(key('library-search-saved-views'), findsOneWidget);
    await searchViews(tester, 'reference');
    expect(key('saved-view-view'), findsOneWidget);
    expect(key('library-save-view'), findsNothing);
    await tester.ensureVisible(key('saved-view-view'));
    await tester.tap(key('saved-view-view'));
    await tester.pumpAndSettle();
    expect((await trash.future as ApplySavedNoteView).view, same(views.single));
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK')
  ]) {
    testWidgets('both library searches and tag counts fit narrow 2× $locale',
        (tester) async {
      tester.view.physicalSize = const Size(280, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester,
          selectedTags: {'Work'},
          tags: ['Work', 'Personal'],
          views: [SavedNoteView(id: 'view', name: '項目研究與會議記錄')],
          locale: locale,
          textScale: 2);
      await searchTags(tester, 'Personal');
      expectTagCounts(tester, 1, 1);
      await searchViews(tester, '[.*');
      final empty = key('library-saved-views-search-empty');
      await tester.ensureVisible(empty);
      await tester.pumpAndSettle();
      final strings = S.of(tester.element(empty));
      expect(tester.widget<Text>(empty).data, strings.Saved_Views_Search_Empty);
      final field = key('library-search-saved-views');
      expect(tester.widget<TextField>(field).decoration!.labelText,
          strings.Search_Saved_Views);
      final clear = key('library-clear-saved-view-search');
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      expect(tester.getSize(clear).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(key('saved-view-view'), findsOneWidget);
      expectTagCounts(tester, 1, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('29 saved views still allows saving the current criteria',
      (tester) async {
    final views = _savedViews(29);
    final result = await open(tester,
        views: views,
        filters: {NoteSearchFilter.unfinished},
        selectedTags: {'Work'},
        tags: ['Work'],
        scope: NoteArchiveScope.all);
    final save = key('library-save-view');
    expect(key('library-saved-view-limit'), findsNothing);
    expect(tester.widget<ListTile>(save).enabled, isTrue);
    expect(tester.widget<ListTile>(save).onTap, isNotNull);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    final selected = (await result.future) as CreateSavedNoteView;
    expect(selected.filters, {NoteSearchFilter.unfinished});
    expect(selected.tags, {'Work'});
    expect(selected.scope, NoteArchiveScope.all);
    expect(views, hasLength(29));
    expect(tester.takeException(), isNull);
  });

  for (final count in [30, 31]) {
    testWidgets('$count saved views blocks creation but still applies filters',
        (tester) async {
      final views = _savedViews(count);
      final result = await open(tester,
          views: views,
          filters: {NoteSearchFilter.recordings},
          selectedTags: {'Work'},
          tags: ['Work']);
      final save = key('library-save-view');
      final strings = S.of(tester.element(save));
      expect(find.text(strings.Saved_View_Limit_Reached(30)), findsOneWidget);
      expect(tester.widget<ListTile>(save).enabled, isFalse);
      expect(tester.widget<ListTile>(save).onTap, isNull);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result.isCompleted, isFalse);
      expect(find.byType(LibraryFiltersSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      final photoFilter = key('library-filter-photos');
      await tester.ensureVisible(photoFilter);
      await tester.pumpAndSettle();
      await tester.tap(photoFilter);
      await tester.pump();
      await tester.ensureVisible(key('library-apply-filters'));
      await tester.tap(key('library-apply-filters'));
      await tester.pumpAndSettle();
      final selected = (await result.future) as ApplyLibraryFilters;
      expect(selected, isNot(isA<CreateSavedNoteView>()));
      expect(selected.filters,
          {NoteSearchFilter.recordings, NoteSearchFilter.photos});
      expect(selected.tags, {'Work'});
      expect(views, hasLength(count));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('applying, renaming and deleting remain available at capacity',
      (tester) async {
    final views = _savedViews(30);
    for (final action in ['apply', 'rename', 'delete']) {
      final result = await open(tester, views: views);
      expect(tester.widget<ListTile>(key('library-save-view')).onTap, isNull);
      final viewTile = key('saved-view-view-0');
      await tester.ensureVisible(viewTile);
      await tester.pumpAndSettle();
      if (action == 'apply') {
        await tester.tap(viewTile);
      } else {
        final menu = find.descendant(
            of: viewTile, matching: find.byType(PopupMenuButton<String>));
        await tester.tap(menu);
        await tester.pumpAndSettle();
        final strings = S.of(tester.element(menu));
        await tester.tap(find.text(
            action == 'rename' ? strings.Rename_View : strings.Delete_View));
      }
      await tester.pumpAndSettle();
      final selected = await result.future;
      switch (action) {
        case 'apply':
          expect((selected as ApplySavedNoteView).view, same(views.first));
        case 'rename':
          expect((selected as RenameSavedNoteView).view, same(views.first));
        case 'delete':
          expect((selected as DeleteSavedNoteView).view, same(views.first));
      }
      expect(views, hasLength(30));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('updated saved-view props refresh the limit without losing edits',
      (tester) async {
    final updates = ValueNotifier(_savedViews(29));
    addTearDown(updates.dispose);
    final result = await open(tester, viewUpdates: updates);
    await tester.tap(key('library-filter-scans'));
    await tester.pump();
    expect(tester.widget<FilterChip>(key('library-filter-scans')).selected,
        isTrue);
    expect(tester.widget<ListTile>(key('library-save-view')).onTap, isNotNull);

    updates.value = _savedViews(30);
    await tester.pump();
    final save = key('library-save-view');
    expect(tester.widget<ListTile>(save).onTap, isNull);
    expect(key('library-saved-view-limit'), findsOneWidget);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump();
    expect(result.isCompleted, isFalse);

    updates.value = _savedViews(29);
    await tester.pump();
    expect(tester.widget<ListTile>(save).onTap, isNotNull);
    expect(key('library-saved-view-limit'), findsNothing);
    expect(tester.widget<FilterChip>(key('library-filter-scans')).selected,
        isTrue);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(((await result.future) as CreateSavedNoteView).filters,
        {NoteSearchFilter.scans});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trash and unavailable views retain distinct feedback',
      (tester) async {
    final views = _savedViews(30);
    final trashResult = await open(tester, views: views, trash: true);
    expect(key('library-save-view'), findsNothing);
    expect(key('library-saved-view-limit'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await trashResult.future, isNull);

    await open(tester, views: views, unavailable: true);
    expect(key('library-save-view'), findsNothing);
    expect(key('library-saved-view-limit'), findsNothing);
    final strings = S.of(tester.element(find.byType(LibraryFiltersSheet)));
    expect(find.text(strings.Saved_View_Failed), findsOneWidget);
    expect(find.text(strings.Saved_View_Empty), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('saved-view limit fits narrow 2× text in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(280, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final result = await open(tester,
          views: _savedViews(30), locale: locale, textScale: 2);
      final save = key('library-save-view');
      final message = key('library-saved-view-limit');
      await tester.ensureVisible(message);
      await tester.pumpAndSettle();
      final strings = S.of(tester.element(message));
      expect(tester.widget<Text>(message).data,
          strings.Saved_View_Limit_Reached(30));
      expect(tester.widget<Text>(message).maxLines, isNull);
      expect(tester.widget<ListTile>(save).enabled, isFalse);
      await tester.tap(save);
      await tester.pump();
      expect(result.isCompleted, isFalse);
      await tester.ensureVisible(key('library-apply-filters'));
      await tester.pumpAndSettle();
      await tester.tap(key('library-apply-filters'));
      await tester.pumpAndSettle();
      expect(await result.future, isA<ApplyLibraryFilters>());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tag search is local, literal, normalized and case insensitive',
      (tester) async {
    final result = await open(tester,
        tags: ['Work', ' WORK ', 'Work  Meetings', 'Personal', '項目研究', 'C++']);
    expect(key('library-search-tags'), findsOneWidget);
    expect(tester.testTextInput.hasAnyClients, isFalse);
    expect(key('library-tag-work'), findsOneWidget);

    await searchTags(tester, '  wOrK  ');
    expect(key('library-tag-work'), findsOneWidget);
    expect(key('library-tag-work meetings'), findsOneWidget);
    expect(key('library-tag-personal'), findsNothing);
    expect(key('library-tag-項目研究'), findsNothing);
    expect(result.isCompleted, isFalse);

    await searchTags(tester, 'WORK \t MEET');
    expect(key('library-tag-work'), findsNothing);
    expect(key('library-tag-work meetings'), findsOneWidget);

    await searchTags(tester, '研究');
    expect(key('library-tag-項目研究'), findsOneWidget);
    expect(key('library-tag-work meetings'), findsNothing);

    await searchTags(tester, '++');
    expect(key('library-tag-c++'), findsOneWidget);
    expect(key('library-tags-search-empty'), findsNothing);

    await searchTags(tester, '[.*');
    final strings = S.of(tester.element(key('library-search-tags')));
    expect(find.text(strings.Tags_Search_Empty), findsOneWidget);
    expect(key('library-tag-c++'), findsNothing);
    expect(key('library-filter-photos'), findsOneWidget);
    expect(key('library-include-archived'), findsOneWidget);
    expect(key('library-save-view'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await searchTags(tester, '  \t ');
    expect(key('library-tags-search-empty'), findsNothing);
    expect(key('library-tag-work'), findsOneWidget);
    expect(key('library-tag-personal'), findsOneWidget);
  });

  testWidgets('empty tag catalog omits the search field', (tester) async {
    await open(tester);
    expect(key('library-search-tags'), findsNothing);
    expect(key('library-clear-tag-search'), findsNothing);
    expect(key('library-tags-search-empty'), findsNothing);
  });

  for (final saveView in [false, true]) {
    testWidgets(
        '${saveView ? 'Save view' : 'Done'} retains hidden selected tags',
        (tester) async {
      final original = {'Work'};
      final result = await open(tester,
          selectedTags: original,
          tags: ['Work', 'Personal'],
          filters: {NoteSearchFilter.recordings});
      await searchTags(tester, 'Personal');
      expect(key('library-tag-work'), findsNothing);
      await tester.tap(key('library-tag-personal'));
      await tester.pump();
      expect(tester.widget<FilterChip>(key('library-tag-personal')).selected,
          isTrue);
      expect(original, {'Work'});
      expect(result.isCompleted, isFalse);
      final action =
          key(saveView ? 'library-save-view' : 'library-apply-filters');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      final selection = (await result.future) as ApplyLibraryFilters;
      expect(selection.tags, {'Work', 'Personal'});
      expect(selection.filters, {NoteSearchFilter.recordings});
      expect(selection,
          saveView ? isA<CreateSavedNoteView>() : isA<ApplyLibraryFilters>());
      expect(original, {'Work'});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('clear search restores selected tags without clearing filters',
      (tester) async {
    final result = await open(tester,
        selectedTags: {'Work'},
        tags: ['Work', 'Personal'],
        filters: {NoteSearchFilter.scans},
        scope: NoteArchiveScope.all);
    await searchTags(tester, 'missing');
    expect(key('library-tags-search-empty'), findsOneWidget);
    final clear = key('library-clear-tag-search');
    final strings = S.of(tester.element(clear));
    expect(find.byTooltip(strings.Clear_Search), findsOneWidget);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(key('library-search-tags')).controller!.text,
        isEmpty);
    expect(key('library-clear-tag-search'), findsNothing);
    expect(key('library-tags-search-empty'), findsNothing);
    expect(tester.widget<FilterChip>(key('library-tag-work')).selected, isTrue);
    expect(tester.widget<FilterChip>(key('library-tag-personal')).selected,
        isFalse);
    await tester.ensureVisible(key('library-apply-filters'));
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    final selected = (await result.future) as ApplyLibraryFilters;
    expect(selected.tags, {'Work'});
    expect(selected.filters, {NoteSearchFilter.scans});
    expect(selected.scope, NoteArchiveScope.all);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden selected tags count toward the limit and can be removed',
      (tester) async {
    final selectedTags = {
      for (var index = 0; index < 20; index++) 'Tag $index',
    };
    final result = await open(tester,
        selectedTags: selectedTags, tags: [...selectedTags, 'New tag']);
    await searchTags(tester, 'New');
    final newTag = key('library-tag-new tag');
    expect(tester.widget<FilterChip>(newTag).onSelected, isNull);
    await tester.tap(newTag);
    await tester.pump();
    expect(tester.widget<FilterChip>(newTag).selected, isFalse);

    await searchTags(tester, 'Tag 0');
    final selectedTag = key('library-tag-tag 0');
    expect(tester.widget<FilterChip>(selectedTag).selected, isTrue);
    expect(tester.widget<FilterChip>(selectedTag).onSelected, isNotNull);
    await tester.tap(selectedTag);
    await tester.pump();
    await searchTags(tester, 'New');
    expect(tester.widget<FilterChip>(newTag).onSelected, isNotNull);
    await tester.tap(newTag);
    await tester.pump();
    await tester.ensureVisible(key('library-apply-filters'));
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    final selected = (await result.future) as ApplyLibraryFilters;
    expect(selected.tags.length, 20);
    expect(selected.tags, contains('New tag'));
    expect(selected.tags, isNot(contains('Tag 0')));
    expect(selectedTags.length, 20);
    expect(selectedTags, contains('Tag 0'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('clear filters resets the query and all hidden tag selections',
      (tester) async {
    final result = await open(tester,
        selectedTags: {'Work', 'Personal'},
        tags: ['Work', 'Personal'],
        filters: {NoteSearchFilter.recordings},
        scope: NoteArchiveScope.all);
    await searchTags(tester, 'nothing');
    await tester.ensureVisible(key('library-clear-filters'));
    await tester.tap(key('library-clear-filters'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(key('library-search-tags')).controller!.text,
        isEmpty);
    expect(key('library-tags-search-empty'), findsNothing);
    for (final tag in ['work', 'personal']) {
      expect(
          tester.widget<FilterChip>(key('library-tag-$tag')).selected, isFalse);
    }
    await tester.ensureVisible(key('library-apply-filters'));
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    final selected = (await result.future) as ApplyLibraryFilters;
    expect(selected.tags, isEmpty);
    expect(selected.filters, isEmpty);
    expect(selected.scope, NoteArchiveScope.active);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid tag selections cannot pass the limit before a rebuild',
      (tester) async {
    final original = {
      for (var index = 0; index < 19; index++) 'Tag $index',
    };
    final result = await open(tester,
        selectedTags: original,
        tags: [...original, 'Candidate A', 'Candidate B']);
    await searchTags(tester, 'Candidate');
    await tester.tap(key('library-tag-candidate a'));
    await tester.tap(key('library-tag-candidate b'));
    await tester.pump();
    expect(tester.widget<FilterChip>(key('library-tag-candidate a')).selected,
        isTrue);
    expect(tester.widget<FilterChip>(key('library-tag-candidate b')).selected,
        isFalse);
    await tester.ensureVisible(key('library-apply-filters'));
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    final selected = (await result.future) as ApplyLibraryFilters;
    expect(selected.tags.length, 20);
    expect(selected.tags, contains('Candidate A'));
    expect(selected.tags, isNot(contains('Candidate B')));
    expect(original.length, 19);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'closing with a focused search discards selection and disposes it',
      (tester) async {
    final original = {'Work'};
    final result =
        await open(tester, selectedTags: original, tags: ['Work', 'Personal']);
    await searchTags(tester, 'Personal');
    await tester.tap(key('library-tag-personal'));
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await result.future, isNull);
    expect(original, {'Work'});
    expect(tester.takeException(), isNull);

    await open(tester, selectedTags: original, tags: ['Work', 'Personal']);
    expect(
        tester.widget<TextField>(key('library-search-tags')).controller!.text,
        isEmpty);
    expect(tester.widget<FilterChip>(key('library-tag-work')).selected, isTrue);
    expect(tester.widget<FilterChip>(key('library-tag-personal')).selected,
        isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets(
        'tag search fits narrow 2× text and preserves controls in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(280, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await open(tester,
            tags: ['個人工作計劃' * 6, 'Work', 'Personal'],
            locale: locale,
            textScale: 2);
        await searchTags(tester, 'missing');
        final field = key('library-search-tags');
        final strings = S.of(tester.element(field));
        expect(tester.widget<TextField>(field).decoration!.labelText,
            strings.Search_Tags);
        expect(key('library-tags-search-empty'), findsOneWidget);
        final clear = key('library-clear-tag-search');
        await tester.ensureVisible(clear);
        await tester.pumpAndSettle();
        expect(tester.getSize(clear).height, greaterThanOrEqualTo(48));
        expect(find.byTooltip(strings.Clear_Search), findsOneWidget);
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(key('library-tag-work'), findsOneWidget);
        await tester.ensureVisible(key('library-save-view'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('landscape keyboard leaves search and Done reachable',
      (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final result = await open(tester,
        tags: ['Work', 'Personal', '會議'], keyboardInset: 140);
    await searchTags(tester, 'work');
    expect(key('library-tag-work'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.ensureVisible(key('library-tag-work'));
    await tester.pumpAndSettle();
    await tester.tap(key('library-tag-work'));
    await tester.pump();
    await tester.ensureVisible(key('library-apply-filters'));
    await tester.pumpAndSettle();
    await tester.tap(key('library-apply-filters'));
    await tester.pumpAndSettle();
    expect(((await result.future) as ApplyLibraryFilters).tags, {'Work'});
    expect(tester.takeException(), isNull);
  });

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
    final done = key('library-apply-filters');
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done.hitTestable());
    await tester.pumpAndSettle();
    expect(result.isCompleted, isTrue);
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
