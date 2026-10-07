import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_image.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card_previews.dart';
import 'package:onlynote/presentation/theme/theme.dart';

Widget _host(Widget card,
        {Locale locale = const Locale('en'),
        double width = 350,
        double textScale = 1,
        bool reduceMotion = false,
        bool dark = false}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: DeskSurface(
          child: SingleChildScrollView(
            child: Center(child: SizedBox(width: width, child: card)),
          ),
        ),
      ),
    );

Widget _thumbnail(BuildContext context, String path) =>
    ColoredBox(color: const Color(0xFFADC9BA), child: Text(path));

Note _mixedNote() => Note(
      id: 'mixed',
      title: 'A useful weekend plan',
      description: 'Take the coastal route and stop for tea.',
      dateTime: DateTime(2026, 10, 7),
      isPinned: true,
      tags: ['Personal', 'Weekend', 'Travel'],
      linkedNoteIds: ['places', 'places', 'mixed', '', 'packing'],
      imagePaths: ['note_images/coast.jpg', 'note_images/map.jpg'],
      imageLayouts: const [
        NoteImageLayout(
            path: 'note_images/map.jpg', textOffset: 10, isDocumentPage: true),
        // A stale layout must not create another visible attachment.
        NoteImageLayout(
            path: 'note_images/missing.jpg',
            textOffset: 0,
            isDocumentPage: true),
      ],
      todo: [
        Todo(id: 'book', title: 'Book a table'),
        Todo(id: 'done', title: 'Find the walking route', completed: true),
        Todo(id: 'blank', title: ' \n '),
      ],
      voiceMemos: [
        VoiceMemo(
            id: 'voice',
            path: 'note_audio/voice.m4a',
            durationMs: 42000,
            createdAt: DateTime(2026, 10, 7)),
      ],
    );

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('home-preview-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await File('/tmp/onlynote-home-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      for (final family in ['Roboto', 'DroidSansFallback']) {
        final font = FontLoader(family)
          ..addFont(rootBundle.load(
              'assets/fonts/$family${family == 'Roboto' ? '-Regular' : ''}.ttf'));
        await font.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  setUp(() {
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              fontFamily:
                  const bool.fromEnvironment('CAPTURE_UI') ? 'Roboto' : null,
              fontFamilyFallback: const bool.fromEnvironment('CAPTURE_UI')
                  ? const ['DroidSansFallback']
                  : null,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() => kAppFontFamilies.addAll(fonts));

  testWidgets('NoteCard shows title, body, and localized date like a note',
      (tester) async {
    final note = Note(
      id: 'note-1',
      title: 'Saturday market',
      description: 'Bread, citrus, and the good olives.',
      color: const Color(0xFFFFF4C2),
      dateTime: DateTime(2026, 8, 19),
    );
    var tapped = false;
    await tester.pumpWidget(_host(NoteCard(
      note: note,
      onTap: () => tapped = true,
      onShare: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Saturday market'), findsOneWidget);
    expect(find.text('Bread, citrus, and the good olives.'), findsOneWidget);
    expect(find.text(DateFormat.yMMMd('en').format(note.dateTime!)),
        findsOneWidget);
    await tester.tap(find.text('Saturday market'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed notes summarize real tasks, scans, recordings, and links',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(NoteCard(
        note: _mixedNote(),
        onTap: () {},
        onShare: () {},
        thumbnailBuilder: _thumbnail,
      )));
      await tester.pumpAndSettle();
      expect(find.text(S.current.Checklist_Progress(1, 2)), findsOneWidget);
      expect(find.byKey(const ValueKey('card-todo-blank')), findsNothing);
      expect(find.text(S.current.Card_Scanned_Pages_Count(1)), findsOneWidget);
      expect(find.text(S.current.Card_Linked_Notes_Count(2)), findsOneWidget);
      expect(find.text(S.current.History_Recordings(1)), findsOneWidget);
      expect(
          find.bySemanticsLabel(
              '${S.current.History_Photos(1)}, ${S.current.Card_Scanned_Pages_Count(1)}'),
          findsOneWidget);
      expect(find.byType(NoteImage), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('blank placeholders stay absent and pending items preview first',
      (tester) async {
    final note = Note(id: 'tasks', todo: [
      Todo(id: 'empty', title: ''),
      Todo(id: 'null', title: null),
      Todo(id: 'space', title: ' \n '),
      for (var index = 0; index < 4; index++)
        Todo(id: 'done-$index', title: 'Completed $index', completed: true),
      Todo(id: 'pending', title: 'The remaining action'),
    ]);
    await tester.pumpWidget(_host(NoteCard(note: note, onShare: () {})));
    await tester.pumpAndSettle();
    final rows =
        tester.widgetList<PaperChecklistRow>(find.byType(PaperChecklistRow));
    expect(rows.map((row) => row.label),
        ['The remaining action', 'Completed 0', 'Completed 1']);
    expect(find.text(S.current.Checklist_Progress(4, 5)), findsOneWidget);

    await tester.pumpWidget(_host(NoteCard(
      note: Note(todo: [Todo.empty(), Todo(title: '\n\t')]),
      onShare: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.byType(PaperChecklistRow), findsNothing);
    expect(find.byKey(const ValueKey('card-checklist-progress')), findsNothing);
    expect(find.byKey(const ValueKey('card-date')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('query matches in later tags and completed tasks explain results',
      (tester) async {
    final note = _mixedNote().copyWith(todo: [
      Todo(id: 'pending', title: 'Book lunch'),
      Todo(id: 'done', title: 'Find the Travel route', completed: true),
    ]);
    await tester.pumpWidget(_host(NoteCard(
      note: note,
      searchQuery: 'travel',
      onShare: () {},
      thumbnailBuilder: _thumbnail,
    )));
    await tester.pumpAndSettle();
    final rows =
        tester.widgetList<PaperChecklistRow>(find.byType(PaperChecklistRow));
    expect(rows.first.label, 'Find the Travel route');
    final tags = tester
        .widgetList<SearchHighlight>(find.byType(SearchHighlight))
        .where((text) => text.text.contains('#'));
    expect(tags.single.text, '#Travel  #Personal  +1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('card share is independent and selection respects reduced motion',
      (tester) async {
    var shares = 0;
    var opens = 0;
    var selected = false;
    var selectionMode = false;
    late StateSetter update;
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (_, setState) {
        update = setState;
        return NoteCard(
          note: Note(id: 'select', title: 'A note'),
          selectionMode: selectionMode,
          selected: selected,
          onShare: () => shares++,
          onTap: () {
            opens++;
            if (selectionMode) setState(() => selected = !selected);
          },
        );
      },
    ), reduceMotion: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(S.current.Share));
    await tester.pump();
    expect(shares, 1);
    expect(opens, 0);

    update(() => selectionMode = true);
    await tester.pump();
    await tester.tap(find.byTooltip(S.current.Select));
    await tester.pump();
    expect(selected, isTrue);
    expect(opens, 1);
    expect(shares, 1);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsNothing);
    final switcher = find.descendant(
        of: find.byType(IconButton), matching: find.byType(AnimatedSwitcher));
    expect(tester.widget<AnimatedSwitcher>(switcher).duration, Duration.zero);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo search preserves combining marks and joined emoji matches',
      (tester) async {
    final note = Note(
      id: 'photo-search',
      title: 'A saved photo',
      imagePaths: ['note_images/photo.jpg'],
    );
    for (final (grapheme, query) in [
      ('e\u0301', '\u0301'),
      ('👩🏽‍💻', '💻')
    ]) {
      await tester.pumpWidget(_host(NoteCard(
        note: note,
        searchQuery: query,
        photoSearchText: 'An earlier label $grapheme detail',
        photoSearchImagePath: note.imagePaths.single,
        thumbnailBuilder: _thumbnail,
        onShare: () {},
      )));
      await tester.pumpAndSettle();
      final excerpt = tester.widget<SearchHighlight>(
          find.byKey(const ValueKey('photo-search-excerpt')));
      expect(excerpt.text, '…$grapheme detail');
      expect(excerpt.query, query);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mixed cards fit narrow Chinese large text in light and dark',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final dark in [false, true]) {
      tester.view.physicalSize = const Size(180, 850);
      await tester.pumpWidget(_host(
        NoteCard(
          note: _mixedNote()
              .copyWith(title: '週末的點子', description: '沿海邊散步，看看春天的風景。'),
          onShare: () {},
          onTap: () {},
          onTodoToggle: (_) {},
          thumbnailBuilder: _thumbnail,
        ),
        width: 180,
        locale: const Locale('zh', 'HK'),
        textScale: 2.4,
        reduceMotion: true,
        dark: dark,
      ));
      await tester.pumpAndSettle();
      expect(find.text(DateFormat.yMMMd('zh_HK').format(DateTime(2026, 10, 7))),
          findsOneWidget);
      await tester.ensureVisible(find.byTooltip(S.current.Share));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(IconButton)).shortestSide,
          greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mixed home previews stay local, interactive and fit all sizes',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final (preview, size, name) in [
      (mixedNoteCardsPreview, const Size(390, 850), 'mixed-light'),
      (mixedNoteCardsDarkPreview, const Size(390, 850), 'mixed-dark'),
      (mixedNoteCardsChinesePreview, const Size(280, 800), 'mixed-chinese-2x'),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('home-preview-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(NoteCard), findsWidgets);
      expect(find.byType(NoteImage), findsNothing);
      final first = find.byKey(const ValueKey('card-todo-book'));
      expect(tester.widget<PaperChecklistRow>(first).completed, isFalse);
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(tester.widget<PaperChecklistRow>(first).completed, isTrue);
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      // Recreate the private fixture state before using the next appearance.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
