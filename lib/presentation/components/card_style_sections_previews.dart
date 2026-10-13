import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/card_style_sections.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';

@Preview(name: 'Card style sections', group: 'Card style', size: Size(390, 700))
Widget cardStyleSectionsLightPreview() => const _CardStyleSectionsPreview();

@Preview(
  name: 'Card style sections, dark',
  group: 'Card style',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget cardStyleSectionsDarkPreview() =>
    const _CardStyleSectionsPreview(dark: true);

@Preview(
  name: 'Card style sections, narrow Chinese 2×',
  group: 'Card style',
  size: Size(280, 700),
)
Widget cardStyleSectionsChinesePreview() =>
    const _CardStyleSectionsPreview(chinese: true, textScale: 2);

/// Exercises selection and horizontal scrolling without persistence or routes.
class _CardStyleSectionsPreview extends StatefulWidget {
  const _CardStyleSectionsPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_CardStyleSectionsPreview> createState() =>
      _CardStyleSectionsPreviewState();
}

class _CardStyleSectionsPreviewState extends State<_CardStyleSectionsPreview> {
  CardStyleSection _selected = CardStyleSection.theme;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: widget.dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF546D5C),
          fontFamilyFallback: const ['DroidSansFallback'],
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
            appBar: AppBar(title: Text(strings.Card_Style)),
            body: SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(strings.Card_Style_Preview),
                      const SizedBox(height: 8),
                      const NoteThemeSample(
                          theme: NoteTheme.legalPad, height: 120),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CardStyleSections(
                    sections: CardStyleSection.values,
                    selected: _selected,
                    onSelected: (section) =>
                        setState(() => _selected = section),
                  ),
                ),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('card-style-preview-panel-${_selected.name}'),
                    child: ListView(
                      key: const ValueKey('card-style-controls'),
                      primary: false,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                cardStyleSectionLabel(_selected, strings),
                                key: const ValueKey(
                                    'card-style-preview-selected'),
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
      );
}
