import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:onlynote/services/note_bulk_export.dart';

/// A finished readable export: the archive on disk and what went into it.
class NoteArchiveExport {
  const NoteArchiveExport(this.file, this.result);
  final File file;
  final NoteBulkExportResult result;
}

/// Writes export entries straight into a zip file on disk.
///
/// One archive is what both platforms can already hand to the user: the save
/// dialog on macOS and the share sheet on iOS. Streaming each entry as it
/// arrives keeps a library's photos and recordings out of memory, so the cost
/// of exporting 500 notes is the same as exporting one.
class ExportArchive {
  ExportArchive._(this._encoder, this.file);

  final ZipFileEncoder _encoder;
  final File file;

  static ExportArchive create(String path) {
    final encoder = ZipFileEncoder()..create(path);
    return ExportArchive._(encoder, File(path));
  }

  Future<void> add(NoteExportEntry entry) async {
    switch (entry) {
      case NoteExportBytes(:final name, :final bytes):
        _encoder.addArchiveFile(ArchiveFile.bytes(name, bytes));
      case NoteExportSourceFile(:final name, :final sourcePath):
        await _encoder.addFile(File(sourcePath), name);
    }
  }

  Future<void> close() => _encoder.close();

  /// Removes a partial archive after a failure, so a cancelled or failed
  /// export leaves nothing behind in the temporary directory.
  Future<void> discard() async {
    try {
      await close();
    } catch (_) {
      // Already closed or never opened; the file is what matters.
    }
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover temporary file is harmless; the OS reclaims it.
    }
  }
}
