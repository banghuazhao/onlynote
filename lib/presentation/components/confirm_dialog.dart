import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Shows a confirmation dialog and returns `true` only if the user confirmed
/// the destructive action. Use this before any irreversible delete so a
/// stray tap can't silently destroy user content.
///
/// Pass [destructive] as `false` for a change that rewrites rather than
/// destroys content, such as merging two tags, so the dialog does not warn
/// about losing anything.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  IconData? icon,
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return AlertDialog(
        scrollable: true,
        icon: Icon(
          icon ??
              (destructive
                  ? Icons.delete_outline_rounded
                  : Icons.help_outline_rounded),
          color: destructive ? colors.error : null,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).Cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError)
                : null,
            child: Text(confirmLabel ?? S.of(context).Delete),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
