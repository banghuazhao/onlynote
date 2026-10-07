import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';

enum NoteSearchFilter { checklists, photos, reminders, pinned, unfinished }

bool matchesNoteSearch(Note note, String query, Set<NoteSearchFilter> filters,
    {required bool hasReminder, Iterable<String> photoText = const []}) {
  if (filters.contains(NoteSearchFilter.checklists) &&
      !note.todo.any((todo) => todo.title?.trim().isNotEmpty == true)) {
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
        ...note.todo
            .where((todo) =>
                !filters.contains(NoteSearchFilter.unfinished) ||
                !todo.completed)
            .map((todo) => todo.title ?? ''),
        ...note.voiceMemos.map((memo) => memo.transcript ?? ''),
        ...photoText,
      ].any(pattern.hasMatch);
}

RegExp? searchPattern(String query) => query.trim().isEmpty
    ? null
    : RegExp(RegExp.escape(query.trim()), caseSensitive: false, unicode: true);

/// Start a card excerpt near its first match so long notes explain the result.
/// A zero [leadingContext] reveals the match immediately in a short OCR preview.
String searchExcerpt(String text, String query, {int leadingContext = 30}) {
  assert(leadingContext >= 0);
  final match = searchPattern(query)?.firstMatch(text);
  if (match == null || (leadingContext != 0 && match.start < 45)) return text;
  final preferredStart = (match.start - leadingContext).clamp(0, match.start);
  var start = 0;
  for (final character in text.characters) {
    // Start at a complete grapheme after the desired clip. If the query
    // begins inside a longer grapheme, retain that entire grapheme instead.
    if (start >= preferredStart || start + character.length > match.start) {
      break;
    }
    start += character.length;
  }
  return start == 0 ? text : '…${text.substring(start)}';
}
