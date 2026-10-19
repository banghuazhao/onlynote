import 'dart:async';

import 'memory_preferences.dart';

class ChecklistPreferences extends MemoryPreferences {
  final _state = _ChecklistPreferenceState();
  final writes = <bool>[];

  bool get failReads => _state.failReads;
  set failReads(bool value) => _state.failReads = value;
  bool get failWrites => _state.failWrites;
  set failWrites(bool value) => _state.failWrites = value;
  int get reads => _state.reads;
  Completer<bool?>? get pendingRead => _state.pendingRead;
  set pendingRead(Completer<bool?>? value) => _state.pendingRead = value;
  Completer<void>? get pendingWrite => _state.pendingWrite;
  set pendingWrite(Completer<void>? value) => _state.pendingWrite = value;

  @override
  Future<bool?> getBool(String key) async {
    _state.reads++;
    if (failReads) throw StateError('Preferences unavailable');
    if (pendingRead != null) return pendingRead!.future;
    return values[key] as bool?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    writes.add(value);
    final pending = pendingWrite;
    pendingWrite = null;
    if (pending != null) await pending.future;
    if (failWrites) throw StateError('Preferences unavailable');
    values[key] = value;
  }
}

class _ChecklistPreferenceState {
  bool failReads = false;
  bool failWrites = false;
  int reads = 0;
  Completer<bool?>? pendingRead;
  Completer<void>? pendingWrite;
}
