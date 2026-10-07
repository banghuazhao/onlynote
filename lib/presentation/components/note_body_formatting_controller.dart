import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Connects a formatting accessory to the native field currently being edited.
///
/// Photo notes contain several text fields. The editor translates their local
/// selection into the single document before an external toolbar applies a style.
class NoteBodyFormattingController extends ChangeNotifier {
  Object? _owner;
  FocusNode? _activeFocusNode;
  VoidCallback? _prepareSelection;
  bool _disposed = false;
  bool _notificationScheduled = false;

  bool get hasFocus => _activeFocusNode?.hasFocus ?? false;
  FocusNode? get activeFocusNode => _activeFocusNode;

  VoidCallback attach({
    required Object owner,
    required FocusNode activeFocusNode,
    required VoidCallback prepareSelection,
  }) {
    if (_disposed) return () {};
    _owner = owner;
    _prepareSelection = prepareSelection;
    _setFocusNode(activeFocusNode);
    return () {
      if (_disposed || !identical(_owner, owner)) return;
      _owner = null;
      _prepareSelection = null;
      _setFocusNode(null);
    };
  }

  void updateActiveFocusNode({
    required Object owner,
    required FocusNode activeFocusNode,
  }) {
    if (_disposed || !identical(_owner, owner)) return;
    _setFocusNode(activeFocusNode);
  }

  void prepareFormattingSelection() {
    if (!_disposed) _prepareSelection?.call();
  }

  void _setFocusNode(FocusNode? node) {
    if (identical(_activeFocusNode, node)) return;
    _activeFocusNode?.removeListener(_focusChanged);
    _activeFocusNode = node;
    _activeFocusNode?.addListener(_focusChanged);
    _notifyChanged();
  }

  void _focusChanged() => _notifyChanged();

  void _notifyChanged() {
    if (_disposed) return;
    // Segment fields can be added or retired while their parent is rebuilding.
    // Notify accessories after that frame instead of rebuilding an ancestor
    // from a child's build/update lifecycle.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_notificationScheduled) return;
      _notificationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notificationScheduled = false;
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _activeFocusNode?.removeListener(_focusChanged);
    _activeFocusNode = null;
    _owner = null;
    _prepareSelection = null;
    super.dispose();
  }
}
