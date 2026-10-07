import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/presentation/components/reminder_picker_sheet.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

import '../support/premium_test_fakes.dart';

Future<void> _openPicker(
  WidgetTester tester,
  List<ReminderPickerResult?> results, {
  Reminder? current,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
  bool allowDelete = true,
  PremiumAccess? premiumAccess,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: S.delegate.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true, extensions: const [AppTokens()]),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        alwaysUse24HourFormat: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              results.add(await showAppSheet<ReminderPickerResult>(
                context: context,
                builder: (_) => ReminderPickerSheet(
                    current: current,
                    allowDelete: allowDelete,
                    premiumAccess: premiumAccess),
              ));
            },
            child: const Text('Open picker'),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

SegmentedButton<ReminderRepeat> _repeatControl(WidgetTester tester) =>
    tester.widget<SegmentedButton<ReminderRepeat>>(
      find.byType(SegmentedButton<ReminderRepeat>),
    );

DateTime _nextScheduledTime(ReminderPickerResult result) => Reminder(
      noteId: 'note',
      reminderId: 42,
      reminderDate: result.date!,
      repeat: result.repeat,
    ).nextOccurrence(DateTime.now());

void main() {
  testWidgets(
      'free repeating option explains Premium and cancel keeps selection',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    final results = <ReminderPickerResult?>[];
    await _openPicker(tester, results,
        premiumAccess: fixture.access,
        size: const Size(320, 640),
        textScale: 2);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await _tapVisible(tester, find.text('Daily'));
    expect(find.byType(PremiumScreen), findsOneWidget);
    expect(results, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_repeatControl(tester).selected, {ReminderRepeat.none});
    await _tapVisible(tester, find.text('In 1 hour'));
    expect(results.single!.repeat, ReminderRepeat.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets('purchase returns to the requested repeat with its selected time',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    final results = <ReminderPickerResult?>[];
    await _openPicker(tester, results,
        premiumAccess: fixture.access,
        current: Reminder(
            noteId: 'note',
            reminderId: 42,
            reminderDate: DateTime(2024, 1, 1, 9, 30)));
    await _tapVisible(tester, find.text('Daily'));
    await _tapVisible(tester, find.byKey(const ValueKey('premium-buy')));
    expect(fixture.access.isPremium, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_repeatControl(tester).selected, {ReminderRepeat.daily});
    expect(find.text('09:30'), findsOneWidget);
    await _tapVisible(tester, find.text('Set reminder'));
    expect(results.single!.repeat, ReminderRepeat.daily);
    expect(results.single!.date!.hour, 9);
    expect(fixture.store.buyCalls, 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing recurrence stays usable and can be turned off for free',
      (tester) async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    final results = <ReminderPickerResult?>[];
    final current = Reminder(
        noteId: 'note',
        reminderId: 42,
        reminderDate: DateTime(2024, 1, 1, 9, 30),
        repeat: ReminderRepeat.daily);
    await _openPicker(tester, results,
        premiumAccess: fixture.access, current: current);
    await _tapVisible(tester, find.text('Set reminder'));
    expect(results.single!.repeat, ReminderRepeat.daily);
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Weekly'));
    expect(find.byType(PremiumScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_repeatControl(tester).selected, {ReminderRepeat.daily});
    await _tapVisible(tester, find.text('Never'));
    await _tapVisible(tester, find.text('In 1 hour'));
    expect(results.last!.repeat, ReminderRepeat.none);
    expect(fixture.access.isPremium, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reschedule picker can omit reminder deletion', (tester) async {
    final results = <ReminderPickerResult?>[];
    await _openPicker(tester, results,
        current: Reminder(
            reminderDate: DateTime.now().add(const Duration(hours: 1)),
            reminderId: 42,
            noteId: 'note'),
        allowDelete: false);
    expect(find.text('Delete'), findsNothing);
    await _tapVisible(tester, find.text('Cancel'));
    expect(results, [null]);
  });
  testWidgets('one-time shortcut closes the sheet with a future date',
      (tester) async {
    final results = <ReminderPickerResult?>[];
    await _openPicker(tester, results);

    expect(_repeatControl(tester).selected, {ReminderRepeat.none});
    expect(find.text('Delete'), findsNothing);
    final before = DateTime.now();
    await _tapVisible(tester, find.text('In 1 hour'));
    final after = DateTime.now();

    expect(find.byType(ReminderPickerSheet), findsNothing);
    expect(results, hasLength(1));
    final result = results.single!;
    expect(result.delete, isFalse);
    expect(result.repeat, ReminderRepeat.none);
    expect(result.date!.compareTo(before.add(const Duration(hours: 1))),
        greaterThanOrEqualTo(0));
    expect(result.date!.compareTo(after.add(const Duration(hours: 1))),
        lessThanOrEqualTo(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing a one-time reminder to daily retains its time',
      (tester) async {
    final results = <ReminderPickerResult?>[];
    final current = Reminder(
      noteId: 'note',
      reminderId: 42,
      reminderDate: DateTime(2024, 1, 1, 9, 30),
    );
    await _openPicker(tester, results, current: current);
    await _tapVisible(tester, find.text('Daily'));

    expect(find.text('In 1 hour'), findsNothing);
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.text('09:30'), findsOneWidget);
    await _tapVisible(tester, find.text('Set reminder'));

    final result = results.single!;
    expect(result.delete, isFalse);
    expect(result.repeat, ReminderRepeat.daily);
    expect(result.date!.hour, 9);
    expect(result.date!.minute, 30);
    final next = _nextScheduledTime(result);
    expect(next.isAfter(DateTime.now()), isTrue);
    expect(
        next.difference(DateTime.now()), lessThan(const Duration(hours: 26)));
    expect(current.repeat, ReminderRepeat.none);
    expect(current.reminderDate, DateTime(2024, 1, 1, 9, 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly selection returns the edited weekday and time',
      (tester) async {
    final results = <ReminderPickerResult?>[];
    final current = Reminder(
      noteId: 'note',
      reminderId: 42,
      reminderDate: DateTime(2024, 1, 1, 9, 30),
      repeat: ReminderRepeat.daily,
    );
    await _openPicker(tester, results, current: current);
    await _tapVisible(tester, find.text('Weekly'));
    await _tapVisible(tester, find.byType(DropdownButton<int>));
    await _tapVisible(tester, find.text('Friday').last);

    await _tapVisible(tester, find.text('Time'));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await _tapVisible(tester, find.byIcon(Icons.keyboard_outlined));
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '17');
    await tester.enterText(fields.at(1), '45');
    await _tapVisible(tester, find.text('OK'));
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(find.text('17:45'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    await _tapVisible(tester, find.text('Set reminder'));

    final result = results.single!;
    expect(result.delete, isFalse);
    expect(result.repeat, ReminderRepeat.weekly);
    expect(result.date!.weekday, DateTime.friday);
    expect(result.date!.hour, 17);
    expect(result.date!.minute, 45);
    final next = _nextScheduledTime(result);
    expect(next.isAfter(DateTime.now()), isTrue);
    expect(next.weekday, DateTime.friday);
    expect(next.difference(DateTime.now()), lessThan(const Duration(days: 8)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing repeat is preselected and cancel differs from delete',
      (tester) async {
    final results = <ReminderPickerResult?>[];
    final anchor = DateTime(2024, 1, 2, 17, 25);
    final current = Reminder(
      noteId: 'note',
      reminderId: 42,
      reminderDate: anchor,
      repeat: ReminderRepeat.weekly,
    );
    await _openPicker(tester, results, current: current);

    expect(_repeatControl(tester).selected, {ReminderRepeat.weekly});
    expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .value,
        DateTime.tuesday);
    expect(find.text('17:25'), findsOneWidget);
    await _tapVisible(tester, find.text('Cancel'));
    expect(results, [null]);
    expect(current.reminderDate, anchor);
    expect(current.repeat, ReminderRepeat.weekly);

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Delete'));
    expect(results, hasLength(2));
    expect(results.last!.delete, isTrue);
    expect(results.last!.date, isNull);
    expect(find.byType(ReminderPickerSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly picker remains usable on a narrow screen in Chinese',
      (tester) async {
    final results = <ReminderPickerResult?>[];
    await _openPicker(
      tester,
      results,
      locale: const Locale('zh'),
      size: const Size(320, 640),
      textScale: 1.6,
      current: Reminder(
        noteId: 'note',
        reminderId: 42,
        reminderDate: DateTime(2024, 1, 4, 9, 30),
        repeat: ReminderRepeat.weekly,
      ),
    );

    expect(find.text('每周'), findsOneWidget);
    expect(find.text('星期四'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tapVisible(tester, find.text('设置提醒'));
    expect(results.single!.repeat, ReminderRepeat.weekly);
    expect(results.single!.date!.weekday, DateTime.thursday);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long weekdays remain usable with large English text',
      (tester) async {
    final results = <ReminderPickerResult?>[];
    await _openPicker(
      tester,
      results,
      size: const Size(320, 640),
      textScale: 2,
      current: Reminder(
        noteId: 'note',
        reminderId: 42,
        reminderDate: DateTime(2024, 1, 3, 9, 30),
        repeat: ReminderRepeat.weekly,
      ),
    );
    expect(find.text('Wednesday'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tapVisible(tester, find.text('Set reminder'));
    expect(results.single!.date!.weekday, DateTime.wednesday);
    expect(tester.takeException(), isNull);
  });
}
