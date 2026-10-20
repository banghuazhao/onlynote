import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/backup_export_section.dart';
import 'package:onlynote/presentation/screens/settings/backup_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The production preference plugin exposes its test platform separately.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _PendingBackupPreferences extends SharedPreferencesAsyncPlatform {
  final values = <String, String>{};
  final writes = <String>[];
  final firstWrite = Completer<void>();

  @override
  Future<String?> getString(
          String key, SharedPreferencesOptions options) async =>
      values[key];

  @override
  Future<void> setString(
      String key, String value, SharedPreferencesOptions options) async {
    if (key == BackupExportStatusStore.storageKey) {
      writes.add(value);
      if (writes.length == 1) await firstWrite.future;
    }
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _screen() => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BackupScreen(
        exportBackup: () async => Uint8List.fromList([1]),
        shareBackup: (_) async =>
            const ShareResult('completed', ShareResultStatus.success),
        saveBackup: (_, __) async => true,
      ),
    );

BackupExportRecord? _visibleRecord(WidgetTester tester) => tester
    .widget<BackupExportSection>(find.byType(BackupExportSection))
    .lastExport;

void main() {
  testWidgets('default backup status survives reopen and orders pending writes',
      (tester) async {
    final platform = _PendingBackupPreferences();
    final previousPlatform = SharedPreferencesAsyncPlatform.instance;
    final previousTarget = debugDefaultTargetPlatformOverride;
    final oldDate = DateTime.utc(2020, 1, 2);
    final oldRecord = jsonEncode({
      'version': 1,
      'exportedAtUtc': oldDate.millisecondsSinceEpoch,
      'destination': 'saved',
    });
    platform.values[BackupExportStatusStore.storageKey] = oldRecord;
    SharedPreferencesAsyncPlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      SharedPreferencesAsyncPlatform.instance = previousPlatform;
      debugDefaultTargetPlatformOverride = previousTarget;
      if (!platform.firstWrite.isCompleted) platform.firstWrite.complete();
    });

    try {
      // The real default store is used on every screen, with its platform write
      // held pending after the save/share action itself has completed.
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();
      expect(_visibleRecord(tester)!.exportedAt, oldDate);
      await tester
          .tap(find.widgetWithText(FilledButton, S.current.Backup_Export));
      await tester.pumpAndSettle();
      final shared = _visibleRecord(tester)!;
      expect(shared.destination, BackupExportDestination.shared);
      expect(platform.writes, hasLength(1));
      expect(platform.values[BackupExportStatusStore.storageKey], oldRecord);

      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();
      expect(_visibleRecord(tester), same(shared));
      await tester
          .tap(find.widgetWithText(FilledButton, S.current.Backup_Save_As));
      await tester.pumpAndSettle();
      final saved = _visibleRecord(tester)!;
      expect(saved.destination, BackupExportDestination.saved);
      expect(platform.writes, hasLength(1));
      expect(platform.values[BackupExportStatusStore.storageKey], oldRecord);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();
      expect(_visibleRecord(tester), same(saved));
      platform.firstWrite.complete();
      await tester.pumpAndSettle();
      expect(
          platform.writes.map((raw) => (jsonDecode(raw) as Map)['destination']),
          ['shared', 'saved']);
      final persisted = await BackupExportStatusStore().read();
      expect(persisted!.destination, saved.destination);
      expect(persisted.exportedAt.millisecondsSinceEpoch,
          saved.exportedAt.millisecondsSinceEpoch);
      expect(tester.takeException(), isNull);
    } finally {
      // Transient feedback keeps a fallback dismissal timer even when its
      // original screen has already been removed.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      // Widget-test invariants run before addTearDown callbacks.
      debugDefaultTargetPlatformOverride = previousTarget;
    }
  });
}
