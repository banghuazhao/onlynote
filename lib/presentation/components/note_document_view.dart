import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'formatted_note_text.dart';
import 'note_image_block.dart';

class NoteDocumentView extends StatelessWidget {
  const NoteDocumentView({
    super.key,
    required this.text,
    this.styles = const [],
    this.imagePaths = const [],
    this.imageLayouts = const [],
    this.style,
    this.selectable = true,
    this.onImageTap,
    this.imageBuilder,
    this.textBuilder,
  });
  final String text;
  final List<NoteTextStyleRange> styles;
  final List<String> imagePaths;
  final List<NoteImageLayout> imageLayouts;
  final TextStyle? style;
  final bool selectable;
  final ValueChanged<String>? onImageTap;
  final NoteBlockImageBuilder? imageBuilder;
  final Widget Function(
          String text, List<NoteTextStyleRange> styles, int start, int end)?
      textBuilder;

  @override
  Widget build(BuildContext context) {
    final layouts = normalizeNoteImageLayouts(imageLayouts, imagePaths, text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final part in noteDocumentParts(text, layouts))
          if (part is NoteTextPart && part.end > part.start)
            textBuilder?.call(
                  text.substring(part.start, part.end),
                  noteTextStylesForPart(styles, part.start, part.end),
                  part.start,
                  part.end,
                ) ??
                FormattedNoteText(
                  text: text.substring(part.start, part.end),
                  styles: noteTextStylesForPart(styles, part.start, part.end),
                  style: style,
                  selectable: selectable,
                )
          else if (part is NoteImagePart)
            NoteImageBlock(
              key: ValueKey('document-image-${part.layout.path}'),
              layout: part.layout,
              imageBuilder: imageBuilder,
              onImageTap: onImageTap == null
                  ? null
                  : () => onImageTap!(part.layout.path),
            ),
      ],
    );
  }
}

List<NoteTextStyleRange> noteTextStylesForPart(
  Iterable<NoteTextStyleRange> styles,
  int start,
  int end,
) =>
    [
      for (final style in styles)
        if (style.start < end && style.end > start)
          NoteTextStyleRange(
            start: (style.start - start).clamp(0, end - start),
            end: (style.end - start).clamp(0, end - start),
            kind: style.kind,
          ),
    ];
