import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onlynote/presentation/routes/routes.dart';

export 'package:onlynote/di/di.dart';
export 'package:onlynote/presentation/routes/routes.dart';

const _toastDuration = Duration(seconds: 2);

extension ContextEx on BuildContext {
  void showToast(
    String message, {
    bool isError = false,
  }) {
    showTransientSnackBar(
      this,
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
        duration: _toastDuration,
      ),
    );
  }
}

/// Shows [snackBar] and guarantees it goes away again.
///
/// ScaffoldMessenger starts the dismissal timer from inside its own `build`,
/// and only once the entry animation has completed. Messages here are posted
/// from bloc callbacks while a dialog, action sheet or page is being popped,
/// and in that window the timer can end up never being armed — the bar then
/// sits on screen covering content indefinitely (observed: a "Moved to Trash"
/// bar still up minutes and several screens later). Closing it ourselves
/// makes the message transient regardless of what the navigator was doing.
void showTransientSnackBar(BuildContext context, SnackBar snackBar) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(snackBar);

  var closed = false;
  Timer? fallback;
  unawaited(controller.closed.then((_) {
    closed = true;
    fallback?.cancel();
  }));
  fallback = Timer(snackBar.duration + const Duration(milliseconds: 100), () {
    if (!closed && messenger.mounted) controller.close();
  });
}

extension AppRouterEx on AppRouter {
  BuildContext get context => navigatorKey.currentContext!;
}
