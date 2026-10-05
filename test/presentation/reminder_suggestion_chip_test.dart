import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/reminder_suggestion_chip.dart';

void main() {
  testWidgets('suggestion and dismiss have separate accessible actions',
      (tester) async {
    var accepted = 0;
    var dismissed = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: Scaffold(
          body: ReminderSuggestionChip(
        date: DateTime(2026, 10, 7, 9),
        onPressed: () => accepted++,
        onDismiss: () => dismissed++,
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Remind me:'));
    await tester.tap(find.byTooltip('Dismiss suggestion'));
    expect(accepted, 1);
    expect(dismissed, 1);
  });

  testWidgets('Chinese suggestion wraps on a narrow screen at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'HK'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2), disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
          body: Padding(
        padding: const EdgeInsets.all(32),
        child: ReminderSuggestionChip(
          date: DateTime(2026, 10, 7, 9),
          onPressed: () {},
          onDismiss: () {},
        ),
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('提醒我'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy suggestion blocks both actions', (tester) async {
    var actions = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: Scaffold(
          body: ReminderSuggestionChip(
        date: DateTime(2026, 10, 7, 9),
        busy: true,
        onPressed: () => actions++,
        onDismiss: () => actions++,
      )),
    ));
    await tester.pump();
    await tester.tap(find.textContaining('Remind me:'));
    await tester.tap(find.byTooltip('Dismiss suggestion'));
    expect(actions, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion shows a static busy indicator', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: ReminderSuggestionChip(
            date: DateTime(2026, 10, 7, 9),
            busy: true,
            onPressed: () {},
            onDismiss: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
  });
}
