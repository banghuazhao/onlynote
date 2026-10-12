import 'package:onlynote/Tools/pdf_glyphs.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_appearance_settings.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/appearance_section.dart';
import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/presentation/components/note_share_sheet.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_export.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget app(Widget home, {bool dark = false, double scale = 1}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: home,
    );

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final loader = FontLoader('Roboto');
      loader.addFont(File('assets/fonts/Roboto-Regular.ttf')
          .readAsBytes()
          .then((b) => ByteData.sublistView(b)));
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  late Map<String, GoogleFontBuilder> fonts;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppAppearanceSettings.instance.load();
    fonts = Map.of(kAppFontFamilies);
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle);
    }
  });
  tearDown(() {
    kAppFontFamilies.addAll(fonts);
  });

  testWidgets('PDF font fallback preserves complete emoji sequences',
      (tester) async {
    await tester.runAsync(() async {
      final fonts = await Future.wait([
        'Roboto-Regular.ttf',
        'DroidSansFallback.ttf'
      ].map((name) => File('assets/fonts/$name')
          .readAsBytes()
          .then((b) => ByteData.sublistView(b))));
      final glyphs = await renderMissingPdfGlyphs('Tea 茶 👩🏽‍💻', fonts);
      expect(glyphs.keys, contains('👩🏽‍💻'));
      expect(glyphs.keys, isNot(contains('茶')));
      expect(glyphs.keys, isNot(contains('T')));
      for (final image in glyphs.values) {
        image.dispose();
      }
    });
  });

  testWidgets('filter chips combine, deselect, and clear at large text',
      (tester) async {
    var filters = <NoteSearchFilter>{};
    await tester.pumpWidget(app(Scaffold(
        body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: StatefulBuilder(
          builder: (_, setState) => NoteSearchFilters(
              selected: filters,
              onChanged: (value) => setState(() => filters = value))),
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();
    expect(filters, {NoteSearchFilter.checklists, NoteSearchFilter.photos});
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(filters, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search card reveals and highlights body and checklist matches',
      (tester) async {
    final note = Note(
        id: 'n',
        title: 'Trip',
        description: '${'Introduction. ' * 80}Buy tea',
        todo: [
          for (var i = 0; i < 6; i++)
            Todo(title: i == 5 ? 'TEA shop' : 'Other $i')
        ]);
    await tester.pumpWidget(app(Scaffold(
        body: SizedBox(
            width: 350, child: NoteCard(note: note, searchQuery: 'tea')))));
    await tester.pumpAndSettle();
    final highlights =
        tester.widgetList<SearchHighlight>(find.byType(SearchHighlight));
    expect(
        highlights
            .any((h) => h.text.startsWith('…') && h.text.contains('Buy tea')),
        isTrue);
    expect(highlights.any((h) => h.text == 'TEA shop'), isTrue);
    final spans = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.textSpan != null)
        .expand((t) => (t.textSpan! as TextSpan).children ?? <InlineSpan>[])
        .whereType<TextSpan>()
        .where((span) => span.style?.backgroundColor != null);
    expect(spans.map((span) => span.text), containsAll(['tea', 'TEA']));
  });

  testWidgets(
      'appearance controls persist and plain paper updates an existing surface',
      (tester) async {
    await tester.pumpWidget(app(const Scaffold(
        body: SingleChildScrollView(
            child: Column(children: [
      AppearanceSection(),
      PaperNote(color: Colors.yellow, child: Text('Preview')),
    ])))));
    await tester.pumpAndSettle();
    final textured = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((w) => w.painter != null)
        .length;
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(AppAppearanceSettings.instance.themeMode, ThemeMode.dark);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(AppAppearanceSettings.instance.plainPaper, isTrue);
    final plain = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((w) => w.painter != null)
        .length;
    expect(plain, lessThan(textured));
    final reloaded = AppAppearanceSettings();
    await reloaded.load();
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.plainPaper, isTrue);
    reloaded.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets(
        'plain paper toggles across the desk and writing surface: $dark',
        (tester) async {
      const screen = Scaffold(
          body: DeskSurface(
              child: SingleChildScrollView(
                  child: Column(children: [
        AppearanceSection(),
        PaperNote(
            color: Colors.yellow,
            child: RuledWritingArea(child: Text('My note'))),
      ]))));
      await tester.pumpWidget(app(screen, dark: dark));
      await tester.pumpAndSettle();
      for (final plain in [true, false, true]) {
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(AppAppearanceSettings.instance.plainPaper, plain);
        expect(find.text('My note'), findsOneWidget);
        final deskPaint = tester.widget<CustomPaint>(find
            .descendant(
                of: find.byType(DeskSurface),
                matching: find.byType(CustomPaint))
            .first);
        expect(deskPaint.painter == null, plain);
      }
      // A saved Plain paper preference must also render on a fresh screen.
      await tester.pumpWidget(const SizedBox());
      await AppAppearanceSettings.instance.load();
      await tester.pumpWidget(app(screen, dark: dark));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('My note'), findsOneWidget);
    });
  }

  for (final dark in [false, true]) {
    testWidgets('share format picker fits a phone with large text: $dark',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      NoteShareFormat? selected;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundaryKey,
          child: app(
              Scaffold(
                  body: Builder(
                      builder: (context) => Center(
                          child: FilledButton(
                              onPressed: () async {
                                selected = await showNoteShareSheet(context);
                              },
                              child: const Text('Share'))))),
              dark: dark,
              scale: 2)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Plain text'), findsOneWidget);
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await tester.runAsync(() async {
          final boundary = boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/onlynote-share-${dark ? 'dark' : 'light'}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.text('PDF document'));
      await tester.tap(find.text('PDF document'));
      await tester.pumpAndSettle();
      expect(selected, NoteShareFormat.pdf);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(S.current.Share_Copy_Text));
      await tester.tap(find.text(S.current.Share_Copy_Text));
      await tester.pumpAndSettle();
      expect(selected, NoteShareFormat.copyText);
      expect(tester.takeException(), isNull);
    });
  }
}
