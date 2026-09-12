import 'package:flutter/material.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/presentation/theme/colors.dart';

class SearchHighlight extends StatelessWidget {
  const SearchHighlight(this.text,
      {super.key,
      this.query = '',
      this.style,
      this.maxLines,
      this.overflow = TextOverflow.ellipsis});
  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final matches = searchPattern(query)?.allMatches(text).toList() ?? [];
    if (matches.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final spans = <TextSpan>[];
    var end = 0;
    for (final match in matches) {
      if (match.start > end) {
        spans.add(TextSpan(text: text.substring(end, match.start)));
      }
      spans.add(TextSpan(
          text: text.substring(match.start, match.end),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFDC72),
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          )));
      end = match.end;
    }
    if (end < text.length) spans.add(TextSpan(text: text.substring(end)));
    return Text.rich(TextSpan(children: spans),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: text);
  }
}
