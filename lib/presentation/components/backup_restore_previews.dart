import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';

import 'backup_restore_preview.dart';

@Preview(name: 'Restore backup — light', group: 'Backup', size: Size(390, 700))
Widget backupRestoreLightPreview() => const _BackupRestorePreview();

@Preview(
  name: 'Restore backup — dark',
  group: 'Backup',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget backupRestoreDarkPreview() => const _BackupRestorePreview(dark: true);

@Preview(
  name: 'Restore backup — Chinese 2× narrow',
  group: 'Backup',
  size: Size(280, 700),
)
Widget backupRestoreChinesePreview() =>
    const _BackupRestorePreview(chinese: true, textScale: 2);

@Preview(
    name: 'Restore backup — large counts',
    group: 'Backup',
    size: Size(390, 700))
Widget backupRestoreLargeCountsPreview() =>
    const _BackupRestorePreview(largeCounts: true);

@Preview(
  name: 'Restore backup — large counts dark',
  group: 'Backup',
  size: Size(390, 700),
  brightness: Brightness.dark,
)
Widget backupRestoreLargeCountsDarkPreview() =>
    const _BackupRestorePreview(dark: true, largeCounts: true);

@Preview(
  name: 'Restore backup — Chinese 2× landscape',
  group: 'Backup',
  size: Size(700, 280),
)
Widget backupRestoreChineseLandscapePreview() =>
    const _BackupRestorePreview(chinese: true, textScale: 2, largeCounts: true);

/// Only local metadata and Flutter widgets; no backup/media/native imports.
class _BackupRestorePreview extends StatelessWidget {
  const _BackupRestorePreview({
    this.dark = false,
    this.chinese = false,
    this.textScale = 1,
    this.largeCounts = false,
  });

  final bool dark;
  final bool chinese;
  final double textScale;
  final bool largeCounts;

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
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: const Color(0xFF685947),
          fontFamilyFallback: const ['DroidSansFallback'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: AlertDialog(
                scrollable: true,
                icon: const Icon(Icons.restore_page_outlined),
                title: Text(S.of(context).Backup_Restore),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackupRestorePreview(
                      metadata: BackupRestoreMetadata(
                        createdAt: DateTime(2026, 10, 7, 14, 30),
                        noteCount: largeCounts ? 10000 : 24,
                        activeNoteCount: largeCounts ? 9000 : 17,
                        archivedNoteCount: largeCounts ? 750 : 5,
                        trashedNoteCount: largeCounts ? 250 : 2,
                        folderCount: largeCounts ? 1000 : 3,
                        photoCount: largeCounts ? 10000 : 16,
                        templateCount: largeCounts ? 100 : 2,
                        recordingFileCount: largeCounts ? 10000 : 5,
                        savedViewCount: largeCounts ? 30 : 4,
                        historyVersionCount: largeCounts ? 1000000 : 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(S.of(context).Backup_Restore_Description),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: Text(S.of(context).Cancel),
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: Text(S.of(context).Restore),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
