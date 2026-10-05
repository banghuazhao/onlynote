import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the contextual widget invitation from returning once it is handled.
class WidgetDiscoverySettings extends ChangeNotifier {
  WidgetDiscoverySettings._();
  static final WidgetDiscoverySettings instance = WidgetDiscoverySettings._();

  static const _key = 'widget_discovery_handled';

  bool _handled = false;
  int _generation = 0;

  bool get handled => _handled;

  Future<void> load() async {
    final generation = _generation;
    final prefs = await SharedPreferences.getInstance();
    // A guide can be opened while preferences are loading. Do not overwrite
    // that newer decision with the value read at the beginning of this load.
    if (generation != _generation) return;
    _handled = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> complete() async {
    _generation++;
    final changed = !_handled;
    _handled = true;
    if (changed) notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (error) {
      // An optional invitation must never block opening the guide or notes.
      debugPrint('Could not save widget discovery preference: $error');
    }
  }
}
