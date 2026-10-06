import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/services/note_text_format.dart';

/// Locations at which a photo can sit between text paragraphs, including an
/// empty note's start and the end of a final paragraph without a line break.
List<int> noteImageInsertionOffsets(String body) {
  final offsets = <int>[0];
  for (var index = 0; index < body.length; index++) {
    if (body.codeUnitAt(index) == 10) offsets.add(index + 1);
  }
  if (offsets.last != body.length) offsets.add(body.length);
  return List.unmodifiable(offsets);
}

/// Repairs an old or edited anchor by keeping the photo after the preceding
/// paragraph. Only paragraph boundaries are used, so no character is split.
int snapNoteImageOffset(int offset, String body) {
  return _snapImageOffset(offset, body.length, noteImageInsertionOffsets(body));
}

int _snapImageOffset(int offset, int bodyLength, List<int> offsets) {
  final target = offset.clamp(0, bodyLength);
  var low = 0;
  var high = offsets.length - 1;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (offsets[middle] < target) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return offsets[low];
}

/// Keeps saved layouts safe to render and fills older notes' missing layouts.
/// Input order is retained, including the order of photos at the same anchor.
List<NoteImageLayout> normalizeNoteImageLayouts(
  Iterable<NoteImageLayout> layouts,
  Iterable<String> imagePaths,
  String body,
) {
  final paths = imagePaths.where((path) => path.trim().isNotEmpty).toSet();
  final offsets = noteImageInsertionOffsets(body);
  final seen = <String>{};
  final result = <NoteImageLayout>[];
  for (final layout in layouts) {
    if (!paths.contains(layout.path) || !seen.add(layout.path)) continue;
    result.add(layout.copyWith(
      textOffset: _snapImageOffset(layout.textOffset, body.length, offsets),
      widthFactor: _finiteClamp(layout.widthFactor, .25, 1, .85),
      xFactor: _finiteClamp(layout.xFactor, 0, 1, .5),
      aspectRatio: _finiteClamp(layout.aspectRatio, .1, 10, 4 / 3),
    ));
  }
  for (final path in paths) {
    if (seen.add(path)) {
      result.add(NoteImageLayout(path: path, textOffset: body.length));
    }
  }
  return List.unmodifiable(result);
}

/// External imports use strict validation before normalization. Missing entries
/// are allowed so legacy photos can receive their default end-of-note layout.
bool areValidNoteImageLayouts(
  Iterable<NoteImageLayout> layouts,
  Iterable<String> imagePaths,
  String body,
) {
  final paths = imagePaths.toSet();
  final offsets = noteImageInsertionOffsets(body).toSet();
  final seen = <String>{};
  return layouts.every((layout) =>
      paths.contains(layout.path) &&
      layout.path.trim().isNotEmpty &&
      seen.add(layout.path) &&
      offsets.contains(layout.textOffset) &&
      _within(layout.widthFactor, .25, 1) &&
      _within(layout.xFactor, 0, 1) &&
      _within(layout.aspectRatio, .1, 10));
}

/// Copies placement alongside copied photo files. Failed copies are omitted;
/// remaining photos retain their order, size and position in the document.
List<NoteImageLayout> remapNoteImageLayouts(
  Iterable<NoteImageLayout> layouts,
  Map<String, String> pathMap,
) {
  final seen = <String>{};
  final result = <NoteImageLayout>[];
  for (final layout in layouts) {
    final newPath = pathMap[layout.path];
    if (newPath == null || newPath.trim().isEmpty || !seen.add(newPath)) {
      continue;
    }
    result.add(layout.copyWith(path: newPath));
  }
  return List.unmodifiable(result);
}

/// Moves photos with edited text. At an insertion boundary, editing the text
/// before a photo moves that photo forward; editing the part after it leaves
/// it in place. Segment context also resolves ambiguous edits in repeated text.
/// Pass the preceding photo paths to distinguish empty text fields between
/// several photos sharing one anchor.
List<NoteImageLayout> rebaseNoteImageLayouts(
  String before,
  String after,
  Iterable<NoteImageLayout> layouts,
  Iterable<String> imagePaths, {
  int? editedPartStart,
  int? editedPartEnd,
  Set<String>? precedingImagePaths,
}) {
  final paths = imagePaths.toList();
  final clean = normalizeNoteImageLayouts(layouts, paths, before);
  if (before == after) return clean;
  final delta = after.length - before.length;
  var change = noteTextChange(before, after);
  var usesPartContext = false;
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
    final localChange = noteTextChange(
      before.substring(editedPartStart, editedPartEnd),
      after.substring(editedPartStart, editedPartEnd + delta),
    );
    change = NoteTextChange(
      start: editedPartStart + localChange.start,
      oldEnd: editedPartStart + localChange.oldEnd,
      inserted: localChange.inserted,
    );
    usesPartContext = true;
  }
  final insertedEnd = change.start + change.inserted.length;
  final rebased = clean.map((layout) {
    final anchor = layout.textOffset;
    int offset;
    if (anchor < change.start) {
      offset = anchor;
    } else if (anchor == change.start &&
        usesPartContext &&
        editedPartStart == anchor &&
        (precedingImagePaths == null ||
            precedingImagePaths.contains(layout.path))) {
      // This field is the text following the image, including an empty field
      // at the end of the document. Its insertion belongs after the image.
      offset = change.start;
    } else if (anchor >= change.oldEnd) {
      offset = anchor + delta;
    } else {
      offset = insertedEnd;
    }
    return layout.copyWith(textOffset: offset);
  });
  return normalizeNoteImageLayouts(rebased, paths, after);
}

sealed class NoteDocumentPart {
  const NoteDocumentPart();
}

class NoteTextPart extends NoteDocumentPart {
  const NoteTextPart({required this.start, required this.end});

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is NoteTextPart && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'NoteTextPart($start, $end)';
}

class NoteImagePart extends NoteDocumentPart {
  const NoteImagePart({required this.layout});

  final NoteImageLayout layout;

  @override
  bool operator ==(Object other) =>
      other is NoteImagePart && other.layout == layout;

  @override
  int get hashCode => layout.hashCode;

  @override
  String toString() => 'NoteImagePart($layout)';
}

/// Interleaves photos and exact slices of the plain body for editing, reading
/// and export. Empty text parts let the editor type before or after a photo.
List<NoteDocumentPart> noteDocumentParts(
  String body,
  Iterable<NoteImageLayout> layouts,
) {
  final supplied = layouts.toList();
  final clean = normalizeNoteImageLayouts(
    supplied,
    supplied.map((layout) => layout.path),
    body,
  );
  // The original index gives equal-offset photos a stable order independent
  // of the runtime's sorting algorithm.
  final ordered = clean.indexed.toList()
    ..sort((a, b) {
      final byOffset = a.$2.textOffset.compareTo(b.$2.textOffset);
      return byOffset != 0 ? byOffset : a.$1.compareTo(b.$1);
    });
  final result = <NoteDocumentPart>[];
  var cursor = 0;
  for (final (_, layout) in ordered) {
    result.add(NoteTextPart(start: cursor, end: layout.textOffset));
    result.add(NoteImagePart(layout: layout));
    cursor = layout.textOffset;
  }
  result.add(NoteTextPart(start: cursor, end: body.length));
  return List.unmodifiable(result);
}

double _finiteClamp(double value, double min, double max, double fallback) =>
    value.isFinite ? value.clamp(min, max).toDouble() : fallback;

bool _within(double value, double min, double max) =>
    value.isFinite && value >= min && value <= max;
