import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_outline.dart';

import 'note_outline_sheet.dart';

@Preview(name: 'Outline', group: 'Note', size: Size(390, 570))
Widget noteOutlinePreview() => const _OutlinePreview();

@Preview(name: 'Outline — dark', group: 'Note', size: Size(390, 570))
Widget noteOutlineDarkPreview() =>
    const _OutlinePreview(brightness: Brightness.dark);

@Preview(
    name: 'Outline — large Chinese text', group: 'Note', size: Size(320, 640))
Widget noteOutlineLargeTextPreview() =>
    const _OutlinePreview(chinese: true, textScale: 2);

class _OutlinePreview extends StatefulWidget {
  const _OutlinePreview({
    this.chinese = false,
    this.textScale = 1,
    this.brightness = Brightness.light,
  });
  final bool chinese;
  final double textScale;
  final Brightness brightness;

  @override
  State<_OutlinePreview> createState() => _OutlinePreviewState();
}

class _OutlinePreviewState extends State<_OutlinePreview> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF685947),
          brightness: widget.brightness,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(widget.textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: NoteOutlineSheet(
              entries: [
                NoteOutlineEntry(
                    text: widget.chinese ? '今天的想法與計劃' : 'Ideas for today',
                    start: 0,
                    end: 16),
                NoteOutlineEntry(
                    text: widget.chinese ? '需要記住的重要細節' : 'Details to remember',
                    start: 200,
                    end: 219),
                NoteOutlineEntry(
                    text: widget.chinese
                        ? '下一步與本週需要完成的事情'
                        : 'Next steps for the week',
                    start: 400,
                    end: 422),
              ],
              currentOffset: _offset,
              onEntrySelected: (entry) => setState(() => _offset = entry.start),
            ),
          ),
        ),
      );
}
