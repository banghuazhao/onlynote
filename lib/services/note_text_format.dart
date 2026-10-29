import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_numbered_list.dart';

/// One familiar marker color, shared by writing, reading and image sharing.
const noteHighlightColor = Color(0xFFFFE7A0);
const noteHighlightedTextColor = Color(0xFF29251C);

/// A visible rule glyph with an explicit saved block style. A user-typed glyph
/// or a run of hyphens remains ordinary text.
const noteDividerText = '─';

bool isNoteDividerRange(NoteTextStyleRange range, String text) =>
    range.kind == NoteTextStyleKind.divider &&
    range.start >= 0 &&
    range.end == range.start + noteDividerText.length &&
    range.end <= text.length &&
    text.substring(range.start, range.end) == noteDividerText &&
    (range.start == 0 || text.codeUnitAt(range.start - 1) == 10) &&
    (range.end == text.length || text.codeUnitAt(range.end) == 10);

/// Assign identities only when a caller deliberately makes a section linkable.
/// Rendering and ordinary normalization never generate random metadata. Each
/// heading paragraph receives its own ID; existing IDs survive subsequent edits.
List<NoteTextStyleRange> ensureNoteHeadingAnchors(
  Iterable<NoteTextStyleRange> styles,
  String text,
) {
  final clean = normalizeNoteTextStyles(styles, text);
  final headings =
      clean.where((range) => range.kind == NoteTextStyleKind.heading);
  if (headings.isEmpty) return clean;
  final result =
      clean.where((range) => range.kind != NoteTextStyleKind.heading).toList();
  final used = <String>{};
  var start = 0;
  for (final paragraph in text.split('\n')) {
    final end = start + paragraph.length;
    final matching = headings
        .where((range) => range.start < end && range.end > start)
        .toList();
    if (paragraph.trim().isNotEmpty && matching.isNotEmpty) {
      final preserved = matching
          .map((range) => range.anchorId)
          .whereType<String>()
          .where((id) => !used.contains(id))
          .firstOrNull;
      final id = preserved ?? const Uuid().v4();
      used.add(id);
      result.add(NoteTextStyleRange(
          start: start,
          end: end,
          kind: NoteTextStyleKind.heading,
          anchorId: id));
    }
    start = end + 1;
  }
  return normalizeNoteTextStyles(result, text);
}

/// Portable plain text represents a saved divider with three familiar dashes.
String noteTextToPlainText(String text, Iterable<NoteTextStyleRange> styles) {
  var result = text;
  final dividers = normalizeNoteTextStyles(styles, text)
      .where((range) => range.kind == NoteTextStyleKind.divider)
      .toList();
  for (final range in dividers.reversed) {
    result = result.replaceRange(range.start, range.end, '---');
  }
  return result;
}

/// A linked heading has one owning paragraph. An overlapping unlinked style
/// must not hide that ID, and a multiline paste must not duplicate it. During
/// editing the caller supplies the position of surviving original heading text.
List<NoteTextStyleRange> _normalizeHeadingAnchorOwnership(
  Iterable<NoteTextStyleRange> styles,
  String text, {
  Map<String, int> preferredOffsets = const {},
}) {
  final all = styles.toList();
  final headings =
      all.where((range) => range.kind == NoteTextStyleKind.heading).toList();
  if (!headings.any((range) => range.anchorId != null)) return all;
  final owners = <String, int>{};
  for (final range in headings) {
    final id = range.anchorId;
    if (id == null || owners.containsKey(id)) continue;
    final offset = (preferredOffsets[id] ?? range.start).clamp(0, text.length);
    owners[id] = offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
  }
  final result =
      all.where((range) => range.kind != NoteTextStyleKind.heading).toList();
  var start = 0;
  for (final paragraph in text.split('\n')) {
    final end = start + paragraph.length;
    final matching = headings
        .where((range) => range.start < end && range.end > start)
        .toList();
    final ids = matching
        .map((range) => range.anchorId)
        .whereType<String>()
        .where((id) => owners[id] == start)
        .toSet();
    for (final range in matching) {
      final id = range.anchorId;
      result.add(NoteTextStyleRange(
          start: math.max(start, range.start),
          end: math.min(end, range.end),
          kind: NoteTextStyleKind.heading,
          anchorId: id == null
              ? (ids.length == 1 ? ids.single : null)
              : (owners[id] == start ? id : null)));
    }
    start = end + 1;
  }
  return result;
}

