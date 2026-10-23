import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Read-only missing-photo feedback that retains the attachment's dimensions.
class MissingNotePhoto extends StatelessWidget {
  const MissingNotePhoto({
    super.key,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = S.maybeOf(context)?.Photo_Unavailable ?? 'Photo unavailable';
    final description = semanticLabel?.trim();
    final accessibleLabel = description == null || description.isEmpty
        ? label
        : '$label. $description';
    final size = width == null || height == null
        ? 24.0
        : (width! < height! ? width! : height!) * 0.42;
    final icon = Icon(
      Icons.image_not_supported_outlined,
      size: size.clamp(14.0, 40.0),
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      image: true,
      label: accessibleLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: accessibleLabel,
        excludeFromSemantics: true,
        child: Container(
          width: width,
          height: height,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: width != null &&
                  height != null &&
                  width!.isFinite &&
                  height!.isFinite
              ? LayoutBuilder(builder: (context, constraints) {
                  final textScaler = MediaQuery.textScalerOf(context);
                  if (constraints.maxWidth < textScaler.scale(100) ||
                      constraints.maxHeight < textScaler.scale(100)) {
                    return icon;
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(height: 8),
                        Text(label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                })
              : icon,
        ),
      ),
    );
  }
}
