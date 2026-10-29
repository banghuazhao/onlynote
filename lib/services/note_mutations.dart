import 'dart:async';

/// Keeps read/modify/save actions from replacing another action's newer note.
///
/// Repository writes alone cannot do this: two callers can both read the same
/// snapshot before either saves. Hold the queue across the whole transaction.
class NoteMutations {
  NoteMutations._();

  static final _zoneKey = Object();
  static Object? _active;
  static Future<void>? _tail;

  static Future<T> run<T>(Future<T> Function() mutation) {
    // Widget imports and editor transfers can be part of a larger action.
    // Their nested transactions share its reservation instead of deadlocking.
    if (_active != null && identical(Zone.current[_zoneKey], _active)) {
      return Future<T>.sync(mutation);
    }
    final previous = _tail;
    final finished = Completer<void>();
    _tail = finished.future;
    return () async {
      if (previous != null) await previous;
      final token = Object();
      _active = token;
      try {
        return await runZoned(mutation, zoneValues: {_zoneKey: token});
      } finally {
        _active = null;
        if (identical(_tail, finished.future)) _tail = null;
        finished.complete();
      }
    }();
  }
}
