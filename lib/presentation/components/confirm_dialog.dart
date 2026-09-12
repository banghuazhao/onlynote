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
        scrollable: true,
        icon: Icon(Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.error),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).Cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError),
            child: Text(S.of(context).Delete),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
