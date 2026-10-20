import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/backup/backup_export_status.dart';

import '../support/memory_preferences.dart';

class _PendingReadPreferences extends MemoryPreferences {
  final pending = Completer<String?>();

  @override
  Future<String?> getString(String key) => pending.future;
}

class _FailingPreferences extends MemoryPreferences {
  @override
  Future<String?> getString(String key) async => throw StateError('No store');

  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('No storage space');
}

class _PendingWritePreferences extends MemoryPreferences {
  _PendingWritePreferences({this.failFirst = false});

  final firstWrite = Completer<void>();
  final writes = <String>[];
  final bool failFirst;

  @override
  Future<void> setString(String key, String value) async {
    writes.add(value);
    if (writes.length == 1) {
      await firstWrite.future;
      if (failFirst) throw StateError('First write failed');
    }
    await super.setString(key, value);
  }
}

void main() {
  final snapshot = DateTime.utc(2026, 10, 19, 1, 25);

  for (final destination in BackupExportDestination.values) {
    test('$destination is stored as one UTC record and survives reopening',
        () async {
      final preferences = MemoryPreferences();
      final status = BackupExportStatusStore(preferences: preferences);
      expect(await status.read(), isNull);
      await status.record(
          BackupExportRecord(exportedAt: snapshot, destination: destination));
      expect(preferences.values.keys, [BackupExportStatusStore.storageKey]);
      final reopened =
          await BackupExportStatusStore(preferences: preferences).read();
      expect(reopened!.destination, destination);
      expect(reopened.exportedAt, snapshot);
      expect(reopened.exportedAt.isUtc, isTrue);
    });
  }

  test('malformed and unsupported records fall back to no record', () async {
    for (final raw in <Object>[
      'not json',
      '[]',
      'null',
      '{}',
      123,
      jsonEncode({'version': 2, 'exportedAtUtc': 1, 'destination': 'saved'}),
      jsonEncode({'version': 1, 'exportedAtUtc': 1, 'destination': 'unknown'}),
      jsonEncode({'version': 1, 'exportedAtUtc': -1, 'destination': 'saved'}),
      jsonEncode(
          {'version': 1, 'exportedAtUtc': 'bad', 'destination': 'saved'}),
      jsonEncode({'version': 1, 'exportedAtUtc': 1.5, 'destination': 'saved'}),
      jsonEncode({
        'version': 1,
        'exportedAtUtc': 8640000000000001,
        'destination': 'saved'
      }),
    ]) {
      final preferences = MemoryPreferences()
        ..values[BackupExportStatusStore.storageKey] = raw;
      expect(await BackupExportStatusStore(preferences: preferences).read(),
          isNull,
          reason: '$raw');
    }
  });

  test('unavailable preferences do not fail the exported result', () async {
    final store = BackupExportStatusStore(preferences: _FailingPreferences());
    expect(await store.read(), isNull);
    await expectLater(
        store.record(BackupExportRecord(
            exportedAt: snapshot, destination: BackupExportDestination.saved)),
        completes);
    expect((await store.read())!.exportedAt, snapshot);
    final unavailablePlugin = BackupExportStatusStore();
    expect(await unavailablePlugin.read(), isNull);
    await expectLater(
        unavailablePlugin.record(BackupExportRecord(
            exportedAt: snapshot, destination: BackupExportDestination.shared)),
        completes);
  });

  test('a slow initial read cannot replace a newer export', () async {
    final preferences = _PendingReadPreferences();
    final store = BackupExportStatusStore(preferences: preferences);
    final initialRead = store.read();
    await store.record(BackupExportRecord(
        exportedAt: snapshot, destination: BackupExportDestination.shared));
    preferences.pending.complete(jsonEncode({
      'version': 1,
      'exportedAtUtc': DateTime.utc(2025).millisecondsSinceEpoch,
      'destination': 'saved',
    }));
    expect((await initialRead)!.exportedAt, snapshot);
    expect((await store.read())!.destination, BackupExportDestination.shared);
  });

  for (final failFirst in [false, true]) {
    test('successive writes remain ordered when first fails: $failFirst',
        () async {
      final preferences = _PendingWritePreferences(failFirst: failFirst);
      final store = BackupExportStatusStore(preferences: preferences);
      final first = store.record(BackupExportRecord(
          exportedAt: DateTime.utc(2025),
          destination: BackupExportDestination.saved));
      final latest = BackupExportRecord(
          exportedAt: snapshot, destination: BackupExportDestination.shared);
      final second = store.record(latest);
      expect(preferences.writes, hasLength(1));
      expect(await store.read(), same(latest));
      preferences.firstWrite.complete();
      await Future.wait([first, second]);
      expect(preferences.writes, hasLength(2));
      final reopened =
          await BackupExportStatusStore(preferences: preferences).read();
      expect(reopened!.exportedAt, snapshot);
      expect(reopened.destination, BackupExportDestination.shared);
    });
  }
}
