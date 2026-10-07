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
    // Styling part of an accent or joined emoji can split its shaping run.
    // Resolve all matches against one set of grapheme boundaries, then merge
    // matches inside the same cluster so the original text is drawn once.
    final boundaries = [0];
    for (final character in text.characters) {
      boundaries.add(boundaries.last + character.length);
    }
    final ranges = <({int start, int end})>[];
    var startBoundary = 0;
    var endBoundary = 0;
    for (final match in matches) {
      while (startBoundary + 1 < boundaries.length &&
          boundaries[startBoundary + 1] <= match.start) {
        startBoundary++;
      }
      if (endBoundary < startBoundary) endBoundary = startBoundary;
      while (boundaries[endBoundary] < match.end) {
        endBoundary++;
      }
      final start = boundaries[startBoundary];
      final end = boundaries[endBoundary];
      if (ranges.isNotEmpty && start < ranges.last.end) {
        final previous = ranges.removeLast();
        ranges.add((start: previous.start, end: end));
      } else {
        ranges.add((start: start, end: end));
      }
    }
    final spans = <TextSpan>[];
    var end = 0;
    for (final range in ranges) {
      if (range.start > end) {
        spans.add(TextSpan(text: text.substring(end, range.start)));
      }
      spans.add(TextSpan(
          text: text.substring(range.start, range.end),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFDC72),
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          )));
      end = range.end;
    }
    if (end < text.length) spans.add(TextSpan(text: text.substring(end)));
    return Text.rich(TextSpan(children: spans),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: text);
  }
}
