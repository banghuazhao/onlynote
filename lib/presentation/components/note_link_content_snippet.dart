import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_search.dart';

const _snippetLength = 160;

/// A small display-only excerpt from stored text, without opening note media.
/// Search keeps the content that explains a match visible, including cached OCR.
String noteLinkContentSnippet(
  Note note, {
  String query = '',
  Iterable<String> photoText = const [],
}) {
  final pattern = searchPattern(query);
  if (pattern != null) {
    for (final text in _content(note).followedBy(photoText)) {
      if (pattern.hasMatch(text)) {
        return _prefix(searchExcerpt(text, query, leadingContext: 0));
      }
    }
  }
  for (final text in _content(note)) {
    final prefix = _prefix(text);
    if (prefix.isNotEmpty) return prefix;
  }
  return '';
}

Iterable<String> _content(Note note) sync* {
  if (note.description case final String text) yield text;
  for (final item in note.todo) {
    if (item.title case final String text) yield text;
  }
  for (final memo in note.voiceMemos) {
    if (memo.transcript case final String text) yield text;
  }
}

String _prefix(String text) {
  // Stop after a finite normalized prefix; never split emoji or combining marks.
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
