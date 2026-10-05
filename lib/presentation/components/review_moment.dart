import 'package:flutter/material.dart';

/// A store prompt should not interrupt text entry or a background session.
bool get isReviewMomentIdle {
  if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
      WidgetsBinding.instance.platformDispatcher.views
          .any((view) => view.viewInsets.bottom > 0)) {
    return false;
  }
  final focusContext = FocusManager.instance.primaryFocus?.context;
  return focusContext?.widget is! EditableText &&
      focusContext?.findAncestorWidgetOfExactType<EditableText>() == null;
}
