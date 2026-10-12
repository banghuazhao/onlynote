import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'reminder_date_label.dart';

@Preview(name: 'Reminder date — light', group: 'Note', size: Size(390, 300))
Widget reminderDateLightPreview() => const _ReminderDatePreview();

@Preview(
  name: 'Reminder date — dark',
  group: 'Note',
  size: Size(390, 300),
  brightness: Brightness.dark,
)
Widget reminderDateDarkPreview() => const _ReminderDatePreview(dark: true);

@Preview(
  name: 'Reminder date — Chinese 2× narrow',
  group: 'Note',
  size: Size(180, 400),
)
Widget reminderDateChinesePreview() =>
    const _ReminderDatePreview(locale: Locale('zh'), textScale: 2);

@Preview(
  name: 'Reminder date — Chinese HK 2× landscape',
  group: 'Note',
  size: Size(568, 180),
)
Widget reminderDateChineseHKPreview() =>
    const _ReminderDatePreview(locale: Locale('zh', 'HK'), textScale: 2);

/// The clock switch changes only local preview preferences.
class _ReminderDatePreview extends StatefulWidget {
  const _ReminderDatePreview({
    this.dark = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
  });

  final bool dark;
  final Locale locale;
  final double textScale;

  @override
  State<_ReminderDatePreview> createState() => _ReminderDatePreviewState();
}

class _ReminderDatePreviewState extends State<_ReminderDatePreview> {
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
                    key: const ValueKey('reminder-preview-clock'),
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
                        return ReminderDateLabel(
                          date: DateTime(2026, 10, 13, 17, 45),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
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
