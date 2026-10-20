import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_links_previews.dart';
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
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(base.textTheme.labelLarge?.copyWith(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['DroidSansFallback'],
        )),
      ),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(_key('note-links-capture'));
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
      'note-links-light',
      noteLinksPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.light
    ),
    (
      'note-links-dark',
      noteLinksDarkPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.dark
    ),
    (
      'note-links-chinese',
      noteLinksLargeTextPreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light
    ),
  ]) {
    testWidgets(
        '$name previews relationships and opens locally without media I/O',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('note-links-capture'),
          child: preview(theme: _captureTheme(brightness)),
        ));
        await tester.pumpAndSettle();
        final packing = _key('linked-note-packing');
        expect(Localizations.localeOf(tester.element(packing)), locale);
        expect(Theme.of(tester.element(packing)).brightness, brightness);
        expect(find.text(S.current.Archive), findsOneWidget);
        expect(_key('linked-note-missing-snippet'), findsNothing);
        expect(find.text(S.current.Link_Unavailable), findsOneWidget);
        for (final (key, expected) in [
          ('linked-note-packing', 'raincoats'),
          ('linked-note-voice', '茶😀'),
          ('backlink-note-travel', 'quiet coastal walk'),
        ]) {
          final row = _key(key);
          final snippet = _key('$key-snippet');
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          expect(tester.widget<Text>(snippet).data, contains(expected));
          expect(tester.widget<Text>(snippet).maxLines, 2);
          expect(tester.widget<Text>(snippet).overflow, TextOverflow.ellipsis);
          final bounds = tester.getRect(snippet);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          final data = tester.getSemantics(row).getSemanticsData();
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.hint, contains(S.current.Open_Linked_Note));
          expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(_key('linked-note-voice'));
        await tester.pumpAndSettle();
        await _capture(tester, name);
        await tester.ensureVisible(packing);
        await tester.pumpAndSettle();
        await tester.tap(packing);
        await tester.pumpAndSettle();
        final opened = _key('note-links-preview-opened');
        await tester.ensureVisible(opened);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(opened).data, 'Packing list');
        final incoming = _key('backlink-note-travel');
        await tester.ensureVisible(incoming);
        await tester.pumpAndSettle();
        await tester.tap(incoming);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(opened).data, 'Weekend trip');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });
  }
}
