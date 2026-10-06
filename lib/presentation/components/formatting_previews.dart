import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_formatting_toolbar.dart';
import 'package:onlynote/presentation/components/paper_note.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/theme.dart';

@Preview(name: 'Simple note formatting — light', size: Size(390, 640))
Widget noteFormattingLightPreview() => _formattingPreview();

@Preview(
  name: 'Simple note formatting — dark',
  size: Size(390, 640),
  brightness: Brightness.dark,
)
Widget noteFormattingDarkPreview() =>
    _formattingPreview(brightness: Brightness.dark);

@Preview(name: 'Simple formatting — Chinese large text', size: Size(320, 640))
Widget noteFormattingChinesePreview() =>
    _formattingPreview(chinese: true, textScale: 2);

Widget _formattingPreview({
  Brightness brightness = Brightness.light,
  bool chinese = false,
  double textScale = 1,
}) =>
    MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
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
      home: _FormattingPreview(chinese: chinese),
    );

/// Editable fixture with no native APIs or persistence.
class _FormattingPreview extends StatefulWidget {
  const _FormattingPreview({required this.chinese});

  final bool chinese;

  @override
  State<_FormattingPreview> createState() => _FormattingPreviewState();
}

class _FormattingPreviewState extends State<_FormattingPreview> {
  late final SimpleFormattingController _controller;
  final _focusNode = FocusNode();
  static const _textStyle = TextStyle(
    fontSize: 17,
    height: 1.55,
    color: AppColors.ink,
  );

  @override
  void initState() {
    super.initState();
    final heading = widget.chinese ? '週末計劃' : 'Weekend plans';
    final emphasis =
        widget.chinese ? '帶上零食和外套。' : 'Pack snacks and a warm layer.';
    final bullets = widget.chinese
        ? '• 找一條安靜的步道\n• 帶上相機'
        : '• Find a quiet walking trail\n• Bring the camera';
    final text = '$heading\n$emphasis\n$bullets';
    _controller = SimpleFormattingController(text: text, styles: [
      NoteTextStyleRange(
        start: 0,
        end: heading.length,
        kind: NoteTextStyleKind.heading,
      ),
      NoteTextStyleRange(
        start: heading.length + 1,
        end: heading.length + 1 + emphasis.length,
        kind: NoteTextStyleKind.bold,
      ),
    ]);
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DeskSurface(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PaperNote(
              color: AppColors.parchment,
              kind: PaperNoteKind.sheet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NoteFormattingToolbar(
                    controller: _controller,
                    focusNode: _focusNode,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: _textStyle,
                    maxLines: null,
                    minLines: 4,
                    decoration: const InputDecoration.collapsed(hintText: ''),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => FormattedNoteText(
                      text: _controller.text,
                      styles: _controller.styles,
                      style: _textStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
