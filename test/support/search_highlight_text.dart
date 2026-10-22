import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Visible highlighted runs beneath a result row, including title and excerpt.
List<String> highlightedSearchText(WidgetTester tester, Finder result) {
  final highlights = <String>[];
  void visit(InlineSpan span) {
    if (span is! TextSpan) return;
    if (span.style?.backgroundColor != null && span.text != null) {
      highlights.add(span.text!);
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      visit(child);
    }
  }

  for (final text in tester.widgetList<Text>(
      find.descendant(of: result, matching: find.byType(Text)))) {
    if (text.textSpan case final InlineSpan span) visit(span);
  }
  return highlights;
}
