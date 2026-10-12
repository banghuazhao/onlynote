import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'app_sheet.dart';
import 'note_share_action_tile.dart';

@Preview(name: 'Copy note text — light', group: 'Note', size: Size(390, 620))
Widget noteTextCopyLightPreview() => const _NoteTextCopyPreview();

@Preview(
  name: 'Copy note text — dark',
  group: 'Note',
  size: Size(390, 620),
  brightness: Brightness.dark,
)
Widget noteTextCopyDarkPreview() => const _NoteTextCopyPreview(dark: true);

@Preview(
  name: 'Copy note text — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget noteTextCopyChinesePreview() =>
    const _NoteTextCopyPreview(chinese: true, textScale: 2);

/// Local actions demonstrate the menu and feedback without clipboard access.
class _NoteTextCopyPreview extends StatelessWidget {
  const _NoteTextCopyPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(builder: (context) {
            final strings = S.of(context);
            return Align(
              alignment: Alignment.bottomCenter,
              child: AppSheet(
                title: strings.Share,
                child: Column(
                  children: [
                    NoteShareActionTile(
                      icon: Icons.text_snippet_outlined,
                      title: strings.Share_Plain_Text,
                      description: strings.Share_Text_Description,
                      onPressed: () {},
                    ),
                    NoteShareActionTile(
                      key: const ValueKey('note-share-copyText'),
                      icon: Icons.copy_outlined,
                      title: strings.Share_Copy_Text,
                      description: strings.Share_Copy_Text_Description,
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(strings.Share_Text_Copied),
                        duration: const Duration(seconds: 2),
                      )),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}
