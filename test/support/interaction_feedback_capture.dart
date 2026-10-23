import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/theme/theme.dart';

const interactionFeedbackCaptureKey = ValueKey('interaction-feedback-capture');

ThemeData interactionFeedbackTheme({required bool dark}) {
  final base = dark ? AppTheme.dark : AppTheme.light;
  if (!const bool.fromEnvironment('CAPTURE_UI')) return base;
  return base.copyWith(
    textTheme: base.textTheme.apply(
        fontFamily: 'Roboto', fontFamilyFallback: const ['DroidSansFallback']),
    primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: 'Roboto', fontFamilyFallback: const ['DroidSansFallback']),
    textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
            textStyle: WidgetStatePropertyAll(base.textTheme.labelLarge
                ?.copyWith(
                    fontFamily: 'Roboto',
                    fontFamilyFallback: const ['DroidSansFallback'])))),
    filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
            textStyle: WidgetStatePropertyAll(base.textTheme.labelLarge
                ?.copyWith(
                    fontFamily: 'Roboto',
                    fontFamilyFallback: const ['DroidSansFallback'])))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
            textStyle: WidgetStatePropertyAll(base.textTheme.labelLarge
                ?.copyWith(
                    fontFamily: 'Roboto',
                    fontFamilyFallback: const ['DroidSansFallback'])))),
  );
}

Future<void> loadInteractionFeedbackFonts() async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  for (final (family, asset) in [
    ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
    ('DroidSansFallback', 'assets/fonts/DroidSansFallback.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }
}

Future<void> captureInteractionFeedback(
    WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(interactionFeedbackCaptureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('/tmp/onlynote-interaction-feedback');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
