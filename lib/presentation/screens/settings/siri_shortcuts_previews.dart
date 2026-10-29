import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'siri_shortcuts_screen.dart';

@Preview(name: 'Siri capture actions', size: Size(390, 844))
Widget siriShortcutsPreview() => _guidePreview();

@Preview(name: 'Siri capture dark', size: Size(390, 844))
Widget siriShortcutsDarkPreview() => _guidePreview(dark: true);

@Preview(name: 'Siri capture large Chinese', size: Size(320, 640))
Widget siriShortcutsChinesePreview() =>
    _guidePreview(locale: const Locale('zh', 'HK'), scale: 2);

@Preview(name: 'Siri pending captures accessibility', size: Size(320, 240))
Widget siriShortcutsPendingPreview() =>
    _guidePreview(scale: 3.2, pending: true);

Widget _guidePreview(
        {bool dark = false,
        Locale locale = const Locale('en'),
        double scale = 1,
        bool pending = false}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: child!),
      home: pending
          ? Builder(
              builder: (context) => Scaffold(
                  appBar: AppBar(
                      title: Text(S.of(context).Siri_Shortcuts_Title,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                  body: SiriShortcutsContent(
                      onOpen: previewOpenShortcuts,
                      onReview: previewReviewCaptures)))
          : SiriShortcutsScreen(openShortcuts: previewOpenShortcuts),
    );

Future<bool> previewOpenShortcuts() async => true;

void previewReviewCaptures() {}
