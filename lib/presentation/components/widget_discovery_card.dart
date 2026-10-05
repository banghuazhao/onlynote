import 'package:flutter/material.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

/// A compact, nonmodal invitation that leaves the user's notes accessible.
class WidgetDiscoveryCard extends StatelessWidget {
  const WidgetDiscoveryCard({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onOpen,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: tokens.space2),
                  child: Icon(Icons.widgets_outlined,
                      color: context.colors.onSurfaceVariant, size: 22),
                ),
                SizedBox(width: tokens.space3),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: tokens.space2),
                    child: Semantics(
                      header: true,
                      child: Text(title, style: context.textStyles.titleSmall),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 22 + tokens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant)),
                  SizedBox(height: tokens.space1),
                  TextButton(
                    onPressed: onOpen,
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
