import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'app_sheet.dart';
import 'saved_view_save_action.dart';

@Preview(
    name: 'Saved views — below limit', group: 'Library', size: Size(390, 620))
Widget savedViewBelowLimitPreview() =>
    const _SavedViewLimitPreview(initialCount: 29);

@Preview(name: 'Saved views — at limit', group: 'Library', size: Size(390, 620))
Widget savedViewAtLimitPreview() => const _SavedViewLimitPreview();

@Preview(
  name: 'Saved views — at limit dark',
  group: 'Library',
  size: Size(390, 620),
  brightness: Brightness.dark,
)
Widget savedViewLimitDarkPreview() => const _SavedViewLimitPreview(dark: true);

@Preview(
  name: 'Saved views — Chinese 2× narrow',
  group: 'Library',
  size: Size(280, 700),
)
Widget savedViewLimitChinesePreview() =>
    const _SavedViewLimitPreview(chinese: true, textScale: 2);

/// Removing and adding fixture views only updates local preview state.
class _SavedViewLimitPreview extends StatefulWidget {
  const _SavedViewLimitPreview({
    this.initialCount = 30,
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final int initialCount;
  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  State<_SavedViewLimitPreview> createState() => _SavedViewLimitPreviewState();
}

class _SavedViewLimitPreviewState extends State<_SavedViewLimitPreview> {
  // The fixture mirrors the app's current cap without importing its store.
  static const _maxViews = 30;
  late int _viewCount = widget.initialCount;

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
            return Align(
              alignment: Alignment.bottomCenter,
              child: AppSheet(
                title: strings.Saved_Views,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('$_viewCount / $_maxViews'),
                    ),
                    if (_viewCount > 0)
                      ListTile(
                        leading: const Icon(Icons.bookmark_border_rounded),
                        title: Text(
                            widget.chinese ? '項目跟進' : 'Project follow-ups'),
                        trailing: IconButton(
                          key: const ValueKey('preview-delete-saved-view'),
                          tooltip: strings.Delete_View,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => setState(() => _viewCount--),
                        ),
                      ),
                    SavedViewSaveAction(
                      viewCount: _viewCount,
                      maxViews: _maxViews,
                      onSave: () => setState(() => _viewCount++),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
}
