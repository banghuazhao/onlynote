import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/note_tag_suggestions_previews.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  for (final (name, preview, size, locale, brightness, textScale) in [
    (
      'light',
      noteTagSuggestionsLightPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.light,
      1.0,
    ),
    (
      'dark',
      noteTagSuggestionsDarkPreview,
      const Size(390, 700),
      const Locale('en'),
      Brightness.dark,
      1.0,
    ),
    (
      'narrow Chinese',
      noteTagSuggestionsChinesePreview,
      const Size(280, 700),
      const Locale('zh', 'HK'),
      Brightness.light,
      2.0,
    ),
  ]) {
    testWidgets('$name tag preview filters, selects, and clears safely',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      final field = _key('note-tag-input');
      final context = tester.element(field);
      expect(Localizations.localeOf(context), locale);
      expect(Theme.of(context).brightness, brightness);
      expect(MediaQuery.textScalerOf(context).scale(10), textScale * 10);
      expect(find.byType(ActionChip), findsNWidgets(5));
      expect(_key('note-tag-work'), findsOneWidget);
      expect(_key('note-tag-個人工作計劃'), findsOneWidget);
      expect(_key('note-tag-suggestion-work'), findsNothing);

      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, '茶');
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNWidgets(2));
      expect(_key('note-tag-suggestion-茶室計劃'), findsOneWidget);
      expect(_key('note-tag-suggestion-茶葉清單'), findsOneWidget);
      expect(_key('note-tag-work'), findsOneWidget);
      expect(_key('note-tag-個人工作計劃'), findsOneWidget);
      expect(find.byType(InputChip), findsNWidgets(2));

      final suggestion = _key('note-tag-suggestion-茶室計劃');
      await tester.ensureVisible(suggestion);
      await tester.pumpAndSettle();
      await tester.tap(suggestion);
      await tester.pumpAndSettle();
      expect(_key('note-tag-茶室計劃'), findsOneWidget);
      expect(_key('note-tag-suggestion-茶室計劃'), findsNothing);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.byType(InputChip), findsNWidgets(3));
      expect(find.byType(ActionChip), findsNWidgets(4));

      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'RELEASE');
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsOneWidget);
      expect(_key('note-tag-suggestion-release draft'), findsOneWidget);
      await tester.enterText(field, 'not present');
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);
      expect(_key('note-tag-suggestions-empty'), findsOneWidget);
      expect(find.byType(InputChip), findsNWidgets(3));
      await tester.ensureVisible(_key('note-tags-save'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final clear = _key('note-tags-clear-input');
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(_key('note-tag-suggestions-empty'), findsNothing);
      expect(find.byType(ActionChip), findsNWidgets(4));
      expect(find.byType(InputChip), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
