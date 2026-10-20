import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/library_search_feedback_previews.dart';
import 'package:onlynote/presentation/components/library_tag_selection_feedback.dart';
import 'package:onlynote/presentation/components/saved_view_name_search.dart';

class _NamedView {
  const _NamedView(this.id, this.name, {this.fields = const []});
  final String id;
  final String name;
  final List<String> fields;
}

Finder _key(String value) => find.byKey(ValueKey(value));

Widget _host(Widget child) => MaterialApp(
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      _key('library-search-feedback-capture'));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-release-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  test('saved-view name matching is literal and retains original objects', () {
    final views = [
      const _NamedView('z', 'Work'),
      const _NamedView('a', 'WORK meetings'),
      const _NamedView('symbol', 'C++ [2026]'),
      const _NamedView('unicode', 'Ångström'),
      const _NamedView('chinese', '項目閱讀與研究'),
    ];
    List<_NamedView> matches(String query) =>
        filterSavedViewNames(views, query, nameOf: (view) => view.name);
    for (final query in ['', ' \t ', '\u3000']) {
      expect(matches(query), orderedEquals(views));
    }
    final work = matches('  wOrK  ');
    expect(work.map((view) => view.id), ['z', 'a']);
    expect(work.first, same(views.first));
    expect(work.last, same(views[1]));
    expect(matches('++').single, same(views[2]));
    expect(matches('[2026]').single, same(views[2]));
    expect(matches('.*'), isEmpty);
    expect(matches('ångström').single, same(views[3]));
    expect(matches('  研究  ').single, same(views[4]));
    expect(views.map((view) => view.id),
        ['z', 'a', 'symbol', 'unicode', 'chinese']);
  });

  test('additional saved-view fields opt in without joining unrelated text',
      () {
    final views = [
      const _NamedView('first', 'Planning',
          fields: ['C++ [2026]', 'North', 'South']),
      const _NamedView('second', 'C++ [2026]', fields: ['Ångström', '項目研究']),
      const _NamedView('third', 'Reference', fields: ['C++ [2026]']),
    ];
    List<_NamedView> matches(String query, {bool includeFields = true}) =>
        filterSavedViewNames(views, query,
            nameOf: (view) => view.name,
            additionalSearchText: includeFields ? (view) => view.fields : null);
    expect(matches('C++', includeFields: false), [same(views[1])]);
    expect(
        matches(' [2026] '), [same(views[0]), same(views[1]), same(views[2])]);
    expect(matches('.*'), isEmpty);
    expect(matches('ångström'), [same(views[1])]);
    expect(matches('研究'), [same(views[1])]);
    expect(matches('Planning C++'), isEmpty);
    expect(matches('North South'), isEmpty);
    expect(matches('missing'), isEmpty);
    expect(matches(' \t '), orderedEquals(views));
    expect(
        filterSavedViewNames(views, ' ',
            nameOf: (_) => throw StateError('Blank searches need no names'),
            additionalSearchText: (_) =>
                throw StateError('Blank searches need no fields')),
        orderedEquals(views));
  });

  for (final (selected, hidden) in [(0, 0), (1, 1), (19, 19), (20, 20)]) {
    testWidgets('tag feedback explains $selected selected and $hidden hidden',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(LibraryTagSelectionFeedback(
          selectedCount: selected,
          hiddenSelectedCount: hidden,
          maxTags: 20,
        )));
        await tester.pumpAndSettle();
        expect(
            find.text(S.current.Tags_Selected_Count(selected)), findsOneWidget);
        expect(_key('library-tags-hidden-count'),
            hidden > 0 ? findsOneWidget : findsNothing);
        if (hidden > 0) {
          expect(find.text(S.current.Tags_Hidden_By_Search_Count(hidden)),
              findsOneWidget);
        }
        expect(_key('library-tags-selection-limit'),
            selected >= 20 ? findsOneWidget : findsNothing);
        expect(
            tester
                .getSemantics(_key('library-tags-selected-count'))
                .getSemanticsData()
                .flagsCollection
                .isLiveRegion,
            isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('pure library previews show counts, limits, matches and recovery',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, preview, size) in [
      (
        'library-search-light',
        librarySearchFeedbackLightPreview,
        const Size(390, 700)
      ),
      (
        'library-search-dark',
        librarySearchFeedbackDarkPreview,
        const Size(390, 700)
      ),
      (
        'library-search-large-en',
        librarySearchFeedbackLargeTextPreview,
        const Size(280, 700)
      ),
      (
        'library-search-zh',
        librarySearchFeedbackChinesePreview,
        const Size(280, 700)
      ),
      (
        'library-search-hk',
        librarySearchFeedbackHongKongPreview,
        const Size(280, 700)
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('library-search-feedback-capture'),
        child: KeyedSubtree(key: ValueKey(name), child: preview()),
      ));
      await tester.pumpAndSettle();
      final selected = _key('library-tags-selected-count');
      await tester.ensureVisible(_key('library-tags-selection-limit'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(selected).data,
          S.current.Tags_Selected_Count(20));
      expect(tester.widget<Text>(_key('library-tags-hidden-count')).data,
          S.current.Tags_Hidden_By_Search_Count(20));
      expect(tester.widget<FilterChip>(_key('preview-tag-c++')).onSelected,
          isNull);
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-tags');

      final viewSearch = _key('library-search-saved-views');
      await tester.ensureVisible(viewSearch);
      await tester.pumpAndSettle();
      await tester.enterText(viewSearch, 'C++');
      await tester.pumpAndSettle();
      final match = _key('preview-saved-view-literal');
      await tester.ensureVisible(match);
      await tester.pumpAndSettle();
      expect(match, findsOneWidget);
      expect(_key('preview-saved-view-work'), findsNothing);
      expect(_key('library-saved-views-search-empty'), findsNothing);
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-views-match');

      await tester.ensureVisible(viewSearch);
      await tester.enterText(viewSearch, S.current.Include_Archived);
      await tester.pumpAndSettle();
      final criteriaMatch = _key('preview-saved-view-meetings');
      expect(criteriaMatch, findsOneWidget);
      expect(_key('preview-saved-view-literal'), findsNothing);
      expect(_key('preview-saved-view-work'), findsNothing);
      await tester.ensureVisible(criteriaMatch);
      await tester.pumpAndSettle();
      expect(find.descendant(of: criteriaMatch, matching: find.byType(Text)),
          findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-views-criteria');

      await tester.ensureVisible(viewSearch);
      await tester.enterText(viewSearch, 'missing');
      await tester.pumpAndSettle();
      final empty = _key('library-saved-views-search-empty');
      await tester.ensureVisible(empty);
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(empty).data, S.current.Saved_Views_Search_Empty);
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-views-empty');

      final clear = _key('library-clear-saved-view-search');
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      expect(tester.getSize(clear).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(_key('library-saved-views-search-empty'), findsNothing);
      expect(tester.widget<ListTile>(_key('preview-saved-view-work')).selected,
          isTrue);

      final tagClear = _key('preview-clear-tag-search');
      await tester.ensureVisible(tagClear);
      await tester.pumpAndSettle();
      await tester.tap(tagClear);
      await tester.pumpAndSettle();
      expect(_key('library-tags-hidden-count'), findsNothing);
      final tag = _key('preview-tag-work 1');
      await tester.ensureVisible(tag);
      await tester.pumpAndSettle();
      await tester.tap(tag);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(selected).data,
          S.current.Tags_Selected_Count(19));
      expect(_key('library-tags-selection-limit'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
