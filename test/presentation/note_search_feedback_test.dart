import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/library_previews.dart';
import 'package:onlynote/presentation/components/note_checklist_previews.dart';
import 'package:onlynote/presentation/components/note_info_previews.dart';
import 'package:onlynote/presentation/components/note_search_feedback.dart';
import 'package:onlynote/presentation/components/note_search_feedback_previews.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('feedback-capture')),
  );
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
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final font = FontLoader('Roboto');
      font.addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
      await font.load();
      final fallback = FontLoader('DroidSansFallback');
      fallback.addFont(rootBundle.load('assets/fonts/DroidSansFallback.ttf'));
      await fallback.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  testWidgets('recovery actions wrap, remain accessible and work in previews',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final (name, preview, size) in [
        ('search-light', searchRecoveryLightPreview, const Size(375, 500)),
        ('search-dark', searchRecoveryDarkPreview, const Size(390, 500)),
        ('search-chinese', searchRecoveryChinesePreview, const Size(280, 500)),
        ('search-landscape', searchRecoveryLightPreview, const Size(640, 280)),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('feedback-capture'),
          child: KeyedSubtree(key: ValueKey(name), child: preview()),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(NoteSearchRecovery), findsOneWidget);
        for (final key in ['home-clear-search', 'home-clear-filters']) {
          final button = find.byKey(ValueKey(key));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        expect(find.bySemanticsLabel(S.current.Clear_Search), findsOneWidget);
        expect(find.bySemanticsLabel(S.current.Clear_Filters), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, name);

        await tester.tap(find.byKey(const ValueKey('home-clear-search')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('home-clear-search')), findsNothing);
        expect(
            find.byKey(const ValueKey('home-clear-filters')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('home-clear-filters')));
        await tester.pumpAndSettle();
        expect(find.byType(NoteSearchRecovery), findsNothing);
        expect(find.text(S.current.Search_Results_Count(3)), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('attachment statistics render in light, dark and large Chinese',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final (name, preview, size) in [
      ('info-light', noteInfoLightPreview, const Size(390, 620)),
      ('info-dark', noteInfoDarkPreview, const Size(390, 620)),
      ('info-chinese', noteInfoChinesePreview, const Size(280, 700)),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('feedback-capture'),
        child: KeyedSubtree(key: ValueKey(name), child: preview()),
      ));
      await tester.pumpAndSettle();
      await _capture(tester, '$name-top');
      await tester.ensureVisible(
          find.byKey(const ValueKey('note-info-recording-duration-value')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
    }
  });

  testWidgets('new checklist and library previews remain usable when narrow',
      (tester) async {
    final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
            fontFamily: 'Roboto',
            fontFamilyFallback: const ['DroidSansFallback'],
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          );
    }
    addTearDown(() => kAppFontFamilies.addAll(fonts));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, preview, size, action) in [
      (
        'copy-light',
        checklistCopyPreview,
        const Size(390, 700),
        'checklist-copy-unfinished'
      ),
      (
        'copy-dark',
        checklistCopyDarkPreview,
        const Size(390, 700),
        'checklist-copy-unfinished'
      ),
      (
        'copy-chinese',
        checklistCopyChinesePreview,
        const Size(280, 700),
        'checklist-copy-unfinished'
      ),
      (
        'library-light',
        libraryFiltersPreview,
        const Size(390, 700),
        'library-filter-scans'
      ),
      (
        'library-chinese',
        libraryFiltersLargeChinesePreview,
        const Size(320, 700),
        'library-filter-recordings'
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('feedback-capture'),
        child: KeyedSubtree(key: ValueKey(name), child: preview()),
      ));
      await tester.pumpAndSettle();
      final button = find.byKey(ValueKey(action));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      if (name.startsWith('copy')) {
        expect(find.text(S.current.Checklist_Copy_Success(2)), findsOneWidget);
      } else {
        final viewId = name == 'library-light' ? 'follow-ups' : 'research';
        final description =
            find.byKey(ValueKey('saved-view-$viewId-description'));
        await tester.ensureVisible(description);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, '$name-views');
      }
    }
  });
}
