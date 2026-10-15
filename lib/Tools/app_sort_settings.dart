import 'package:shared_preferences/shared_preferences.dart';
import 'package:onlynote/services/note_sort.dart';

export 'package:onlynote/services/note_sort.dart' show NoteSortOrder;

/// Library sort order preference, persisted via SharedPreferences.
///
/// An unreadable, missing, or unknown stored value falls back to
/// [NoteSortOrder.manual] — the order every release before this one used — so
/// a failed read can only ever show the arrangement the user already knows.
class AppSortSettings {
  AppSortSettings({SharedPreferencesAsync? preferences})
      : _preferences = preferences;
  static final AppSortSettings instance = AppSortSettings();

  static const storageKey = 'app_note_sort_order';

  SharedPreferencesAsync? _preferences;
  NoteSortOrder _order = NoteSortOrder.manual;

  NoteSortOrder get order => _order;

  /// Built on first read or write, never at construction: the plugin's
  /// platform instance throws until it is registered, and merely holding a
  /// view preference must not depend on that having happened yet.
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  Future<void> load() async {
    try {
      final stored = await _store.getString(storageKey);
      _order = NoteSortOrder.values.firstWhere(
        (order) => order.name == stored,
        orElse: () => NoteSortOrder.manual,
      );
    } catch (_) {
      // Sorting is a view preference. Startup must not fail over it.
      _order = NoteSortOrder.manual;
    }
  }

  /// Applies [order] in memory even when the write fails, so the library still
  /// obeys the choice the user just made; only its persistence is lost.
  /// Returns whether the choice was stored.
  Future<bool> setOrder(NoteSortOrder order) async {
    _order = order;
    try {
      await _store.setString(storageKey, order.name);
      return true;
    } catch (_) {
      return false;
    }
  }
}
