import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_find.dart';
import 'note_find_bar.dart';
import 'note_find_preview.dart';
import 'paper_note.dart';

@Preview(name: 'Find in note — phone', size: Size(390, 760))
Widget noteFindPhonePreview() => _preview();

@Preview(name: 'Find in note — narrow Chinese', size: Size(320, 760))
Widget noteFindChinesePreview() => _preview(chinese: true);

@Preview(
    name: 'Find in note — dark tablet',
    size: Size(760, 900),
    brightness: Brightness.dark)
Widget noteFindTabletPreview() => _preview(dark: true);

Widget _preview({bool chinese = false, bool dark = false}) => MaterialApp(
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: _FindPreview(chinese: chinese),
    );

class _FindPreview extends StatefulWidget {
  const _FindPreview({required this.chinese});
  final bool chinese;
  @override
  State<_FindPreview> createState() => _FindPreviewState();
}

class _FindPreviewState extends State<_FindPreview> {
  final _controller = NoteSearchController();
  late final Note _note;
  bool _finding = true;
  @override
  void initState() {
    super.initState();
    final title = widget.chinese ? '週末散步' : 'Weekend walk';
    final body = widget.chinese
        ? '週末散步\n帶上零食，沿著海岸散步。\n找一條安靜的步道。'
        : 'Weekend walk\nPack snacks and walk along the coast.\nFind a quiet trail.';
    _note = Note(title: title, description: body, todo: [
      Todo(id: 'map', title: widget.chinese ? '查找散步路線' : 'Find a walking route')
    ], imagePaths: [
      'coast'
    ], imageLayouts: [
      NoteImageLayout(
          path: 'coast', textOffset: title.length + 1, aspectRatio: 1.6)
    ], textStyles: [
      NoteTextStyleRange(
          start: 0, end: title.length, kind: NoteTextStyleKind.heading)
    ]);
    _controller.setFields(noteSearchFields(_note));
    _controller.setQuery(widget.chinese ? '散步' : 'walk');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(S.of(context).Find_In_Note), actions: [
          if (!_finding)
            IconButton(
                onPressed: () => setState(() => _finding = true),
                icon: const Icon(Icons.search))
        ]),
        body: Column(children: [
          if (_finding)
            NoteFindBar(
                controller: _controller,
                hintText: S.of(context).Find_In_Note,
                noMatchesText: S.of(context).Find_No_Matches,
                previousTooltip: S.of(context).Find_Previous,
                nextTooltip: S.of(context).Find_Next,
                closeTooltip: S.of(context).Find_Close,
                onClose: () {
                  _controller.setQuery('');
                  setState(() => _finding = false);
                }),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PaperNote(
                    color: const Color(0xFFFFF3CD),
                    kind: PaperNoteKind.sheet,
                    child: NoteFindPreview(
                        note: _note,
                        controller: _controller,
                        imageBuilder: (_, path) => const DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                              Color(0xFF8BAAB7),
                              Color(0xFFDAD9B8)
                            ])),
                            child: Center(
                                child: Icon(Icons.landscape,
                                    color: Color(0xFF456667), size: 80)))),
                  ))),
        ]),
      );
}
