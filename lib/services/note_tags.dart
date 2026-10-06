import 'package:characters/characters.dart';

const maxNoteTags = 20;
const maxNoteTagLength = 40;

final _tagWhitespace = RegExp(r'[\s\u0085]+', unicode: true);

String _normalizeTag(String tag) => tag.trim().replaceAll(_tagWhitespace, ' ');

/// The comparison key used by tag editing, search, and filtering.
String tagKey(String tag) => _normalizeTag(tag).toLowerCase();

/// Normalizes visible tags without changing the first spelling of duplicates.
///
/// Blank entries are ignored. Limits apply to unique tags and to user-visible
/// characters, so emoji and combining marks are never split or truncated.
List<String> normalizeNoteTags(Iterable<String> tags) {
  final normalized = <String>[];
  final keys = <String>{};
  for (final tag in tags) {
    final value = _normalizeTag(tag);
    if (value.isEmpty) continue;
    if (value.characters.length > maxNoteTagLength) {
      throw const FormatException('Tags must contain at most 40 characters.');
    }
    if (!keys.add(tagKey(value))) continue;
    if (normalized.length == maxNoteTags) {
      throw const FormatException('Notes may contain at most 20 tags.');
    }
    normalized.add(value);
  }
  return List<String>.unmodifiable(normalized);
}
