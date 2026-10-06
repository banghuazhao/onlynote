import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_replace.dart';
import 'note_find_bar.dart';
import 'note_find_preview.dart';
import 'paper_note.dart';

@Preview(name: 'Find and replace with Undo', size: Size(390, 760))
Widget noteReplacePhonePreview() => _preview();

@Preview(name: 'Replace — narrow Chinese large text', size: Size(320, 860))
Widget noteReplaceChinesePreview() => _preview(chinese: true, scale: 1.5);

@Preview(
    name: 'Replace — dark tablet',
    size: Size(760, 900),
    brightness: Brightness.dark)
Widget noteReplaceTabletPreview() => _preview(dark: true);

Widget _preview({bool chinese = false, bool dark = false, double scale = 1}) =>
    MaterialApp(
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: _ReplacePreview(chinese: chinese),
    );

class _ReplacePreview extends StatefulWidget {
  const _ReplacePreview({required this.chinese});
  final bool chinese;

  @override
  State<_ReplacePreview> createState() => _ReplacePreviewState();
}

class _ReplacePreviewState extends State<_ReplacePreview> {
  final _controller = NoteSearchController();
  late Note _note;
  Note? _undo;
  bool _finding = true;

  @override
  void initState() {
    super.initState();
    final heading = widget.chinese ? '週末散步' : 'Weekend walk';
    _note = Note(
      title: heading,
      description: widget.chinese
          ? '$heading\n沿著海岸散步。\n散步後買一杯咖啡。'
          : '$heading\nWalk along the coast.\nCoffee after the walk.',
      todo: [
        Todo(id: 'route', title: widget.chinese ? '查找散步路線' : 'Plan the walk')
      ],
      textStyles: [
        NoteTextStyleRange(
            start: 0, end: heading.length, kind: NoteTextStyleKind.heading)
      ],
      imagePaths: ['coast'],
      imageLayouts: [
        NoteImageLayout(
            path: 'coast', textOffset: heading.length + 1, aspectRatio: 1.8)
      ],
    );
    _controller.setFields(noteSearchFields(_note));
    _controller.setQuery(widget.chinese ? '散步' : 'walk');
  }

  void _replace(String text, {NoteSearchMatch? match}) {
    final result = replaceNoteText(_note,
        query: _controller.query,
        replacement: text,
        match: match,
        expectedFields: _controller.fields);
    if (result.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.failure == NoteReplaceFailure.lengthLimit
              ? S.of(context).Find_Replace_Limit
              : S.of(context).Find_Replace_Changed)));
      return;
    }
    if (!result.changed) return;
    setState(() {
      _undo = _note;
      _note = result.note;
    });
    _controller.setFields(noteSearchFields(_note));
  }

  void _restore() {
    if (_undo == null) return;
    setState(() {
      _note = _undo!;
      _undo = null;
    });
    _controller.setFields(noteSearchFields(_note));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(S.of(context).Find_In_Note), actions: [
          IconButton(
              tooltip: S.of(context).Undo,
              onPressed: _undo == null ? null : _restore,
              icon: const Icon(Icons.undo_rounded)),
          if (!_finding)
            IconButton(
                onPressed: () => setState(() => _finding = true),
                icon: const Icon(Icons.search_rounded)),
        ]),
        body: SingleChildScrollView(
          child: Column(children: [
            if (_finding)
              NoteFindBar(
                controller: _controller,
                hintText: S.of(context).Find_In_Note,
                noMatchesText: S.of(context).Find_No_Matches,
                previousTooltip: S.of(context).Find_Previous,
                nextTooltip: S.of(context).Find_Next,
                closeTooltip: S.of(context).Find_Close,
                replaceToggleLabel: S.of(context).Find_Replace,
                replaceHintText: S.of(context).Find_Replace_With,
                replaceLabel: S.of(context).Find_Replace,
                replaceAllLabel: S.of(context).Find_Replace_All,
                initialReplaceVisible: true,
                onReplace: (match, text) => _replace(text, match: match),
                onReplaceAll: _replace,
                onClose: () => setState(() => _finding = false),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PaperNote(
                color: const Color(0xFFFFF3CD),
                kind: PaperNoteKind.sheet,
                child: NoteFindPreview(
                  note: _note,
                  controller: _controller,
                  imageBuilder: (_, __) => const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Color(0xFF8BAAB7), Color(0xFFDAD9B8)])),
                      child: Center(
                          child: Icon(Icons.landscape,
                              color: Color(0xFF456667), size: 80))),
                ),
              ),
            ),
          ]),
        ),
      );
}
