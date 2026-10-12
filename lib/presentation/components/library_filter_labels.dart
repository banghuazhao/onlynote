import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/saved_note_views.dart';

String noteSearchFilterLabel(NoteSearchFilter filter, S strings) =>
    switch (filter) {
      NoteSearchFilter.checklists => strings.Filter_Checklists,
      NoteSearchFilter.photos => strings.Filter_Photos,
      NoteSearchFilter.reminders => strings.Filter_Reminders,
      NoteSearchFilter.pinned => strings.Filter_Pinned,
      NoteSearchFilter.unfinished => strings.Filter_Unfinished,
      NoteSearchFilter.recordings => strings.Filter_Recordings,
      NoteSearchFilter.scans => strings.Filter_Scans,
    };

/// Describes the criteria that will be applied, using only local metadata.
/// Missing folders resolve to All Notes, matching saved-view application.
String savedNoteViewDescription(
  SavedNoteView view, {
  required S strings,
  Map<String, String> folderNames = const {},
}) {
  final resolved = view.withAvailableFolders(folderNames.keys.toSet());
  final query = resolved.query.trim();
  return [
    folderNames[resolved.folderId] ?? strings.All_Notes,
    if (query.isNotEmpty) strings.Saved_View_Search(query),
    for (final filter in NoteSearchFilter.values)
      if (resolved.filters.contains(filter))
        noteSearchFilterLabel(filter, strings),
    if (resolved.tags.isNotEmpty)
      strings.Saved_View_Tags(resolved.tags.join(', ')),
    if (resolved.archiveScope == NoteArchiveScope.archived) strings.Archive,
    if (resolved.archiveScope == NoteArchiveScope.all) strings.Include_Archived,
  ].join(' · ');
}
