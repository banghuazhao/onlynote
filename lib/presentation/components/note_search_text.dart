import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:onlynote/services/note_web_links.dart';
import 'formatted_note_text.dart';

/// Styled search highlights with an exact glyph target, even when one text
/// widget contains hundreds of paragraphs below an inline photo.
class NoteSearchText extends StatefulWidget {
  const NoteSearchText({
    super.key,
    required this.controller,
    required this.fieldId,
    required this.text,
    this.textOffset = 0,
    this.styles = const [],
    this.style,
    this.selectable = true,
    this.enableWebLinks = true,
    this.onOpenUrl,
    this.onMatchTap,
    this.onCopySelection,
  });
  final NoteSearchController controller;
  final String fieldId;
  final String text;
  final int textOffset;
  final List<NoteTextStyleRange> styles;
  final TextStyle? style;
  final bool selectable;
  final bool enableWebLinks;
  final NoteWebLinkOpener? onOpenUrl;
  final ValueChanged<NoteSearchMatch>? onMatchTap;
  final ValueChanged<NoteTextSelection>? onCopySelection;

  @override
  State<NoteSearchText> createState() => _NoteSearchTextState();
}

class _NoteSearchTextState extends State<NoteSearchText> {
  final _textKey = GlobalKey();
  VoidCallback? _unregister;
  final Map<NoteSearchMatch, TapGestureRecognizer> _matchRecognizers = {};

  @override
  void initState() {
    super.initState();
    _register();
  }

  void _register() {
    _unregister?.call();
    _unregister = widget.controller.registerTarget(
      owner: this,
      fieldId: widget.fieldId,
      start: widget.textOffset,
      end: widget.textOffset + widget.text.length,
      reveal: _reveal,
    );
  }

  @override
  void didUpdateWidget(covariant NoteSearchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.fieldId != widget.fieldId ||
        oldWidget.textOffset != widget.textOffset ||
        oldWidget.text.length != widget.text.length) {
      _register();
    }
  }

  void _reveal(NoteSearchMatch match) {
    if (!mounted) return;
    RenderParagraph? paragraph;
    void visit(RenderObject object) {
      if (object is RenderParagraph) {
        paragraph = object;
        return;
      }
      object.visitChildren(visit);
    }

    final root = _textKey.currentContext?.findRenderObject();
    if (root == null) return;
    visit(root);
    final text = paragraph;
    if (text == null || !text.hasSize) return;
    final boxes = text.getBoxesForSelection(TextSelection(
      baseOffset:
          (match.start - widget.textOffset).clamp(0, widget.text.length),
      extentOffset:
          (match.end - widget.textOffset).clamp(0, widget.text.length),
    ));
    if (boxes.isEmpty) return;
    final rect = boxes.first.toRect().inflate(16);
    text.showOnScreen(
      rect: rect,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _unregister?.call();
    for (final recognizer in _matchRecognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _updateMatchRecognizers(List<NoteSearchMatch> matches) {
    final wanted =
        widget.onMatchTap == null ? <NoteSearchMatch>{} : matches.toSet();
    for (final match in _matchRecognizers.keys.toList()) {
      if (!wanted.contains(match)) {
        _matchRecognizers.remove(match)!.dispose();
      }
    }
    for (final match in wanted) {
      _matchRecognizers.putIfAbsent(
        match,
        () => TapGestureRecognizer()
          ..onTap = () => widget.onMatchTap?.call(match),
      );
    }
  }

  Widget _readingText(List<TextSpan> spans, TextStyle style,
          {required bool selectable}) =>
      NoteReadingText(
        text: widget.text,
        spans: spans,
        style: style,
        selectable: selectable,
        enableWebLinks: widget.enableWebLinks && widget.selectable,
        onOpenUrl: widget.onOpenUrl,
        textKey: _textKey,
        textStyles: widget.styles,
        onCopySelection: widget.onCopySelection,
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final style = widget.style ?? DefaultTextStyle.of(context).style;
          final formatted = buildNoteTextSpans(
              text: widget.text, styles: widget.styles, baseStyle: style);
          if (widget.controller.query.trim().isEmpty) {
            _updateMatchRecognizers(const []);
            return _readingText(formatted, style,
                selectable: widget.selectable);
          }
          final matches = widget.controller.matches
              .where((match) =>
                  match.fieldId == widget.fieldId &&
                  match.start < widget.textOffset + widget.text.length &&
                  match.end > widget.textOffset)
              .toList();
          _updateMatchRecognizers(matches);
          final result = <TextSpan>[];
          var runStart = 0;
          var matchIndex = 0;
          for (final span in formatted) {
            final text = span.text ?? '';
            final runEnd = runStart + text.length;
            final points = <int>{runStart, runEnd};
            while (matchIndex < matches.length &&
                matches[matchIndex].end - widget.textOffset <= runStart) {
              matchIndex++;
            }
            for (var index = matchIndex; index < matches.length; index++) {
              final match = matches[index];
              if (match.start - widget.textOffset >= runEnd) break;
              points.add(
                  (match.start - widget.textOffset).clamp(runStart, runEnd));
              points
                  .add((match.end - widget.textOffset).clamp(runStart, runEnd));
            }
            final sorted = points.toList()..sort();
            for (var index = 0; index < sorted.length - 1; index++) {
              final start = sorted[index];
              final end = sorted[index + 1];
              while (matchIndex < matches.length &&
                  matches[matchIndex].end - widget.textOffset <= start) {
                matchIndex++;
              }
              final match =
                  matchIndex < matches.length ? matches[matchIndex] : null;
              final highlighted = match != null &&
                  match.start - widget.textOffset <= start &&
                  match.end - widget.textOffset >= end;
              final active =
                  highlighted && match == widget.controller.currentMatch;
              result.add(TextSpan(
                  text: text.substring(start - runStart, end - runStart),
                  style: !highlighted
                      ? span.style
                      : span.style?.copyWith(
                          backgroundColor: active
                              ? const Color(0xFFF2BD54)
                              : const Color(0xFFFFE7A0),
                          color: const Color(0xFF29251C)),
                  recognizer: highlighted ? _matchRecognizers[match] : null));
            }
            runStart = runEnd;
          }
          // A RenderParagraph exposes exact selection boxes. Closing find
          // restores normal text selection and copying.
          return _readingText(result, style, selectable: false);
        },
      );
}
