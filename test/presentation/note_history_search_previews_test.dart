import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_history_search_previews.dart';
import 'package:onlynote/presentation/components/note_history_version_tile.dart';
import 'package:onlynote/presentation/components/search_result_summary.dart';

import '../support/search_highlight_text.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('history-search-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-history-search-$name.png')
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
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final (name, preview, size, locale, brightness) in [
    (
      'light',
      noteHistorySearchLightPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.light,
    ),
    (
      'dark',
      noteHistorySearchDarkPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.dark,
    ),
    (
      'chinese',
      noteHistorySearchChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light,
    ),
  ]) {
    testWidgets('$name history search preview filters, selects, and clears',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('history-search-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('history-search'));
      expect(Localizations.localeOf(tester.element(field)), locale);
      expect(Theme.of(tester.element(field)).brightness, brightness);
      expect(find.byType(NoteHistoryVersionTile), findsNWidgets(2));
      final count = find.byKey(const ValueKey('history-search-count'));
      expect(count, findsNothing);
      await tester.enterText(field, '茶😀');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(NoteHistoryVersionTile), findsOneWidget);
      final matchingRow =
          find.byKey(const ValueKey('history-search-version-review'));
      expect(
          tester.widget<NoteHistoryVersionTile>(matchingRow).snippet, '…茶😀');
      expect(tester.widget<NoteHistoryVersionTile>(matchingRow).title,
          'Release review [draft]');
      expect(highlightedSearchText(tester, matchingRow), ['茶😀']);
      expect(tester.widget<SearchResultSummary>(count).label,
          S.current.History_Search_Count(1, 2));
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        final data = tester
            .getSemantics(
                find.descendant(of: count, matching: find.byType(Semantics)))
            .getSemanticsData();
        expect(data.label, S.current.History_Search_Count(1, 2));
        expect(data.flagsCollection.isLiveRegion, isTrue);
      } finally {
        semantics.dispose();
      }
      await _capture(tester, '$name-match');
      await tester.enterText(field, '[DRAFT]');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(NoteHistoryVersionTile), findsOneWidget);
      expect(highlightedSearchText(tester, matchingRow), ['[draft]']);
      await _capture(tester, name);
      final row = find.byKey(const ValueKey('history-search-version-review'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsNWidgets(2));
      expect(count, findsNothing);
      final back = find.byKey(const ValueKey('history-search-preview-back'));
      await tester.ensureVisible(back);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '[DRAFT]');
      expect(find.byType(NoteHistoryVersionTile), findsOneWidget);
      expect(tester.widget<SearchResultSummary>(count).label,
          S.current.History_Search_Count(1, 2));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'missing');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text(S.current.History_Search_Empty), findsOneWidget);
      expect(tester.widget<SearchResultSummary>(count).label,
          S.current.History_Search_Count(0, 2));
      await _capture(tester, '$name-empty');
      final clear = find.byKey(const ValueKey('history-search-reset'));
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.byType(NoteHistoryVersionTile), findsNWidgets(2));
      expect(count, findsNothing);
      expect(highlightedSearchText(tester, find.byType(NoteHistoryVersionTile)),
          isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
