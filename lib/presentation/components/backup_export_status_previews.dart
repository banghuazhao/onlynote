import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

import 'backup_export_section.dart';

@Preview(
    name: 'Backup export — first use', group: 'Backup', size: Size(390, 500))
Widget backupExportFirstUsePreview() => const _BackupExportStatusPreview();

@Preview(name: 'Backup export — saved', group: 'Backup', size: Size(640, 400))
Widget backupExportSavedPreview() => const _BackupExportStatusPreview(
    destination: BackupExportDestination.saved);

@Preview(
  name: 'Backup export — shared, dark',
  group: 'Backup',
  size: Size(390, 500),
  brightness: Brightness.dark,
)
Widget backupExportSharedPreview() => const _BackupExportStatusPreview(
    destination: BackupExportDestination.shared, dark: true);

@Preview(
  name: 'Backup export — Chinese 2× narrow',
  group: 'Backup',
  size: Size(280, 600),
)
Widget backupExportChinesePreview() => const _BackupExportStatusPreview(
    destination: BackupExportDestination.shared, chinese: true, textScale: 2);

/// Native preferences and backup I/O stay outside these isolated controls.
class _BackupExportStatusPreview extends StatelessWidget {
  const _BackupExportStatusPreview({
    this.destination,
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
  });

  final BackupExportDestination? destination;
  final bool dark;
  final bool chinese;
  final double textScale;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: chinese ? const Locale('zh', 'HK') : const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            alwaysUse24HourFormat: true,
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BackupExportSection(
              saveToFile: destination == BackupExportDestination.saved,
              lastExport: destination == null
                  ? null
                  : BackupExportRecord(
                      exportedAt: DateTime(2026, 10, 19, 14, 30),
                      destination: destination!,
                    ),
              onExport: () {},
            ),
          ),
        ),
      );
}
