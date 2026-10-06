import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/services/note_document.dart';

/// Adds reviewed scanner pages in capture order. Page metadata lets PDF export
/// retain a complete page while ordinary note photos keep their usual layout.
Note appendScannedPages(
  Note note,
  Iterable<String> savedPaths, {
  int? textOffset,
}) {
  final body = note.description ?? '';
  final paths = note.imagePaths.toList();
  final layouts = normalizeNoteImageLayouts(
    note.imageLayouts,
    paths,
    body,
  ).toList();
  final seen = paths.toSet();
  final offset = snapNoteImageOffset(
    textOffset ?? body.length,
    body,
  );
  for (final path in savedPaths) {
    if (path.trim().isEmpty || !seen.add(path)) continue;
    paths.add(path);
    layouts.add(NoteImageLayout(
      path: path,
      textOffset: offset,
      widthFactor: 1,
      aspectRatio: 210 / 297,
      isDocumentPage: true,
    ));
  }
  return note.copyWith(imagePaths: paths, imageLayouts: layouts);
}
