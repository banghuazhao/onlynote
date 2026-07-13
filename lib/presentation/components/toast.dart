import 'package:flutter/material.dart';
import 'package:onlynote/presentation/routes/routes.dart';

export 'package:onlynote/di/di.dart';
export 'package:onlynote/presentation/routes/routes.dart';

extension ContextEx on BuildContext {
  void showToast(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

extension AppRouterEx on AppRouter {
  BuildContext get context => navigatorKey.currentContext!;
}
