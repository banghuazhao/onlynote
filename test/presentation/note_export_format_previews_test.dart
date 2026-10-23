import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_export_format_previews.dart';
import 'package:onlynote/presentation/components/note_export_section.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_bulk_export.dart';

Finder get _hint => find.byKey(const ValueKey('note-export-format-hint'));

String _hintText(WidgetTester tester) => tester.widget<Text>(_hint).data!;

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  final theme = app.theme!;
  TextStyle? captureStyle(TextStyle? style) => style?.copyWith(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['DroidSansFallback'],
      );
  // Preserve the fixture's current selection while supplying the CJK fallback
  // that a device provides automatically but widget-test rendering does not.
  final section =
      tester.widget<NoteExportSection>(find.byType(NoteExportSection));
  await tester.pumpWidget(RepaintBoundary(
    key: const ValueKey('export-format-capture'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: app.locale,
      supportedLocales: app.supportedLocales,
      localizationsDelegates: app.localizationsDelegates,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        chipTheme: theme.chipTheme.copyWith(
          labelStyle: captureStyle(theme.chipTheme.labelStyle),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: theme.outlinedButtonTheme.style?.copyWith(
            textStyle: WidgetStatePropertyAll(
                captureStyle(theme.textTheme.labelLarge)),
          ),
        ),
      ),
      builder: app.builder,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: section,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.ensureVisible(_hint);
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('export-format-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
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

  for (final (locale, markdownExcerpt, plainExcerpt, pdfExcerpt) in [
    (
      const Locale('en'),
      'Photos and recordings',
      '.txt files',
      'Printable pages'
    ),
    (const Locale('zh'), '照片和录音', '.txt 文件', '适合打印'),
    (const Locale('zh', 'HK'), '照片和錄音', '.txt 檔案', '適合列印'),
  ]) {
    testWidgets('$locale format hints follow choices without exporting early',
        (tester) async {
      var format = NoteBulkExportFormat.markdown;
      final exported = <NoteBulkExportFormat>[];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
            body: SingleChildScrollView(
          child: StatefulBuilder(
              builder: (context, setState) => NoteExportSection(
                    saveToFile: false,
                    format: format,
                    onFormatChanged: (value) => setState(() => format = value),
                    onExport: () => exported.add(format),
                  )),
        )),
      ));
      await tester.pumpAndSettle();
      expect(_hintText(tester), contains(markdownExcerpt));
      for (final (choice, excerpt) in [
        (NoteBulkExportFormat.pdf, pdfExcerpt),
        (NoteBulkExportFormat.plainText, plainExcerpt),
        (NoteBulkExportFormat.markdown, markdownExcerpt),
      ]) {
        final chip = find.byKey(ValueKey('note-export-format-${choice.name}'));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(_hintText(tester), contains(excerpt));
        expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
        expect(exported, isEmpty);
      }
      final button =
          find.widgetWithText(OutlinedButton, S.current.Export_Notes);
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(exported, [NoteBulkExportFormat.markdown]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'busy export disables format choice semantics and can enable them again',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final enabled = ValueNotifier(false);
      addTearDown(enabled.dispose);
      var format = NoteBulkExportFormat.plainText;
      var changes = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [S.delegate],
        home: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, value, _) => Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NoteExportSection(
                saveToFile: false,
                format: format,
                onFormatChanged: (value) => setState(() {
                  changes++;
                  format = value;
                }),
                onExport: value ? () {} : null,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final original = _hintText(tester);
      for (final choice in NoteBulkExportFormat.values) {
        final chip = find.byKey(ValueKey('note-export-format-${choice.name}'));
        expect(tester.widget<ChoiceChip>(chip).onSelected, isNull);
        final node = tester.getSemantics(chip);
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        await tester.tap(chip);
        await tester.pump();
      }
      expect(changes, 0);
      expect(_hintText(tester), original);
      enabled.value = true;
      await tester.pumpAndSettle();
      final pdfChip = find.byKey(const ValueKey('note-export-format-pdf'));
      expect(tester.widget<ChoiceChip>(pdfChip).onSelected, isNotNull);
      expect(tester.getSemantics(pdfChip).flagsCollection.isEnabled,
          Tristate.isTrue);
      await tester.tap(pdfChip);
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(format, NoteBulkExportFormat.pdf);
      expect(tester.widget<ChoiceChip>(pdfChip).selected, isTrue);
      expect(_hintText(tester), isNot(original));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('restored format controls fit and remain interactive in previews',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size, format, saveToFile) in [
      (
        rememberedPlainTextExportPreview,
        const Size(390, 500),
        NoteBulkExportFormat.plainText,
        false,
      ),
      (
        rememberedPdfExportPreview,
        const Size(640, 420),
        NoteBulkExportFormat.pdf,
        true,
      ),
      (
        rememberedExportChinesePreview,
        const Size(280, 900),
        NoteBulkExportFormat.markdown,
        false,
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      final section =
          tester.widget<NoteExportSection>(find.byType(NoteExportSection));
      expect(section.format, format);
      expect(section.saveToFile, saveToFile);
      final originalHint = _hintText(tester);
      expect(originalHint, isNotEmpty);
      final alternate = format == NoteBulkExportFormat.pdf
          ? NoteBulkExportFormat.plainText
          : NoteBulkExportFormat.pdf;
      final chip = find.byKey(ValueKey('note-export-format-${alternate.name}'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      expect(_hintText(tester), isNot(originalHint));
      expect(tester.takeException(), isNull);
      await _capture(tester,
          'export-format-hints-${alternate.name}-${size.width.toInt()}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
