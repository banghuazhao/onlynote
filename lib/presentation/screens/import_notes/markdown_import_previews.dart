import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/markdown_import.dart';

import 'markdown_import_content.dart';

@Preview(
    name: 'Review Markdown import',
    group: 'Markdown import',
    size: Size(390, 740))
Widget markdownImportPreview() => const MarkdownImportPreview();

@Preview(
    name: 'Review Markdown import dark',
    group: 'Markdown import',
    size: Size(390, 740))
Widget markdownImportDarkPreview() => const MarkdownImportPreview(dark: true);

@Preview(
    name: 'Large Chinese import review',
    group: 'Markdown import',
    size: Size(320, 600))
Widget markdownImportLargePreview() =>
    const MarkdownImportPreview(locale: Locale('zh', 'HK'), scale: 2);

class MarkdownImportPreview extends StatefulWidget {
  const MarkdownImportPreview(
      {super.key,
      this.dark = false,
      this.locale = const Locale('en'),
      this.scale = 1});
  final bool dark;
  final Locale locale;
  final double scale;
  @override
  State<MarkdownImportPreview> createState() => _MarkdownImportPreviewState();
}

class _MarkdownImportPreviewState extends State<MarkdownImportPreview> {
  final _batch = MarkdownImportBatch(documents: [
    MarkdownImportParser.parse(
        '# Weekend plans\n\n## Saturday\nVisit the **market** and meet friends.\n\n---\n\n- [ ] Bring a bag\n- [x] Book the train',
        sourceName: 'weekend.md'),
    MarkdownImportParser.parse(
        '# Reading notes\n\nA useful [source](https://example.com) to return to.',
        sourceName: 'research/reading.md'),
  ]);
  Set<int> _selected = {0, 1};
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _previewTheme(widget.dark),
      locale: widget.locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(widget.scale)),
          child: child!),
      home: Scaffold(
        appBar: AppBar(
            title: Builder(
                builder: (context) => Text(S.of(context).Markdown_Import))),
        body: DeskSurface(
            child: MarkdownImportContent(
                batch: _batch,
                selected: _selected,
                onSelected: (index, value) => setState(() =>
                    value ? _selected.add(index) : _selected.remove(index)),
                onToggleAll: () => setState(
                    () => _selected = _selected.length == 2 ? {} : {0, 1}))),
      ));
}

ThemeData _previewTheme(bool dark) {
  final base = dark ? AppTheme.dark : AppTheme.light;
  final text = base.textTheme
      .apply(fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']);
  return base.copyWith(
    textTheme: text,
    primaryTextTheme: base.primaryTextTheme
        .apply(fontFamily: 'Roboto', fontFamilyFallback: ['DroidSansFallback']),
    appBarTheme: base.appBarTheme.copyWith(titleTextStyle: text.titleLarge),
    textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style
            ?.copyWith(textStyle: WidgetStatePropertyAll(text.labelLarge))),
  );
}
