import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/photo_search_status.dart';
import 'package:onlynote/presentation/components/note_image.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:screenshot/screenshot.dart';

class _PausedCaptureController extends ScreenshotController {
  final result = Completer<Uint8List?>();
  bool called = false;

  @override
  Future<Uint8List?> capture(
      {double? pixelRatio, Duration delay = const Duration(milliseconds: 20)}) {
    called = true;
    return result.future;
  }
}

Widget _host(Widget child,
        {Locale locale = const Locale('en'),
        bool dark = false,
        double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: true, textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final loader = FontLoader('Roboto');
      loader.addFont(File('assets/fonts/Roboto-Regular.ttf')
          .readAsBytes()
          .then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
      final fallback = FontLoader('DroidSansFallback');
      fallback.addFont(File('assets/fonts/DroidSansFallback.ttf')
          .readAsBytes()
          .then((bytes) => ByteData.sublistView(bytes)));
      await fallback.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  late Map<String, GoogleFontBuilder> fonts;
  setUp(() {
    fonts = Map.of(kAppFontFamilies);
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily:
                  const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null,
              fontFamilyFallback: const bool.fromEnvironment('CAPTURE_UI')
                  ? ['DroidSansFallback']
                  : null,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('photo-only match explains and highlights its result',
      (tester) async {
    final note = Note(id: 'receipt', title: 'Receipt', description: 'Lunch');
    final photoText = '${'Unrelated receipt line. ' * 30}Green TEA 4.50';
    var opened = false;
    await tester.pumpWidget(_host(NoteCard(
      note: note,
      searchQuery: 'tea',
      photoSearchText: photoText,
      onTap: () => opened = true,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Text in photo'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    final excerpt = tester.widget<SearchHighlight>(
        find.byKey(const ValueKey('photo-search-excerpt')));
    expect(excerpt.text, startsWith('…'));
    expect(excerpt.text, startsWith('…TEA 4.50'));
    expect(excerpt.text.length, lessThan(80));
    expect(excerpt.maxLines, 3);
    final text = tester.widget<Text>(find.descendant(
        of: find.byKey(const ValueKey('photo-search-excerpt')),
        matching: find.byType(Text)));
    final spans = (text.textSpan! as TextSpan).children!.whereType<TextSpan>();
    expect(
        spans.singleWhere((span) => span.text == 'TEA').style?.backgroundColor,
        isNotNull);
    await tester.tap(find.text('Text in photo'));
    await tester.pump();
    expect(opened, isTrue);
    expect(note.description, 'Lunch');
    expect(note.title, 'Receipt');
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank search and stale unmatched photo text keep ordinary cards',
      (tester) async {
    final note = Note(id: 'receipt', title: 'Receipt', imagePaths: [
      'note_images/first.jpg',
      'note_images/second.jpg',
    ]);
    for (final query in ['', '  ', 'coffee']) {
      await tester.pumpWidget(_host(NoteCard(
        note: note,
        searchQuery: query,
        photoSearchText: 'Green tea 4.50',
        photoSearchImagePath: 'note_images/second.jpg',
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo-search-match')), findsNothing);
      expect(find.text('Receipt'), findsOneWidget);
      expect(tester.widget<NoteImage>(find.byType(NoteImage)).path,
          'note_images/first.jpg');
    }
  });

  testWidgets('literal whitespace queries retain their matching photo text',
      (tester) async {
    await tester.pumpWidget(_host(NoteCard(
      note: Note(id: 'receipt', title: 'Receipt'),
      searchQuery: 'Total  12.50',
      photoSearchText: 'Receipt\nTotal  12.50\nThank you!',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Text in photo'), findsOneWidget);
    final excerpt = tester.widget<SearchHighlight>(
        find.byKey(const ValueKey('photo-search-excerpt')));
    expect(excerpt.text, contains('Total  12.50'));
    expect(excerpt.query, 'Total  12.50');
    expect(tester.takeException(), isNull);
  });

  testWidgets('derived photo text is excluded from image capture and restored',
      (tester) async {
    final controller = _PausedCaptureController();
    final key = GlobalKey<NoteCardState>();
    final note = Note(
      id: 'receipt',
      title: 'Receipt',
      description: 'Lunch',
      imagePaths: ['note_images/first.jpg', 'note_images/second.jpg'],
    );
    await tester.pumpWidget(_host(NoteCard(
      key: key,
      note: note,
      searchQuery: 'tea',
      photoSearchText: 'Green tea 4.50',
      photoSearchImagePath: 'note_images/second.jpg',
      screenshotController: controller,
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-search-match')), findsOneWidget);
    expect(tester.widget<NoteImage>(find.byType(NoteImage)).path,
        'note_images/second.jpg');
    expect(find.text('+1'), findsOneWidget);

    final capture = key.currentState!.captureImage();
    await tester.pump();
    expect(controller.called, isTrue);
    expect(find.byKey(const ValueKey('photo-search-match')), findsNothing);
    expect(find.text('Lunch'), findsOneWidget);
    expect(tester.widget<NoteImage>(find.byType(NoteImage)).path,
        'note_images/first.jpg');
    controller.result.complete(null);
    await capture;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-search-match')), findsOneWidget);
    expect(tester.widget<NoteImage>(find.byType(NoteImage)).path,
        'note_images/second.jpg');
    expect(
        note.imagePaths, ['note_images/first.jpg', 'note_images/second.jpg']);
    expect(note.description, 'Lunch');
    expect(tester.takeException(), isNull);
  });

  testWidgets('indexing status disappears when complete without a spinner',
      (tester) async {
    await tester.pumpWidget(_host(const PhotoSearchStatus(indexing: true)));
    await tester.pumpAndSettle();
    expect(find.text('Making photo text searchable…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    final semantics = tester.widget<Semantics>(find
        .ancestor(
            of: find.byKey(const ValueKey('photo-search-status')),
            matching: find.byType(Semantics))
        .first);
    expect(semantics.properties.liveRegion, isTrue);
    await tester.pumpWidget(_host(const PhotoSearchStatus(indexing: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-search-status')), findsNothing);
  });

  if (const bool.fromEnvironment('CAPTURE_UI')) {
    testWidgets('capture realistic photo search on a phone', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const receiptPath = '/tmp/onlynote-photo-search-receipt.png';
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xFFDBCEC0), BlendMode.src);
        canvas.drawRect(const Rect.fromLTWH(55, 18, 270, 450),
            Paint()..color = Colors.white);
        final receipt = TextPainter(
          text: const TextSpan(
            text: 'THE CORNER CAFE\n\nFriday, 6 October\n\n'
                'Green tea        4.50\nAvocado toast   12.00\n\n'
                'TOTAL           16.50\n\nThank you!',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                height: 1.5,
                color: Colors.black87),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 240);
        receipt.paint(canvas, const Offset(70, 48));
        final picture = recorder.endRecording();
        final image = await picture.toImage(380, 490);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(receiptPath).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      });
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.runAsync(() async {
        await precacheImage(
            ResizeImage.resizeIfNeeded(64, null, FileImage(File(receiptPath))),
            tester.element(find.byType(Scaffold)));
      });
      final boundaryKey = GlobalKey();
      final searchController = TextEditingController(text: 'tea');
      addTearDown(searchController.dispose);
      await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: _host(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 52, 20, 20),
                child: Text('Onlynote',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 28)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PaperNote(
                  color: const Color(0xFFFFF9F0),
                  seed: 11,
                  tilt: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 16),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.clear),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const PhotoSearchStatus(indexing: true),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NoteCard(
                        note: Note(
                          id: 'receipt',
                          title: 'Lunch receipt',
                          dateTime: DateTime(2026, 10, 6),
                          imagePaths: [receiptPath],
                        ),
                        searchQuery: 'tea',
                        photoSearchText: 'THE CORNER CAFE\nFriday 6 October\n'
                            'Green tea 4.50\nAvocado toast 12.00\n'
                            'TOTAL 16.50\nThank you!',
                        photoSearchImagePath: receiptPath,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NoteCard(
                        note: Note(
                          id: 'shopping',
                          title: 'Weekend list',
                          dateTime: DateTime(2026, 10, 5),
                          todo: [
                            Todo(title: 'Green tea'),
                            Todo(title: 'Bread'),
                            Todo(title: 'Milk'),
                          ],
                        ),
                        searchQuery: 'tea',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/tmp/onlynote-photo-search-phone.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in [const Locale('zh'), const Locale('zh', 'HK')]) {
    testWidgets('photo search fits narrow dark cards with large text: $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(
        Column(
          children: [
            const PhotoSearchStatus(indexing: true),
            SizedBox(
              width: 160,
              child: NoteCard(
                note: Note(id: 'receipt', title: '购物收据'),
                searchQuery: '茶',
                photoSearchText: '${'之前的内容 ' * 20}绿茶 4.50，牛奶 3.00',
              ),
            ),
          ],
        ),
        locale: locale,
        dark: true,
        scale: 2.4,
      ));
      await tester.pumpAndSettle();
      expect(find.text('照片中的文字'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('photo-search-excerpt')), findsOneWidget);
      final excerpt = tester.widget<SearchHighlight>(
          find.byKey(const ValueKey('photo-search-excerpt')));
      final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
          of: find.byKey(const ValueKey('photo-search-excerpt')),
          matching: find.byType(RichText)));
      final matchOffset = excerpt.text.indexOf('茶');
      expect(
          paragraph.getBoxesForSelection(TextSelection(
              baseOffset: matchOffset, extentOffset: matchOffset + 1)),
          isNotEmpty);
      expect(
          find.text(
              locale.countryCode == 'HK' ? '正在辨識照片文字以便搜尋…' : '正在识别照片文字以便搜索…'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
