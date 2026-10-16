import 'package:onlynote/domain/model/note.dart';

/// Library ordering choices.
///
/// [manual] is the historical order, kept as the default so an upgrade changes
/// nothing: the user's dragged `sortOrder`, falling back to most recently
/// changed for notes saved before that field existed. Every other mode derives
/// from values already stored on the note, so choosing one never writes to a
/// note and never touches `sortOrder` — switching back to [manual] restores
/// the arrangement the user dragged.
enum NoteSortOrder {
  manual,
  modifiedNewest,
  modifiedOldest,
  titleAsc,
  titleDesc,
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// Pinned notes stay above unpinned ones in every mode, so pinning keeps
/// meaning what it always has, and sorting only arranges notes within each
/// group. Trash keeps its own most-recently-deleted order and never uses this.
int compareLibraryNotes(Note a, Note b, NoteSortOrder order) {
  if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
  final result = switch (order) {
    NoteSortOrder.manual => _compareManual(a, b),
    NoteSortOrder.modifiedNewest => _compareModified(b, a),
    NoteSortOrder.modifiedOldest => _compareModified(a, b),
    NoteSortOrder.titleAsc => _compareHeadlines(a, b),
    NoteSortOrder.titleDesc => _compareHeadlines(b, a),
  };
  // Equal notes resolve by id so repeated sorts of the same notes are
  // identical. Without it, an unrelated refresh could reshuffle same-titled
  // or same-second notes under the reader.
  return result != 0 ? result : (a.id ?? '').compareTo(b.id ?? '');
}

int _compareManual(Note a, Note b) {
  if (a.sortOrder != null && b.sortOrder != null) {
    final order = a.sortOrder!.compareTo(b.sortOrder!);
    if (order != 0) return order;
  }
  return _compareModified(b, a);
}

int _compareModified(Note a, Note b) =>
    (a.dateTime ?? _epoch).compareTo(b.dateTime ?? _epoch);

int _compareHeadlines(Note a, Note b) =>
    _headlineKey(a).compareTo(_headlineKey(b));

/// The text a note's card leads with: its title, or the first line of whatever
/// content it has instead. Sorting by what the reader actually sees keeps A–Z
/// predictable for untitled notes rather than lumping them all together.
///
/// Comparison is by lower-cased code unit, which is alphabetical for Latin
/// text and codepoint order for everything else; Dart has no locale collator,
/// so CJK titles order by codepoint rather than by reading.
String _headlineKey(Note note) {
  final title = note.title?.trim() ?? '';
  if (title.isNotEmpty) return title.toLowerCase();
  final body = _firstLine(note.description);
  if (body.isNotEmpty) return body;
  for (final todo in note.todo) {
    final task = _firstLine(todo.title);
    if (task.isNotEmpty) return task;
  }
  for (final memo in note.voiceMemos) {
    final transcript = _firstLine(memo.transcript);
    if (transcript.isNotEmpty) return transcript;
  }
  return '';
}

String _firstLine(String? text) {
  for (final line in (text ?? '').split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) return trimmed.toLowerCase();
  }
  return '';
}
