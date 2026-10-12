import 'package:flutter/material.dart';

/// A share-menu action without export services, media or platform dependencies.
class NoteShareActionTile extends StatelessWidget {
  const NoteShareActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        onTap: onPressed,
      );
}
