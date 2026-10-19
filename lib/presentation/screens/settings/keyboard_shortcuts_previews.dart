import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';

import 'keyboard_shortcuts_screen.dart';

@Preview(
    name: 'Mac keyboard shortcuts', group: 'Settings', size: Size(1000, 760))
Widget keyboardShortcutsPreview() => _host();

@Preview(
  name: 'Mac keyboard shortcuts, dark',
  group: 'Settings',
  size: Size(1000, 760),
  brightness: Brightness.dark,
)
Widget keyboardShortcutsDarkPreview() => _host(dark: true);

@Preview(
  name: 'Mac keyboard shortcuts, narrow Chinese 2×',
  group: 'Settings',
  size: Size(280, 600),
)
Widget keyboardShortcutsChinesePreview() =>
    _host(locale: const Locale('zh', 'HK'), scale: 2);

Widget _host({
  bool dark = false,
  Locale locale = const Locale('en'),
  double scale = 1,
}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: (dark ? AppTheme.dark : AppTheme.light)
          .copyWith(platform: TargetPlatform.macOS),
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
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const KeyboardShortcutsScreen(),
    );
