import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'voice_memo_date_label.dart';

@Preview(name: 'Recording date — light', group: 'Note', size: Size(390, 400))
Widget voiceMemoDateLightPreview() => const _VoiceMemoDatePreview();

@Preview(
  name: 'Recording date — dark',
  group: 'Note',
  size: Size(390, 400),
  brightness: Brightness.dark,
)
Widget voiceMemoDateDarkPreview() => const _VoiceMemoDatePreview(dark: true);

@Preview(
    name: 'Recording date — Chinese 2× narrow',
    group: 'Note',
    size: Size(280, 600))
Widget voiceMemoDateChinesePreview() =>
    const _VoiceMemoDatePreview(locale: Locale('zh'), textScale: 2);

@Preview(
    name: 'Recording date — Hong Kong 2× narrow',
    group: 'Note',
    size: Size(280, 600))
Widget voiceMemoDateHongKongPreview() =>
    const _VoiceMemoDatePreview(locale: Locale('zh', 'HK'), textScale: 2);

/// The clock preference changes locally; this preview has no media dependency.
class _VoiceMemoDatePreview extends StatefulWidget {
  const _VoiceMemoDatePreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final bool dark;
  final Locale locale;
  final double textScale;

  @override
  State<_VoiceMemoDatePreview> createState() => _VoiceMemoDatePreviewState();
}

class _VoiceMemoDatePreviewState extends State<_VoiceMemoDatePreview> {
  bool _use24HourClock = false;

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
            alwaysUse24HourFormat: _use24HourClock,
            textScaler: TextScaler.linear(widget.textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile.adaptive(
                    key: const ValueKey('voice-memo-date-preview-clock'),
                    title: Text(widget.locale.languageCode == 'zh'
                        ? '24 小時制'
                        : '24-hour clock'),
                    value: _use24HourClock,
                    onChanged: (value) =>
                        setState(() => _use24HourClock = value),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Builder(builder: (context) {
                        final theme = Theme.of(context);
                        return Row(children: [
                          const Icon(Icons.mic_none_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(S.of(context).Voice_Memo,
                                    style: theme.textTheme.titleSmall),
                                Text('0:42', style: theme.textTheme.bodySmall),
                                const SizedBox(height: 4),
                                VoiceMemoDateLabel(
                                  createdAt: DateTime(2026, 10, 11, 17, 45),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
