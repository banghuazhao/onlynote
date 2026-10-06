import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'note_body_editor.dart';
import 'paper_note.dart';
import 'simple_formatting_controller.dart';

@Preview(name: 'Movable photos — phone', size: Size(390, 760))
Widget imageBlocksPhonePreview() => _preview();

@Preview(name: 'Movable photos — narrow Chinese', size: Size(320, 760))
Widget imageBlocksChinesePreview() => _preview(chinese: true);

@Preview(
    name: 'Movable photos — dark tablet',
    size: Size(760, 900),
    brightness: Brightness.dark)
Widget imageBlocksTabletPreview() => _preview(dark: true);

Widget _preview({bool chinese = false, bool dark = false}) => MaterialApp(
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: _ImagePreview(chinese: chinese),
    );

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({required this.chinese});
  final bool chinese;
  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  late final SimpleFormattingController _controller;
  final _focus = FocusNode();
  late List<NoteImageLayout> _layouts;
  List<String> _paths = ['mountains'];

  @override
  void initState() {
    super.initState();
    final heading = widget.chinese ? '週末散步' : 'Weekend walk';
    _controller = SimpleFormattingController(
        text:
            '$heading\n${widget.chinese ? '帶上零食。\n找一條安靜的步道。' : 'Pack snacks.\nFind a quiet walking trail.'}');
    _layouts = [
      NoteImageLayout(
          path: 'mountains', textOffset: heading.length + 1, aspectRatio: 1.5)
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DeskSurface(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: PaperNote(
                  color: AppColors.parchment,
                  kind: PaperNoteKind.sheet,
                  child: NoteBodyEditor(
                    controller: _controller,
                    focusNode: _focus,
                    imagePaths: _paths,
                    imageLayouts: _layouts,
                    onImageLayoutsChanged: (layouts) =>
                        setState(() => _layouts = layouts),
                    onRemoveImage: (path) => setState(() {
                      _paths = _paths.where((item) => item != path).toList();
                      _layouts =
                          _layouts.where((item) => item.path != path).toList();
                    }),
                    imageBuilder: previewNoteBlockImage,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Native-free visual fixture; the editor itself remains fully interactive.
Widget previewNoteBlockImage(BuildContext context, String path) => DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF92B2BD), Color(0xFFD7D6BD), Color(0xFF637E67)],
        ),
      ),
      child: const Center(
          child: Icon(Icons.landscape_rounded,
              size: 84, color: Color(0xFF46685F))),
    );
