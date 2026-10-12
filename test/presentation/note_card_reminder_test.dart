import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/reminder_date_label.dart';
import 'package:onlynote/presentation/screens/home/widgets/note_card.dart';

const _cardKey = ValueKey('reminder-note-card');
const _labelKey = ValueKey('reminder-date-text');

Widget _host(Note note,
        {Locale locale = const Locale('en'),
        double width = 350,
        double textScale = 1,
        VoidCallback? onTap}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: width,
              child: NoteCard(key: _cardKey, note: note, onTap: onTap),
            ),
          ),
        ),
      ),
    );

String _expectedLabel(WidgetTester tester, DateTime date) {
  final context = tester.element(find.byKey(_labelKey));
  final local = date.toLocal();
  final strings = MaterialLocalizations.of(context);
  final time = strings.formatTimeOfDay(TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
  return '${strings.formatMediumDate(local)} · $time';
}

String _visibleLabel(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(_labelKey)).data!;

void main() {
  final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
  late List<Reminder> previousReminders;

  setUp(() {
    previousReminders = ReminderData.shared.reminders;
    ReminderData.shared.reminders = [];
    for (final family in fonts.keys) {
      kAppFontFamilies[family] = (
              {textStyle, color, fontSize, fontWeight, fontStyle}) =>
          (textStyle ?? const TextStyle()).copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          );
    }
  });
  tearDown(() {
    ReminderData.shared.reminders = previousReminders;
    kAppFontFamilies.addAll(fonts);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    for (final use24Hours in [false, true]) {
      testWidgets(
          'NoteCard uses $locale reminder date and device 24-hour=$use24Hours',
          (tester) async {
        tester.platformDispatcher.alwaysUse24HourFormatTestValue = use24Hours;
        // The test override does not notify the view's cached MediaQuery.
        tester.binding.handleMetricsChanged();
        addTearDown(() {
          tester.platformDispatcher.clearAlwaysUse24HourTestValue();
          tester.binding.handleMetricsChanged();
        });
        final note = Note(
            id: 'reminder-note',
            title: 'Call the dentist',
            tags: ['Personal'],
            folderId: 'work');
        final reminder = Reminder(
          noteId: note.id!,
          reminderId: 42,
          reminderDate: DateTime(2040, 8, 19, 13, 5),
        );
        final stored = reminder.toJson();
        final reminders = [reminder];
        ReminderData.shared.reminders = reminders;
        await tester.pumpWidget(_host(note, locale: locale));
        await tester.pumpAndSettle();

        expect(find.byType(ReminderDateLabel), findsOneWidget);
        expect(
            MediaQuery.alwaysUse24HourFormatOf(
                tester.element(find.byKey(_labelKey))),
            use24Hours);
        expect(_visibleLabel(tester),
            _expectedLabel(tester, reminder.reminderDate));
        expect(
            tester
                .widget<ReminderDateLabel>(find.byType(ReminderDateLabel))
                .date,
            reminder.reminderDate);
        if (locale.languageCode == 'en') {
          expect(_visibleLabel(tester),
              contains(use24Hours ? '13:05' : '1:05 PM'));
        }
        expect(ReminderData.shared.reminders, same(reminders));
        expect(reminder.toJson(), stored);
        expect(tester.widget<NoteCard>(find.byKey(_cardKey)).note, same(note));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('one-time UTC and past reminders retain their stored instant',
      (tester) async {
    final note = Note(id: 'reminder-note', title: 'Keep the original date');
    for (final date in [
      DateTime.utc(2040, 8, 19, 13, 5),
      DateTime.utc(2000, 1, 3, 0, 15),
    ]) {
      final reminder =
          Reminder(noteId: note.id!, reminderId: 42, reminderDate: date);
      ReminderData.shared.reminders = [reminder];
      await tester.pumpWidget(_host(note, locale: const Locale('zh', 'HK')));
      await tester.pumpAndSettle();
      final label =
          tester.widget<ReminderDateLabel>(find.byType(ReminderDateLabel));
      expect(label.date, date);
      expect(label.date.isUtc, isTrue);
      expect(_visibleLabel(tester), _expectedLabel(tester, date));
      expect(reminder.reminderDate, date);
      expect(reminder.repeat, ReminderRepeat.none);
      expect(tester.takeException(), isNull);
    }
  });

  for (final repeat in [ReminderRepeat.daily, ReminderRepeat.weekly]) {
    testWidgets('$repeat NoteCard displays next occurrence of past pattern',
        (tester) async {
      final note = Note(id: 'reminder-note', title: 'Recurring reminder');
      final reminder = Reminder(
        noteId: note.id!,
        reminderId: 42,
        reminderDate: DateTime(2000, 1, 3, 13, 5),
        repeat: repeat,
      );
      final stored = reminder.toJson();
      ReminderData.shared.reminders = [reminder];
      final before = DateTime.now();
      await tester.pumpWidget(_host(note));
      await tester.pumpAndSettle();
      final after = DateTime.now();
      final date =
          tester.widget<ReminderDateLabel>(find.byType(ReminderDateLabel)).date;

      expect(
          date,
          anyOf(
              reminder.nextOccurrence(before), reminder.nextOccurrence(after)));
      expect(date.isAfter(before), isTrue);
      expect(date, isNot(reminder.reminderDate));
      expect(date.hour, 13);
      expect(date.minute, 5);
      if (repeat == ReminderRepeat.weekly) {
        expect(date.weekday, reminder.reminderDate.weekday);
      }
      expect(_visibleLabel(tester), _expectedLabel(tester, date));
      expect(reminder.toJson(), stored);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'mounted NoteCard follows live clock preference and locale changes',
      (tester) async {
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
    tester.binding.handleMetricsChanged();
    addTearDown(() {
      tester.platformDispatcher.clearAlwaysUse24HourTestValue();
      tester.binding.handleMetricsChanged();
    });
    final note = Note(id: 'reminder-note', title: 'Call the dentist');
    final reminder = Reminder(
        noteId: note.id!,
        reminderId: 42,
        reminderDate: DateTime(2040, 8, 19, 13, 5));
    final reminders = [reminder];
    final stored = reminder.toJson();
    ReminderData.shared.reminders = reminders;
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);
    var reminderChanges = 0;
    void countChanges() => reminderChanges++;
    ReminderData.shared.addListener(countChanges);
    addTearDown(() => ReminderData.shared.removeListener(countChanges));
    await tester.pumpWidget(ValueListenableBuilder<Locale>(
      valueListenable: locale,
      builder: (_, value, __) => _host(note, locale: value),
    ));
    await tester.pumpAndSettle();
    final state = tester.state<NoteCardState>(find.byKey(_cardKey));
    expect(
        MediaQuery.alwaysUse24HourFormatOf(
            tester.element(find.byKey(_labelKey))),
        isFalse);
    final original = _visibleLabel(tester);
    expect(original, contains('1:05 PM'));

    tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
    // The test override does not emit a platform notification itself.
    tester.binding.handleMetricsChanged();
    await tester.pumpAndSettle();
    expect(_visibleLabel(tester), contains('13:05'));
    expect(_visibleLabel(tester), isNot(original));
    expect(
        _visibleLabel(tester), _expectedLabel(tester, reminder.reminderDate));

    for (final value in [const Locale('zh'), const Locale('zh', 'HK')]) {
      locale.value = value;
      await tester.pumpAndSettle();
      expect(
          Localizations.localeOf(tester.element(find.byKey(_labelKey))), value);
      expect(
          _visibleLabel(tester), _expectedLabel(tester, reminder.reminderDate));
      expect(tester.state<NoteCardState>(find.byKey(_cardKey)), same(state));
    }
    locale.value = const Locale('en');
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
    tester.binding.handleMetricsChanged();
    await tester.pumpAndSettle();
    expect(_visibleLabel(tester), original);
    expect(ReminderData.shared.reminders, same(reminders));
    expect(reminder.toJson(), stored);
    expect(reminderChanges, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'NoteCard without a matching reminder stays tappable without label',
      (tester) async {
    var taps = 0;
    final note = Note(id: 'normal', title: 'An ordinary note');
    for (final reminders in [
      <Reminder>[],
      [Reminder(noteId: 'other', reminderId: 99, reminderDate: DateTime(2040))],
    ]) {
      ReminderData.shared.reminders = reminders;
      await tester.pumpWidget(_host(note, onTap: () => taps++));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderDateLabel), findsNothing);
      expect(find.byKey(_labelKey), findsNothing);
      expect(find.byIcon(Icons.alarm_rounded), findsNothing);
      expect(find.text(note.title!), findsOneWidget);
      await tester.tap(find.text(note.title!));
      await tester.pumpAndSettle();
      expect(ReminderData.shared.reminders, same(reminders));
      expect(tester.takeException(), isNull);
    }
    expect(taps, 2);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    testWidgets('$locale NoteCard reminder wraps at 180px and 2x text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(180, 640);
      addTearDown(tester.view.reset);
      final note = Note(id: 'narrow', title: '提醒', tags: ['工作']);
      final reminder = Reminder(
          noteId: note.id!,
          reminderId: 42,
          reminderDate: DateTime(2040, 8, 19, 13, 5));
      ReminderData.shared.reminders = [reminder];
      await tester
          .pumpWidget(_host(note, locale: locale, width: 180, textScale: 2));
      await tester.pumpAndSettle();
      expect(
          _visibleLabel(tester), _expectedLabel(tester, reminder.reminderDate));
      final cardRect = tester.getRect(find.byKey(_cardKey));
      final textRect = tester.getRect(find.byKey(_labelKey));
      expect(textRect.left, greaterThanOrEqualTo(cardRect.left));
      expect(textRect.right, lessThanOrEqualTo(cardRect.right));
      expect(textRect.bottom, lessThanOrEqualTo(cardRect.bottom));
      expect(tester.takeException(), isNull);
    });
  }
}
