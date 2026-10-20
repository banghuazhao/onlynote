import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_links_previews.dart';

void main() {
  for (final (name, preview, size, locale, brightness) in [
    (
      'light',
      noteLinkPickerPreview,
      const Size(390, 740),
      const Locale('en'),
      Brightness.light,
    ),
    (
      'dark',
      noteLinkPickerDarkPreview,
      const Size(390, 740),
      const Locale('en'),
      Brightness.dark,
    ),
    (
      'narrow Chinese',
      noteLinkPickerLargeTextPreview,
      const Size(320, 640),
      const Locale('zh', 'HK'),
      Brightness.light,
    ),
  ]) {
    testWidgets('$name preview reports and preserves filtered selections',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('note-link-search'));
      final count = find.byKey(const ValueKey('note-link-selection-count'));
      final hiddenCount =
          find.byKey(const ValueKey('note-link-hidden-selection-count'));
      final results = find.byKey(const ValueKey('note-link-results'));
      final scrollable =
          find.descendant(of: results, matching: find.byType(Scrollable));
      final packing = find.byKey(const ValueKey('choose-note-link-packing'));
      expect(Localizations.localeOf(tester.element(search)), locale);
      expect(Theme.of(tester.element(search)).brightness, brightness);
      expect(find.text(S.current.Link_Selected_Count(3)), findsOneWidget);
      expect(hiddenCount, findsNothing);

      await tester.enterText(search, 'packing');
      await tester.pumpAndSettle();
      expect(find.text(S.current.Link_Selected_Count(3)), findsOneWidget);
      expect(
          find.text(S.current.Link_Hidden_By_Search_Count(1)), findsOneWidget);
      expect(find.text(S.current.Link_Unavailable), findsOneWidget);
      expect(find.text('Weekend trip'), findsNothing);
      await tester.scrollUntilVisible(packing, 60,
          scrollable: scrollable, maxScrolls: 10);
      await tester.pumpAndSettle();
      expect(packing.hitTestable(), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(packing).value, isTrue);
      final snippet = find.byKey(const ValueKey('note-link-snippet-packing'));
      expect(snippet, findsOneWidget);
      expect(tester.widget<Text>(snippet).data, contains('raincoats'));
      expect(tester.widget<Text>(snippet).maxLines, 2);
      expect(find.text(S.current.Archive), findsOneWidget);
      await tester.tap(packing);
      await tester.pumpAndSettle();

      await tester
          .tap(find.descendant(of: search, matching: find.byType(IconButton)));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      await tester.scrollUntilVisible(count, -60,
          scrollable: scrollable, maxScrolls: 10);
      await tester.pumpAndSettle();
      expect(find.text(S.current.Link_Selected_Count(2)), findsOneWidget);
      expect(hiddenCount, findsNothing);
      await tester.scrollUntilVisible(packing, 60,
          scrollable: scrollable, maxScrolls: 10);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(packing).value, isFalse);
      final travel = find.byKey(const ValueKey('choose-note-link-travel'));
      await tester.scrollUntilVisible(travel, -60,
          scrollable: scrollable, maxScrolls: 10);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(travel).value, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
