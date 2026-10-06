import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_reader_sections.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_web_links.dart';
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
    this.onOpenUrl,
    this.onCopySelection,
    this.collapsibleSections = false,
    this.sectionToggleLabel,
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
  final NoteWebLinkOpener? onOpenUrl;
  final ValueChanged<NoteTextSelection>? onCopySelection;

  /// Reader-only, temporary folding. Editors, previews and exports use the
  /// original document layout unless the reader explicitly opts in.
  final bool collapsibleSections;
  final String Function(String heading, bool expanded)? sectionToggleLabel;
  final Widget Function(
          String text, List<NoteTextStyleRange> styles, int start, int end)?
      textBuilder;

  @override
  State<NoteDocumentView> createState() => _NoteDocumentViewState();
}

class _NoteDocumentViewState extends State<NoteDocumentView> {
  final Map<int, GlobalKey> _textKeys = {};
  final Set<int> _collapsedSections = {};
  late List<NoteDocumentPart> _parts;
  late NoteReaderDocument _readerDocument;
  VoidCallback? _detachOutline;

  @override
  void initState() {
    super.initState();
    _updateDocument();
    _attachOutline();
  }

  void _updateDocument() {
    final layouts = normalizeNoteImageLayouts(
        widget.imageLayouts, widget.imagePaths, widget.text);
    _parts = noteDocumentParts(widget.text, layouts);
    _readerDocument =
        buildNoteReaderSections(widget.text, widget.styles, layouts);
    _collapsedSections.clear();
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
    if (oldWidget.text != widget.text ||
        !listEquals(oldWidget.styles, widget.styles) ||
        !listEquals(oldWidget.imagePaths, widget.imagePaths) ||
        !listEquals(oldWidget.imageLayouts, widget.imageLayouts)) {
      _updateDocument();
    }
  }

  Future<bool> _jumpTo(int offset) async {
    if (!mounted || offset < 0 || offset > widget.text.length) return false;
    final originalText = widget.text;
    if (widget.collapsibleSections) {
      final section = _readerDocument.sections
          .where((section) =>
              section.containsOffset(offset, textLength: widget.text.length))
          .lastOrNull;
      if (section != null && _collapsedSections.contains(section.start)) {
        setState(() => _collapsedSections.remove(section.start));
      }
    }
    final textParts = _renderableParts.whereType<NoteTextPart>();
    var part = textParts
        .where((part) => part.start <= offset && part.end >= offset)
        .lastOrNull;
    // A heading's separating newline is represented by the row boundary.
    // An end-of-note caret can therefore be just after its final text widget.
    if (part == null && offset == widget.text.length) {
      part = textParts.where((part) => part.start <= offset).lastOrNull;
    }
    if (part == null) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || widget.text != originalText) return false;
    final targetContext = _textKeys[part.start]?.currentContext;
    if (targetContext == null || !targetContext.mounted) return false;
    return revealNoteTextOffset(targetContext, offset - part.start);
  }

  Iterable<NoteDocumentPart> get _renderableParts sync* {
    if (!widget.collapsibleSections) {
      yield* _parts;
      return;
    }
    yield* _readerDocument.introParts;
    for (final section in _readerDocument.sections) {
      yield section.headingPart;
      if (!_collapsedSections.contains(section.start)) yield* section.bodyParts;
    }
  }

  Widget _buildText(NoteTextPart part) => KeyedSubtree(
        key: _textKeys.putIfAbsent(part.start, GlobalKey.new),
        child: widget.textBuilder?.call(
              widget.text.substring(part.start, part.end),
              noteTextStylesForPart(widget.styles, part.start, part.end),
              part.start,
              part.end,
            ) ??
            FormattedNoteText(
              text: widget.text.substring(part.start, part.end),
              styles:
                  noteTextStylesForPart(widget.styles, part.start, part.end),
              style: widget.style,
              selectable: widget.selectable,
              onOpenUrl: widget.onOpenUrl,
              onCopySelection: widget.onCopySelection,
            ),
      );

  List<Widget> _buildParts(Iterable<NoteDocumentPart> parts) => [
        for (final part in parts)
          if (part is NoteTextPart && part.end > part.start)
            _buildText(part)
          else if (part is NoteImagePart)
            NoteImageBlock(
              key: ValueKey('document-image-${part.layout.path}'),
              layout: part.layout,
              imageBuilder: widget.imageBuilder,
              onImageTap: widget.onImageTap == null
                  ? null
                  : () => widget.onImageTap!(part.layout.path),
            ),
      ];

  Widget _buildSection(NoteReaderSection section) {
    final expanded = !_collapsedSections.contains(section.start);
    final heading = Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildText(section.headingPart),
      ),
    );
    final label =
        widget.sectionToggleLabel?.call(section.heading.text, expanded) ??
            '${expanded ? 'Collapse' : 'Expand'} ${section.heading.text}';
    void toggle() => setState(() {
          if (expanded) {
            _collapsedSections.add(section.start);
          } else {
            _collapsedSections.remove(section.start);
          }
        });

    return Column(
      key: ValueKey('note-reader-section-${section.start}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.canCollapse)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 4),
              Semantics(
                key: ValueKey('note-section-state-${section.start}'),
                button: true,
                expanded: expanded,
                label: label,
                onTap: toggle,
                child: ExcludeSemantics(
                  child: IconButton(
                    key: ValueKey('note-section-toggle-${section.start}'),
                    tooltip: label,
                    constraints:
                        const BoxConstraints.tightFor(width: 48, height: 48),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.standard,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      size: 20,
                    ),
                    onPressed: toggle,
                  ),
                ),
              ),
            ],
          )
        else
          heading,
        if (expanded) ..._buildParts(section.bodyParts),
      ],
    );
  }

  @override
  void dispose() {
    _detachOutline?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starts = _renderableParts
        .whereType<NoteTextPart>()
        .map((part) => part.start)
        .toSet();
    _textKeys.removeWhere((start, _) => !starts.contains(start));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.collapsibleSections
          ? [
              ..._buildParts(_readerDocument.introParts),
              for (final section in _readerDocument.sections)
                _buildSection(section),
            ]
          : _buildParts(_parts),
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
