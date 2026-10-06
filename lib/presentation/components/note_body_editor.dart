import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'formatted_note_text.dart';
import 'note_document_view.dart';
import 'note_formatting_toolbar.dart';
import 'note_image_block.dart';
import 'paper_note.dart';
import 'simple_formatting_controller.dart';

/// Text remains a single plain document. Small native fields surround photos,
/// forwarding their editing values to the same formatting controller.
class NoteBodyEditor extends StatefulWidget {
  const NoteBodyEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.imagePaths,
    required this.imageLayouts,
    required this.onImageLayoutsChanged,
    required this.onRemoveImage,
    this.autofocus = false,
    this.paperColor,
    this.imageBuilder,
  });

  final SimpleFormattingController controller;
  final FocusNode focusNode;
  final List<String> imagePaths;
  final List<NoteImageLayout> imageLayouts;
  final ValueChanged<List<NoteImageLayout>> onImageLayoutsChanged;
  final ValueChanged<String> onRemoveImage;
  final bool autofocus;
  final Color? paperColor;
  final NoteBlockImageBuilder? imageBuilder;

  @override
  State<NoteBodyEditor> createState() => _NoteBodyEditorState();
}

class _NoteBodyEditorState extends State<NoteBodyEditor> {
  final Map<String, _TextSegment> _segments = {};
  List<NoteImageLayout> _layouts = const [];
  String _lastText = '';
  int _documentRevision = 0;
  String? _activeKey;
  String? _selectedImage;
  bool _dragging = false;
  bool _syncing = false;
  Timer? _autoScrollTimer;
  Offset? _dragPosition;

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    _documentRevision = widget.controller.documentRevision;
    _layouts = normalizeNoteImageLayouts(
        widget.imageLayouts, widget.imagePaths, _lastText);
    widget.controller.addListener(_masterChanged);
    _syncSegments();
  }

  @override
  void didUpdateWidget(NoteBodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_masterChanged);
      widget.controller.addListener(_masterChanged);
      _lastText = widget.controller.text;
      _documentRevision = widget.controller.documentRevision;
    }
    if (!listEquals(oldWidget.imageLayouts, widget.imageLayouts) ||
        !listEquals(oldWidget.imagePaths, widget.imagePaths)) {
      _layouts = normalizeNoteImageLayouts(
          widget.imageLayouts, widget.imagePaths, widget.controller.text);
      if (!widget.imagePaths.contains(_selectedImage)) _selectedImage = null;
    }
    _syncSegments();
  }

  void _masterChanged() {
    if (_syncing || !mounted) return;
    final text = widget.controller.text;
    final documentReplaced =
        _documentRevision != widget.controller.documentRevision;
    _documentRevision = widget.controller.documentRevision;
    if (documentReplaced) {
      _layouts = normalizeNoteImageLayouts(_layouts, widget.imagePaths, text);
    } else if (text != _lastText && _layouts.isNotEmpty) {
      final active = _segments[_activeKey];
      _publishLayouts(rebaseNoteImageLayouts(
        _lastText,
        text,
        _layouts,
        widget.imagePaths,
        editedPartStart: active?.start,
        editedPartEnd: active?.end,
        precedingImagePaths: active?.precedingImagePaths,
      ));
    }
    _lastText = text;
    _syncSegments();
    setState(() {});
  }

  void _publishLayouts(List<NoteImageLayout> layouts) {
    if (listEquals(_layouts, layouts)) return;
    _layouts = layouts;
    widget.onImageLayoutsChanged(layouts);
  }

  /// Keys follow the adjacent photo rather than text offsets, keeping focus and
  /// the IME's composing field alive as preceding text changes length.
  List<({String key, NoteTextPart part, Set<String> precedingImages})>
      _textParts() {
    final parts = noteDocumentParts(widget.controller.text, _layouts);
    final result =
        <({String key, NoteTextPart part, Set<String> precedingImages})>[];
    final precedingImages = <String>{};
    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      if (part is NoteImagePart) precedingImages.add(part.layout.path);
      if (part is! NoteTextPart) continue;
      final following = index + 1 < parts.length ? parts[index + 1] : null;
      result.add((
        key: following is NoteImagePart
            ? 'before:${following.layout.path}'
            : 'end',
        part: part,
        precedingImages: Set.of(precedingImages),
      ));
    }
    return result;
  }

  void _syncSegments() {
    _syncing = true;
    final parts = _textParts();
    if (_activeKey == null) {
      final selection = widget.controller.selection;
      _activeKey = selection.isValid
          ? parts
              .where((item) =>
                  item.part.start <= selection.extentOffset &&
                  item.part.end >= selection.extentOffset)
              .lastOrNull
              ?.key
          : parts.firstOrNull?.key;
    }
    if (_layouts.isNotEmpty && !widget.controller.selection.isValid) {
      widget.controller.selection =
          TextSelection.collapsed(offset: parts.first.part.start);
    }
    for (var index = 0; index < parts.length; index++) {
      final item = parts[index];
      final segment = _segments.putIfAbsent(item.key, () {
        final focus = FocusNode();
        final created = _TextSegment(
          key: item.key,
          focus: focus,
          controller: _PartController(master: widget.controller),
        );
        created.controller.addListener(() => _segmentChanged(created));
        focus.addListener(() {
          if (!focus.hasFocus || _syncing || !mounted) return;
          _activeKey = created.key;
          _forwardSelection(created);
          if (_selectedImage != null) setState(() => _selectedImage = null);
        });
        return created;
      });
      segment.start = item.part.start;
      segment.end = item.part.end;
      segment.precedingImagePaths = item.precedingImages;
      segment.controller.partStart = segment.start;
      final raw = widget.controller.text.substring(segment.start, segment.end);
      segment.hiddenNewline = segment.key != 'end' && raw.endsWith('\n');
      final text =
          segment.hiddenNewline ? raw.substring(0, raw.length - 1) : raw;
      final local = segment.controller.value;
      var selection = local.selection;
      if (_activeKey == segment.key && widget.controller.selection.isValid) {
        final global = widget.controller.selection;
        selection = TextSelection(
          baseOffset: (global.baseOffset - segment.start).clamp(0, text.length),
          extentOffset:
              (global.extentOffset - segment.start).clamp(0, text.length),
          affinity: global.affinity,
          isDirectional: global.isDirectional,
        );
      } else if (selection.isValid) {
        selection = TextSelection(
          baseOffset: selection.baseOffset.clamp(0, text.length),
          extentOffset: selection.extentOffset.clamp(0, text.length),
        );
      }
      var composing = local.composing;
      if (text != local.text) {
        composing = TextRange.empty;
        final global = widget.controller.value.composing;
        if (global.isValid &&
            global.start >= segment.start &&
            global.end <= segment.end) {
          composing = TextRange(
              start: global.start - segment.start,
              end: global.end - segment.start);
        }
      }
      segment.controller.value = TextEditingValue(
          text: text, selection: selection, composing: composing);
      segment.controller.refreshStyles();
    }
    _activeKey ??= parts.firstOrNull?.key;
    // Retire removed fields after their elements unmount, since a text field
    // may still remove its own controller listener during this frame.
    final currentKeys = parts.map((part) => part.key).toSet();
    final retired =
        _segments.keys.where((key) => !currentKeys.contains(key)).toList();
    for (final key in retired) {
      final segment = _segments.remove(key)!;
      WidgetsBinding.instance.addPostFrameCallback((_) => segment.dispose());
      if (_activeKey == key) _activeKey = parts.firstOrNull?.key;
    }
    _syncing = false;
  }

  void _forwardSelection(_TextSegment segment) {
    final selection = segment.controller.selection;
    if (!selection.isValid) return;
    widget.controller.selection = TextSelection(
      baseOffset: segment.start + selection.baseOffset,
      extentOffset: segment.start + selection.extentOffset,
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  void _segmentChanged(_TextSegment segment) {
    if (_syncing || !mounted) return;
    _activeKey = segment.key;
    final body = widget.controller.text;
    final value = segment.controller.value;
    final raw = body.substring(segment.start, segment.end);
    final previous =
        segment.hiddenNewline ? raw.substring(0, raw.length - 1) : raw;
    if (value.text == previous) {
      _forwardSelection(segment);
      return;
    }
    _syncing = true;
    var prefix = body.substring(0, segment.start);
    var inserted = value.text;
    final suffix = body.substring(segment.end);
    // A photo is between paragraphs. The separator is maintained for the
    // writer, including their first keystroke beside an image-only note.
    if (inserted.isNotEmpty &&
        prefix.isNotEmpty &&
        !prefix.endsWith('\n') &&
        _layouts.any((layout) => layout.textOffset == segment.start)) {
      prefix += '\n';
    }
    if (inserted.isNotEmpty &&
        segment.key != 'end' &&
        (segment.hiddenNewline || suffix.isNotEmpty)) {
      inserted += '\n';
    }
    final candidate = '$prefix$inserted$suffix';
    final layouts = rebaseNoteImageLayouts(
        body, candidate, _layouts, widget.imagePaths,
        editedPartStart: segment.start,
        editedPartEnd: segment.end,
        precedingImagePaths: segment.precedingImagePaths);
    _publishLayouts(layouts);
    final selection = value.selection.isValid
        ? TextSelection(
            baseOffset: prefix.length + value.selection.baseOffset,
            extentOffset: prefix.length + value.selection.extentOffset,
            affinity: value.selection.affinity,
            isDirectional: value.selection.isDirectional,
          )
        : TextSelection.collapsed(offset: prefix.length + inserted.length);
    final composing = value.composing.isValid
        ? TextRange(
            start: prefix.length + value.composing.start,
            end: prefix.length + value.composing.end)
        : TextRange.empty;
    widget.controller.applySegmentValue(
        TextEditingValue(
            text: candidate, selection: selection, composing: composing),
        editedPartStart: segment.start,
        editedPartEnd: segment.end - (segment.hiddenNewline ? 1 : 0));
    // Native list continuation can add a bullet to the submitted editing value.
    // Its final document is authoritative for the same image affinities.
    if (widget.controller.text != candidate) {
      _publishLayouts(rebaseNoteImageLayouts(
          candidate, widget.controller.text, _layouts, widget.imagePaths,
          editedPartStart: prefix.length,
          editedPartEnd: prefix.length + inserted.length,
          precedingImagePaths: segment.precedingImagePaths));
    }
    _lastText = widget.controller.text;
    _syncing = false;
    _syncSegments();
    setState(() {});
  }

  void _changeImage(NoteImageLayout changed) {
    final updated = [
      for (final layout in _layouts)
        layout.path == changed.path ? changed : layout
    ];
    _publishLayouts(normalizeNoteImageLayouts(
        updated, widget.imagePaths, widget.controller.text));
    _syncSegments();
    setState(() {});
  }

  void _moveImage(String path, int offset, {int? relativeTo}) {
    final index = _layouts.indexWhere((layout) => layout.path == path);
    if (index < 0) return;
    final updated = [..._layouts];
    final layout = updated.removeAt(index).copyWith(textOffset: offset);
    final destination = relativeTo?.clamp(0, updated.length) ?? updated.length;
    updated.insert(destination, layout);
    _publishLayouts(normalizeNoteImageLayouts(
        updated, widget.imagePaths, widget.controller.text));
    _syncSegments();
    setState(() {});
  }

  void _moveOne(String path, int direction) {
    final displayOrder = noteDocumentParts(widget.controller.text, _layouts)
        .whereType<NoteImagePart>()
        .map((part) => part.layout)
        .toList();
    final index = displayOrder.indexWhere((layout) => layout.path == path);
    if (index < 0) return;
    final layout = displayOrder[index];
    final offsets = noteImageInsertionOffsets(widget.controller.text);
    _layouts = displayOrder;
    if (direction < 0) {
      if (index > 0 && _layouts[index - 1].textOffset == layout.textOffset) {
        _moveImage(path, layout.textOffset, relativeTo: index - 1);
      } else {
        final earlier =
            offsets.where((offset) => offset < layout.textOffset).lastOrNull;
        if (earlier != null) _moveImage(path, earlier, relativeTo: 0);
      }
    } else {
      if (index + 1 < _layouts.length &&
          _layouts[index + 1].textOffset == layout.textOffset) {
        _moveImage(path, layout.textOffset, relativeTo: index + 1);
      } else {
        final later =
            offsets.where((offset) => offset > layout.textOffset).firstOrNull;
        if (later != null) _moveImage(path, later);
      }
    }
  }

  void _prepareFormattingSelection() {
    final segment = _segments[_activeKey];
    if (segment == null || segment.controller.text.isNotEmpty) return;
    final body = widget.controller.text;
    final start = segment.start;
    final needsPreviousSeparator =
        start > 0 && body.codeUnitAt(start - 1) != 10;
    final needsFollowingSeparator =
        start < body.length && body.codeUnitAt(start) != 10;
    if (!needsPreviousSeparator && !needsFollowingSeparator) return;
    _syncing = true;
    final candidate = body.replaceRange(start, start, '\n');
    _publishLayouts(rebaseNoteImageLayouts(
        body, candidate, _layouts, widget.imagePaths,
        editedPartStart: start,
        editedPartEnd: start,
        precedingImagePaths: segment.precedingImagePaths));
    widget.controller.applySegmentValue(
        TextEditingValue(
            text: candidate,
            selection: TextSelection.collapsed(
                offset: start + (needsPreviousSeparator ? 1 : 0))),
        editedPartStart: start,
        editedPartEnd: start);
    _lastText = widget.controller.text;
    _syncing = false;
    _syncSegments();
    setState(() {});
  }

  Widget _textField(_TextSegment segment, int index) => RuledWritingArea(
        paperColor: widget.paperColor ?? AppColors.parchment,
        lineHeight: MediaQuery.textScalerOf(context)
                .scale(AppTypography.formText.fontSize ?? 17) *
            (AppTypography.formText.height ?? 1.55),
        child: TextField(
          key: ValueKey('note-body-${segment.key}'),
          controller: segment.controller,
          focusNode: segment.focus,
          autofocus: widget.autofocus && index == 0,
          style: AppTypography.formText,
          strutStyle: StrutStyle.fromTextStyle(AppTypography.formText,
              forceStrutHeight: true),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onTap: () {
            _activeKey = segment.key;
            if (_selectedImage != null) setState(() => _selectedImage = null);
          },
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: widget.controller.text.isEmpty && index == 0
                ? S.of(context).Type_something
                : null,
            hintStyle: AppTypography.formText
                .copyWith(color: AppColors.ink.withValues(alpha: .4)),
            filled: false,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          minLines: 1,
          maxLines: index == 0 ? 100 : 99,
        ),
      );

  Widget _dropTarget(int offset,
          {String? beforeImagePath, bool afterImages = false}) =>
      DragTarget<NoteImageDrag>(
        key: ValueKey(beforeImagePath != null
            ? 'image-drop-$offset-before-$beforeImagePath'
            : afterImages
                ? 'image-drop-$offset-after'
                : 'image-drop-$offset'),
        onAcceptWithDetails: (details) {
          if (beforeImagePath == details.data.path) return;
          final ordered = noteDocumentParts(widget.controller.text, _layouts)
              .whereType<NoteImagePart>()
              .map((part) => part.layout)
              .toList();
          _layouts = ordered;
          final remaining = ordered
              .where((layout) => layout.path != details.data.path)
              .toList();
          var destination = beforeImagePath == null
              ? remaining.indexWhere((layout) => afterImages
                  ? layout.textOffset > offset
                  : layout.textOffset >= offset)
              : remaining
                  .indexWhere((layout) => layout.path == beforeImagePath);
          if (destination < 0) destination = remaining.length;
          _moveImage(details.data.path, offset, relativeTo: destination);
        },
        builder: (context, candidates, _) => AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(vertical: 5),
          height: 36,
          decoration: BoxDecoration(
            color:
                AppColors.ink.withValues(alpha: candidates.isEmpty ? .03 : .12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.ink
                    .withValues(alpha: candidates.isEmpty ? .15 : .8)),
          ),
          child: Center(
              child: Text(S.of(context).Image_Drop_Here,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink))),
        ),
      );

  List<Widget> _dragDocument() {
    final body = widget.controller.text;
    final offsets = noteImageInsertionOffsets(body);
    final result = <Widget>[];
    for (var index = 0; index < offsets.length; index++) {
      final offset = offsets[index];
      result.add(_dropTarget(offset));
      final images =
          _layouts.where((layout) => layout.textOffset == offset).toList();
      for (var photoIndex = 0; photoIndex < images.length; photoIndex++) {
        result.add(_image(images[photoIndex]));
        result.add(_dropTarget(offset,
            beforeImagePath: photoIndex + 1 < images.length
                ? images[photoIndex + 1].path
                : null,
            afterImages: photoIndex + 1 == images.length));
      }
      if (index + 1 < offsets.length) {
        final end = offsets[index + 1];
        if (end > offset) {
          result.add(FormattedNoteText(
            text: body.substring(offset, end),
            styles:
                noteTextStylesForPart(widget.controller.styles, offset, end),
            selectable: false,
          ));
        }
      }
    }
    return result;
  }

  Widget _image(NoteImageLayout layout) => NoteImageBlock(
        key: ValueKey('editor-image-${layout.path}'),
        layout: layout,
        selected: _selectedImage == layout.path,
        imageBuilder: widget.imageBuilder,
        onSelected: () {
          FocusScope.of(context).unfocus();
          setState(() => _selectedImage = layout.path);
        },
        onLayoutChanged: _changeImage,
        onDragStarted: () {
          FocusScope.of(context).unfocus();
          setState(() => _dragging = true);
          _autoScrollTimer?.cancel();
          _autoScrollTimer = Timer.periodic(
              const Duration(milliseconds: 16), (_) => _autoScroll());
        },
        onDragPosition: (details) => _dragPosition = details.globalPosition,
        onDragEnded: () {
          _autoScrollTimer?.cancel();
          _autoScrollTimer = null;
          _dragPosition = null;
          if (mounted) setState(() => _dragging = false);
        },
        onMoveEarlier: () => _moveOne(layout.path, -1),
        onMoveLater: () => _moveOne(layout.path, 1),
        onRemove: () => widget.onRemoveImage(layout.path),
      );

  void _autoScroll() {
    if (!mounted || _dragPosition == null) return;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    final box = scrollable.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final position = scrollable.position;
    if (!position.hasContentDimensions) return;
    final y = box.globalToLocal(_dragPosition!).dy;
    const edge = 64.0;
    final delta = y < edge
        ? -((edge - y) / edge).clamp(0.0, 1.0) * 12
        : y > box.size.height - edge
            ? ((y - box.size.height + edge) / edge).clamp(0.0, 1.0) * 12
            : 0.0;
    if (delta == 0) return;
    position.jumpTo((position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final active = _segments[_activeKey];
    if (_layouts.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NoteFormattingToolbar(
            controller: widget.controller, focusNode: widget.focusNode),
        const SizedBox(height: 8),
        RuledWritingArea(
          paperColor: widget.paperColor ?? AppColors.parchment,
          lineHeight: MediaQuery.textScalerOf(context)
                  .scale(AppTypography.formText.fontSize ?? 17) *
              (AppTypography.formText.height ?? 1.55),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            style: AppTypography.formText,
            strutStyle: StrutStyle.fromTextStyle(AppTypography.formText,
                forceStrutHeight: true),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: S.of(context).Type_something,
              hintStyle: AppTypography.formText
                  .copyWith(color: AppColors.ink.withValues(alpha: .4)),
              filled: false,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            minLines: 6,
            maxLines: 100,
          ),
        ),
      ]);
    }
    var textIndex = 0;
    final textParts = _textParts();
    final children = <Widget>[];
    if (_dragging) {
      children.addAll(_dragDocument());
    } else {
      for (final part in noteDocumentParts(widget.controller.text, _layouts)) {
        if (part is NoteImagePart) {
          children.add(_image(part.layout));
        } else if (part is NoteTextPart) {
          final segment = _segments[textParts[textIndex].key]!;
          children.add(_textField(segment, textIndex));
          textIndex++;
        }
      }
    }
    return TapRegion(
      onTapOutside: (_) {
        if (_selectedImage != null && !_dragging) {
          setState(() => _selectedImage = null);
        }
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NoteFormattingToolbar(
            controller: widget.controller,
            focusNode: active?.focus ?? widget.focusNode,
            beforeApply: _prepareFormattingSelection),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    widget.controller.removeListener(_masterChanged);
    for (final segment in _segments.values) {
      segment.dispose();
    }
    super.dispose();
  }
}

class _TextSegment {
  _TextSegment(
      {required this.key, required this.controller, required this.focus});
  final String key;
  final _PartController controller;
  final FocusNode focus;
  Set<String> precedingImagePaths = {};
  bool hiddenNewline = false;
  int start = 0;
  int end = 0;
  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _PartController extends TextEditingController {
  _PartController({required this.master});
  final SimpleFormattingController master;
  int partStart = 0;
  void refreshStyles() => notifyListeners();

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final base = style ?? const TextStyle();
    return TextSpan(
        style: base,
        children: buildNoteTextSpans(
          text: text,
          styles: noteTextStylesForPart(
              master.styles, partStart, partStart + text.length),
          baseStyle: base,
          composing: withComposing ? value.composing : TextRange.empty,
        ));
  }
}
