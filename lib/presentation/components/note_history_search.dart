import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_search.dart';

/// Filters snapshots without changing their order or identity.
List<T> filterNoteHistoryVersions<T>(Iterable<T> versions, String query,
    {required Iterable<String> Function(T) searchableText}) {
  final pattern = searchPattern(query);
  if (pattern == null) return versions.toList(growable: false);
  return versions
      .where((version) => searchableText(version).any(pattern.hasMatch))
      .toList(growable: false);
}

class NoteHistorySearchField extends StatelessWidget {
  const NoteHistorySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('history-search'),
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: S.of(context).History_Search,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('history-clear-search'),
                  tooltip: S.of(context).Clear_Search,
                  onPressed: () {
                    if (!context.mounted ||
                        ModalRoute.of(context)?.isCurrent == false) {
                      return;
                    }
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      );
}

class NoteHistorySearchEmpty extends StatelessWidget {
  const NoteHistorySearchEmpty({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                S.of(context).History_Search_Empty,
                key: const ValueKey('history-search-empty'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('history-search-reset'),
              onPressed: onClear,
              child: Text(S.of(context).Clear_Search),
            ),
          ],
        ),
      );
}
