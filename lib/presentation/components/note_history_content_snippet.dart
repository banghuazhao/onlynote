import 'package:characters/characters.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/services/note_search.dart';

const _snippetLength = 160;

/// Display text from a saved snapshot, without converting or loading its media.
/// A blank query retains the original history summary exactly.
String noteHistoryContentSnippet(NoteDto note, {String query = ''}) {
  final pattern = searchPattern(query);
  if (pattern == null) return _ordinarySnippet(note);
  for (final text in _content(note)) {
    if (pattern.hasMatch(text)) {
      return _boundedPrefix(searchExcerpt(text, query, leadingContext: 0));
    }
  }
  // A title-only match still has the usual content context underneath it.
  return _boundedPrefix(_ordinarySnippet(note));
}

Iterable<String> _content(NoteDto note) sync* {
  if (note.description case final String text) yield text;
  for (final todo in note.todoList ?? const <TodoDto>[]) {
    if (todo.title case final String text) yield text;
  }
  for (final memo in note.voiceMemos ?? const <Map>[]) {
    if (memo['transcript'] case final String text) yield text;
  }
}

String _ordinarySnippet(NoteDto note) {
  if (note.description?.trim().isNotEmpty ?? false) {
    return note.description!.trim();
  }
  final checklist = (note.todoList ?? const <TodoDto>[])
      .map((todo) => todo.title ?? '')
      .where((title) => title.trim().isNotEmpty)
      .join(', ');
  if (checklist.isNotEmpty) return checklist;
  for (final memo in note.voiceMemos ?? const <Map>[]) {
    final transcript = memo['transcript'];
    if (transcript is String && transcript.trim().isNotEmpty) {
      return transcript.trim();
    }
  }
  return '';
}

String _boundedPrefix(String text) {
  final prefix = _normalizedCharacters(text).take(_snippetLength + 1).toList();
  if (prefix.length <= _snippetLength) return prefix.join();
  return '${prefix.take(_snippetLength - 1).join().trimRight()}…';
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
