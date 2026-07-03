import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Shows a confirmation dialog and returns `true` only if the user confirmed
/// the destructive action. Use this before any irreversible delete so a
/// stray tap can't silently destroy user content.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).Cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              S.of(context).Delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
