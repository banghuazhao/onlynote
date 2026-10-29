import 'dart:convert';
import 'dart:typed_data';

import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_export.dart';

/// Readable formats for exporting a whole library. Mirrors the per-note share
/// sheet's formats, minus the ones that only make sense for a single note.
enum NoteBulkExportFormat { markdown, plainText, pdf }

/// One entry in the export archive. Bytes are held only for as long as one
/// note's own content; a source file is copied by the writer straight from
/// disk, so photos and recordings never pass through memory.
sealed class NoteExportEntry {
  const NoteExportEntry(this.name);
  final String name;
}

class NoteExportBytes extends NoteExportEntry {
  const NoteExportBytes(super.name, this.bytes);
  final Uint8List bytes;
}

class NoteExportSourceFile extends NoteExportEntry {
  const NoteExportSourceFile(super.name, this.sourcePath);
  final String sourcePath;
}

class NoteBulkExportResult {
  const NoteBulkExportResult({
    required this.exported,
    required this.skipped,
    required this.failed,
  });

  /// Notes that produced a file.
  final int exported;

  /// Notes with nothing this format can carry, such as a photo-only note
  /// exported as plain text.
  final int skipped;

  /// Notes whose content could not be built or whose media went missing.
  final int failed;

  int get total => exported + skipped + failed;
}

/// Writes every note into one archive, one note at a time.
///
/// Everything that touches a plugin, the filesystem or an isolate is injected,
/// so the whole walk — naming, deduplication, which notes a format can carry,
/// and what happens when one note fails — is testable on its own. A single
/// unreadable photo or unbuildable PDF costs that one note, never the export.
class NoteBulkExport {
  NoteBulkExport({
    required this.format,
    required this.write,
    this.buildPdf,
    this.reminderFor,
    this.resolvePhoto,
    this.resolveRecording,
    this.recordingLabel = 'Recording',
    this.sectionLinksLabel = 'Heading links',
    this.onProgress,
  });

  final NoteBulkExportFormat format;

  /// Adds one entry to the archive. A failure here is fatal to the export,
  /// because it means the archive itself cannot be written.
  final Future<void> Function(NoteExportEntry entry) write;

  /// Builds one note's PDF, usually in an isolate. Required for
  /// [NoteBulkExportFormat.pdf] and unused by the text formats.
  final Future<Uint8List> Function(Note note, String? reminder)? buildPdf;

  /// The reminder line to append, already localized.
  final String? Function(Note note)? reminderFor;

  /// Resolves a stored photo path to a readable absolute path, or null when
  /// the file is gone.
  final String? Function(String storedPath)? resolvePhoto;

  /// Resolves a recording to a readable absolute path, or null when the file
  /// is gone.
  final Future<String?> Function(VoiceMemo memo)? resolveRecording;

  final String recordingLabel;
  final String sectionLinksLabel;
  final void Function(int done, int total)? onProgress;

  // Zip entries are case-sensitive, but the filesystems these archives are
  // unpacked on are not, so two notes called "Trip" and "trip" must still land
  // as separate files.
  final _usedStems = <String>{};

  Future<NoteBulkExportResult> run(Iterable<Note> notes) async {
    final pending = notes.where((note) => !note.isDeleted).toList();
    var exported = 0, skipped = 0, failed = 0;
    for (var index = 0; index < pending.length; index++) {
      final note = pending[index];
      try {
        final wrote = switch (format) {
          NoteBulkExportFormat.markdown => await _writeMarkdown(note),
          NoteBulkExportFormat.plainText => await _writePlainText(note),
          NoteBulkExportFormat.pdf => await _writePdf(note),
        };
        if (wrote) {
          exported++;
        } else {
          skipped++;
        }
      } on _ArchiveFailure {
        rethrow;
      } catch (_) {
        failed++;
      }
      onProgress?.call(index + 1, pending.length);
    }
    return NoteBulkExportResult(
        exported: exported, skipped: skipped, failed: failed);
  }

  Future<bool> _writePlainText(Note note) async {
    final text = NoteExport.plainText(note,
        reminder: reminderFor?.call(note),
        sectionLinksLabel: sectionLinksLabel);
    if (text.trim().isEmpty) return false;
    await _add(NoteExportBytes('${_stem(note)}.txt', _utf8(text)));
    return true;
  }

  Future<bool> _writeMarkdown(Note note) async {
    final stem = _stem(note);
    final photos = <(String, String)>[];
    for (var index = 0; index < note.imagePaths.length; index++) {
      final source = resolvePhoto?.call(note.imagePaths[index]);
      if (source == null) continue;
      photos.add(('$stem-photo-${index + 1}${_extension(source)}', source));
    }
    final recordings = <(String, String)>[];
    for (var index = 0; index < note.voiceMemos.length; index++) {
      final source = await resolveRecording?.call(note.voiceMemos[index]);
      if (source == null) continue;
      recordings.add(('$stem-recording-${index + 1}.m4a', source));
    }
    final markdown = NoteExport.markdown(note,
        reminder: reminderFor?.call(note),
        photos: photos.map((photo) => photo.$1).toList(),
        recordings: recordings.map((recording) => recording.$1).toList(),
        recordingLabel: recordingLabel,
        sectionLinksLabel: sectionLinksLabel);
    if (markdown.trim().isEmpty) return false;
    await _add(NoteExportBytes('$stem.md', _utf8(markdown)));
    // Attachments keep their note's stem, so one flat archive still reads as
    // a set of notes and every Markdown link resolves beside its own file.
    // One attachment that vanished between being listed and being copied
    // leaves a dangling link in that note, which is a far better outcome than
    // abandoning an export that is otherwise complete.
    for (final (name, source) in [...photos, ...recordings]) {
      try {
        await write(NoteExportSourceFile(name, source));
      } catch (_) {
        continue;
      }
    }
    return true;
  }

  Future<bool> _writePdf(Note note) async {
    final build = buildPdf;
    if (build == null) return false;
    // An empty note would still produce a one-page PDF, which is noise in a
    // library archive; skip it on the same terms as the text formats.
    if (NoteExport.plainText(note).trim().isEmpty && note.imagePaths.isEmpty) {
      return false;
    }
    final bytes = await build(note, reminderFor?.call(note));
    await _add(NoteExportBytes('${_stem(note)}.pdf', bytes));
    return true;
  }

  /// Writes an entry the export cannot do without: a note's own content, or
  /// the archive is not worth finishing.
  Future<void> _add(NoteExportEntry entry) async {
    try {
      await write(entry);
    } catch (error) {
      throw _ArchiveFailure(error);
    }
  }

  String _stem(Note note) {
    final base = NoteExport.fileStem(note);
    var candidate = base;
    var suffix = 1;
    while (!_usedStems.add(candidate.toLowerCase())) {
      candidate = '$base (${++suffix})';
    }
    return candidate;
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf('/');
    if (dot <= slash + 1 || dot == path.length - 1) return '';
    final extension = path.substring(dot);
    return extension.length > 8 ? '' : extension;
  }

  static Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));
}

/// Marks a failure to write the archive itself, which no single note can
/// recover from, so it passes through the per-note handler untouched.
class _ArchiveFailure implements Exception {
  _ArchiveFailure(this.cause);
  final Object cause;
  @override
  String toString() => 'Could not write the export archive: $cause';
}
