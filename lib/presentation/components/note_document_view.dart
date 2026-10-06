import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'formatted_note_text.dart';
import 'note_image_block.dart';
import 'note_outline_navigation_controller.dart';

class NoteDocumentView extends StatefulWidget {
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
    this.outlineController,
  });
  final String text;
  final List<NoteTextStyleRange> styles;
  final List<String> imagePaths;
  final List<NoteImageLayout> imageLayouts;
  final TextStyle? style;
  final bool selectable;
  final ValueChanged<String>? onImageTap;
  final NoteBlockImageBuilder? imageBuilder;
  final NoteOutlineNavigationController? outlineController;
  final Widget Function(
          String text, List<NoteTextStyleRange> styles, int start, int end)?
      textBuilder;

  @override
  State<NoteDocumentView> createState() => _NoteDocumentViewState();
}

class _NoteDocumentViewState extends State<NoteDocumentView> {
  final Map<int, GlobalKey> _textKeys = {};
  VoidCallback? _detachOutline;

  @override
  void initState() {
    super.initState();
    _attachOutline();
  }

  void _attachOutline() {
    _detachOutline?.call();
    _detachOutline =
        widget.outlineController?.attach(owner: this, jump: _jumpTo);
  }

  @override
  void didUpdateWidget(NoteDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outlineController != widget.outlineController) {
      _attachOutline();
    }
  }

  Future<bool> _jumpTo(int offset) async {
    if (!mounted || offset > widget.text.length) return false;
    final layouts = normalizeNoteImageLayouts(
        widget.imageLayouts, widget.imagePaths, widget.text);
    final part = noteDocumentParts(widget.text, layouts)
        .whereType<NoteTextPart>()
        .where((part) => part.start <= offset && part.end >= offset)
        .lastOrNull;
    if (part == null) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;
    final targetContext = _textKeys[part.start]?.currentContext;
    if (targetContext == null || !targetContext.mounted) return false;
    return revealNoteTextOffset(targetContext, offset - part.start);
  }

  @override
  void dispose() {
    _detachOutline?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layouts = normalizeNoteImageLayouts(
        widget.imageLayouts, widget.imagePaths, widget.text);
    final parts = noteDocumentParts(widget.text, layouts);
    final starts =
        parts.whereType<NoteTextPart>().map((part) => part.start).toSet();
    _textKeys.removeWhere((start, _) => !starts.contains(start));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final part in parts)
          if (part is NoteTextPart && part.end > part.start)
            KeyedSubtree(
              key: _textKeys.putIfAbsent(part.start, GlobalKey.new),
              child: widget.textBuilder?.call(
                    widget.text.substring(part.start, part.end),
                    noteTextStylesForPart(widget.styles, part.start, part.end),
                    part.start,
                    part.end,
                  ) ??
                  FormattedNoteText(
                    text: widget.text.substring(part.start, part.end),
                    styles: noteTextStylesForPart(
                        widget.styles, part.start, part.end),
                    style: widget.style,
                    selectable: widget.selectable,
                  ),
            )
          else if (part is NoteImagePart)
            NoteImageBlock(
              key: ValueKey('document-image-${part.layout.path}'),
              layout: part.layout,
              imageBuilder: widget.imageBuilder,
              onImageTap: widget.onImageTap == null
                  ? null
                  : () => widget.onImageTap!(part.layout.path),
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
