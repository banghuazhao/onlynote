import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/theme/button_styles.dart';
import 'package:onlynote/services/note_search.dart';

class NoteSearchFilters extends StatelessWidget {
  const NoteSearchFilters(
      {super.key, required this.selected, required this.onChanged});
  final Set<NoteSearchFilter> selected;
  final ValueChanged<Set<NoteSearchFilter>> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Keep search controls to one row when the keyboard reduces Home's height.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(spacing: 8, children: [
        for (final filter in NoteSearchFilter.values)
          FilterChip(
            label: Text(switch (filter) {
              NoteSearchFilter.checklists => s.Filter_Checklists,
              NoteSearchFilter.photos => s.Filter_Photos,
              NoteSearchFilter.reminders => s.Filter_Reminders,
              NoteSearchFilter.pinned => s.Filter_Pinned,
              NoteSearchFilter.unfinished => s.Filter_Unfinished,
            }),
            selected: selected.contains(filter),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: (value) =>
                onChanged({...selected}..toggle(filter, value)),
          ),
        if (selected.isNotEmpty)
          TextButton(
              onPressed: () => onChanged({}), child: Text(s.Clear_Filters)),
      ]),
    );
  }
}

extension on Set<NoteSearchFilter> {
  void toggle(NoteSearchFilter filter, bool value) {
    if (value) {
      add(filter);
    } else {
      remove(filter);
    }
  }
}

class LibraryFiltersButton extends StatelessWidget {
  const LibraryFiltersButton(
      {super.key, required this.onPressed, this.count = 0});

  final VoidCallback onPressed;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = S.of(context).Library_Filters;
    final description = count > 0 ? '$label ($count)' : label;
    return MergeSemantics(
      child: Semantics(
        label: description,
        child: Tooltip(
          message: description,
          excludeFromSemantics: true,
          child: IconButton(
            style: AppButtonStyles.icon(Theme.of(context).colorScheme),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onPressed,
            icon: ExcludeSemantics(
              child: Badge(
                isLabelVisible: count > 0,
                label: Text('$count',
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.3)),
                child: const Icon(Icons.tune_rounded, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
