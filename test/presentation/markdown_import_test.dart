import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/import_notes/markdown_import_content.dart';
import 'package:onlynote/presentation/screens/import_notes/markdown_import_previews.dart';
import 'package:onlynote/presentation/screens/import_notes/markdown_import_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/markdown_import.dart';
import 'package:onlynote/services/markdown_import_files.dart';
import 'package:onlynote/services/markdown_import_service.dart';

import '../support/premium_test_fakes.dart';

MarkdownImportBatch _batch() => MarkdownImportBatch(documents: [
      MarkdownImportParser.parse('# First\nA **bold** thought.',
          sourceName: 'one.md'),
      MarkdownImportParser.parse('# Second\n- [ ] A task',
          sourceName: 'two.md'),
    ]);

Future<void> _pump(WidgetTester tester, Widget screen,
    {Size size = const Size(390, 844),
    double scale = 1,
    Locale locale = const Locale('en')}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
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
            textScaler: TextScaler.linear(scale), disableAnimations: true),
        child: child!),
    home: Builder(
        builder: (context) => Scaffold(
            body: TextButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => screen)),
                child: const Text('Open import')))),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open import'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_IMPORT_UI')) return;
    final regular = FontLoader('Roboto')
      ..addFont(File('assets/fonts/Roboto-Regular.ttf')
          .readAsBytes()
          .then(ByteData.sublistView))
      ..addFont(File('assets/fonts/Roboto-Bold.ttf')
          .readAsBytes()
          .then(ByteData.sublistView));
    await regular.load();
    await (FontLoader('DroidSansFallback')
          ..addFont(File('assets/fonts/DroidSansFallback.ttf')
              .readAsBytes()
              .then(ByteData.sublistView)))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  late PremiumTestFixture fixture;
  setUp(() async {
    fixture = PremiumTestFixture(premium: true);
    await fixture.init();
  });
  tearDown(() => fixture.dispose());

  testWidgets(
      'preview and selection are read-only until explicit import, duplicate actions save once',
      (tester) async {
    final writes = <List<MarkdownImportDocument>>[];
    final pending = Completer<MarkdownImportResult>();
    await _pump(
        tester,
        MarkdownImportScreen(
            initialBatch: _batch(),
            premiumAccess: fixture.access,
            noteCount: () => 0,
            importDocuments: (docs) {
              writes.add(docs);
              return pending.future;
            }));
    expect(writes, isEmpty);
    await tester.tap(find.byKey(const ValueKey('markdown-import-note-1')));
    await tester.pumpAndSettle();
    final save = tester
        .widget<FilledButton>(
            find.byKey(const ValueKey('markdown-import-save')))
        .onPressed!;
    save();
    save();
    await tester.pump();
    expect(writes, hasLength(1));
    expect(writes.single.single.note.title, 'First');
    pending.complete(const MarkdownImportResult(importedIds: ['new']));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownImportScreen), findsNothing);
    expect(find.text('Open import'), findsOneWidget);
    save();
    await tester.pump();
    expect(writes, hasLength(1));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'picking cancellation preserves previous review and rejected files do not save',
      (tester) async {
    var pickCalls = 0;
    var writes = 0;
    await _pump(
        tester,
        MarkdownImportScreen(
            initialBatch: _batch(),
            premiumAccess: fixture.access,
            noteCount: () => 0,
            readFiles: (files) async => MarkdownImportReader.readBytes(
                files.single.name, files.single.bytes),
            pickFiles: () async {
              pickCalls++;
              if (pickCalls == 1) return [];
              return [
                MarkdownImportPickedFile(
                    name: 'bad.txt',
                    bytes: Uint8List.fromList(utf8.encode('Text')))
              ];
            },
            importDocuments: (_) async {
              writes++;
              return const MarkdownImportResult();
            }));
    await tester.tap(find.byKey(const ValueKey('markdown-import-choose')));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('markdown-import-choose')));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(writes, 0);
    expect(find.text(S.current.Markdown_Import_Failed), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'covered save completion cannot dismiss a different route or reimport consumed notes',
      (tester) async {
    final pending = Completer<MarkdownImportResult>();
    var writes = 0;
    await _pump(
        tester,
        MarkdownImportScreen(
            initialBatch: _batch(),
            premiumAccess: fixture.access,
            noteCount: () => 0,
            importDocuments: (_) {
              writes++;
              return pending.future;
            }));
    final save = tester
        .widget<FilledButton>(
            find.byKey(const ValueKey('markdown-import-save')))
        .onPressed!;
    save();
    await tester.pump();
    final context = tester.element(find.byType(MarkdownImportScreen));
    unawaited(showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Another route'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    pending.complete(const MarkdownImportResult(importedIds: ['one', 'two']));
    await tester.pumpAndSettle();
    expect(find.text('Another route'), findsOneWidget);
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownImportScreen), findsOneWidget);
    expect(find.text('First'), findsNothing);
    save();
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial failure retries only remaining documents',
      (tester) async {
    final batch = _batch();
    final calls = <List<MarkdownImportDocument>>[];
    await _pump(
        tester,
        MarkdownImportScreen(
            initialBatch: batch,
            premiumAccess: fixture.access,
            noteCount: () => 0,
            importDocuments: (docs) async {
              calls.add(docs);
              return calls.length == 1
                  ? MarkdownImportResult(
                      importedIds: ['one'],
                      remaining: [batch.documents[1]],
                      failure: MarkdownImportFailure.save)
                  : const MarkdownImportResult(importedIds: ['two']);
            }));
    await tester.tap(find.byKey(const ValueKey('markdown-import-save')));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text(S.current.Markdown_Import_Save_Failed), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('markdown-import-save')));
    await tester.pumpAndSettle();
    expect(calls, hasLength(2));
    expect(calls.last.single.note.title, 'Second');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('import photo thumbnails decode at their displayed height',
      (tester) async {
    final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6S58AAAAASUVORK5CYII=');
    final document = MarkdownImportParser.parse('![Photo](photo.png)',
        sourceName: 'photo.md', attachments: {'photo.png': bytes});
    await _pump(
        tester,
        MarkdownImportScreen(
            initialBatch: MarkdownImportBatch(documents: [document]),
            premiumAccess: fixture.access,
            noteCount: () => 0));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).height, 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'review fits narrow large-text landscape and its selection is interactive',
      (tester) async {
    await _pump(
        tester,
        MarkdownImportScreen(
            initialBatch: _batch(),
            premiumAccess: fixture.access,
            noteCount: () => 0,
            importDocuments: (_) async => const MarkdownImportResult()),
        size: const Size(320, 320),
        scale: 2,
        locale: const Locale('zh', 'HK'));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('markdown-import-note-0')), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(MarkdownImportContent), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all preview configurations render without overflow',
      (tester) async {
    var index = 0;
    for (final preview in [
      markdownImportPreview(),
      markdownImportDarkPreview(),
      markdownImportLargePreview()
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize =
          index == 2 ? const Size(320, 600) : const Size(390, 740);
      final captureKey = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: captureKey, child: preview));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownImportContent), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_IMPORT_UI')) {
        final boundary = captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          try {
            final data = await image.toByteData(format: ImageByteFormat.png);
            final name = ['light', 'dark', 'large-chinese'][index];
            await File('/private/tmp/onlynote-markdown-import-$name.png')
                .writeAsBytes(data!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      index++;
    }
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}
