import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_selection_previews.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

ThemeData? _captureTheme(Brightness brightness) {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return null;
  final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['DroidSansFallback'],
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['DroidSansFallback'],
    ),
    listTileTheme: base.listTileTheme.copyWith(
      titleTextStyle: base.listTileTheme.titleTextStyle?.copyWith(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['DroidSansFallback'],
      ),
      subtitleTextStyle: base.listTileTheme.subtitleTextStyle?.copyWith(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['DroidSansFallback'],
      ),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      _key('note-copy-destination-capture'));
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
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final (name, preview, size, locale, brightness) in [
    (
      'note-copy-match-light',
      copySelectionDestinationPreview,
      const Size(390, 740),
      const Locale('en'),
      Brightness.light
    ),
    (
      'note-copy-match-dark',
      copySelectionDestinationDarkPreview,
      const Size(390, 740),
      const Locale('en'),
      Brightness.dark
    ),
    (
      'note-copy-match-chinese',
      copySelectionDestinationChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light
    ),
  ]) {
    testWidgets('$name shows matched transcript and recovers after clear',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('note-copy-destination-capture'),
          child: preview(theme: _captureTheme(brightness)),
        ));
        await tester.pumpAndSettle();
        final search = _key('note-copy-search');
        expect(Localizations.localeOf(tester.element(search)), locale);
        expect(Theme.of(tester.element(search)).brightness, brightness);
        expect(tester.takeException(), isNull);
        await tester.enterText(search, ' [2026] ');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        final target = _key('note-copy-existing-trip');
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        final snippet = _key('note-copy-snippet-trip');
        expect(tester.widget<Text>(snippet).data, startsWith('…[2026]'));
        expect(find.text('Take the coastal path and stop at the market.'),
            findsNothing);
        expect(_key('note-copy-existing-garden'), findsNothing);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        final bounds = tester.getRect(snippet);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(
            tester
                .getSemantics(target)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isTrue);
        expect(tester.takeException(), isNull);
        await _capture(tester, name);
        await tester.enterText(search, '茶😀');
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(snippet).data, startsWith('…茶😀'));
        await tester.enterText(search, 'no matching content');
        await tester.pumpAndSettle();
        expect(find.text(S.current.Copy_Selection_No_Matches), findsOneWidget);
        expect(_key('note-copy-new'), findsOneWidget);
        final clear =
            find.descendant(of: search, matching: find.byType(IconButton));
        await tester.ensureVisible(clear);
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        expect(find.text(S.current.Copy_Selection_No_Matches), findsNothing);
        expect(_key('note-copy-existing-garden'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });
  }
}