/// Cleans saved formatting without cutting an emoji or combining character.
/// Same-kind overlaps are merged so equality is stable across saves.
List<NoteTextStyleRange> normalizeNoteTextStyles(
  Iterable<NoteTextStyleRange> styles,
  String text,
) {
  if (text.isEmpty) return const [];
  final boundaries = _graphemeBoundaries(text);
  final clean = <NoteTextStyleRange>[];
  for (final range in styles) {
    if (range.end <= range.start ||
        range.end <= 0 ||
        range.start >= text.length) {
      continue;
    }
    final start = _floorBoundary(boundaries, range.start.clamp(0, text.length));
    final end = _ceilBoundary(boundaries, range.end.clamp(0, text.length));
    if (start < end) {
      final normalized = NoteTextStyleRange(
          start: start, end: end, kind: range.kind, anchorId: range.anchorId);
      if (range.kind != NoteTextStyleKind.divider ||
          isNoteDividerRange(normalized, text)) {
        clean.add(normalized);
      }
    }
  }
  final anchorSafe = _normalizeHeadingAnchorOwnership(clean, text);
  final merged = <NoteTextStyleRange>[];
  for (final kind in NoteTextStyleKind.values) {
    final matching = anchorSafe.where((range) => range.kind == kind).toList()
      ..sort((a, b) {
        final byStart = a.start.compareTo(b.start);
        return byStart != 0 ? byStart : a.end.compareTo(b.end);
      });
    for (final range in matching) {
      if (merged.isNotEmpty &&
          merged.last.kind == kind &&
          range.start <= merged.last.end &&
          range.anchorId == merged.last.anchorId) {
        final previous = merged.removeLast();
        merged.add(NoteTextStyleRange(
          start: previous.start,
          end: math.max(previous.end, range.end),
          kind: kind,
          anchorId: previous.anchorId,
        ));
      } else {
        merged.add(range);
      }
    }
  }
  merged.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    if (byStart != 0) return byStart;
    final byEnd = a.end.compareTo(b.end);
    return byEnd != 0 ? byEnd : a.kind.index.compareTo(b.kind.index);
  });
  return List.unmodifiable(merged);
}

/// External data uses strict validation; ordinary saved notes use the forgiving
/// normalizer above so a stale range cannot make the editor fail to open.
bool areValidNoteTextStyles(
  Iterable<NoteTextStyleRange> styles,
  String text,
) {
  final boundaries = _graphemeBoundaries(text).toSet();
  return styles.every((range) =>
      range.start >= 0 &&
      range.end > range.start &&
      range.end <= text.length &&
      boundaries.contains(range.start) &&
      boundaries.contains(range.end) &&
      (range.kind != NoteTextStyleKind.divider ||
          isNoteDividerRange(range, text)));
}

