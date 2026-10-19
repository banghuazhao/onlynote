import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_sort.dart';
import 'package:onlynote/services/note_tags.dart';

import 'library_filter_labels.dart';

/// Selected criteria and derived sorting; callbacks leave data and scope to Home.
class NoteActiveCriteriaSummary extends StatelessWidget {
  const NoteActiveCriteriaSummary({
    super.key,
    required this.filters,
    required this.tags,
    required this.onRemoveFilter,
    required this.onRemoveTag,
    this.includeArchived = false,
    this.onRemoveIncludeArchived,
    this.sortOrder = NoteSortOrder.manual,
  });

  final Set<NoteSearchFilter> filters;
  final Set<String> tags;
  final ValueChanged<NoteSearchFilter> onRemoveFilter;
  final ValueChanged<String> onRemoveTag;
  final bool includeArchived;
  final VoidCallback? onRemoveIncludeArchived;
  final NoteSortOrder sortOrder;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty &&
        tags.isEmpty &&
        !includeArchived &&
        sortOrder == NoteSortOrder.manual) {
      return const SizedBox.shrink();
    }
    final strings = S.of(context);
    final uniqueTags = <String, String>{};
    for (final tag in tags) {
      final key = tagKey(tag);
      if (key.isNotEmpty) uniqueTags.putIfAbsent(key, () => tag);
    }
    return LayoutBuilder(builder: (context, constraints) {
      // Keep each delete action reachable on narrow screens without shrinking
      // the touch target or reserving vertical space outside the notes scroll.
      final labelWidth = math.max(40.0, constraints.maxWidth - 116);
      Widget chipLabel(String label) => ConstrainedBox(
            // RawChip derives its content height from the label before
            // placing the delete control, so both need the same minimum.
            constraints: BoxConstraints(minHeight: 48, maxWidth: labelWidth),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              heightFactor: 1,
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          );
      Widget chip(String key, String label, VoidCallback? onDeleted) =>
          InputChip(
            key: ValueKey(key),
            label: chipLabel(label),
            tooltip: label,
            onDeleted: onDeleted,
            deleteButtonTooltipMessage: strings.Remove_Library_Criterion(label),
            deleteIcon: SizedBox.square(
              key: ValueKey('$key-delete-target'),
              dimension: 48,
              child: const Center(child: Icon(Icons.close_rounded)),
            ),
            deleteIconBoxConstraints:
                const BoxConstraints.tightFor(width: 48, height: 48),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
          );
      final sortLabel =
          '${strings.Sort_By}: ${noteSortOrderLabel(sortOrder, strings)}';
      return SingleChildScrollView(
        key: const ValueKey('home-active-criteria-summary'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(spacing: 8, children: [
          if (sortOrder != NoteSortOrder.manual)
            Tooltip(
              message: sortLabel,
              child: Chip(
                key: const ValueKey('active-sort-order'),
                avatar: const Icon(Icons.sort_rounded),
                label: chipLabel(sortLabel),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
              ),
            ),
          for (final filter in NoteSearchFilter.values)
            if (filters.contains(filter))
              chip(
                  'active-filter-${filter.name}',
                  noteSearchFilterLabel(filter, strings),
                  () => onRemoveFilter(filter)),
          for (final entry in uniqueTags.entries)
            chip('active-tag-${entry.key}', '${strings.Tags}: ${entry.value}',
                () => onRemoveTag(entry.value)),
          if (includeArchived)
            chip('active-scope-include-archived', strings.Include_Archived,
                onRemoveIncludeArchived),
        ]),
      );
    });
  }
}
