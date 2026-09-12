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