/// Moves formatting with a plain text edit. Newly typed text inherits the style
/// at the edit point unless the caller supplies an explicit toolbar state.
List<NoteTextStyleRange> rebaseNoteTextStyles(
  String oldText,
  String newText,
  Iterable<NoteTextStyleRange> styles, {
  bool? insertedBold,
  bool? insertedHeading,
  bool? insertedHighlight,
  NoteTextChange? changeOverride,
}) {
  final clean = normalizeNoteTextStyles(styles, oldText);
  if (oldText == newText) return clean;
  final change = changeOverride ?? noteTextChange(oldText, newText);
  final delta = newText.length - oldText.length;
  final insertEnd = change.start + change.inserted.length;
  final result = <NoteTextStyleRange>[];
  final anchorOffsets = <String, int>{};
  for (final range in clean) {
    final id = range.anchorId;
    if (range.kind == NoteTextStyleKind.heading && id != null) {
      if (range.start < change.start) {
        anchorOffsets[id] = range.start;
      } else if (range.end > change.oldEnd) {
        anchorOffsets[id] = math.max(range.start, change.oldEnd) + delta;
      } else if (change.inserted.isNotEmpty) {
        anchorOffsets[id] = change.start;
      }
    }
    final leftEnd = math.min(range.end, change.start);
    if (range.start < leftEnd) {
      result.add(NoteTextStyleRange(
        start: range.start,
        end: leftEnd,
        kind: range.kind,
        anchorId: range.anchorId,
      ));
    }
    final rightStart = math.max(range.start, change.oldEnd);
    if (rightStart < range.end) {
      result.add(NoteTextStyleRange(
        start: rightStart + delta,
        end: range.end + delta,
        kind: range.kind,
        anchorId: range.anchorId,
      ));
    }
  }
  bool inherits(NoteTextStyleKind kind) {
    return clean.any((range) =>
        range.kind == kind &&
        range.start <= change.start &&
        range.end >= change.start &&
        // A new paragraph begins normally even if the previous one is styled.
        !(range.end == change.start &&
            change.start > 0 &&
            oldText[change.start - 1] == '\n'));
  }

  // Highlight is applied to a selection, never a sticky typing mode. Edits
  // inside marked text keep the marker, while typing beside it stays plain.
  bool inheritsHighlight() => clean.any((range) =>
      range.kind == NoteTextStyleKind.highlight &&
      (change.oldEnd > change.start
          ? range.start <= change.start && range.end >= change.oldEnd
          : range.start < change.start && range.end > change.start));

  if (change.inserted.isNotEmpty) {
    final bold = insertedBold ?? inherits(NoteTextStyleKind.bold);
    final heading = insertedHeading ?? inherits(NoteTextStyleKind.heading);
    final paragraphBreak = isNoteParagraphBreak(change.inserted);
    final highlight =
        insertedHighlight ?? (!paragraphBreak && inheritsHighlight());
    if (bold) {
      result.add(NoteTextStyleRange(
        start: change.start,
        end: insertEnd,
        kind: NoteTextStyleKind.bold,
      ));
    }
    if (heading) {
      result.add(NoteTextStyleRange(
        start: change.start,
        end: insertEnd,
        kind: NoteTextStyleKind.heading,
        anchorId: clean
            .where((range) =>
                range.kind == NoteTextStyleKind.heading &&
                range.start <= change.start &&
                range.end >= change.start)
            .map((range) => range.anchorId)
            .whereType<String>()
            .firstOrNull,
      ));
    }
    if (highlight) {
      result.add(NoteTextStyleRange(
        start: change.start,
        end: insertEnd,
        kind: NoteTextStyleKind.highlight,
      ));
    }
    // Pressing Return in a heading creates an ordinary next paragraph,
    // including the trailing text when Return is pressed mid-paragraph.
    if (paragraphBreak) {
      final priorHeading = clean.where((range) =>
          range.kind == NoteTextStyleKind.heading &&
          range.start <= change.start &&
          range.end >= change.start);
      var headingEnd = insertEnd;
      for (final range in priorHeading) {
        headingEnd = math.max(headingEnd, range.end + delta);
      }
      var nextStyles = removeNoteTextStyle(
        result,
        change.start,
        headingEnd,
        NoteTextStyleKind.heading,
      );
      if (priorHeading.isNotEmpty || heading) {
        nextStyles = removeNoteTextStyle(
          nextStyles,
          change.start,
          headingEnd,
          NoteTextStyleKind.bold,
        );
      }
      return normalizeNoteTextStyles(
          _normalizeHeadingAnchorOwnership(nextStyles, newText,
              preferredOffsets: anchorOffsets),
          newText);
    }
  }
  return normalizeNoteTextStyles(
      _normalizeHeadingAnchorOwnership(result, newText,
          preferredOffsets: anchorOffsets),
      newText);
}

/// The smallest changed region whose ends are safe character boundaries in
/// both documents. Optional part bounds keep repeated text in other paragraphs
/// from shifting the detected edit. Invalid bounds fall back to a full diff.
NoteTextChange noteTextChange(
  String before,
  String after, {
  int? editedPartStart,
  int? editedPartEnd,
}) {
  final delta = after.length - before.length;
  if (editedPartStart != null &&
      editedPartEnd != null &&
      editedPartStart >= 0 &&
      editedPartEnd >= editedPartStart &&
      editedPartEnd <= before.length &&
      editedPartEnd + delta >= editedPartStart &&
      editedPartEnd + delta <= after.length &&
      before.substring(0, editedPartStart) ==
          after.substring(0, editedPartStart) &&
      before.substring(editedPartEnd) ==
          after.substring(editedPartEnd + delta)) {
    final oldBoundaries = _graphemeBoundaries(before).toSet();
    final newBoundaries = _graphemeBoundaries(after).toSet();
    if (oldBoundaries.contains(editedPartStart) &&
        oldBoundaries.contains(editedPartEnd) &&
        newBoundaries.contains(editedPartStart) &&
        newBoundaries.contains(editedPartEnd + delta)) {
      final local = noteTextChange(
        before.substring(editedPartStart, editedPartEnd),
        after.substring(editedPartStart, editedPartEnd + delta),
      );
      return NoteTextChange(
        start: editedPartStart + local.start,
        oldEnd: editedPartStart + local.oldEnd,
        inserted: local.inserted,
      );
    }
  }
  var prefix = 0;
  while (prefix < before.length &&
      prefix < after.length &&
      before.codeUnitAt(prefix) == after.codeUnitAt(prefix)) {
    prefix++;
  }
  final oldBoundaries = _graphemeBoundaries(before).toSet();
  final newBoundaries = _graphemeBoundaries(after).toSet();
  while (!oldBoundaries.contains(prefix) || !newBoundaries.contains(prefix)) {
    prefix--;
  }
  var suffix = 0;
  while (suffix < before.length - prefix &&
      suffix < after.length - prefix &&
      before.codeUnitAt(before.length - suffix - 1) ==
          after.codeUnitAt(after.length - suffix - 1)) {
    suffix++;
  }
  while (!oldBoundaries.contains(before.length - suffix) ||
      !newBoundaries.contains(after.length - suffix)) {
    suffix--;
  }
  return NoteTextChange(
    start: prefix,
    oldEnd: before.length - suffix,
    inserted: after.substring(prefix, after.length - suffix),
  );
}

