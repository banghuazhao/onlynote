import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_position_store.dart';

import 'note_document_view.dart';
import 'note_reader_position_controller.dart';

@Preview(
    name: 'Resume reading after reflow', group: 'Note', size: Size(390, 700))
Widget noteResumePreview({String? fontFamily}) =>
    _ResumePreview(fontFamily: fontFamily);

@Preview(
  name: 'Resume reading — dark and large text',
  group: 'Note',
  size: Size(320, 700),
  brightness: Brightness.dark,
)
Widget noteResumeLargePreview({String? fontFamily}) =>
    _ResumePreview(dark: true, large: true, fontFamily: fontFamily);

class _ResumePreview extends StatefulWidget {
  const _ResumePreview(
      {this.fontFamily, this.dark = false, this.large = false});
  final String? fontFamily;
  final bool dark;
  final bool large;

  @override
  State<_ResumePreview> createState() => _ResumePreviewState();
}

/// Fixtures use an injected photo and in-memory snapshot, with no device APIs.
class _ResumePreviewState extends State<_ResumePreview> {
  final _reader = NoteReaderPositionController();
  final _scroll = ScrollController();
  NoteReadingPosition? _saved;
  var _reflow = false;
  var _message = 'Read, save your place, then change the layout.';

  String get _text => '${_reflow ? 'An opening paragraph was inserted.\n' : ''}'
      'Weekend notes\n'
      '${'Walk along the coast, look for birds and stop for coffee.\n' * 16}'
      'Remember this place\n'
      'Bring water, a warm layer and a camera 👩🏽‍💻.\n'
      '${'Leave time to enjoy the view and take a slower route home.\n' * 20}';

  Future<void> _restore() async {
    if (_saved == null) return;
    final restored = await _reader.restore(_saved!);
    if (mounted) {
      setState(() => _message = restored
          ? 'Restored reading position'
          : 'Reading position was unavailable');
    }
  }

  @override
  void dispose() {
    _reader.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final heading = text.indexOf('Weekend notes');
    final target = text.indexOf('Remember this place');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: ThemeData(
        brightness: widget.dark ? Brightness.dark : Brightness.light,
        colorSchemeSeed: const Color(0xFF685947),
        fontFamily: widget.fontFamily,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(_reflow || widget.large ? 1.65 : 1),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(_message),
                  Wrap(
                    children: [
                      TextButton(
                        key: const ValueKey('resume-preview-deep'),
                        onPressed: () => _reader.restore(
                            NoteReadingPosition.capture(
                                text: text, offset: target)),
                        child: const Text('Read later paragraph'),
                      ),
                      TextButton(
                        key: const ValueKey('resume-preview-save'),
                        onPressed: () => setState(() {
                          _saved = _reader.capture();
                          _message = 'Reading position saved';
                        }),
                        child: const Text('Save place'),
                      ),
                      TextButton(
                        key: const ValueKey('resume-preview-reflow'),
                        onPressed: () {
                          _scroll.jumpTo(0);
                          setState(() => _reflow = !_reflow);
                        },
                        child: const Text('Change layout'),
                      ),
                      TextButton(
                        key: const ValueKey('resume-preview-restore'),
                        onPressed: _saved == null ? null : _restore,
                        child: const Text('Resume'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                child: NoteDocumentView(
                  text: text,
                  styles: [
                    NoteTextStyleRange(
                        start: heading,
                        end: heading + 'Weekend notes'.length,
                        kind: NoteTextStyleKind.heading),
                    NoteTextStyleRange(
                        start: target,
                        end: target + 'Remember this place'.length,
                        kind: NoteTextStyleKind.heading),
                  ],
                  style: TextStyle(
                      fontFamily: widget.fontFamily, fontSize: 17, height: 1.5),
                  readerPositionController: _reader,
                  collapsibleSections: true,
                  imagePaths: const ['coast'],
                  imageLayouts: [
                    NoteImageLayout(
                      path: 'coast',
                      textOffset: heading + 'Weekend notes\n'.length,
                      aspectRatio: _reflow ? 1 : 2,
                    ),
                  ],
                  imageBuilder: (_, __) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFF879E9D),
                        Color(0xFFC8C6A9),
                      ]),
                    ),
                    child:
                        Center(child: Icon(Icons.landscape_rounded, size: 64)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
