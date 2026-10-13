import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'backup_export_section.dart';
import 'note_insert_sheet.dart';

@Preview(name: 'Mac insert menu', group: 'Desktop', size: Size(600, 480))
Widget desktopInsertMenuPreview() =>
    _host(const Scaffold(body: NoteInsertSheet(mobileCapture: false)));

@Preview(name: 'Phone insert menu', group: 'Desktop', size: Size(390, 650))
Widget mobileInsertMenuPreview() =>
    _host(const Scaffold(body: NoteInsertSheet(mobileCapture: true)));

@Preview(name: 'Mac backup Save As', group: 'Desktop', size: Size(900, 560))
Widget desktopBackupSavePreview() => _host(const _BackupPreview());

@Preview(
    name: 'Mac backup, narrow Chinese 2×',
    group: 'Desktop',
    size: Size(320, 680))
Widget desktopBackupChinesePreview() =>
    _host(const _BackupPreview(), chinese: true, scale: 2);

Widget _host(Widget screen, {bool chinese = false, double scale = 1}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light.copyWith(platform: TargetPlatform.macOS),
      locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: screen,
    );

/// Preview clicks only acknowledge the action; no filesystem or plugin calls.
class _BackupPreview extends StatelessWidget {
  const _BackupPreview();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(S.of(context).Backup_Title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: BackupExportSection(
                saveToFile: true,
                onExport: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).Backup_Export_Saved))),
              ),
            ),
          ),
        ),
      );
}
