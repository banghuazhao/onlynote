import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'app_sheet.dart';
import 'template_name_search.dart';

@Preview(
    name: 'Template name search — light', group: 'Note', size: Size(390, 700))
Widget templateNameSearchLightPreview() => const _TemplateNameSearchPreview();

@Preview(
  name: 'Template name search — dark',
  group: 'Note',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget templateNameSearchDarkPreview() =>
    const _TemplateNameSearchPreview(dark: true);

@Preview(
  name: 'Template name search — Chinese 2× narrow',
  group: 'Note',
  size: Size(280, 700),
)
Widget templateNameSearchChinesePreview() =>
    const _TemplateNameSearchPreview(chinese: true, textScale: 2);

/// The fixture is names only; searching and selection use local UI state.
class _TemplateNameSearchPreview extends StatefulWidget {
  const _TemplateNameSearchPreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_TemplateNameSearchPreview> createState() =>
      _TemplateNameSearchPreviewState();
}

class _TemplateNameSearchPreviewState
    extends State<_TemplateNameSearchPreview> {
  final _controller = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: widget.chinese ? const Locale('zh', 'HK') : const Locale('en'),
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
          body: Builder(builder: (context) {
            final strings = S.of(context);
            const custom = [
              (id: 'work', name: 'Work routine'),
              (id: 'literal', name: 'C++ [2026]'),
              (id: 'cjk', name: '閱讀與研究茶😀'),
            ];
            final starters = [
              (id: 'shopping', name: strings.Template_Shopping_Title),
              (id: 'packing', name: strings.Template_Packing_Title),
              (id: 'dailyPlan', name: strings.Template_Daily_Plan_Title),
              (id: 'meeting', name: strings.Template_Meeting_Title),
            ];
            final customMatches = filterTemplateNames(custom, _controller.text,
                displayName: (template) => template.name);
            final starterMatches = filterTemplateNames(
                starters, _controller.text,
                displayName: (template) => template.name);
            Widget heading(String label) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Semantics(
                    header: true,
                    child: Text(label,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                );
            Widget row(String key, String name) => ListTile(
                  key: ValueKey(key),
                  minVerticalPadding: 16,
                  leading: const Icon(Icons.notes_outlined),
                  title: Text(name),
                  onTap: () => setState(() => _selected = name),
                );
            return Align(
              alignment: Alignment.bottomCenter,
              child: AppSheet(
                title: strings.Templates,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: TemplateNameSearchField(
                        controller: _controller,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_controller.text.trim().isNotEmpty &&
                        customMatches.isEmpty &&
                        starterMatches.isEmpty)
                      const TemplateNameSearchEmpty(),
                    heading(strings.My_Templates),
                    for (final template in customMatches)
                      row('custom-template-${template.id}', template.name),
                    heading(strings.Starter_Templates),
                    for (final template in starterMatches)
                      row('template-${template.id}', template.name),
                    if (_selected != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_selected!,
                            key: const ValueKey('template-search-selected')),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}
