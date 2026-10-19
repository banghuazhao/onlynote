import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/backup_export_section.dart';
import 'package:onlynote/presentation/components/backup_export_status_previews.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

void main() {
  for (final use24HourFormat in [false, true]) {
    testWidgets('backup status respects the $use24HourFormat clock preference',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: use24HourFormat),
          child: child!,
        ),
        home: Scaffold(
          body: BackupExportSection(
            saveToFile: true,
            lastExport: BackupExportRecord(
              exportedAt: DateTime(2026, 10, 19, 14, 30),
              destination: BackupExportDestination.saved,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final status = tester
          .widget<Text>(find.byKey(const ValueKey('backup-export-status')))
          .data!;
      expect(status, contains('2026'));
      expect(status, contains(use24HourFormat ? '14:30' : '2:30 PM'));
      expect(status, startsWith('Last backup saved:'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('backup status previews fit across sizes and localizations',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (preview, size, destination) in [
      (backupExportFirstUsePreview, const Size(390, 500), null),
      (
        backupExportSavedPreview,
        const Size(640, 400),
        BackupExportDestination.saved
      ),
      (
        backupExportSharedPreview,
        const Size(390, 500),
        BackupExportDestination.shared
      ),
      (
        backupExportChinesePreview,
        const Size(280, 600),
        BackupExportDestination.shared
      ),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      final section =
          tester.widget<BackupExportSection>(find.byType(BackupExportSection));
      expect(section.lastExport?.destination, destination);
      expect(
          find.byKey(const ValueKey('backup-export-status')), findsOneWidget);
      if (destination == null) {
        expect(find.text(S.current.Backup_Export_No_Record), findsOneWidget);
      }
      final button = find.byType(FilledButton);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      expect(tester.takeException(), isNull);
    }
  });
}
