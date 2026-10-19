import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/Tools/app_typography_settings.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_reader_date_label.dart';
import 'package:onlynote/presentation/components/note_reader_date_previews.dart';
import 'package:onlynote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:screenshot/screenshot.dart';

Finder get _dateText => find.descendant(
      of: find.byType(NoteReaderDateLabel),
      matching: find.byType(SelectableText),
    );

Widget _readerHost(Note note,
        {Locale locale = const Locale('en'),
        bool use24HourFormat = false,
        bool exportMode = false,
        double textScale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
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
          alwaysUse24HourFormat: use24HourFormat,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: LoadedView(
          note: note,
          screenshotController: ScreenshotController(),
          onReminderTap: null,
          exportMode: exportMode,
        ),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() {
    final fonts = Map<String, GoogleFontBuilder>.of(kAppFontFamilies);
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
    addTearDown(() => kAppFontFamilies.addAll(fonts));
  });

  testWidgets('reader updates date when locale or device clock changes',
      (tester) async {
    final date = DateTime(2026, 10, 11, 17, 45);
    final note = Note(
        id: 'reader-date',
        title: 'Weekend plans',
        description: 'Bring a camera.',
        dateTime: date);
    for (final (locale, use24HourFormat, expected) in [
      (const Locale('en'), false, 'Oct 11, 2026 5:45 PM'),
      (const Locale('en'), true, 'Oct 11, 2026 17:45'),
      (const Locale('zh'), true, '2026年10月11日 17:45'),
      (const Locale('zh', 'HK'), false, '2026年10月11日 下午5:45'),
    ]) {
      await tester.pumpWidget(
          _readerHost(note, locale: locale, use24HourFormat: use24HourFormat));
      await tester.pumpAndSettle();
      expect(tester.widget<SelectableText>(_dateText).data, expected);
      expect(Localizations.localeOf(tester.element(_dateText)), locale);
      expect(MediaQuery.alwaysUse24HourFormatOf(tester.element(_dateText)),
          use24HourFormat);
      expect(tester.takeException(), isNull);
    }
    expect(note.dateTime, date);
  });

  testWidgets('image export keeps the localized timestamp inside the capture',
      (tester) async {
    final note =
        Note(title: 'Weekend plans', dateTime: DateTime(2026, 10, 11, 17, 45));
    await tester.pumpWidget(_readerHost(note,
        locale: const Locale('zh', 'HK'),
        use24HourFormat: true,
        exportMode: true));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(Screenshot), matching: _dateText),
        findsOneWidget);
    expect(tester.widget<SelectableText>(_dateText).data, '2026年10月11日 17:45');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reader converts UTC dates locally and preserves missing metadata',
      (tester) async {
    final utc = DateTime.utc(2026, 10, 11, 23, 45);
    await tester.pumpWidget(_readerHost(Note(dateTime: utc),
        locale: const Locale('zh'), use24HourFormat: true));
    await tester.pumpAndSettle();
    expect(tester.widget<SelectableText>(_dateText).data,
        DateFormat.yMMMd('zh').add_Hm().format(utc.toLocal()));
    await tester.pumpWidget(_readerHost(Note(), use24HourFormat: true));
    await tester.pumpAndSettle();
    expect(tester.widget<SelectableText>(_dateText).data, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final (name, preview, locale, dark) in [
    (
      'English',
      noteReaderDateEnglishPreview,
      const Locale('en'),
      false,
    ),
    ('dark', noteReaderDateDarkPreview, const Locale('en'), true),
    ('Chinese', noteReaderDateChinesePreview, const Locale('zh'), false),
    (
      'Hong Kong',
      noteReaderDateHongKongPreview,
      const Locale('zh', 'HK'),
      false,
    ),
  ]) {
    testWidgets('$name date preview switches clocks without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(280, 460);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(Localizations.localeOf(tester.element(_dateText)), locale);
      expect(Theme.of(tester.element(_dateText)).brightness,
          dark ? Brightness.dark : Brightness.light);
      expect(
          tester.widget<SelectableText>(_dateText).data,
          DateFormat.yMMMd(locale.toString())
              .add_jm()
              .format(DateTime(2026, 10, 11, 17, 45)));
      final clock = find.byKey(const ValueKey('reader-date-preview-clock'));
      await tester.ensureVisible(clock);
      await tester.tap(clock);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(clock).value, isTrue);
      expect(
          tester.widget<SelectableText>(_dateText).data,
          DateFormat.yMMMd(locale.toString())
              .add_Hm()
              .format(DateTime(2026, 10, 11, 17, 45)));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reader date wraps at narrow widths with large text',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_readerHost(
        Note(title: '本週安排', dateTime: DateTime(2026, 10, 11, 17, 45)),
        locale: const Locale('zh', 'HK'),
        textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.widget<SelectableText>(_dateText).data, '2026年10月11日 下午5:45');
    expect(tester.getSize(_dateText).width, lessThanOrEqualTo(280));
    expect(tester.takeException(), isNull);
  });
}
