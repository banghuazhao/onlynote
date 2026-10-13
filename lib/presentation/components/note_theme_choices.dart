import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/domain/model/note_theme.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/note_theme_labels.dart';
import 'package:onlynote/presentation/components/note_theme_surface.dart';

/// A local theme selection. Premium choices remain available to preview.
class NoteThemeChoices extends StatelessWidget {
  const NoteThemeChoices({
    super.key,
    required this.selected,
    required this.onSelected,
    this.inheritedTheme = NoteTheme.classic,
    this.showInherited = false,
    this.premiumAvailable = false,
    this.enabled = true,
  });

  final NoteTheme? selected;
  final ValueChanged<NoteTheme?> onSelected;
  final NoteTheme inheritedTheme;
  final bool showInherited;
  final bool premiumAvailable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final theme in [
          if (showInherited) null,
          ...NoteTheme.values,
        ]) ...[
          if (theme != (showInherited ? null : NoteTheme.values.first))
            const SizedBox(height: 8),
          _NoteThemeChoice(
            key: ValueKey('note-theme-choice-${theme?.name ?? "default"}'),
            theme: theme ?? inheritedTheme,
            label: theme == null
                ? strings.Card_Style_Use_Default
                : noteThemeLabel(theme, strings),
            selected: theme == selected,
            premium: theme?.isPremium == true,
            locked: theme?.isPremium == true && !premiumAvailable,
            onPressed: enabled
                ? () {
                    if (!context.mounted ||
                        ModalRoute.of(context)?.isCurrent == false) {
                      return;
                    }
                    onSelected(theme);
                  }
                : null,
          ),
        ],
      ],
    );
  }
}

class _NoteThemeChoice extends StatelessWidget {
  const _NoteThemeChoice({
    super.key,
    required this.theme,
    required this.label,
    required this.selected,
    required this.premium,
    required this.locked,
    required this.onPressed,
  });

  final NoteTheme theme;
  final String label;
  final bool selected;
  final bool premium;
  final bool locked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onPressed != null,
        child: Material(
          color: selected ? colors.secondaryContainer : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 84),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(builder: (context, constraints) {
                  final sample = ExcludeSemantics(
                    child: SizedBox(
                      width: math.min(64, constraints.maxWidth),
                      child: NoteThemeSample(theme: theme),
                    ),
                  );
                  final labels = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.bodyLarge),
                      if (premium) ...[
                        const SizedBox(height: 4),
                        Text(S.of(context).Premium,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: colors.primary)),
                      ],
                    ],
                  );
                  final status = ExcludeSemantics(
                      child: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : locked
                                  ? Icons.lock_outline_rounded
                                  : Icons.radio_button_unchecked_rounded,
                          size: math.min(24, constraints.maxWidth)));
                  if (constraints.maxWidth < 180) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        sample,
                        const SizedBox(height: 8),
                        labels,
                        const SizedBox(height: 8),
                        status,
                      ],
                    );
                  }
                  return Row(children: [
                    sample,
                    const SizedBox(width: 12),
                    Expanded(child: labels),
                    const SizedBox(width: 8),
                    status,
                  ]);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
