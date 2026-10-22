import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/backup_export_section.dart';
import 'package:onlynote/presentation/components/backup_settings_tile.dart';
import 'package:onlynote/presentation/screens/settings/backup_screen.dart';
import 'package:onlynote/presentation/screens/settings/settings_screen.dart';
import 'package:onlynote/presentation/theme/theme.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';
import 'package:onlynote/services/purchase_service.dart';

class _StatusStore extends BackupExportStatusStore {
  BackupExportRecord? current;
  var failRead = false;
  var reads = 0;
  var writes = 0;

  @override
  Future<BackupExportRecord?> read() async {
    reads++;
    if (failRead) throw StateError('Status unavailable');
    return current;
  }

  @override
  Future<void> record(BackupExportRecord record) async {
    writes++;
    current = record;
  }
}

class _PendingStatusStore extends _StatusStore {
  final pendingReads = <Completer<BackupExportRecord?>>[];

  @override
  Future<BackupExportRecord?> read() {
    final result = Completer<BackupExportRecord?>();
    pendingReads.add(result);
    return result.future;
  }
}

class _NavigationObserver extends NavigatorObserver {
  var pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}

Widget _host(
  Widget home, {
  NavigatorObserver? observer,
  bool use24HourFormat = true,
}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [if (observer != null) observer],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: use24HourFormat),
        child: child!,
      ),
      home: home,
    );

SettingsScreen _settings(BackupExportStatusStore store) => SettingsScreen(
      purchases: PurchaseService(isIOS: false),
      backupStatusStore: store,
    );

BackupExportRecord _record(
  BackupExportDestination destination, {
  int year = 2026,
}) =>
    BackupExportRecord(
      exportedAt: DateTime(year, 10, 19, 14, 30),
      destination: destination,
    );

Finder get _backupTile => find.byKey(const ValueKey('settings-backup'));

String _settingsLabel(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('settings-backup-status')))
    .data!;

Future<void> _openBackup(WidgetTester tester) async {
  await tester.ensureVisible(_backupTile);
  await tester.pumpAndSettle();
  await tester.tap(_backupTile);
  await tester.pumpAndSettle();
  expect(find.byType(BackupScreen), findsOneWidget);
}

Future<void> _returnToSettings(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(BackupScreen))).pop();
  await tester.pumpAndSettle();
}

void main() {
  for (final destination in [null, ...BackupExportDestination.values]) {
    testWidgets('settings shows existing $destination status without writing', (
      tester,
    ) async {
      final store = _StatusStore()
        ..current = destination == null ? null : _record(destination);
      await tester.pumpWidget(_host(_settings(store)));
      await tester.pumpAndSettle();
      final label = _settingsLabel(tester);
      if (destination == null) {
        expect(label, S.current.Backup_Export_No_Record);
      } else {
        expect(label, contains('2026'));
        expect(label, contains('14:30'));
        expect(
          label,
          startsWith(
            destination == BackupExportDestination.saved
                ? 'Last backup saved:'
                : 'Last backup shared:',
          ),
        );
      }
      expect(store.reads, 1);
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final use24HourFormat in [false, true]) {
    testWidgets('settings and export share $use24HourFormat clock formatting', (
      tester,
    ) async {
      final record = _record(BackupExportDestination.shared);
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Column(
              children: [
                BackupSettingsTile(lastExport: record),
                BackupExportSection(saveToFile: false, lastExport: record),
              ],
            ),
          ),
          use24HourFormat: use24HourFormat,
        ),
      );
      await tester.pumpAndSettle();
      final exportLabel = tester
          .widget<Text>(find.byKey(const ValueKey('backup-export-status')))
          .data!;
      expect(_settingsLabel(tester), exportLabel);
      expect(exportLabel, contains(use24HourFormat ? '14:30' : '2:30 PM'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unavailable status leaves backup navigation usable', (
    tester,
  ) async {
    final store = _StatusStore()..failRead = true;
    await tester.pumpWidget(_host(_settings(store)));
    await tester.pumpAndSettle();
    expect(_settingsLabel(tester), S.current.Backup_Export_No_Record);
    await _openBackup(tester);
    await _returnToSettings(tester);
    expect(_settingsLabel(tester), S.current.Backup_Export_No_Record);
    expect(store.reads, 3);
    expect(store.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'returning from backup refreshes status and a failed read retains it',
    (tester) async {
      final store = _StatusStore()
        ..current = _record(BackupExportDestination.saved, year: 2020);
      await tester.pumpWidget(_host(_settings(store)));
      await tester.pumpAndSettle();
      expect(_settingsLabel(tester), contains('2020'));
      await _openBackup(tester);
      store.current = _record(BackupExportDestination.shared);
      await _returnToSettings(tester);
      final refreshed = _settingsLabel(tester);
      expect(refreshed, startsWith('Last backup shared:'));
      expect(refreshed, contains('2026'));
      await _openBackup(tester);
      store.failRead = true;
      await _returnToSettings(tester);
      expect(_settingsLabel(tester), refreshed);
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late initial read cannot overwrite status loaded after returning',
    (tester) async {
      final store = _PendingStatusStore();
      await tester.pumpWidget(_host(_settings(store)));
      await tester.pumpAndSettle();
      await _openBackup(tester);
      await _returnToSettings(tester);
      expect(store.pendingReads, hasLength(3));
      store.pendingReads[2].complete(_record(BackupExportDestination.shared));
      await tester.pumpAndSettle();
      final refreshed = _settingsLabel(tester);
      store.pendingReads[0].complete(
        _record(BackupExportDestination.saved, year: 2020),
      );
      store.pendingReads[1].completeError(StateError('Disposed backup screen'));
      await tester.pumpAndSettle();
      expect(_settingsLabel(tester), refreshed);
      expect(refreshed, startsWith('Last backup shared:'));
      expect(refreshed, contains('2026'));
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final failRead in [false, true]) {
    testWidgets('status completion after disposal is safe: error $failRead', (
      tester,
    ) async {
      final store = _PendingStatusStore();
      await tester.pumpWidget(_host(_settings(store)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      if (failRead) {
        store.pendingReads.single.completeError(
          StateError('Status unavailable'),
        );
      } else {
        store.pendingReads.single.complete(
          _record(BackupExportDestination.saved),
        );
      }
      await tester.pumpAndSettle();
      expect(store.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rapid backup taps push only one route', (tester) async {
    final store = _StatusStore();
    final observer = _NavigationObserver();
    await tester.pumpWidget(_host(_settings(store), observer: observer));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_backupTile);
    await tester.pumpAndSettle();
    final onTap = tester.widget<ListTile>(_backupTile).onTap!;
    onTap();
    onTap();
    await tester.pumpAndSettle();
    expect(find.byType(BackupScreen), findsOneWidget);
    expect(observer.pushes, 2); // Initial Settings route and one backup route.
    await _returnToSettings(tester);
    expect(tester.takeException(), isNull);
  });
}
