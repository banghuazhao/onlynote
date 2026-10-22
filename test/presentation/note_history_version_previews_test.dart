import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_history_version_previews.dart';
import 'package:onlynote/presentation/components/note_history_version_tile.dart';

import '../support/search_highlight_text.dart';

const _transcript =
    'Recorded thought 茶😀 — a longer first line to recognize this version\n'
    'Keep the reviewed transcript ready for the next release. 第二行記錄。';
const _voiceChannel = MethodChannel('com.appsbay.onlynote/voice_memos');

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('history-transcript-capture')));
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

  testWidgets('query highlights content only and preserves the supplied action',
      (tester) async {
    const text = 'C++ [draft].* 茶室😀 👩🏽‍💻';
    const metadata = 'C++ [draft].* 茶室😀 👩🏽‍💻 metadata';
    var selections = 0;
    final query = ValueNotifier('');
    addTearDown(query.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<String>(
          valueListenable: query,
          builder: (_, value, __) => NoteHistoryVersionTile(
            key: const ValueKey('highlighted-version'),
            title: text,
            dateLabel: metadata,
            snippet: text,
            query: value,
            mediaCounts: const Text(metadata),
            onPressed: () => selections++,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('highlighted-version'));
    for (final (value, expected) in [
      (' c++ ', 'C++'),
      ('[DRAFT].*', '[draft].*'),
      ('茶室😀', '茶室😀'),
      ('👩', '👩🏽‍💻'),
    ]) {
      query.value = value;
      await tester.pumpAndSettle();
      expect(highlightedSearchText(tester, row), [expected, expected]);
      expect(find.text(metadata), findsNWidgets(2));
      for (final label in tester.widgetList<Text>(find.text(metadata))) {
        expect(label.textSpan, isNull);
      }
      expect(selections, 0);
      expect(tester.takeException(), isNull);
    }
    query.value = '';
    await tester.pumpAndSettle();
    expect(highlightedSearchText(tester, row), isEmpty);
    expect(find.text(text), findsNWidgets(2));
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(selections, 1);
  });

  for (final (name, preview, size, locale, brightness) in [
    (
      'light',
      noteHistoryTranscriptLightPreview,
      const Size(390, 620),
      const Locale('en'),
      Brightness.light,
    ),
    (
      'dark',
      noteHistoryTranscriptDarkPreview,
      const Size(390, 620),
      const Locale('en'),
      Brightness.dark,
    ),
    (
      'Chinese narrow 2x',
      noteHistoryTranscriptChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light,
    ),
  ]) {
    testWidgets(
        '$name transcript history preview preserves text and selects locally',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final nativeCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            nativeCalls.add(call.method);
          }
          return null;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _voiceChannel,
        (call) async {
          nativeCalls.add(call.method);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(_voiceChannel, null);
      });
      try {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('history-transcript-capture'),
          child: preview(),
        ));
        await tester.pumpAndSettle();
        final row =
            find.byKey(const ValueKey('history-version-transcript-preview'));
        expect(row, findsOneWidget);
        expect(Localizations.localeOf(tester.element(row)), locale);
        expect(Theme.of(tester.element(row)).brightness, brightness);
        expect(find.text(_transcript.split('\n').first), findsOneWidget);
        expect(find.text(_transcript), findsOneWidget);
        expect(find.text(S.current.History_Recordings(1)), findsOneWidget);
        expect(find.text(S.current.History_Title), findsOneWidget);
        expect(find.byType(SelectableText), findsNothing);
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(row.hitTestable(), findsOneWidget);
        final targetSize = tester.getSize(row);
        expect(targetSize.width, greaterThanOrEqualTo(48));
        expect(targetSize.height, greaterThanOrEqualTo(48));
        expect(
            tester
                .getSemantics(row)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isTrue);
        expect(
            tester
                .getSemantics(find.text(_transcript))
                .getSemanticsData()
                .label,
            contains(_transcript));
        final captureName = locale.languageCode == 'zh' ? 'chinese' : name;
        await _capture(tester, 'history-transcript-$captureName');
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(row, findsNothing);
        expect(find.text(S.current.History_Preview), findsOneWidget);
        expect(
            find.widgetWithText(SelectableText, _transcript), findsOneWidget);
        expect(find.text(S.current.History_Recordings(1)), findsOneWidget);
        await _capture(tester, 'history-transcript-$captureName-selected');
        final back = find.byKey(const ValueKey('history-preview-back'));
        await tester.ensureVisible(back);
        await tester.pumpAndSettle();
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(row, findsOneWidget);
        expect(find.byType(SelectableText), findsNothing);
        expect(nativeCalls, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
      'history tile invokes its supplied selection callback once per tap',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selections = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: NoteHistoryVersionTile(
            key: const ValueKey('version-action'),
            title: _transcript.split('\n').first,
            dateLabel: 'Oct 13, 2026, 10:00 AM',
            snippet: _transcript,
            mediaCounts: const Text('1 recording'),
            onPressed: () => selections++,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('version-action'));
    await tester.ensureVisible(row);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    expect(selections, 0);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(selections, 1);
    expect(find.text(_transcript), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
