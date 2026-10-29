import 'package:onlynote/domain/model/note_text_style.dart';

/// An outline uses the same UTF-16 offsets as the native editing fields.
class NoteOutlineEntry {
  const NoteOutlineEntry({
    required this.text,
    required this.start,
    required this.end,
    this.anchorId,
  });

  final String text;
  final int start;
  final int end;
  final String? anchorId;
}

/// Only paragraphs with saved heading formatting belong in the outline.
/// Plain text that happens to begin with Markdown markers remains plain text.
List<NoteOutlineEntry> buildNoteOutline(
  String text,
  Iterable<NoteTextStyleRange> styles,
) {
  // Outline offsets always come from whole paragraphs below. Range boundaries
  // only determine membership, so rebuilding all grapheme/style boundaries on
  // each caret move would add work without making navigation more accurate.
  final headings = styles
      .where((range) =>
          range.kind == NoteTextStyleKind.heading &&
          range.end > range.start &&
          range.end > 0 &&
          range.start < text.length)
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (headings.isEmpty) return const [];
  final entries = <NoteOutlineEntry>[];
  var start = 0;
  var headingIndex = 0;
  for (final paragraph in text.split('\n')) {
    final end = start + paragraph.length;
    while (
        headingIndex < headings.length && headings[headingIndex].end <= start) {
      headingIndex++;
    }
    final trimmed = paragraph.trim();
    if (trimmed.isNotEmpty &&
        headingIndex < headings.length &&
        headings[headingIndex].start < end &&
        headings[headingIndex].end > start) {
      final leading = paragraph.length - paragraph.trimLeft().length;
      final trailing = paragraph.length - paragraph.trimRight().length;
      entries.add(NoteOutlineEntry(
        text: trimmed,
        anchorId: headings[headingIndex].anchorId,
        start: start + leading,
        end: end - trailing,
      ));
    }
    start = end + 1;
  }
  return List.unmodifiable(entries);
}

/// Short notes do not need another action in the toolbar.
bool shouldShowNoteOutline(String text, List<NoteOutlineEntry> entries) =>
    entries.length >= 2 || (text.length >= 500 && entries.isNotEmpty);

NoteOutlineEntry? currentNoteOutlineEntry(
  List<NoteOutlineEntry> entries,
  int textOffset,
) {
  NoteOutlineEntry? current;
  for (final entry in entries) {
    if (entry.start > textOffset) break;
    current = entry;
  }
  return current;
}
