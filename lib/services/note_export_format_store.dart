import 'package:onlynote/services/note_bulk_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A local readable-export preference, separate from note data and backups.
class NoteExportFormatStore {
  NoteExportFormatStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  /// One session-wide queue preserves choice order across reopened screens.
  static final instance = NoteExportFormatStore();
  static const storageKey = 'note_export_format';

  SharedPreferencesAsync? _preferences;
  NoteBulkExportFormat _current = NoteBulkExportFormat.markdown;
  bool _loaded = false;
  int _revision = 0;
  Future<void> _writes = Future<void>.value();

  // Creating the platform client can fail in previews or without native
  // storage, so keep initialization inside each guarded operation.
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  Future<NoteBulkExportFormat> read() async {
    if (_loaded) return _current;
    final revision = _revision;
    var format = NoteBulkExportFormat.markdown;
    try {
      final name = await _store.getString(storageKey);
      for (final value in NoteBulkExportFormat.values) {
        if (value.name == name) {
          format = value;
          break;
        }
      }
    } catch (_) {
      // Missing, malformed or unavailable preferences use the safe default.
    }
    if (revision == _revision) {
      _current = format;
      _loaded = true;
    }
    return _current;
  }

  /// Keep the session's choice immediately; serialize disk writes so rapid
  /// choices cannot let an older value finish after the latest one.
  Future<void> write(NoteBulkExportFormat format) {
    _revision++;
    _current = format;
    _loaded = true;
    final write = _writes.then((_) async {
      try {
        await _store.setString(storageKey, format.name);
      } catch (_) {
        // Saving a display preference must never interrupt an export.
      }
    });
    _writes = write;
    return write;
  }
}