class NoteTextChange {
  const NoteTextChange({
    required this.start,
    required this.oldEnd,
    required this.inserted,
  });

  final int start;
  final int oldEnd;
  final String inserted;
}

List<NoteTextStyleRange> removeNoteTextStyle(
  Iterable<NoteTextStyleRange> styles,
  int start,
  int end,
  NoteTextStyleKind kind,
) {
  final result = <NoteTextStyleRange>[];
  for (final range in styles) {
    if (range.kind != kind || range.end <= start || range.start >= end) {
      result.add(range);
      continue;
    }
    if (range.start < start) {
      result.add(NoteTextStyleRange(
          start: range.start,
          end: start,
          kind: kind,
          anchorId: range.anchorId));
    }
    if (range.end > end) {
      result.add(NoteTextStyleRange(
          start: end, end: range.end, kind: kind, anchorId: range.anchorId));
    }
  }
  return result;
}

/// Keeps visible editor/reader text identical to the stored plain body, so
/// cursor and selection offsets continue to work with the native text field.
List<TextSpan> buildNoteTextSpans({
  required String text,
  required Iterable<NoteTextStyleRange> styles,
  TextStyle? baseStyle,
  TextRange composing = TextRange.empty,
  Color? highlightColor = noteHighlightColor,
}) {
  final clean = normalizeNoteTextStyles(styles, text);
  final boundaries = <int>{0, text.length};
  for (final range in clean) {
    boundaries.addAll([range.start, range.end]);
  }
  final validComposing = composing.isValid &&
      !composing.isCollapsed &&
      composing.start >= 0 &&
      composing.end <= text.length;
  if (validComposing) boundaries.addAll([composing.start, composing.end]);
  final points = boundaries.toList()..sort();
  final boldRanges =
      clean.where((r) => r.kind == NoteTextStyleKind.bold).toList();
  final headingRanges =
      clean.where((r) => r.kind == NoteTextStyleKind.heading).toList();
  final highlightRanges =
      clean.where((r) => r.kind == NoteTextStyleKind.highlight).toList();
  var boldIndex = 0;
  var headingIndex = 0;
  var highlightIndex = 0;
  final spans = <TextSpan>[];
  for (var index = 0; index < points.length - 1; index++) {
    final start = points[index];
    final end = points[index + 1];
    if (start == end) continue;
    while (
        boldIndex < boldRanges.length && boldRanges[boldIndex].end <= start) {
      boldIndex++;
    }
    while (headingIndex < headingRanges.length &&
        headingRanges[headingIndex].end <= start) {
      headingIndex++;
    }
    while (highlightIndex < highlightRanges.length &&
        highlightRanges[highlightIndex].end <= start) {
      highlightIndex++;
    }
    final bold =
        boldIndex < boldRanges.length && boldRanges[boldIndex].start <= start;
    final heading = headingIndex < headingRanges.length &&
        headingRanges[headingIndex].start <= start;
    final highlighted = highlightIndex < highlightRanges.length &&
        highlightRanges[highlightIndex].start <= start;
    final underline =
        validComposing && composing.start <= start && composing.end >= end;
    var spanStyle = baseStyle ?? const TextStyle();
    if (heading) {
      spanStyle = spanStyle.copyWith(
        fontSize: (baseStyle?.fontSize ?? 16) + 2,
        fontWeight: FontWeight.w600,
      );
    }
    if (bold) spanStyle = spanStyle.copyWith(fontWeight: FontWeight.w700);
    if (highlighted && highlightColor != null) {
      spanStyle = spanStyle.copyWith(
        backgroundColor: highlightColor,
        color: noteHighlightedTextColor,
      );
    }
    if (underline) {
      spanStyle = spanStyle.copyWith(decoration: TextDecoration.underline);
    }
    spans.add(TextSpan(text: text.substring(start, end), style: spanStyle));
  }
  return spans;
}

