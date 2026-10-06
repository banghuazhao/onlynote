import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/services/note_text_format.dart';

/// A copy of selected text and its saved formatting, independent of the source
/// field's focus, selection, and subsequent edits. Style offsets are local.
@immutable
class NoteTextSelection {
  NoteTextSelection({
    required this.text,
    Iterable<NoteTextStyleRange> textStyles = const [],
  }) : textStyles = normalizeNoteTextStyles(textStyles, text);

  final String text;
  final List<NoteTextStyleRange> textStyles;

  bool get isEmpty => text.isEmpty;
}

/// Snap both ends outwards to complete characters before clipping formatting.
/// Flutter selections and saved style ranges share UTF-16 offsets.
NoteTextSelection? captureNoteTextSelection({
  required String text,
  required TextSelection selection,
  Iterable<NoteTextStyleRange> styles = const [],
  TextRange composing = TextRange.empty,
}) {
  if (text.isEmpty ||
      !selection.isValid ||
      selection.isCollapsed ||
      (composing.isValid && !composing.isCollapsed)) {
    return null;
  }
  final clampedStart = selection.start.clamp(0, text.length);
  final clampedEnd = selection.end.clamp(0, text.length);
  if (clampedStart >= clampedEnd) return null;
  final boundaries = <int>[0];
  var offset = 0;
  for (final character in text.characters) {
    offset += character.length;
    boundaries.add(offset);
  }
  final start = _boundary(boundaries, clampedStart, roundUp: false);
  final end = _boundary(boundaries, clampedEnd, roundUp: true);
  final selectedStyles = <NoteTextStyleRange>[];
  for (final range in normalizeNoteTextStyles(styles, text)) {
    final clippedStart = math.max(start, range.start);
    final clippedEnd = math.min(end, range.end);
    if (clippedStart >= clippedEnd) continue;
    selectedStyles.add(NoteTextStyleRange(
      start: clippedStart - start,
      end: clippedEnd - start,
      kind: range.kind,
    ));
  }
  return NoteTextSelection(
    text: text.substring(start, end),
    textStyles: selectedStyles,
  );
}

/// Add text after the existing document, retaining all destination metadata.
/// Normalizing photos before appending keeps legacy end-of-note photos before
/// the added text; rebasing them as a text edit would place them after it.
Note appendSelectionToNote(Note destination, NoteTextSelection selection) {
  if (selection.isEmpty) return destination;
  final before = destination.description ?? '';
  final separator = before.isEmpty
      ? ''
      : before.endsWith('\n\n')
          ? ''
          : before.endsWith('\n')
              ? '\n'
              : '\n\n';
  final insertionOffset = before.length + separator.length;
  final after = '$before$separator${selection.text}';
  final originalLayouts = normalizeNoteImageLayouts(
    destination.imageLayouts,
    destination.imagePaths,
    before,
  );
  return destination.copyWith(
    description: after,
    textStyles: normalizeNoteTextStyles([
      ...normalizeNoteTextStyles(destination.textStyles, before),
      for (final range in selection.textStyles)
        NoteTextStyleRange(
          start: insertionOffset + range.start,
          end: insertionOffset + range.end,
          kind: range.kind,
        ),
    ], after),
    imageLayouts: normalizeNoteImageLayouts(
      originalLayouts,
      destination.imagePaths,
      after,
    ),
  );
}

int _boundary(List<int> boundaries, int target, {required bool roundUp}) {
  var low = 0;
  var high = boundaries.length - 1;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (boundaries[middle] < target) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return boundaries[low] == target || roundUp
      ? boundaries[low]
      : boundaries[low - 1];
}
