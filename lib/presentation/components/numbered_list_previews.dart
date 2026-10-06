import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/formatted_note_text.dart';
import 'package:onlynote/presentation/components/note_formatting_toolbar.dart';
import 'package:onlynote/presentation/components/simple_formatting_controller.dart';
import 'package:onlynote/presentation/theme/theme.dart';

@Preview(name: 'Numbered list — light', size: Size(390, 560))
Widget numberedListLightPreview() => _numberedListPreview();

@Preview(
  name: 'Numbered list — dark and large text',
  size: Size(320, 640),
  brightness: Brightness.dark,
)
Widget numberedListDarkPreview() =>
    _numberedListPreview(dark: true, textScale: 1.6);

Widget _numberedListPreview({bool dark = false, double textScale = 1}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const _NumberedListPreview(),
    );

/// This editable fixture only uses text and local widget state, so the preview
/// can run on the web without persistence, photo plugins or native APIs.
class _NumberedListPreview extends StatefulWidget {
  const _NumberedListPreview();

  @override
  State<_NumberedListPreview> createState() => _NumberedListPreviewState();
}

class _NumberedListPreviewState extends State<_NumberedListPreview> {
  final _focus = FocusNode();
  final _controller = SimpleFormattingController(
    text: 'Weekend errands\n1. 買茶 🍵\n2. Pick up bread\n3. ',
    styles: const [
      NoteTextStyleRange(start: 0, end: 15, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(start: 28, end: 41, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 28, end: 41, kind: NoteTextStyleKind.highlight),
    ],
  );

  @override
  void initState() {
    super.initState();
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NoteFormattingToolbar(
                controller: _controller,
                focusNode: _focus,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _focus,
                maxLines: null,
                minLines: 5,
                style: const TextStyle(fontSize: 17, height: 1.55),
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
                  style: const TextStyle(fontSize: 17, height: 1.55),
                ),
              ),
            ],
          ),
        ),
      );
}
