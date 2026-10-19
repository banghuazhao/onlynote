import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A display preference shared by checklist readers, separate from note data.
class AppChecklistSettings extends ChangeNotifier {
  AppChecklistSettings({SharedPreferencesAsync? preferences})
      : _preferences = preferences,
        _persistent = true;

  /// Keeps isolated previews and tests independent of the native plugin.
  AppChecklistSettings.memory({bool completedExpanded = true})
      : _completedExpanded = completedExpanded,
        _persistent = false;

  static final AppChecklistSettings instance = AppChecklistSettings();
  static const storageKey = 'app_checklist_completed_expanded';

  SharedPreferencesAsync? _preferences;
  final bool _persistent;
  bool _completedExpanded = true;
  bool _disposed = false;
  int _revision = 0;
  Future<void>? _loading;
  Future<void> _writes = Future<void>.value();

  bool get completedExpanded => _completedExpanded;

  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  /// Loads once per instance. A slow read must never replace a newer choice.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    if (!_persistent || _disposed || _revision != 0) return;
    final revision = _revision;
    var expanded = true;
    try {
      expanded = await _store.getBool(storageKey) ?? true;
    } catch (_) {
      // An unavailable or unreadable display preference cannot block a note.
    }
    if (_disposed || revision != _revision) return;
    if (_completedExpanded != expanded) {
      _completedExpanded = expanded;
      notifyListeners();
    }
  }

  /// Applies immediately even if saving fails. Writes run in choice order so
  /// rapid taps cannot leave an older value on disk after a newer value.
  Future<bool> setCompletedExpanded(bool expanded) {
    if (_disposed) return Future<bool>.value(false);
    _revision++;
    if (_completedExpanded != expanded) {
      _completedExpanded = expanded;
      notifyListeners();
    }
    if (!_persistent) return Future<bool>.value(true);

    final write = _writes.then((_) async {
      try {
        await _store.setBool(storageKey, expanded);
        return true;
      } catch (_) {
        return false;
      }
    });
    _writes = write.then((_) {});
    return write;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
