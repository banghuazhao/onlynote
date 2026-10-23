import 'package:flutter/material.dart';

/// Wrapping alternatives keep labels and checkmarks readable at large text sizes.
class SettingsChoice<T> extends StatelessWidget {
  const SettingsChoice(
      {super.key,
      required this.values,
      required this.selected,
      required this.label,
      required this.onSelected,
      this.enabled = true,
      this.keyOf});
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final bool enabled;

  /// An optional per-option key, so a caller's tests can address one choice
  /// without depending on its label text.
  final Key Function(T)? keyOf;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              key: keyOf?.call(value),
              label: Text(label(value)),
              selected: value == selected,
              showCheckmark: true,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: enabled ? (_) => onSelected(value) : null,
            ),
        ],
      );
}
