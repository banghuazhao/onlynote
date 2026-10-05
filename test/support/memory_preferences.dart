import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An uncached store shared by foreground and simulated background registries.
class MemoryPreferences extends Fake implements SharedPreferencesAsync {
  final values = <String, Object>{};

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<int?> getInt(String key) async => values[key] as int?;

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async => values.keys
      .where((key) => allowList == null || allowList.contains(key))
      .toSet();
}
