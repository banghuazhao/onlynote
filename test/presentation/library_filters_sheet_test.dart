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

  testWidgets('large Chinese text and long tags remain scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester,
        tags: ['個人工作計劃' * 6],
        views: [SavedNoteView(id: 'long', name: '本週重要項目及未完成工作清單')],
        locale: const Locale('zh'),
        textScale: 2);
    await tester.ensureVisible(key('library-save-view'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