/// A portable Markdown body with actual formatting, while literal Markdown
/// typed in an old plain-text note remains literal.
String noteTextToMarkdown(
  String text,
  Iterable<NoteTextStyleRange> styles,
) {
  final clean = normalizeNoteTextStyles(styles, text);
  final result = StringBuffer();
  var lineStart = 0;
  final lines = text.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final lineEnd = lineStart + line.length;
    if (clean.any((range) =>
        range.kind == NoteTextStyleKind.divider &&
        range.start == lineStart &&
        range.end == lineEnd)) {
      result.write('---');
      if (index != lines.length - 1) result.write('\n');
      lineStart = lineEnd + 1;
      continue;
    }
    final bullet = line.startsWith('• ');
    final numbered = noteNumberedListMarker(line);
    final contentStart =
        lineStart + (bullet ? 2 : numbered?.prefix.length ?? 0);
    final heading = clean.any((range) =>
        range.kind == NoteTextStyleKind.heading &&
        range.start < lineEnd &&
        range.end > lineStart);
    if (bullet) result.write('- ');
    if (numbered != null) result.write(numbered.prefix);
    if (heading) result.write('## ');
    final boundaries = <int>{contentStart, lineEnd};
    for (final range in clean.where((r) =>
        r.kind == NoteTextStyleKind.bold ||
        r.kind == NoteTextStyleKind.highlight)) {
      if (range.start < lineEnd && range.end > contentStart) {
        boundaries.add(math.max(contentStart, range.start));
        boundaries.add(math.min(lineEnd, range.end));
      }
    }
    final points = boundaries.toList()..sort();
    for (var part = 0; part < points.length - 1; part++) {
      final start = points[part];
      final end = points[part + 1];
      if (start == end) continue;
      final bold = clean.any((range) =>
          range.kind == NoteTextStyleKind.bold &&
          range.start <= start &&
          range.end >= end);
      final highlighted = clean.any((range) =>
          range.kind == NoteTextStyleKind.highlight &&
          range.start <= start &&
          range.end >= end);
      if (highlighted) result.write('<mark>');
      // Keep whitespace outside emphasis delimiters: Markdown does not render
      // a **bold ** run that ends with a space.
      final fragment = text.substring(start, end);
      final trimmed = fragment.trim();
      if (bold && trimmed.isNotEmpty) {
        final leading = fragment.length - fragment.trimLeft().length;
        final trailing = fragment.length - fragment.trimRight().length;
        result.write(_escapeMarkdown(fragment.substring(0, leading)));
        final punctuationEdge =
            RegExp(r'^[\p{P}\p{S}]|[\p{P}\p{S}]$', unicode: true)
                .hasMatch(trimmed);
        if (punctuationEdge) {
          result.write('<strong>${_escapeMarkdown(trimmed)}</strong>');
        } else {
          result.write('**${_escapeMarkdown(trimmed)}**');
        }
        result.write(
            _escapeMarkdown(fragment.substring(fragment.length - trailing)));
      } else {
        result.write(_escapeMarkdown(fragment));
      }
      if (highlighted) result.write('</mark>');
    }
    if (index != lines.length - 1) result.write('\n');
    lineStart = lineEnd + 1;
  }
  return result.toString();
}

String _escapeMarkdown(String value) => value.replaceAllMapped(
    RegExp(r'[\\`*_{}\[\]<>#+\-.!|~&]'), (match) => '\\${match[0]}');

List<int> _graphemeBoundaries(String text) {
  final result = <int>[0];
  var offset = 0;
  for (final character in text.characters) {
    offset += character.length;
    result.add(offset);
  }
  return result;
}

int _floorBoundary(List<int> boundaries, int offset) {
  var low = 0;
  var high = boundaries.length - 1;
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    if (boundaries[middle] <= offset) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return boundaries[low];
}

int _ceilBoundary(List<int> boundaries, int offset) {
  var low = 0;
  var high = boundaries.length - 1;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (boundaries[middle] < offset) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return boundaries[low];
}
