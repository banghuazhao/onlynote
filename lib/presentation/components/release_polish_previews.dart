import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import 'empty_note_library.dart';
import 'missing_note_photo.dart';
import 'paper_note.dart';

@Preview(name: 'Empty library — light', group: 'Library', size: Size(390, 700))
Widget emptyLibraryLightPreview() => const _PolishPreview();

@Preview(
    name: 'Empty library — dark',
    group: 'Library',
    size: Size(390, 700),
    brightness: Brightness.dark)
Widget emptyLibraryDarkPreview() => const _PolishPreview(dark: true);

@Preview(
    name: 'Empty library — Chinese 2×', group: 'Library', size: Size(280, 700))
Widget emptyLibraryChinesePreview() =>
    const _PolishPreview(chinese: true, textScale: 2);

@Preview(name: 'Missing photo — light', group: 'Note', size: Size(390, 560))
Widget missingPhotoLightPreview() => const _PolishPreview(photo: true);

@Preview(
    name: 'Missing photo — dark',
    group: 'Note',
    size: Size(390, 560),
    brightness: Brightness.dark)
Widget missingPhotoDarkPreview() =>
    const _PolishPreview(photo: true, dark: true);

@Preview(
    name: 'Missing photo — Chinese 2×', group: 'Note', size: Size(280, 700))
Widget missingPhotoChinesePreview() =>
    const _PolishPreview(photo: true, chinese: true, textScale: 2);

/// Local display fixtures: no preferences, note writes, media or navigation.
class _PolishPreview extends StatelessWidget {
  const _PolishPreview({
    this.photo = false,
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool photo;
  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final base = dark ? AppTheme.dark : AppTheme.light;
    final buttonText = base.textTheme.labelLarge?.copyWith(
        fontFamily: 'Roboto', fontFamilyFallback: const ['DroidSansFallback']);
    final theme = base.copyWith(
      textTheme: base.textTheme.apply(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['DroidSansFallback']),
      primaryTextTheme: base.primaryTextTheme.apply(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['DroidSansFallback']),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(buttonText),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(buttonText),
        ),
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SafeArea(
          child: DeskSurface(
            child: photo
                ? Builder(builder: (context) {
                    final width =
                        math.min(320.0, MediaQuery.sizeOf(context).width - 48);
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          MissingNotePhoto(width: width, height: 240),
                          const SizedBox(height: 24),
                          const MissingNotePhoto(width: 64, height: 52),
                        ]),
                      ),
                    );
                  })
                : EmptyNoteLibrary(onAdd: () {}, onTemplates: () {}),
          ),
        ),
      ),
    );
  }
}
