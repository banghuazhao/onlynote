import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_text_format.dart';

enum NoteReplaceFailure { staleMatch, lengthLimit }

/// One complete draft update, suitable for a single editor undo step.
class NoteReplaceResult {
  const NoteReplaceResult({
    required this.note,
    this.replacedCount = 0,
    this.failure,
    this.failedFieldId,
  });

  final Note note;
  final int replacedCount;
  final NoteReplaceFailure? failure;
  final String? failedFieldId;
  bool get changed => replacedCount > 0;
}

/// Replaces the exact highlighted graphemes in one match, or all current
/// matches when [match] is omitted. Empty replacement text deletes the matches.
/// No field changes if a supplied match/snapshot is stale or a length limit
/// would be exceeded. Image contents, recordings and note metadata are kept.
NoteReplaceResult replaceNoteText(
  Note note, {
  required String query,
  required String replacement,
  NoteSearchMatch? match,
  Iterable<NoteSearchField>? expectedFields,
}) {
  final fields = noteSearchFields(note);
  NoteReplaceResult rejected(NoteReplaceFailure failure, [String? fieldId]) =>
      NoteReplaceResult(note: note, failure: failure, failedFieldId: fieldId);
  if (expectedFields != null) {
    final expected = expectedFields.toList();
    if (expected.length != fields.length ||
        expected.indexed.any((item) =>
            item.$2.id != fields[item.$1].id ||
            item.$2.text != fields[item.$1].text)) {
      return rejected(NoteReplaceFailure.staleMatch);
    }
  }
  // Field identifiers must resolve to a single editable field.
  if (fields.map((field) => field.id).toSet().length != fields.length) {
    return rejected(NoteReplaceFailure.staleMatch);
  }
  final found = findNoteMatches(fields, query);
  if (match != null && !found.contains(match)) {
    return rejected(NoteReplaceFailure.staleMatch, match.fieldId);
  }
  final selected = match == null ? found : [match];
  if (selected.isEmpty) return NoteReplaceResult(note: note);
  final byField = <String, List<NoteSearchMatch>>{};
  for (final occurrence in selected.toSet()) {
    byField.putIfAbsent(occurrence.fieldId, () => []).add(occurrence);
  }
  final newTexts = <String, String>{};
  var count = 0;
  for (final field in fields) {
    final matches = byField[field.id];
    if (matches == null) continue;
    matches.sort((a, b) => a.start.compareTo(b.start));
    for (var index = 1; index < matches.length; index++) {
      if (matches[index - 1].end > matches[index].start) {
        return rejected(NoteReplaceFailure.staleMatch, field.id);
      }
    }
    var text = field.text;
    for (final occurrence in matches.reversed) {
      if (text.substring(occurrence.start, occurrence.end) == replacement) {
        continue;
      }
      text = text.replaceRange(occurrence.start, occurrence.end, replacement);
      count++;
    }
    if (text == field.text) continue;
    // Persistence currently caps these fields in UTF-16 coordinates. Reject
    // rather than letting save truncate unrelated text or split a grapheme.
    final limit = field.id == 'title'
        ? maxTitleCharCount
        : field.id.startsWith('todo:')
            ? todoMaxCharCount
            : null;
    if (limit != null && text.length > limit) {
      return rejected(NoteReplaceFailure.lengthLimit, field.id);
    }
    newTexts[field.id] = text;
  }
  if (newTexts.isEmpty) return NoteReplaceResult(note: note);

  var body = note.description ?? '';
  var styles = note.textStyles;
  var layouts = note.imageLayouts;
  for (final occurrence
      in byField['body']?.reversed ?? const Iterable<NoteSearchMatch>.empty()) {
    if (body.substring(occurrence.start, occurrence.end) == replacement) {
      continue;
    }
    final after =
        body.replaceRange(occurrence.start, occurrence.end, replacement);
    styles = _replaceBodyStyles(body, after, styles, occurrence, replacement);
    layouts = rebaseNoteImageLayouts(body, after, layouts, note.imagePaths,
        editedPartStart: occurrence.start, editedPartEnd: occurrence.end);
    body = after;
  }
  return NoteReplaceResult(
    note: note.copyWith(
      title: newTexts['title'] ?? note.title,
      description: newTexts['body'] ?? note.description,
      textStyles: styles,
      imageLayouts: layouts,
      todo: [
        for (final (index, todo) in note.todo.indexed)
          newTexts.containsKey('todo:${todo.id ?? index}')
              ? todo.copyWith(title: newTexts['todo:${todo.id ?? index}'])
              : todo,
      ],
      voiceMemos: [
        for (final memo in note.voiceMemos)
          newTexts.containsKey('voice:${memo.id}')
              ? memo.copyWith(transcript: newTexts['voice:${memo.id}'])
              : memo,
      ],
    ),
    replacedCount: count,
  );
}

List<NoteTextStyleRange> _replaceBodyStyles(
  String before,
  String after,
  List<NoteTextStyleRange> styles,
  NoteSearchMatch match,
  String replacement,
) {
  final clean = normalizeNoteTextStyles(styles, before);
  bool covers(NoteTextStyleKind kind) => clean.any((range) =>
      range.kind == kind &&
      range.start <= match.start &&
      range.end >= match.end);
  final rebased = rebaseNoteTextStyles(
    before,
    after,
    clean,
    insertedBold: covers(NoteTextStyleKind.bold),
    insertedHeading: covers(NoteTextStyleKind.heading),
    insertedHighlight: covers(NoteTextStyleKind.highlight),
    changeOverride: NoteTextChange(
        start: match.start, oldEnd: match.end, inserted: replacement),
  );
  final delta = after.length - before.length;
  final insertEnd = match.start + replacement.length;
  // Typing Return normally clears the trailing heading. Find replacement must
  // keep styles on all untouched text, including when replacing with a newline.
  return normalizeNoteTextStyles([
    for (final range in clean) ...[
      if (range.start < match.start)
        NoteTextStyleRange(
            start: range.start,
            end: range.end.clamp(range.start, match.start),
            kind: range.kind),
      if (range.end > match.end)
        NoteTextStyleRange(
            start: range.start.clamp(match.end, range.end) + delta,
            end: range.end + delta,
            kind: range.kind),
    ],
    for (final range in rebased)
      if (range.start < insertEnd && range.end > match.start)
        NoteTextStyleRange(
            start: range.start.clamp(match.start, insertEnd),
            end: range.end.clamp(match.start, insertEnd),
            kind: range.kind),
  ], after);
}
