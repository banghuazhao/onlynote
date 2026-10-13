import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_theme_choices.dart';
import 'package:onlynote/presentation/components/note_theme_labels.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';

@Preview(name: 'Note themes, free', group: 'Note themes', size: Size(390, 780))
Widget noteThemeChoicesLightPreview() => const _NoteThemesPreview();

@Preview(
  name: 'Note themes, Premium dark',
  group: 'Note themes',
  size: Size(390, 780),
  brightness: Brightness.dark,
)
Widget noteThemeChoicesDarkPreview() =>
    const _NoteThemesPreview(dark: true, premium: true);

@Preview(
  name: 'Note themes, narrow Chinese 2×',
  group: 'Note themes',
  size: Size(280, 700),
)
Widget noteThemeChoicesChinesePreview() =>
    const _NoteThemesPreview(chinese: true, textScale: 2);

class _NoteThemesPreview extends StatefulWidget {
  const _NoteThemesPreview({
    this.dark = false,
    this.premium = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool premium;
  final bool chinese;
  final double textScale;

  @override
  State<_NoteThemesPreview> createState() => _NoteThemesPreviewState();
}

class _NoteThemesPreviewState extends State<_NoteThemesPreview> {
  late NoteTheme? _selected =
      widget.premium ? NoteTheme.dottedJournal : NoteTheme.sticky;
  static const _inherited = NoteTheme.ruledNotebook;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamilyFallback: const ['DroidSansFallback'],
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF546D5C),
            brightness: widget.dark ? Brightness.dark : Brightness.light,
          ),
        ),
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
          ),
          child: child!,
        ),
        home: Builder(builder: (context) {
          final strings = S.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(strings.Note_Theme)),
            body: ListView(
              key: const ValueKey('note-theme-preview-scroll'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(strings.Note_Theme_Description),
                const SizedBox(height: 12),
                NoteThemeSample(theme: _selected ?? _inherited, height: 96),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _selected == null
                        ? strings.Card_Style_Use_Default
                        : noteThemeLabel(_selected!, strings),
                    key: const ValueKey('note-theme-preview-selected'),
                  ),
                ),
                const SizedBox(height: 16),
                NoteThemeChoices(
                  selected: _selected,
                  inheritedTheme: _inherited,
                  showInherited: true,
                  premiumAvailable: widget.premium,
                  onSelected: (theme) => setState(() => _selected = theme),
                ),
              ],
            ),
          );
        }),
      );
}
