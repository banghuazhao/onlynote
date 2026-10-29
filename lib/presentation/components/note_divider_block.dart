import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/colors.dart';

/// A saved document block, distinct from ordinary text or menu separators.
class NoteDividerBlock extends StatelessWidget {
  const NoteDividerBlock({super.key, this.onRemove});

  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Semantics(
      label: strings.Editor_Divider,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.ink.withValues(alpha: .35),
                ),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: '${strings.Delete} ${strings.Editor_Divider}',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onRemove,
                color: AppColors.ink.withValues(alpha: .65),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
