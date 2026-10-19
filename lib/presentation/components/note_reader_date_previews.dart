import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_reader_date_label.dart';
import 'package:onlynote/presentation/theme/theme.dart';

@Preview(name: 'Reader date · English', size: Size(390, 300))
Widget noteReaderDateEnglishPreview() => const _ReaderDatePreview();

@Preview(name: 'Reader date · dark', size: Size(390, 300))
Widget noteReaderDateDarkPreview() => const _ReaderDatePreview(dark: true);

@Preview(name: 'Reader date · Chinese at 2×', size: Size(280, 460))
Widget noteReaderDateChinesePreview() =>
    const _ReaderDatePreview(locale: Locale('zh'), textScale: 2);

@Preview(name: 'Reader date · Hong Kong at 2×', size: Size(280, 460))
Widget noteReaderDateHongKongPreview() =>
    const _ReaderDatePreview(locale: Locale('zh', 'HK'), textScale: 2);

class _ReaderDatePreview extends StatefulWidget {
  const _ReaderDatePreview(
      {this.locale = const Locale('en'),
      this.dark = false,
      this.textScale = 1});

  final Locale locale;
  final bool dark;
  final double textScale;

  @override
  State<_ReaderDatePreview> createState() => _ReaderDatePreviewState();
}

class _ReaderDatePreviewState extends State<_ReaderDatePreview> {
  bool _use24HourFormat = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
        locale: widget.locale,
        theme: widget.dark ? AppTheme.dark : AppTheme.light,
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: _use24HourFormat,
            textScaler: TextScaler.linear(widget.textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                NoteReaderDateLabel(
                  dateTime: DateTime(2026, 10, 11, 17, 45),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  key: const ValueKey('reader-date-preview-clock'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.locale.languageCode == 'en'
                      ? '24-hour clock'
                      : '24小時制'),
                  value: _use24HourFormat,
                  onChanged: (value) =>
                      setState(() => _use24HourFormat = value),
                ),
              ],
            ),
          ),
        ),
      );
}
