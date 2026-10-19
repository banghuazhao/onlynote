import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum BackupExportDestination { saved, shared }

/// A completed backup export. The timestamp describes the exported snapshot,
/// rather than the later moment a save dialog or share sheet was closed.
class BackupExportRecord {
  BackupExportRecord({
    required DateTime exportedAt,
    required this.destination,
  }) : exportedAt = exportedAt.toUtc();

  final DateTime exportedAt;
  final BackupExportDestination destination;
}

/// Optional local metadata, kept outside note content and backup archives.
class BackupExportStatusStore {
  BackupExportStatusStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  static const storageKey = 'backup_export_status_v1';

  SharedPreferencesAsync? _preferences;
  BackupExportRecord? _current;
  var _loaded = false;
  var _revision = 0;
  Future<void>? _writeTail;

  // Plugin initialization can fail in previews or when platform storage is
  // unavailable, so keep it inside the guarded read/write operations.
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  Future<BackupExportRecord?> read() async {
    if (_loaded) return _current;
    final revision = _revision;
    BackupExportRecord? record;
    try {
      final raw = await _store.getString(storageKey);
      final value = raw == null ? null : jsonDecode(raw);
      if (value is Map && value['version'] == 1) {
        final milliseconds = value['exportedAtUtc'];
        final destination = value['destination'];
        if (milliseconds is int &&
            milliseconds >= 0 &&
            (destination == 'saved' || destination == 'shared')) {
          record = BackupExportRecord(
            exportedAt:
                DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true),
            destination: destination == 'saved'
                ? BackupExportDestination.saved
                : BackupExportDestination.shared,
          );
        }
      }
    } catch (_) {
      // Missing, malformed or unreadable metadata cannot block a backup.
    }
    // A delayed first read must not replace an export completed meanwhile.
    if (revision == _revision) {
      _current = record;
      _loaded = true;
    }
    return _current;
  }

  Future<void> record(BackupExportRecord record) async {
    _current = record;
    _loaded = true;
    _revision++;
    final previous = _writeTail;
    final completed = Completer<void>();
    _writeTail = completed.future;
    try {
      if (previous != null) await previous;
      await _store.setString(
          storageKey,
          jsonEncode({
            'version': 1,
            'exportedAtUtc': record.exportedAt.millisecondsSinceEpoch,
            'destination': record.destination.name,
          }));
    } catch (_) {
      // The session still shows the completed export if persistence fails.
    } finally {
      if (identical(_writeTail, completed.future)) _writeTail = null;
      completed.complete();
    }
  }
}
