import 'package:shared_preferences/shared_preferences.dart';

enum NoteEditorTipKind { formatting, imageLayout }

/// Optional, local guidance. A tip remains available until explicitly dismissed.
class NoteEditorTips {
  NoteEditorTips({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  static final instance = NoteEditorTips();
  static const storagePrefix = 'note_editor_tip_dismissed_v1.';

  SharedPreferencesAsync? _preferences;
  final Set<NoteEditorTipKind> _dismissed = {};

  // Initialize the platform plugin inside the optional-storage guards below.
  SharedPreferencesAsync get _instance =>
      _preferences ??= SharedPreferencesAsync();

  static String storageKey(NoteEditorTipKind kind) =>
      '$storagePrefix${kind.name}';

  Future<bool> shouldShow(NoteEditorTipKind kind) async {
    if (_dismissed.contains(kind)) return false;
    try {
      // Uncached reads respect dismissals made by another editor instance.
      if (await _instance.getBool(storageKey(kind)) == true) {
        _dismissed.add(kind);
      }
      // A dismissal can happen while the preference read is pending.
      return !_dismissed.contains(kind);
    } catch (_) {
      // Hints are optional. An unavailable preference plugin must never block
      // writing or repeatedly offer a tip whose dismissal cannot be read.
      return false;
    }
  }

  Future<void> dismiss(NoteEditorTipKind kind) async {
    // Hide immediately, including when persistence is slow or unavailable.
    _dismissed.add(kind);
    try {
      await _instance.setBool(storageKey(kind), true);
    } catch (_) {
      // Retain the dismissal for the current session if storage is unavailable.
    }
  }
}
