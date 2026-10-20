import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/reminders/reminders_agenda_search_previews.dart';
import 'package:onlynote/presentation/theme/theme.dart';

ThemeData? _captureTheme(Brightness brightness) {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return null;
  final base = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['DroidSansFallback'],
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['DroidSansFallback'],
    ),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['DroidSansFallback'],
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(base.textTheme.labelLarge?.copyWith(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['DroidSansFallback'],
        )),
      ),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('reminder-search-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/onlynote-reminder-search-$name.png')
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
      final loader = FontLoader(family)..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  for (final (name, preview, size, locale, brightness) in [
    (
      'light',
      reminderSearchLightPreview,
      const Size(390, 780),
      const Locale('en'),
      Brightness.light
    ),
    (
      'dark',
      reminderSearchDarkPreview,
      const Size(390, 780),
      const Locale('en'),
      Brightness.dark
    ),
    (
      'chinese',
      reminderSearchChinesePreview,
      const Size(320, 640),
      const Locale('zh', 'HK'),
      Brightness.light
    ),
  ]) {
    testWidgets('$name reminder preview searches and clears locally',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('reminder-search-capture'),
          child: preview(theme: _captureTheme(brightness))));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('reminders-search'));
      expect(Localizations.localeOf(tester.element(field)), locale);
      expect(Theme.of(tester.element(field)).brightness, brightness);
      final chinese = locale.languageCode == 'zh';
      await tester.enterText(field, chinese ? '茶😀' : '  FOLLOW-UP [2026]  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text(chinese ? '閱讀清單' : 'Call dentist'), findsOneWidget);
      expect(find.text(chinese ? 'Review C++ [2026] notes' : 'Errands'),
          findsOneWidget);
      await _capture(tester, name);
      await tester.enterText(field, 'not found');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text(S.current.Reminders_Search_Empty_Title), findsOneWidget);
      await _capture(tester, '$name-empty');
      final clear = find.byKey(const ValueKey('reminders-empty-clear-search'));
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(
          find.byKey(const ValueKey('reminders-search-empty')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
