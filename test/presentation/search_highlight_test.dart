import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/search_highlight.dart';

Widget _host(SearchHighlight highlight) => MaterialApp(
      home: Scaffold(body: highlight),
    );

List<TextSpan> _spans(WidgetTester tester) =>
    (tester.widget<Text>(find.byType(Text)).textSpan as TextSpan)
        .children!
        .cast<TextSpan>();

List<String> _highlighted(WidgetTester tester) => _spans(tester)
    .where((span) => span.style?.backgroundColor != null)
    .map((span) => span.text!)
    .toList();

void main() {
  testWidgets('accent and emoji queries style whole graphemes without loss',
      (tester) async {
    for (final (grapheme, query) in [
      ('e\u0301', 'e'),
      ('e\u0301', '\u0301'),
      ('👩🏽‍💻', '💻'),
      ('👩🏽‍💻', '🏽'),
      ('🇳🇿', '🇿'),
      ('♥️', '\uFE0F'),
    ]) {
      final text = 'Start $grapheme finish';
      await tester.pumpWidget(_host(SearchHighlight(text, query: query)));
      await tester.pump();
      expect(_highlighted(tester), [grapheme]);
      expect(_spans(tester).map((span) => span.text).join(), text);
      final richText = tester.widget<Text>(find.byType(Text));
      expect(richText.semanticsLabel, text);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('multiple matches in a single grapheme are merged exactly once',
      (tester) async {
    for (final (grapheme, query) in [
      ('e\u0301\u0301', '\u0301'),
      ('👩‍👩‍👧‍👧', '👩'),
    ]) {
      final text = 'Before $grapheme between $grapheme after';
      await tester.pumpWidget(_host(SearchHighlight(text, query: query)));
      await tester.pump();
      expect(_highlighted(tester), [grapheme, grapheme]);
      expect(_spans(tester).map((span) => span.text).join(), text,
          reason: 'Expanded overlapping matches must not duplicate the emoji');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('cross-cluster matches preserve complete shaping at both ends',
      (tester) async {
    const text = 'Before e\u0301 and 👩🏽‍💻 after';
    await tester
        .pumpWidget(_host(const SearchHighlight(text, query: '\u0301 and 👩')));
    await tester.pump();
    expect(_highlighted(tester), ['e\u0301 and 👩🏽‍💻']);
    expect(_spans(tester).map((span) => span.text).join(), text);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'literal and case-insensitive queries keep normal search behavior',
      (tester) async {
    const text = 'Tea [paid] tea .* TEA';
    await tester.pumpWidget(
        _host(const SearchHighlight(text, query: ' tea ', maxLines: 2)));
    await tester.pump();
    expect(_highlighted(tester), ['Tea', 'tea', 'TEA']);
    expect(_spans(tester).map((span) => span.text).join(), text);
    expect(tester.widget<Text>(find.byType(Text)).maxLines, 2);

    for (final query in ['[paid]', '.*']) {
      await tester.pumpWidget(_host(SearchHighlight(text, query: query)));
      await tester.pump();
      expect(_highlighted(tester), [query]);
      expect(_spans(tester).map((span) => span.text).join(), text);
    }
    for (final query in ['', 'missing']) {
      await tester.pumpWidget(_host(SearchHighlight(text, query: query)));
      await tester.pump();
      final rendered = tester.widget<Text>(find.byType(Text));
      expect(rendered.data, text);
      expect(rendered.textSpan, isNull);
    }
    expect(tester.takeException(), isNull);
  });
}
