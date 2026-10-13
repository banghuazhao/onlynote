import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

enum CardStyleSection { theme, color, text, layout }

String cardStyleSectionLabel(CardStyleSection section, S strings) =>
    switch (section) {
      CardStyleSection.theme => strings.Card_Style_Theme,
      CardStyleSection.color => strings.Card_Style_Color,
      CardStyleSection.text => strings.Card_Style_Text,
      CardStyleSection.layout => strings.Card_Style_Layout,
    };

/// A pinned, horizontally scrollable selector without app state or IO.
class CardStyleSections extends StatelessWidget {
  const CardStyleSections({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final List<CardStyleSection> sections;
  final CardStyleSection selected;
  final ValueChanged<CardStyleSection> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        key: const ValueKey('card-style-sections'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final section in sections)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: ChoiceChip(
                    key: ValueKey('card-style-section-${section.name}'),
                    label: Text(cardStyleSectionLabel(section, S.of(context))),
                    selected: section == selected,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: enabled
                        ? (_) {
                            if (!context.mounted ||
                                ModalRoute.of(context)?.isCurrent == false) {
                              return;
                            }
                            onSelected(section);
                          }
                        : null,
                  ),
                ),
              ),
          ],
        ),
      );
}
