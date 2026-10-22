import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

import 'backup_settings_tile.dart';

@Preview(
  name: 'Backup settings — first use',
  group: 'Backup',
  size: Size(390, 300),
)
Widget backupSettingsFirstUsePreview() => const _BackupSettingsPreview();

@Preview(name: 'Backup settings — saved', group: 'Backup', size: Size(640, 300))
Widget backupSettingsSavedPreview() =>
    const _BackupSettingsPreview(destination: BackupExportDestination.saved);

@Preview(
  name: 'Backup settings — shared, dark',
  group: 'Backup',
  size: Size(390, 300),
  brightness: Brightness.dark,
)
Widget backupSettingsSharedPreview() => const _BackupSettingsPreview(
      destination: BackupExportDestination.shared,
      dark: true,
    );

@Preview(
  name: 'Backup settings — Chinese 2× narrow',
  group: 'Backup',
  size: Size(280, 500),
)
Widget backupSettingsChinesePreview() => const _BackupSettingsPreview(
      destination: BackupExportDestination.shared,
      chinese: true,
      textScale: 2,
    );

class _BackupSettingsPreview extends StatelessWidget {
  const _BackupSettingsPreview({
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
            child: BackupSettingsTile(
              lastExport: destination == null
                  ? null
                  : BackupExportRecord(
                      exportedAt: DateTime(2026, 10, 19, 14, 30),
                      destination: destination!,
                    ),
              onTap: () {},
            ),
          ),
        ),
      );
}
