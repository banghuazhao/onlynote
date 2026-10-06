import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';

import 'note_document_view.dart';
import 'note_outline_navigation_controller.dart';

@Preview(name: 'Reader sections — phone', group: 'Note', size: Size(390, 700))
Widget noteReaderSectionsPreview({String? fontFamily}) =>
    _ReaderPreview(fontFamily: fontFamily);

@Preview(
  name: 'Reader sections — dark',
  group: 'Note',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget noteReaderSectionsDarkPreview({String? fontFamily}) =>
    _ReaderPreview(dark: true, fontFamily: fontFamily);

@Preview(
  name: 'Reader sections — Chinese 2× narrow',
  group: 'Note',
  size: Size(150, 700),
)
Widget noteReaderSectionsChinesePreview({String? fontFamily}) =>
    _ReaderPreview(chinese: true, textScale: 2, fontFamily: fontFamily);

class _ReaderPreview extends StatefulWidget {
  const _ReaderPreview({
    this.chinese = false,
    this.dark = false,
    this.textScale = 1,
    this.fontFamily,
  });

  final bool chinese;
  final bool dark;
  final double textScale;
  final String? fontFamily;

  @override
  State<_ReaderPreview> createState() => _ReaderPreviewState();
}

/// The photo and URL opener are local fixtures. No native APIs are invoked.
class _ReaderPreviewState extends State<_ReaderPreview> {
  final _outline = NoteOutlineNavigationController();
  late final String _text;
  late final List<NoteTextStyleRange> _styles;
  late final int _secondHeading;
  String? _message;

  @override
  void initState() {
    super.initState();
    final first = widget.chinese ? '週末散步' : 'Weekend walk';
    final second = widget.chinese ? '帶上這些東西' : 'What to bring';
    _text = widget.chinese
        ? '這週記得留些時間給自己。\n$first\n'
            '沿著海邊走一走，看看春天的風景。\n'
            '路線：https://example.com/trails\n$second\n'
            '水、零食和一件暖外套。\n下次可以邀請朋友一起來。'
        : 'Make some time for yourself this week.\n$first\n'
            'Follow the coast and enjoy the spring scenery.\n'
            'Trail map: https://example.com/trails\n$second\n'
            'Water, snacks and a warm layer.\nInvite a friend next time.';
    _secondHeading = _text.indexOf(second);
    _styles = [
      for (final heading in [first, second])
        NoteTextStyleRange(
          start: _text.indexOf(heading),
          end: _text.indexOf(heading) + heading.length,
          kind: NoteTextStyleKind.heading,
        ),
    ];
  }

  @override
  void dispose() {
    _outline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          brightness: widget.dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
          fontFamily: widget.fontFamily,
          fontFamilyFallback:
              widget.fontFamily == null ? null : ['DroidSansFallback'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor:
              widget.dark ? const Color(0xFF201F1B) : const Color(0xFFE8E0D0),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: () => _outline.jumpTo(_secondHeading),
                  child: Text(widget.chinese ? '下一節' : 'Jump to next section'),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.dark
                        ? const Color(0xFF302E28)
                        : const Color(0xFFFFF9EA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
                    child: NoteDocumentView(
                      text: _text,
                      styles: _styles,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        fontFamily: widget.fontFamily,
                        fontFamilyFallback: widget.fontFamily == null
                            ? null
                            : ['DroidSansFallback'],
                        color: widget.dark
                            ? const Color(0xFFF2EBDD)
                            : const Color(0xFF302A22),
                      ),
                      imagePaths: const ['coast'],
                      imageLayouts: [
                        NoteImageLayout(
                          path: 'coast',
                          textOffset: _secondHeading,
                          aspectRatio: 1.8,
                        ),
                      ],
                      imageBuilder: _previewPhoto,
                      collapsibleSections: true,
                      outlineController: _outline,
                      sectionToggleLabel: (heading, expanded) => widget.chinese
                          ? '${expanded ? '收起' : '展開'}「$heading」'
                          : '${expanded ? 'Collapse' : 'Expand'} $heading',
                      onOpenUrl: (uri) async {
                        setState(() => _message = uri.toString());
                        return true;
                      },
                      onCopySelection: (_) => setState(
                          () => _message = widget.chinese ? '已複製' : 'Copied'),
                    ),
                  ),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_message!),
                  ),
              ],
            ),
          ),
        ),
      );
}

Widget _previewPhoto(BuildContext context, String path) => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DAFBB), Color(0xFFB9D4CD), Color(0xFFE0D4B1)],
        ),
      ),
      child: Center(
        child: Icon(Icons.waves_rounded, size: 36, color: Color(0xFF5A7C84)),
      ),
    );
