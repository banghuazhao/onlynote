import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/note_info_previews.dart';
import 'package:onlynote/presentation/components/note_text_copy_previews.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('copy-trash-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-copy-trash');
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

  for (final (name, preview, size, target) in [
    (
      'copy-light',
      noteTextCopyLightPreview,
      const Size(390, 620),
      'note-share-copyText',
    ),
    (
      'copy-dark',
      noteTextCopyDarkPreview,
      const Size(390, 620),
      'note-share-copyText',
    ),
    (
      'copy-chinese',
      noteTextCopyChinesePreview,
      const Size(280, 700),
      'note-share-copyText',
    ),
    (
      'copy-landscape',
      noteTextCopyLightPreview,
      const Size(568, 320),
      'note-share-copyText',
    ),
    (
      'trash-light',
      trashNoteInfoLightPreview,
      const Size(390, 620),
      'note-info-moved-to-trash',
    ),
    (
      'trash-dark',
      trashNoteInfoDarkPreview,
      const Size(390, 620),
      'note-info-moved-to-trash',
    ),
    (
      'trash-chinese',
      trashNoteInfoChinesePreview,
      const Size(280, 700),
      'note-info-moved-to-trash',
    ),
    (
      'trash-landscape',
      trashNoteInfoLightPreview,
      const Size(568, 320),
      'note-info-moved-to-trash',
    ),
  ]) {
    testWidgets('$name scrolls to the new action or timestamp', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('copy-trash-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      final content = find.byKey(ValueKey(target));
      expect(content, findsOneWidget);
      await tester.ensureVisible(content);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      if (name.startsWith('trash-')) {
        await tester.ensureVisible(
            find.byKey(const ValueKey('note-info-recording-duration-value')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
