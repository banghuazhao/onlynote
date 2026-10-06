import 'package:onlynote/domain/model/note.dart';

enum NoteSearchFilter { checklists, photos, reminders, pinned, unfinished }

bool matchesNoteSearch(Note note, String query, Set<NoteSearchFilter> filters,
    {required bool hasReminder, Iterable<String> photoText = const []}) {
  if (filters.contains(NoteSearchFilter.checklists) && !note.hasTodo) {
    return false;
  }
  if (filters.contains(NoteSearchFilter.photos) && !note.hasImages) {
    return false;
  }
  if (filters.contains(NoteSearchFilter.reminders) && !hasReminder) {
    return false;
  }
  if (filters.contains(NoteSearchFilter.pinned) && !note.isPinned) return false;
  if (filters.contains(NoteSearchFilter.unfinished) &&
      !note.todo.any(
          (todo) => !todo.completed && todo.title?.trim().isNotEmpty == true)) {
    return false;
  }
  final pattern = searchPattern(query);
  return pattern == null ||
      [
        note.title ?? '',
        note.description ?? '',
        ...note.tags,
        ...note.todo.map((todo) => todo.title ?? ''),
        ...note.voiceMemos.map((memo) => memo.transcript ?? ''),
        ...photoText,
      ].any(pattern.hasMatch);
}

RegExp? searchPattern(String query) => query.trim().isEmpty
    ? null
    : RegExp(RegExp.escape(query.trim()), caseSensitive: false, unicode: true);

/// Start a card excerpt near its first match so long notes explain the result.
String searchExcerpt(String text, String query) {
  final match = searchPattern(query)?.firstMatch(text);
  if (match == null || match.start < 45) return text;
  var start = match.start - 30;
  // Avoid cutting a UTF-16 surrogate pair in half.
  if (text.codeUnitAt(start) >= 0xDC00 && text.codeUnitAt(start) <= 0xDFFF) {
    start++;
  }
  return '…${text.substring(start)}';
}
