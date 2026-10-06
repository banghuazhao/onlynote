import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_find.dart';
import 'formatted_note_text.dart';
import 'note_search_text.dart';
import 'paper_note.dart';

@Preview(name: 'Website links — reader', size: Size(390, 640))
Widget noteWebLinksPreview() => _preview();

@Preview(
  name: 'Website links — dark reader',
  size: Size(390, 640),
  brightness: Brightness.dark,
)
Widget noteWebLinksDarkPreview() => _preview(dark: true);

@Preview(name: 'Website links — Chinese large text', size: Size(320, 680))
Widget noteWebLinksChinesePreview() => _preview(chinese: true, textScale: 2);

@Preview(name: 'Website links — find emphasis', size: Size(390, 640))
Widget noteWebLinksFindPreview() => _preview(finding: true);

Widget _preview({
  bool dark = false,
  bool chinese = false,
  bool finding = false,
  double textScale = 1,
}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: _WebLinksPreview(chinese: chinese, finding: finding),
    );

/// Every tap is handled locally; previews never invoke a native launcher.
class _WebLinksPreview extends StatefulWidget {
  const _WebLinksPreview({required this.chinese, required this.finding});
  final bool chinese;
  final bool finding;

  @override
  State<_WebLinksPreview> createState() => _WebLinksPreviewState();
}

class _WebLinksPreviewState extends State<_WebLinksPreview> {
  final _find = NoteSearchController();
  late final String _text;
  late final List<NoteTextStyleRange> _styles;
  Uri? _opened;

  @override
  void initState() {
    super.initState();
    final heading = widget.chinese ? '週末計劃' : 'Weekend plans';
    _text = widget.chinese
        ? '$heading\n\n查看步道路線：\nhttps://example.com/trails\n\n'
            '帶上零食，然後看看www.example.org。'
        : '$heading\n\nCheck the trail map:\nhttps://example.com/trails\n\n'
            'Pack snacks and a warm layer.\nMore ideas at www.example.org.';
    final urlStart = _text.indexOf('https://');
    _styles = [
      NoteTextStyleRange(
          start: 0, end: heading.length, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(
          start: urlStart + 8,
          end: urlStart + 19,
          kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(
          start: urlStart,
          end: urlStart + 'https://example.com/trails'.length,
          kind: NoteTextStyleKind.highlight),
    ];
    _find.setFields([NoteSearchField('body', _text)]);
    if (widget.finding) _find.setQuery('example');
  }

  Future<bool> _open(Uri uri) async {
    setState(() => _opened = uri);
    return true;
  }

  @override
  void dispose() {
    _find.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style =
        TextStyle(fontSize: 17, height: 1.55, color: scheme.onSurface);
    return Scaffold(
      body: DeskSurface(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PaperNote(
            kind: PaperNoteKind.sheet,
            color: scheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.finding)
                  NoteSearchText(
                    controller: _find,
                    fieldId: 'body',
                    text: _text,
                    styles: _styles,
                    style: style,
                    onOpenUrl: _open,
                  )
                else
                  FormattedNoteText(
                    text: _text,
                    styles: _styles,
                    style: style,
                    onOpenUrl: _open,
                  ),
                if (_opened != null) ...[
                  const SizedBox(height: 24),
                  Text(_opened!.toString(),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
