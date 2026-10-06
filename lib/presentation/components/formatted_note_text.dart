import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/note_text_format.dart';

/// The same spans are used by the reader and the editable writing field.
TextSpan formattedNoteTextSpan(
  String text,
  List<NoteTextStyleRange> styles,
  TextStyle style,
) =>
    TextSpan(
      style: style,
      children: buildNoteTextSpans(
        text: text,
        styles: styles,
        baseStyle: style,
      ),
    );

class FormattedNoteText extends StatelessWidget {
  const FormattedNoteText({
    super.key,
    required this.text,
    this.styles = const [],
    this.style,
    this.selectable = true,
  });

  final String text;
  final List<NoteTextStyleRange> styles;
  final TextStyle? style;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final span =
        formattedNoteTextSpan(text, styles, style ?? AppTypography.formText);
    if (selectable) return SelectableText.rich(span);
    return Text.rich(span, semanticsLabel: text);
  }
}
