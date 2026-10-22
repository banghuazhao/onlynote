import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_dates.dart';

import 'app_sheet.dart';
import 'note_history_version_tile.dart';

@Preview(
    name: 'History transcript — light', group: 'Note', size: Size(390, 620))
Widget noteHistoryTranscriptLightPreview() => const _HistoryTranscriptPreview();

@Preview(
  name: 'History transcript — dark',
  group: 'Note',
  size: Size(390, 620),
  brightness: Brightness.dark,
)
Widget noteHistoryTranscriptDarkPreview() =>
    const _HistoryTranscriptPreview(dark: true);

@Preview(
  name: 'History transcript — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget noteHistoryTranscriptChinesePreview() =>
    const _HistoryTranscriptPreview(chinese: true, textScale: 2);

/// Flat metadata and local selection keep this preview free of audio/storage I/O.
class _HistoryTranscriptPreview extends StatefulWidget {
  const _HistoryTranscriptPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_HistoryTranscriptPreview> createState() =>
      _HistoryTranscriptPreviewState();
}

class _HistoryTranscriptPreviewState extends State<_HistoryTranscriptPreview> {
  bool _selected = false;
  static const _transcript =
      'Recorded thought 茶😀 — a longer first line to recognize this version\n'
      'Keep the reviewed transcript ready for the next release. 第二行記錄。';

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
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(builder: (context) {
            final strings = S.of(context);
            final dateLabel = noteReaderDateTimeLabel(
                dateTime: DateTime(2026, 10, 13, 10),
                locale: Localizations.localeOf(context).toString(),
                use24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
            final counts = Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(strings.History_Recordings(1)),
            );
            return Align(
              alignment: Alignment.bottomCenter,
              child: AppSheet(
                title:
                    _selected ? strings.History_Preview : strings.History_Title,
                child: _selected
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextButton.icon(
                              key: const ValueKey('history-preview-back'),
                              onPressed: () =>
                                  setState(() => _selected = false),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(strings.History_Title),
                            ),
                            const SelectableText(_transcript),
                            counts,
                          ],
                        ),
                      )
                    : NoteHistoryVersionTile(
                        key: const ValueKey(
                            'history-version-transcript-preview'),
                        title: _transcript.split('\n').first,
                        dateLabel: dateLabel,
                        snippet: _transcript,
                        mediaCounts: counts,
                        onPressed: () => setState(() => _selected = true),
                      ),
              ),
            );
          }),
        ),
      );
}
