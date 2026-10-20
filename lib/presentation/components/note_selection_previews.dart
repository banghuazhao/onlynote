import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_copy_destination_sheet.dart';
import 'package:onlynote/presentation/components/note_selection_menu.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_text_format.dart';

List<Note> previewCopyDestinations() => [
      Note(
        id: 'garden',
        title: 'Garden journal',
        description: 'Plant the spring herbs beside the kitchen window.',
      ),
      Note(
        id: 'trip',
        title: 'Weekend trip',
        description: 'Take the coastal path and stop at the market.',
        voiceMemos: [
          VoiceMemo(
            id: 'trip-recording',
            path: 'note_audio/unavailable-trip.m4a',
            durationMs: 1000,
            createdAt: DateTime(2026, 10, 20),
            transcript: '${List.filled(30, 'Earlier travel ideas. ').join()}'
                'Reserve the cabin [2026] and bring 茶😀 for the journey.',
          ),
        ],
      ),
      Note(
        id: 'shopping',
        title: 'Shopping list',
        todo: [Todo(title: 'Coffee'), Todo(title: 'Fresh bread')],
      ),
    ];

@Preview(name: 'Copy selected text destination', size: Size(390, 740))
Widget copySelectionDestinationPreview({ThemeData? theme}) =>
    _destinationPreview(theme ?? AppTheme.light);

@Preview(
    name: 'Copy selected text destination dark',
    size: Size(390, 740),
    brightness: Brightness.dark)
Widget copySelectionDestinationDarkPreview({ThemeData? theme}) =>
    _destinationPreview(theme ?? AppTheme.dark);

@Preview(
    name: 'Copy selected text destination Chinese narrow 2×',
    size: Size(280, 700))
Widget copySelectionDestinationChinesePreview({ThemeData? theme}) =>
    _destinationPreview(theme ?? AppTheme.light, chinese: true, textScale: 2);

Widget _destinationPreview(ThemeData theme,
        {bool chinese = false, double textScale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
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
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: NoteCopyDestinationSheet(notes: previewCopyDestinations()),
      ),
    );

@Preview(name: 'Select formatted text to copy', size: Size(390, 500))
Widget copyFormattedSelectionPreview() => const _SelectionPreview();

class _SelectionPreview extends StatefulWidget {
  const _SelectionPreview();

  @override
  State<_SelectionPreview> createState() => _SelectionPreviewState();
}

class _SelectionPreviewState extends State<_SelectionPreview> {
  NoteTextSelection? _copied;
  static const _text =
      'Ideas for the weekend\nVisit the coast and bring a book.';
  static const _styles = [
    NoteTextStyleRange(start: 0, end: 21, kind: NoteTextStyleKind.heading),
    NoteTextStyleRange(start: 28, end: 37, kind: NoteTextStyleKind.bold),
    NoteTextStyleRange(start: 42, end: 54, kind: NoteTextStyleKind.highlight),
  ];

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          backgroundColor: AppColors.parchment,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Select a passage, then choose Copy to note.'),
                const SizedBox(height: 20),
                SelectableText.rich(
                  TextSpan(
                    children: buildNoteTextSpans(text: _text, styles: _styles),
                  ),
                  contextMenuBuilder: (context, state) =>
                      buildNoteSelectionContextMenu(
                    context,
                    state,
                    textStyles: _styles,
                    onCopySelection: (selection) =>
                        setState(() => _copied = selection),
                  ),
                ),
                if (_copied != null) ...[
                  const SizedBox(height: 24),
                  const Text('Captured selection'),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: buildNoteTextSpans(
                          text: _copied!.text, styles: _copied!.textStyles),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
