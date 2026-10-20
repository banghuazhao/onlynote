import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_search.dart';

const _snippetLength = 160;

/// Explains a match using stored content only, without reading note media.
/// Empty, title-only and unmatched queries have no matching content excerpt.
String noteSearchMatchSnippet(Note note, String query) {
  final pattern = searchPattern(query);
  if (pattern == null) return '';
  for (final text in _content(note)) {
    if (pattern.hasMatch(text)) {
      // Two-line previews must reveal the match even with narrow, large text.
      return _prefix(searchExcerpt(text, query, leadingContext: 0));
    }
  }
  return '';
}

Iterable<String> _content(Note note) sync* {
  if (note.description case final String body) yield body;
  for (final item in note.todo) {
    if (item.title case final String title) yield title;
  }
  for (final memo in note.voiceMemos) {
    if (memo.transcript case final String transcript) yield transcript;
  }
  yield* note.tags;
}

String _prefix(String text) {
  final characters =
      _normalizedCharacters(text).take(_snippetLength + 1).toList();
  if (characters.length <= _snippetLength) return characters.join();
  return '${characters.take(_snippetLength).join().trimRight()}…';
}

Iterable<String> _normalizedCharacters(String text) sync* {
  var started = false;
  var pendingSpace = false;
  for (final character in text.characters) {
    if (character.trim().isEmpty) {
      if (started) pendingSpace = true;
      continue;
    }
    if (pendingSpace) yield ' ';
    yield character;
    started = true;
    pendingSpace = false;
  }
}
