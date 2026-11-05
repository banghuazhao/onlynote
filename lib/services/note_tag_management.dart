import 'package:characters/characters.dart';

import 'note_tags.dart';

/// Library-wide tag edits: one spelling of a tag, wherever it is referenced.
///
/// Tags are compared by [tagKey], so changing only capitalization or spacing
/// is a rename too. These functions never add a tag a list did not already
/// carry, so a rewrite can never push a note past [maxNoteTags] and never
/// throws — a half-applied rename would leave the library inconsistent.

/// Why a replacement tag name cannot be stored.
enum TagNameProblem { empty, tooLong }

/// Checks a replacement tag name before anything is rewritten.
TagNameProblem? tagNameProblem(String value) {
  final name = normalizeTagName(value);
  if (name.isEmpty) return TagNameProblem.empty;
  if (name.characters.length > maxNoteTagLength) return TagNameProblem.tooLong;
  return null;
}

/// Applies a tag rename to one stored tag list.
///
/// Entries matching either name collapse onto [to] at the earlier of the two
/// positions, so renaming onto an existing tag merges instead of repeating it.
/// Lists without [from] are returned unchanged, keeping their own spelling of
/// [to]; the library already shows those as one tag. Lists that do change are
/// also tidied, which folds away legacy duplicate spellings written before
/// tags were normalized on save.
List<String> renameTagIn(
  List<String> tags, {
  required String from,
  required String to,
}) {
  final fromKey = tagKey(from);
  if (!tags.any((tag) => tagKey(tag) == fromKey)) return tags;
  final toKey = tagKey(to);
  final replacement = normalizeTagName(to);
  if (replacement.isEmpty) return tags;
  return _canonical([
    for (final tag in tags)
      if (tagKey(tag) == fromKey || tagKey(tag) == toKey) replacement else tag,
  ]);
}

/// Removes every spelling of [tag] from one stored tag list.
List<String> removeTagIn(List<String> tags, String tag) {
  final key = tagKey(tag);
  if (!tags.any((value) => tagKey(value) == key)) return tags;
  return _canonical([
    for (final value in tags)
      if (tagKey(value) != key) value,
  ]);
}

/// Normalizes spellings and drops repeats, without enforcing tag limits.
List<String> _canonical(Iterable<String> tags) {
  final keys = <String>{};
  final result = <String>[];
  for (final tag in tags) {
    final value = normalizeTagName(tag);
    if (value.isEmpty) continue;
    if (!keys.add(tagKey(value))) continue;
    result.add(value);
  }
  return List<String>.unmodifiable(result);
}
