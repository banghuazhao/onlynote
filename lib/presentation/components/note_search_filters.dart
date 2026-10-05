import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_search.dart';

class NoteSearchFilters extends StatelessWidget {
  const NoteSearchFilters(
      {super.key, required this.selected, required this.onChanged});
  final Set<NoteSearchFilter> selected;
  final ValueChanged<Set<NoteSearchFilter>> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        for (final filter in NoteSearchFilter.values)
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(switch (filter) {
                  NoteSearchFilter.checklists => s.Filter_Checklists,
                  NoteSearchFilter.photos => s.Filter_Photos,
                  NoteSearchFilter.reminders => s.Filter_Reminders,
                  NoteSearchFilter.pinned => s.Filter_Pinned,
                  NoteSearchFilter.unfinished => s.Filter_Unfinished,
                }),
                selected: selected.contains(filter),
                onSelected: (value) =>
                    onChanged({...selected}..toggle(filter, value)),
              )),
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

/// A visible shortcut for the common checklist workflow without opening search.
class UnfinishedNotesFilter extends StatelessWidget {
  const UnfinishedNotesFilter(
      {super.key, required this.selected, required this.onChanged});
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilterChip(
            key: const ValueKey('unfinished-quick-filter'),
            avatar: const Icon(Icons.check_box_outlined, size: 18),
            label: Text(S.of(context).Filter_Unfinished),
            selected: selected,
            onSelected: onChanged,
          ),
        ),
      );
}
