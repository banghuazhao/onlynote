import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';

/// Literal Unicode name matching retains input order and original objects.
List<T> filterSavedViewNames<T>(
  Iterable<T> views,
  String query, {
  required String Function(T) nameOf,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return views.toList(growable: false);
  final pattern =
      RegExp(RegExp.escape(trimmed), caseSensitive: false, unicode: true);
  return views
      .where((view) => pattern.hasMatch(nameOf(view)))
      .toList(growable: false);
}

/// A local search field and feedback, with no dependency on saved-view storage.
class SavedViewNameSearch extends StatelessWidget {
  const SavedViewNameSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hasMatches,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasMatches;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            key: const ValueKey('library-search-saved-views'),
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: strings.Search_Saved_Views,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('library-clear-saved-view-search'),
                      tooltip: strings.Clear_Search,
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        if (!hasMatches && controller.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(strings.Saved_Views_Search_Empty,
                  key: const ValueKey('library-saved-views-search-empty')),
            ),
          ),
      ],
    );
  }
}
