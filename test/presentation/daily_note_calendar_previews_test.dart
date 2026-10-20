import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/daily_note_calendar_previews.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(_key('daily-calendar-capture'));
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

Future<void> _tap(WidgetTester tester, String value) async {
  final target = _key(value);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
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

  for (final (name, preview, size) in [
    (
      'daily-calendar-media-light',
      dailyNoteCalendarMediaPreview,
      const Size(390, 844)
    ),
    (
      'daily-calendar-media-dark',
      dailyNoteCalendarMediaDarkPreview,
      const Size(390, 844)
    ),
    (
      'daily-calendar-media-chinese',
      dailyNoteCalendarMediaChinesePreview,
      const Size(320, 760)
    ),
  ]) {
    testWidgets('$name keeps attachment metadata visible and navigation usable',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('daily-calendar-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      final summary = _key('daily-calendar-media-summary');
      await tester.ensureVisible(summary);
      await tester.pumpAndSettle();
      final strings = S.of(tester.element(summary));
      expect(tester.widget<Text>(_key('daily-calendar-photos')).data,
          strings.History_Photos(1));
      expect(tester.widget<Text>(_key('daily-calendar-scans')).data,
          strings.Card_Scanned_Pages_Count(1));
      expect(tester.widget<Text>(_key('daily-calendar-recordings')).data,
          '${strings.History_Recordings(2)} · 1:55');
      expect(_key('daily-calendar-selected-snippet'), findsNothing);
      expect(find.byType(Image), findsNothing);
      for (final key in ['photos', 'scans', 'recordings']) {
        final bounds = tester.getRect(_key('daily-calendar-$key'));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);
      await _capture(tester, name);

      await _tap(tester, 'daily-calendar-next-month');
      expect(summary, findsNothing);
      expect(_key('daily-calendar-no-note'), findsOneWidget);
      await _tap(tester, 'daily-calendar-show-today');
      expect(summary, findsOneWidget);
      await _tap(tester, 'daily-calendar-previous-saved');
      expect(summary, findsNothing);
      await _tap(tester, 'daily-calendar-next-saved');
      expect(summary, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('transcript-only preview identifies the saved voice note',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('daily-calendar-capture'),
      child: dailyNoteCalendarTranscriptPreview(),
    ));
    await tester.pumpAndSettle();
    final snippet = _key('daily-calendar-selected-snippet');
    await tester.ensureVisible(snippet);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(snippet).data,
        'Ideas from this morning’s walk, saved in a voice note.');
    expect(_key('daily-calendar-photos'), findsNothing);
    expect(_key('daily-calendar-scans'), findsNothing);
    expect(_key('daily-calendar-recordings'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'daily-calendar-transcript');
  });
}
