import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_position_store.dart';
import 'package:onlynote/services/note_reader_sections.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_web_links.dart';
import 'formatted_note_text.dart';
import 'note_divider_block.dart';
import 'note_image_block.dart';
import 'note_outline_navigation_controller.dart';
import 'note_reader_position_controller.dart';

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
    this.readerPositionController,
    this.onOpenUrl,
    this.onCopySelection,
    this.onAddSelectionToChecklist,
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
  final NoteReaderPositionController? readerPositionController;
  final NoteWebLinkOpener? onOpenUrl;
  final ValueChanged<NoteTextSelection>? onCopySelection;
  final ValueChanged<NoteTextSelection>? onAddSelectionToChecklist;

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
  final Map<String, GlobalKey> _imageKeys = {};
  final Set<int> _collapsedSections = {};
  late List<NoteDocumentPart> _parts;
  late NoteReaderDocument _readerDocument;
  VoidCallback? _detachOutline;
  VoidCallback? _detachPosition;

  @override
  void initState() {
    super.initState();
    _updateDocument();
    _attachOutline();
    _attachPosition();
  }

  void _updateDocument() {
    final layouts = normalizeNoteImageLayouts(
        widget.imageLayouts, widget.imagePaths, widget.text);
    _parts = noteDocumentParts(widget.text, layouts, styles: widget.styles);
    _readerDocument =
        buildNoteReaderSections(widget.text, widget.styles, layouts);
    _collapsedSections.clear();
  }

  void _attachOutline() {
    _detachOutline?.call();
    _detachOutline =
        widget.outlineController?.attach(owner: this, jump: _jumpTo);
  }

  void _attachPosition() {
    _detachPosition?.call();
    _detachPosition = widget.readerPositionController?.attach(
      owner: this,
      capture: _capturePosition,
      restore: _restorePosition,
    );
  }

  @override
  void didUpdateWidget(NoteDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outlineController != widget.outlineController) {
      _attachOutline();
    }
    if (oldWidget.readerPositionController != widget.readerPositionController) {
      _attachPosition();
    }
    if (oldWidget.text != widget.text ||
        !listEquals(oldWidget.styles, widget.styles) ||
        !listEquals(oldWidget.imagePaths, widget.imagePaths) ||
        !listEquals(oldWidget.imageLayouts, widget.imageLayouts)) {
      _updateDocument();
    }
  }

  Future<bool> _jumpTo(int offset) async {
    widget.readerPositionController?.cancelPendingRestore();
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

  NoteReadingPosition? _capturePosition() {
    if (!mounted) return null;
    final viewport = NoteReaderViewport.fromContext(context);
    if (viewport == null) return null;
    final top = viewport.bounds.top;
    NoteReadingPosition? closest;
    var distance = double.infinity;
    final direction = Directionality.of(context);
    for (final part in _renderableParts) {
      if (part is NoteTextPart && part.end > part.start) {
        final partContext = _textKeys[part.start]?.currentContext;
        if (partContext == null) continue;
        final glyph = NoteReaderGlyph.fromContext(partContext);
        if (glyph == null || glyph.length == 0) continue;
        final localText = widget.text.substring(part.start, part.end);
        final offset = clampNotePositionOffset(
            localText, glyph.positionNearTop(top, direction));
        final rect = glyph.globalRectForOffset(offset);
        if (rect == null) continue;
        final gap = (rect.top - top).abs();
        if (gap < distance) {
          distance = gap;
          closest = NoteReadingPosition.capture(
            text: widget.text,
            offset: part.start + offset,
            leadingDisplacement: rect.top - top,
          );
        }
      } else if (part is NoteImagePart) {
        final render =
            _imageKeys[part.layout.path]?.currentContext?.findRenderObject();
        if (render is! RenderBox || !render.hasSize) continue;
        final rect = render.localToGlobal(Offset.zero) & render.size;
        if (rect.height <= 0) continue;
        final fraction = ((top - rect.top) / rect.height).clamp(0.0, 1.0);
        final imageTop = rect.top + rect.height * fraction;
        final gap = (imageTop - top).abs();
        if (gap < distance) {
          distance = gap;
          closest = NoteReadingPosition.capture(
            text: widget.text,
            offset: part.layout.textOffset,
            imagePath: part.layout.path,
            imageFraction: fraction,
            leadingDisplacement: imageTop - top,
          );
        }
      }
    }
    return closest;
  }

  Future<bool> _restorePosition(
      NoteReadingPosition position, bool Function() canRestore) async {
    if (!mounted || !canRestore()) return false;
    final originalText = widget.text;
    final offset = position.resolve(widget.text);
    final image = _parts
        .whereType<NoteImagePart>()
        .where((part) => part.layout.path == position.imagePath)
        .firstOrNull;
    if (widget.collapsibleSections) {
      // A photo anchored at the next heading belongs to the preceding body.
      // Inspect actual section ownership instead of treating its text offset
      // as a glyph within the next section.
      final section = image == null
          ? _readerDocument.sections
              .where((section) => section.containsOffset(offset,
                  textLength: widget.text.length))
              .lastOrNull
          : _readerDocument.sections
              .where((section) => section.bodyParts.any((part) =>
                  part is NoteImagePart &&
                  part.layout.path == image.layout.path))
              .firstOrNull;
      if (section != null && _collapsedSections.contains(section.start)) {
        setState(() => _collapsedSections.remove(section.start));
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || widget.text != originalText || !canRestore()) return false;
    final viewport = NoteReaderViewport.fromContext(context);
    if (viewport == null) return false;
    if (image != null) {
      final render =
          _imageKeys[image.layout.path]?.currentContext?.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        final top = render.localToGlobal(Offset.zero).dy +
            render.size.height * position.imageFraction;
        return viewport.restoreTop(top, position.leadingDisplacement);
      }
    }
    final textParts = _renderableParts.whereType<NoteTextPart>();
    var part = textParts
        .where((part) => part.start <= offset && part.end >= offset)
        .lastOrNull;
    part ??= textParts.where((part) => part.start <= offset).lastOrNull;
    part ??= textParts.firstOrNull;
    final partContext =
        part == null ? null : _textKeys[part.start]?.currentContext;
    if (part == null || partContext == null || !partContext.mounted) {
      return false;
    }
    final glyph = NoteReaderGlyph.fromContext(partContext);
    final rect = glyph?.globalRectForOffset(offset - part.start);
    if (rect == null || !canRestore()) return false;
    return viewport.restoreTop(rect.top, position.leadingDisplacement);
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
              onAddSelectionToChecklist: widget.onAddSelectionToChecklist,
            ),
      );

  List<Widget> _buildParts(Iterable<NoteDocumentPart> parts) => [
        for (final part in parts)
          if (part is NoteTextPart && part.end > part.start)
            _buildText(part)
          else if (part is NoteDividerPart)
            NoteDividerBlock(key: ValueKey('document-divider-${part.start}'))
          else if (part is NoteImagePart)
            KeyedSubtree(
              key: _imageKeys.putIfAbsent(part.layout.path, GlobalKey.new),
              child: NoteImageBlock(
                key: ValueKey('document-image-${part.layout.path}'),
                layout: part.layout,
                imageBuilder: widget.imageBuilder,
                onImageTap: widget.onImageTap == null
                    ? null
                    : () => widget.onImageTap!(part.layout.path),
              ),
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
    void toggle() {
      widget.readerPositionController?.cancelPendingRestore();
      setState(() {
        if (expanded) {
          _collapsedSections.add(section.start);
        } else {
          _collapsedSections.remove(section.start);
        }
      });
    }

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
    _detachPosition?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starts = _renderableParts
        .whereType<NoteTextPart>()
        .map((part) => part.start)
        .toSet();
    _textKeys.removeWhere((start, _) => !starts.contains(start));
    final images = _renderableParts
        .whereType<NoteImagePart>()
        .map((part) => part.layout.path)
        .toSet();
    _imageKeys.removeWhere((path, _) => !images.contains(path));
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
            anchorId: style.anchorId,
          ),
    ];
