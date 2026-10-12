import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'note_search_feedback.dart';

@Preview(
    name: 'Search recovery — light', group: 'Library', size: Size(390, 500))
Widget searchRecoveryLightPreview() => const _SearchRecoveryPreview();

@Preview(
  name: 'Search recovery — dark',
  group: 'Library',
  size: Size(390, 500),
  brightness: Brightness.dark,
)
Widget searchRecoveryDarkPreview() => const _SearchRecoveryPreview(dark: true);

@Preview(
  name: 'Search recovery — Chinese 2× narrow',
  group: 'Library',
  size: Size(280, 500),
)
Widget searchRecoveryChinesePreview() =>
    const _SearchRecoveryPreview(locale: Locale('zh', 'HK'), textScale: 2);

/// Interactive local fixtures, without repositories or native plugins.
class _SearchRecoveryPreview extends StatefulWidget {
  const _SearchRecoveryPreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final bool dark;
  final Locale locale;
  final double textScale;

  @override
  State<_SearchRecoveryPreview> createState() => _SearchRecoveryPreviewState();
}

class _SearchRecoveryPreviewState extends State<_SearchRecoveryPreview> {
  bool _hasQuery = true;
  bool _hasFilters = true;

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
          body: SafeArea(
            child: Builder(builder: (context) {
              final hasCriteria = _hasQuery || _hasFilters;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NoteSearchResultCount(count: hasCriteria ? 0 : 3),
                    if (hasCriteria) ...[
                      const SizedBox(height: 24),
                      Text(
                        S.of(context).No_Search_Results,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      NoteSearchRecovery(
                        onClearSearch: _hasQuery
                            ? () => setState(() => _hasQuery = false)
                            : null,
                        onClearFilters: _hasFilters
                            ? () => setState(() => _hasFilters = false)
                            : null,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      );
}
