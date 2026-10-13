import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';

import 'note_theme_surface.dart';

@Preview(name: 'Stationery themes — light', size: Size(390, 720))
Widget noteThemeSurfaceLightPreview() => const _StationeryPreview();

@Preview(
  name: 'Stationery themes — dark',
  size: Size(390, 720),
  brightness: Brightness.dark,
)
Widget noteThemeSurfaceDarkPreview() => const _StationeryPreview(dark: true);

@Preview(name: 'Stationery themes — English 2×', size: Size(280, 720))
Widget noteThemeSurfaceLargeTextPreview() =>
    const _StationeryPreview(textScale: 2);

@Preview(name: 'Stationery themes — Hong Kong 2×', size: Size(280, 720))
Widget noteThemeSurfaceHongKongPreview() =>
    const _StationeryPreview(locale: Locale('zh', 'HK'), textScale: 2);

/// Uses only the canvas surface and local fixture state. No note, preferences,
/// purchases, media, or native plugins are loaded by the widget previewer.
class _StationeryPreview extends StatefulWidget {
  const _StationeryPreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final bool dark;
  final Locale locale;
  final double textScale;

  @override
  State<_StationeryPreview> createState() => _StationeryPreviewState();
}

class _StationeryPreviewState extends State<_StationeryPreview> {
  NoteTheme _theme = NoteTheme.classic;

  String _label(S strings, NoteTheme theme) => switch (theme) {
        NoteTheme.classic => strings.Note_Theme_Classic,
        NoteTheme.sticky => strings.Note_Theme_Sticky,
        NoteTheme.legalPad => strings.Note_Theme_Legal_Pad,
        NoteTheme.ruledNotebook => strings.Note_Theme_Ruled_Notebook,
        NoteTheme.gridPaper => strings.Note_Theme_Grid_Paper,
        NoteTheme.dottedJournal => strings.Note_Theme_Dotted_Journal,
        NoteTheme.kraftNotebook => strings.Note_Theme_Kraft_Notebook,
        NoteTheme.parchment => strings.Note_Theme_Parchment,
      };

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.locale,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          brightness: widget.dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('note-theme-preview-capture'),
            child: ColoredBox(
              color: widget.dark ? AppColors.deskDark : AppColors.desk,
              child: Builder(builder: (context) {
                final strings = S.of(context);
                final paperColor = noteThemePaperColor(_theme);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final theme in NoteTheme.values)
                          SizedBox(
                            width: 104,
                            child: Column(
                              children: [
                                NoteThemeSample(
                                  theme: theme,
                                  selected: _theme == theme,
                                ),
                                TextButton(
                                  key: ValueKey('preview-theme-${theme.name}'),
                                  onPressed: () =>
                                      setState(() => _theme = theme),
                                  child: Text(_label(strings, theme),
                                      textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: ColoredBox(
                        key: const ValueKey('note-theme-preview-sheet'),
                        color: paperColor,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: NoteThemePainter(
                                      theme: _theme,
                                      color: paperColor,
                                      sheet: true),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(28, 22, 14, 22),
                              child: DefaultTextStyle(
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 17,
                                  height: 1.55,
                                  fontFamily: 'Roboto',
                                  fontFamilyFallback: ['DroidSansFallback'],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(strings.Card_Style_Preview_Title,
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    Text(strings.Card_Style_Preview_Body),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: Icon(Icons.check_box_outlined,
                                              color: AppColors.ink, size: 22),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(strings
                                                .Card_Style_Preview_Task)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      );
}
