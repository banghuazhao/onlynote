import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_search_filters.dart';
import 'package:onlynote/presentation/screens/home/widgets/daily_note_shortcut.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child,
      {bool reduceMotion = false}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('daily action stays reachable in narrow quick and search rows',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    var calendarTaps = 0;
    final shortcut = DailyNoteShortcut(
        onPressed: () => taps++, onOpenCalendar: () => calendarTaps++);
    await pump(
        tester,
        UnfinishedNotesFilter(
          selected: false,
          onChanged: (_) {},
          leadingAction: shortcut,
          onOpenReminders: () {},
          onOpenLibrary: () {},
        ));
    await tester.tap(find.byKey(const ValueKey('daily-note-shortcut')));
    expect(taps, 1);
    await tester
        .tap(find.byKey(const ValueKey('daily-note-calendar-shortcut')));
    expect(calendarTaps, 1);
    expect(tester.takeException(), isNull);
    await pump(
        tester,
        NoteSearchFilters(
          selected: const {},
          onChanged: (_) {},
          leadingAction: shortcut,
        ));
    await tester.tap(find.byKey(const ValueKey('daily-note-shortcut')));
    expect(taps, 2);
    await tester
        .tap(find.byKey(const ValueKey('daily-note-calendar-shortcut')));
    expect(calendarTaps, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening state disables repeat taps and honors reduced motion',
      (tester) async {
    var taps = 0;
    await pump(
        tester,
        DailyNoteShortcut(
          isOpening: true,
          onPressed: () => taps++,
          onOpenCalendar: () => taps++,
        ),
        reduceMotion: true);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byKey(const ValueKey('daily-note-shortcut')));
    expect(taps, 0);
    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.onPressed, isNull);
    final calendar = tester.widget<IconButton>(
        find.byKey(const ValueKey('daily-note-calendar-shortcut')));
    expect(calendar.onPressed, isNull);
  });
}
