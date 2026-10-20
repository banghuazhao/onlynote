import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/voice_memo_date_label.dart';
import 'package:onlynote/presentation/components/voice_memo_date_previews.dart';

Finder get _label => find.descendant(
      of: find.byType(VoiceMemoDateLabel),
      matching: find.byType(Text),
    );

Widget _host(DateTime createdAt,
        {Locale locale = const Locale('en'), bool use24HourClock = false}) =>
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
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: use24HourClock),
        child: child!,
      ),
      home: Scaffold(body: VoiceMemoDateLabel(createdAt: createdAt)),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('voice-memo-date-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-recording-date-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    for (final (family, asset) in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  testWidgets('recording date rebuilds with stored date, locale and clock',
      (tester) async {
    final createdAt = DateTime(2026, 10, 11, 17, 45);
    for (final (locale, use24HourClock, date, prefix) in [
      (const Locale('en'), false, 'Oct 11, 2026 5:45 PM', 'Recorded '),
      (const Locale('en'), true, 'Oct 11, 2026 17:45', 'Recorded '),
      (const Locale('zh'), true, '2026年10月11日 17:45', '录制于 '),
      (const Locale('zh', 'HK'), false, '2026年10月11日 下午5:45', '錄製於 '),
    ]) {
      await tester.pumpWidget(
          _host(createdAt, locale: locale, use24HourClock: use24HourClock));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(_label).data, '$prefix$date');
      expect(Localizations.localeOf(tester.element(_label)), locale);
      expect(MediaQuery.alwaysUse24HourFormatOf(tester.element(_label)),
          use24HourClock);
    }
    final changed = DateTime(2027, 1, 2, 9, 7);
    await tester.pumpWidget(_host(changed, use24HourClock: true));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(_label).data, 'Recorded Jan 2, 2027 09:07');
    expect(createdAt, DateTime(2026, 10, 11, 17, 45));
    expect(tester.takeException(), isNull);
  });

  testWidgets('UTC recordings use local time with explicit recorded semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final stored = DateTime.utc(2026, 10, 11, 23, 45);
      await tester.pumpWidget(_host(stored,
          locale: const Locale('zh', 'HK'), use24HourClock: true));
      await tester.pumpAndSettle();
      final expected = S.current.Voice_Recorded_At(
          DateFormat.yMMMd('zh_HK').add_Hm().format(stored.toLocal()));
      expect(tester.widget<Text>(_label).data, expected);
      expect(find.bySemanticsLabel(expected), findsOneWidget);
      await tester.pumpWidget(_host(stored.toLocal(),
          locale: const Locale('zh', 'HK'), use24HourClock: true));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(_label).data, expected);
      expect(stored.isUtc, isTrue);
      expect(stored, DateTime.utc(2026, 10, 11, 23, 45));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final (name, preview, locale, brightness, size) in [
    (
      'light',
      voiceMemoDateLightPreview,
      const Locale('en'),
      Brightness.light,
      const Size(390, 400)
    ),
    (
      'dark',
      voiceMemoDateDarkPreview,
      const Locale('en'),
      Brightness.dark,
      const Size(390, 400)
    ),
    (
      'chinese',
      voiceMemoDateChinesePreview,
      const Locale('zh'),
      Brightness.light,
      const Size(280, 600)
    ),
    (
      'hong-kong',
      voiceMemoDateHongKongPreview,
      const Locale('zh', 'HK'),
      Brightness.light,
      const Size(280, 600)
    ),
  ]) {
    testWidgets('$name date preview changes clocks without media dependencies',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('voice-memo-date-capture'), child: preview()));
      await tester.pumpAndSettle();
      expect(Localizations.localeOf(tester.element(_label)), locale);
      expect(Theme.of(tester.element(_label)).brightness, brightness);
      final date = DateTime(2026, 10, 11, 17, 45);
      expect(
          tester.widget<Text>(_label).data,
          S.current.Voice_Recorded_At(
              DateFormat.yMMMd(locale.toString()).add_jm().format(date)));
      expect(tester.getSize(_label).width, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      final clock = find.byKey(const ValueKey('voice-memo-date-preview-clock'));
      await tester.ensureVisible(clock);
      await tester.tap(clock);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(clock).value, isTrue);
      expect(
          tester.widget<Text>(_label).data,
          S.current.Voice_Recorded_At(
              DateFormat.yMMMd(locale.toString()).add_Hm().format(date)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
