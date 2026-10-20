import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import '../theme/theme.dart';
import 'note_tags_sheet.dart';

@Preview(name: 'Tag suggestions — light', group: 'Note', size: Size(390, 700))
Widget noteTagSuggestionsLightPreview() => const _TagSuggestionsPreview();

@Preview(
  name: 'Tag suggestions — dark',
  group: 'Note',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget noteTagSuggestionsDarkPreview() =>
    const _TagSuggestionsPreview(dark: true);

@Preview(
  name: 'Tag suggestions — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget noteTagSuggestionsChinesePreview() =>
    const _TagSuggestionsPreview(chinese: true, textScale: 2);

/// Uses the real editable sheet with local sample tags and no repository I/O.
class _TagSuggestionsPreview extends StatelessWidget {
  const _TagSuggestionsPreview({
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
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
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
        home: const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: NoteTagsSheet(
              tags: ['Work', '個人工作計劃'],
              suggestions: [
                'Work',
                'Home ideas',
                'Weekend [plans]',
                'Release draft',
                '茶室計劃',
                '茶葉清單',
              ],
            ),
          ),
        ),
      );
}
