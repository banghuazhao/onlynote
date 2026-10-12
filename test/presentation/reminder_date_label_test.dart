import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/reminder_date_label.dart';
import 'package:onlynote/presentation/components/reminder_date_label_previews.dart';

Finder get _dateText => find.byKey(const ValueKey('reminder-date-text'));
final _date = DateTime(2026, 10, 13, 17, 45);

String _expected(BuildContext context, DateTime date, bool use24HourClock) {
  final material = MaterialLocalizations.of(context);
  final local = date.toLocal();
  return '${material.formatMediumDate(local)} · ${material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: use24HourClock,
  )}';
}

Widget _host(Locale locale, bool use24HourClock,
        {DateTime? date, TextStyle? style}) =>
    MaterialApp(
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
          alwaysUse24HourFormat: use24HourClock,
          textScaler: const TextScaler.linear(2),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReminderDateLabel(date: date ?? _date, style: style),
        ),
      ),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('reminder-date-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-release-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'HK'),
  ]) {
    for (final use24HourClock in [false, true]) {
      testWidgets(
          '$locale reminder date follows $use24HourClock clock preference at 180px 2x',
          (tester) async {
        tester.view.physicalSize = const Size(180, 240);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        const style = TextStyle(color: Colors.deepPurple, fontSize: 14);
        try {
          await tester.pumpWidget(_host(locale, use24HourClock, style: style));
          await tester.pumpAndSettle();
          final text = tester.widget<Text>(_dateText);
          final expected =
              _expected(tester.element(_dateText), _date, use24HourClock);
          expect(text.data, expected);
          expect(text.style, style);
          expect(Localizations.localeOf(tester.element(_dateText)), locale);
          expect(tester.widget<Icon>(find.byIcon(Icons.alarm_rounded)).color,
              style.color);
          expect(tester.getSemantics(_dateText).getSemanticsData().label,
              expected);
          expect(tester.getRect(_dateText).width, lessThanOrEqualTo(160));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('reminder label rebuilds when device clock preference changes',
      (tester) async {
    await tester.pumpWidget(_host(const Locale('en'), false));
    await tester.pumpAndSettle();
    final before = tester.widget<Text>(_dateText).data!;
    expect(before, contains('5:45 PM'));
    await tester.pumpWidget(_host(const Locale('en'), true));
    await tester.pumpAndSettle();
    final after = tester.widget<Text>(_dateText).data!;
    expect(after, _expected(tester.element(_dateText), _date, true));
    expect(after, contains('17:45'));
    expect(after, isNot(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('UTC metadata is formatted using the local calendar and clock',
      (tester) async {
    final utc = DateTime.utc(2026, 10, 13, 23, 45);
    await tester.pumpWidget(_host(const Locale('en'), true, date: utc));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(_dateText).data,
        _expected(tester.element(_dateText), utc, true));
    expect(tester.takeException(), isNull);
  });

  for (final (name, preview, size, locale, brightness) in [
    (
      'reminder-date-light',
      reminderDateLightPreview,
      const Size(390, 300),
      const Locale('en'),
      Brightness.light
    ),
    (
      'reminder-date-dark',
      reminderDateDarkPreview,
      const Size(390, 300),
      const Locale('en'),
      Brightness.dark
    ),
    (
      'reminder-date-chinese',
      reminderDateChinesePreview,
      const Size(180, 400),
      const Locale('zh'),
      Brightness.light
    ),
    (
      'reminder-date-landscape',
      reminderDateChineseHKPreview,
      const Size(568, 180),
      const Locale('zh', 'HK'),
      Brightness.light
    ),
  ]) {
    testWidgets(
        '$name preview changes its clock preference locally without overflow',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('reminder-date-capture'),
        child: preview(),
      ));
      await tester.pumpAndSettle();
      expect(Localizations.localeOf(tester.element(_dateText)), locale);
      expect(Theme.of(tester.element(_dateText)).brightness, brightness);
      expect(tester.widget<Text>(_dateText).data,
          _expected(tester.element(_dateText), _date, false));
      await tester.ensureVisible(_dateText);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      final clock = find.byKey(const ValueKey('reminder-preview-clock'));
      await tester.ensureVisible(clock);
      await tester.pumpAndSettle();
      expect(tester.getSize(clock).height, greaterThanOrEqualTo(48));
      expect(tester.widget<SwitchListTile>(clock).value, isFalse);
      await tester.tap(clock);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(clock).value, isTrue);
      expect(MediaQuery.alwaysUse24HourFormatOf(tester.element(_dateText)),
          isTrue);
      expect(tester.widget<Text>(_dateText).data,
          _expected(tester.element(_dateText), _date, true));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
