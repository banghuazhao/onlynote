import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/typography.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:onlynote/services/note_web_links.dart';

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
    this.onOpenUrl,
  });

  final String text;
  final List<NoteTextStyleRange> styles;
  final TextStyle? style;
  final bool selectable;
  final NoteWebLinkOpener? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? AppTypography.formText;
    return NoteReadingText(
      text: text,
      spans: buildNoteTextSpans(
        text: text,
        styles: styles,
        baseStyle: baseStyle,
      ),
      style: baseStyle,
      selectable: selectable,
      enableWebLinks: selectable,
      onOpenUrl: onOpenUrl,
    );
  }
}

/// Adds website interaction after saved formatting and find highlights have
/// been applied. One recognizer per URL survives style and query rebuilds.
class NoteReadingText extends StatefulWidget {
  const NoteReadingText({
    super.key,
    required this.text,
    required this.spans,
    required this.style,
    this.selectable = true,
    this.enableWebLinks = true,
    this.onOpenUrl,
    this.textKey,
  });

  final String text;
  final List<TextSpan> spans;
  final TextStyle style;
  final bool selectable;
  final bool enableWebLinks;
  final NoteWebLinkOpener? onOpenUrl;
  final Key? textKey;

  @override
  State<NoteReadingText> createState() => _NoteReadingTextState();
}

class _NoteReadingTextState extends State<NoteReadingText> {
  List<NoteWebLink> _links = const [];
  final Map<NoteWebLink, TapGestureRecognizer> _recognizers = {};

  @override
  void initState() {
    super.initState();
    _updateLinks();
  }

  @override
  void didUpdateWidget(covariant NoteReadingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.enableWebLinks != widget.enableWebLinks) {
      _updateLinks();
    }
  }

  void _updateLinks() {
    _links = widget.enableWebLinks ? findNoteWebLinks(widget.text) : const [];
    final wanted = _links.toSet();
    for (final link in _recognizers.keys.toList()) {
      if (!wanted.contains(link)) _recognizers.remove(link)!.dispose();
    }
    for (final link in _links) {
      _recognizers.putIfAbsent(
        link,
        () => TapGestureRecognizer()..onTap = () => _open(link.uri),
      );
    }
  }

  Future<void> _open(Uri uri) async {
    var opened = false;
    try {
      opened = await (widget.onOpenUrl ?? openNoteWebLink)(uri);
    } catch (_) {
      // Injected openers may also report platform failures by throwing.
    }
    if (opened || !mounted) return;
    final message = S.maybeOf(context)?.Web_Link_Open_Failed;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (message == null || messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  List<TextSpan> _linkedSpans() {
    if (_links.isEmpty) return widget.spans;
    final result = <TextSpan>[];
    var runStart = 0;
    var linkIndex = 0;
    for (final span in widget.spans) {
      final text = span.text ?? '';
      final runEnd = runStart + text.length;
      var start = runStart;
      while (start < runEnd) {
        while (linkIndex < _links.length && _links[linkIndex].end <= start) {
          linkIndex++;
        }
        final link = linkIndex < _links.length ? _links[linkIndex] : null;
        final linked = link != null && link.start <= start;
        final end = link == null
            ? runEnd
            : (linked ? link.end : link.start).clamp(start, runEnd);
        final recognizer =
            span.recognizer ?? (linked ? _recognizers[link] : null);
        result.add(TextSpan(
          text: text.substring(start - runStart, end - runStart),
          style: linked
              ? (span.style ?? const TextStyle()).copyWith(
                  decoration: TextDecoration.combine([
                    if (span.style?.decoration != null) span.style!.decoration!,
                    TextDecoration.underline,
                  ]),
                )
              : span.style,
          recognizer: recognizer,
          mouseCursor:
              recognizer == null ? span.mouseCursor : SystemMouseCursors.click,
          onEnter: span.onEnter,
          onExit: span.onExit,
          locale: span.locale,
          spellOut: span.spellOut,
        ));
        start = end;
      }
      runStart = runEnd;
    }
    return result;
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = _linkedSpans();
    final span = TextSpan(style: widget.style, children: spans);
    return widget.selectable
        ? SelectableText.rich(span, key: widget.textKey)
        : Text.rich(
            span,
            key: widget.textKey,
            // A whole-text label preserves the previous export behavior.
            // Interactive fragments retain their individual accessible actions.
            semanticsLabel: spans.every((span) => span.recognizer == null)
                ? widget.text
                : null,
          );
  }
}
