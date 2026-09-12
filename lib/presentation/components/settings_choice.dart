import 'package:flutter/material.dart';

/// Wrapping alternatives keep labels and checkmarks readable at large text sizes.
class SettingsChoice<T> extends StatelessWidget {
  const SettingsChoice(
      {super.key,
      required this.values,
      required this.selected,
      required this.label,
      required this.onSelected});
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              label: Text(label(value)),
              selected: value == selected,
              showCheckmark: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onSelected(value),
            ),
        ],
      );
}
