import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/app_sheet.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/note_tags.dart';
import 'package:onlynote/services/saved_note_views.dart';

import 'library_filter_labels.dart';

sealed class LibraryFilterResult {
  const LibraryFilterResult();
}

class ApplyLibraryFilters extends LibraryFilterResult {
  const ApplyLibraryFilters(this.filters, this.tags, this.scope);
  final Set<NoteSearchFilter> filters;
  final Set<String> tags;
  final NoteArchiveScope scope;
}

class CreateSavedNoteView extends ApplyLibraryFilters {
  const CreateSavedNoteView(super.filters, super.tags, super.scope);
}

class ApplySavedNoteView extends LibraryFilterResult {
  const ApplySavedNoteView(this.view);
  final SavedNoteView view;
}

class RenameSavedNoteView extends LibraryFilterResult {
  const RenameSavedNoteView(this.view);
  final SavedNoteView view;
}

class DeleteSavedNoteView extends LibraryFilterResult {
  const DeleteSavedNoteView(this.view);
  final SavedNoteView view;
}

/// One library panel keeps tags, search filters, and saved views off the grid.
/// Results are explicit so the caller owns dialogs and durable mutations.
class LibraryFiltersSheet extends StatefulWidget {
  const LibraryFiltersSheet({
    super.key,
    this.filters = const {},
    this.selectedTags = const {},
    this.availableTags = const [],
    this.scope = NoteArchiveScope.active,
    this.savedViews = const [],
    this.selectedViewId,
    this.folderNames = const {},
    this.showTrash = false,
    this.viewsUnavailable = false,
  });
  final Set<NoteSearchFilter> filters;
  final Set<String> selectedTags;
  final List<String> availableTags;
  final NoteArchiveScope scope;
  final List<SavedNoteView> savedViews;
  final String? selectedViewId;
  final Map<String, String> folderNames;
  final bool showTrash;
  final bool viewsUnavailable;

  @override
  State<LibraryFiltersSheet> createState() => _LibraryFiltersSheetState();
}

class _LibraryFiltersSheetState extends State<LibraryFiltersSheet> {
  late final Set<NoteSearchFilter> _filters = Set.of(widget.filters);
  late final Set<String> _tags = Set.of(widget.selectedTags);
  late NoteArchiveScope _scope = widget.scope;

  void _selectTag(String tag, bool selected) => setState(() {
        _tags.removeWhere((value) => tagKey(value) == tagKey(tag));
        if (selected) _tags.add(tag);
      });

  Widget _heading(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Semantics(
            header: true,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
      );

  Widget _chipLabel(String text, double width) => ConstrainedBox(
        constraints:
            BoxConstraints(minHeight: 24, maxWidth: math.max(0, width - 64)),
        child: Text(text),
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tags = <String, String>{};
    for (final tag in [...widget.selectedTags, ...widget.availableTags]) {
      tags.putIfAbsent(tagKey(tag), () => tag);
    }
    return AppSheet(
      title: s.Library_Filters,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
                builder: (context, constraints) =>
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      for (final filter in NoteSearchFilter.values)
                        FilterChip(
                          key: ValueKey('library-filter-${filter.name}'),
                          avatarBoxConstraints: const BoxConstraints.tightFor(
                              width: 24, height: 24),
                          label: _chipLabel(noteSearchFilterLabel(filter, s),
                              constraints.maxWidth),
                          selected: _filters.contains(filter),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _filters.add(filter);
                            } else {
                              _filters.remove(filter);
                            }
                          }),
                        ),
                    ])),
          ),
          if (!widget.showTrash && _scope != NoteArchiveScope.archived)
            SwitchListTile.adaptive(
              key: const ValueKey('library-include-archived'),
              title: Text(s.Include_Archived),
              value: _scope == NoteArchiveScope.all,
              onChanged: (selected) => setState(() => _scope =
                  selected ? NoteArchiveScope.all : NoteArchiveScope.active),
            ),
          if (tags.isNotEmpty) ...[
            _heading(s.Filter_Tags),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(
                  builder: (context, constraints) =>
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        for (final tag in tags.values)
                          FilterChip(
                            key: ValueKey('library-tag-${tagKey(tag)}'),
                            avatarBoxConstraints: const BoxConstraints.tightFor(
                                width: 24, height: 24),
                            label: _chipLabel(tag, constraints.maxWidth),
                            selected: _tags
                                .any((value) => tagKey(value) == tagKey(tag)),
                            onSelected: _tags.length < 20 ||
                                    _tags.any(
                                        (value) => tagKey(value) == tagKey(tag))
                                ? (selected) => _selectTag(tag, selected)
                                : null,
                          ),
                      ])),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 12, runSpacing: 8, children: [
              FilledButton(
                key: const ValueKey('library-apply-filters'),
                onPressed: () => Navigator.pop(
                    context,
                    ApplyLibraryFilters(
                        Set.of(_filters), Set.of(_tags), _scope)),
                child: Text(s.Done),
              ),
              TextButton(
                key: const ValueKey('library-clear-filters'),
                onPressed: () => setState(() {
                  _filters.clear();
                  _tags.clear();
                  if (_scope == NoteArchiveScope.all) {
                    _scope = NoteArchiveScope.active;
                  }
                }),
                child: Text(s.Clear_Filters),
              ),
            ]),
          ),
          const Divider(),
          _heading(s.Saved_Views),
          if (widget.viewsUnavailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(s.Saved_View_Failed),
            )
          else if (widget.savedViews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(s.Saved_View_Empty),
            ),
          for (final view in widget.savedViews)
            ListTile(
              key: ValueKey('saved-view-${view.id}'),
              leading: const Icon(Icons.bookmark_border_rounded),
              title:
                  Text(view.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                savedNoteViewDescription(view,
                    strings: s, folderNames: widget.folderNames),
                key: ValueKey('saved-view-${view.id}-description'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              selected: widget.selectedViewId == view.id,
              onTap: () => Navigator.pop(context, ApplySavedNoteView(view)),
              trailing: PopupMenuButton<String>(
                tooltip: s.Edit,
                onSelected: (action) => Navigator.pop(
                    context,
                    action == 'rename'
                        ? RenameSavedNoteView(view)
                        : DeleteSavedNoteView(view)),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'rename', child: Text(s.Rename_View)),
                  PopupMenuItem(value: 'delete', child: Text(s.Delete_View)),
                ],
              ),
            ),
          if (!widget.showTrash && !widget.viewsUnavailable)
            ListTile(
              key: const ValueKey('library-save-view'),
              leading: const Icon(Icons.bookmark_add_outlined),
              title: Text(s.Save_Current_View),
              onTap: () => Navigator.pop(context,
                  CreateSavedNoteView(Set.of(_filters), Set.of(_tags), _scope)),
            ),
        ],
      ),
    );
  }
}
