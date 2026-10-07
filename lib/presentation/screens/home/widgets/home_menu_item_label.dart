import 'package:flutter/material.dart';

class HomeMenuItemLabel extends StatelessWidget {
  const HomeMenuItemLabel(this.label,
      {super.key,
      required this.icon,
      this.activeSearch = false,
      this.searchDotKey});

  final String label;
  final IconData icon;
  final bool activeSearch;
  final Key? searchDotKey;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (activeSearch) ...[
            const SizedBox(width: 12),
            ExcludeSemantics(
              child: Badge(
                  key: searchDotKey,
                  smallSize: 8,
                  backgroundColor: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      );
}

class HomeSearchStatusIcon extends StatelessWidget {
  const HomeSearchStatusIcon(
      {super.key, required this.icon, required this.active, this.badgeKey});

  final IconData icon;
  final bool active;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) => Badge(
        key: badgeKey,
        smallSize: 8,
        isLabelVisible: active,
        backgroundColor: Theme.of(context).colorScheme.error,
        child: Icon(icon),
      );
}
