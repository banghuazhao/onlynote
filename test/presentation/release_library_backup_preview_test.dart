import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/presentation/components/backup_restore_previews.dart';
import 'package:onlynote/presentation/components/library_previews.dart';
import 'package:onlynote/presentation/components/note_active_criteria_previews.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('release-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-library-backup');
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
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  setUp(() {
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
  });

  testWidgets('restore preview scrolls at large Chinese text', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, preview, size) in [
      ('backup-light', backupRestoreLightPreview, const Size(390, 700)),
      ('backup-dark', backupRestoreDarkPreview, const Size(390, 700)),
      ('backup-chinese', backupRestoreChinesePreview, const Size(280, 700)),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('release-capture'),
        child: KeyedSubtree(key: ValueKey(name), child: preview()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-top');
      await tester.ensureVisible(
          find.byKey(const ValueKey('backup-preview-history-versions-value')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
    }
  });

  testWidgets('selected criteria remain removable across preview sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, preview, size) in [
      ('criteria-light', activeCriteriaLightPreview, const Size(390, 340)),
      ('criteria-dark', activeCriteriaDarkPreview, const Size(390, 340)),
      ('criteria-chinese', activeCriteriaChinesePreview, const Size(180, 340)),
      (
        'criteria-landscape',
        activeCriteriaChineseLandscapePreview,
        const Size(568, 180)
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('release-capture'),
        child: KeyedSubtree(key: ValueKey(name), child: preview()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      final chip = find.byKey(const ValueKey('active-filter-unfinished'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      tester.widget<InputChip>(chip).onDeleted!();
      await tester.pumpAndSettle();
      expect(chip, findsNothing);
      final archive =
          find.byKey(const ValueKey('active-scope-include-archived'));
      await tester.ensureVisible(archive);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-tags');
    }
  });

  testWidgets('tag search and clear search work in localized previews',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (name, preview, size) in [
      ('tags-light', libraryFiltersPreview, const Size(390, 700)),
      ('tags-chinese', libraryFiltersLargeChinesePreview, const Size(320, 700)),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('release-capture'),
        child: KeyedSubtree(key: ValueKey(name), child: preview()),
      ));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('library-search-tags'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'C++');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('C++'), findsWidgets);
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      await tester.enterText(search, 'no matching tags');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library-tags-search-empty')),
          findsOneWidget);
      await _capture(tester, '$name-empty');
      final clear = find.byKey(const ValueKey('library-clear-tag-search'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library-tags-search-empty')),
          findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
