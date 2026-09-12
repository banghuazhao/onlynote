import 'package:flutter/material.dart';
import 'package:onlynote/presentation/theme/spacing.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      container: true,
      label: title,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(tokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon,
                          size: 22, color: context.colors.onPrimaryContainer),
                    ),
                    SizedBox(width: tokens.space2),
                  ],
                  Expanded(
                      child: Semantics(
                          header: true,
                          child: Text(title,
                              style: context.textStyles.titleMedium))),
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: tokens.space1),
                Text(subtitle!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    )),
              ],
              SizedBox(height: tokens.space4),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
