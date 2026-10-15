import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_bulk_export.dart';

class _Archive {
  final entries = <String, Object>{};
  final failNames = <String>{};
  Object? failEverythingWith;

  Future<void> write(NoteExportEntry entry) async {
    if (failEverythingWith != null) throw failEverythingWith!;
    if (failNames.contains(entry.name)) {
      throw StateError('Could not write ${entry.name}');
    }
    entries[entry.name] = switch (entry) {
      NoteExportBytes(:final bytes) => utf8.decode(bytes, allowMalformed: true),
      NoteExportSourceFile(:final sourcePath) => sourcePath,
    };
  }

  List<String> get names => entries.keys.toList();
}

Note _note(
  String id, {
  String? title,
  String? description,
  List<String> imagePaths = const [],
  List<VoiceMemo> voiceMemos = const [],
  List<Todo> todo = const [],
  DateTime? deletedAt,
}) =>
    Note(
      id: id,
      title: title,
      description: description,
      imagePaths: imagePaths,
      voiceMemos: voiceMemos,
      todo: todo,
      deletedAt: deletedAt,
    );

VoiceMemo _memo(String id) => VoiceMemo(
    id: id,
    path: 'note_audio/$id.m4a',
    durationMs: 1000,
    createdAt: DateTime(2026, 1, 1));

NoteBulkExport _export(
  _Archive archive, {
  NoteBulkExportFormat format = NoteBulkExportFormat.markdown,
  Future<Uint8List> Function(Note, String?)? buildPdf,
  String? Function(String)? resolvePhoto,
  Future<String?> Function(VoiceMemo)? resolveRecording,
  String? Function(Note)? reminderFor,
  void Function(int, int)? onProgress,
}) =>
    NoteBulkExport(
      format: format,
      write: archive.write,
      buildPdf: buildPdf,
      reminderFor: reminderFor,
      resolvePhoto: resolvePhoto ?? (stored) => '/photos/$stored',
      resolveRecording:
          resolveRecording ?? (memo) async => '/audio/${memo.id}.m4a',
      recordingLabel: 'Recording',
      onProgress: onProgress,
    );

void main() {
  test('Markdown writes one file per note beside its own attachments',
      () async {
    final archive = _Archive();
    final result = await _export(archive).run([
      _note('a',
          title: 'Trip ideas',
          description: 'Visit Hong Kong',
          imagePaths: ['note_images/one.jpg', 'note_images/two.png'],
          voiceMemos: [_memo('rec')]),
      _note('b', title: 'Groceries', todo: [Todo(id: 't', title: 'Tea')]),
    ]);
    expect(result.exported, 2);
    expect(result.skipped, 0);
    expect(result.failed, 0);
    expect(archive.names, [
      'Trip ideas.md',
      'Trip ideas-photo-1.jpg',
      'Trip ideas-photo-2.png',
      'Trip ideas-recording-1.m4a',
      'Groceries.md',
    ]);
    // Attachment names are what the Markdown links point at, URL-escaped by
    // NoteExport, so an unpacked archive resolves without rewriting anything.
    expect(
        archive.entries['Trip ideas.md'],
        allOf(contains('Trip%20ideas-photo-1.jpg'),
            contains('Trip%20ideas-recording-1.m4a'), contains('Hong Kong')));
    expect(archive.entries['Trip ideas-photo-1.jpg'],
        '/photos/note_images/one.jpg');
  });

  test('colliding titles stay separate files, ignoring case', () async {
    final archive = _Archive();
    final result =
        await _export(archive, format: NoteBulkExportFormat.plainText).run([
      _note('a', title: 'Notes', description: 'first'),
      _note('b', title: 'notes', description: 'second'),
      _note('c', title: 'NOTES', description: 'third'),
      _note('d', description: 'untitled one'),
      _note('e', description: 'untitled two'),
    ]);
    expect(result.exported, 5);
    expect(archive.names, [
      'Notes.txt',
      'notes (2).txt',
      'NOTES (3).txt',
      'note.txt',
      'note (2).txt',
    ]);
  });

  test('plain text carries only text, and skips notes that have none',
      () async {
    final archive = _Archive();
    final result =
        await _export(archive, format: NoteBulkExportFormat.plainText).run([
      _note('photos', title: '', imagePaths: ['note_images/one.jpg']),
      _note('text', title: 'Kept', description: 'body'),
    ]);
    expect(result.exported, 1);
    expect(result.skipped, 1);
    expect(archive.names, ['Kept.txt']);
  });

  test('a photo-only note still exports as Markdown', () async {
    final archive = _Archive();
    final result = await _export(archive).run([
      _note('photos', imagePaths: ['note_images/one.jpg'])
    ]);
    expect(result.exported, 1);
    expect(archive.names, ['note.md', 'note-photo-1.jpg']);
  });

  test('trashed notes are never exported', () async {
    final archive = _Archive();
    final result = await _export(archive).run([
      _note('kept', title: 'Kept', description: 'body'),
      _note('gone',
          title: 'Deleted',
          description: 'body',
          deletedAt: DateTime(2026, 2, 2)),
    ]);
    expect(result.total, 1);
    expect(archive.names, ['Kept.md']);
  });

  test('missing media is left out without failing its note', () async {
    final archive = _Archive();
    final result = await _export(archive,
        resolvePhoto: (_) => null, resolveRecording: (_) async => null).run([
      _note('a',
          title: 'Trip',
          description: 'body',
          imagePaths: ['note_images/gone.jpg'],
          voiceMemos: [_memo('gone')]),
    ]);
    expect(result.exported, 1);
    expect(archive.names, ['Trip.md']);
  });

  test('an attachment that vanishes mid-copy still keeps its note', () async {
    final archive = _Archive()..failNames.add('Trip-photo-1.jpg');
    final result = await _export(archive).run([
      _note('a',
          title: 'Trip',
          description: 'body',
          imagePaths: ['note_images/one.jpg', 'note_images/two.jpg']),
    ]);
    expect(result.exported, 1);
    expect(result.failed, 0);
    expect(archive.names, ['Trip.md', 'Trip-photo-2.jpg']);
  });

  test('one unbuildable PDF costs its own note and nothing else', () async {
    final archive = _Archive();
    final result = await _export(archive, format: NoteBulkExportFormat.pdf,
        buildPdf: (note, _) async {
      if (note.id == 'bad') throw StateError('Unreadable photo');
      return Uint8List.fromList(utf8.encode('pdf:${note.id}'));
    }).run([
      _note('good', title: 'Good', description: 'body'),
      _note('bad', title: 'Bad', description: 'body'),
      _note('last', title: 'Last', description: 'body'),
    ]);
    expect(result.exported, 2);
    expect(result.failed, 1);
    expect(archive.names, ['Good.pdf', 'Last.pdf']);
  });

  test('PDF export passes the localized reminder line through', () async {
    final archive = _Archive();
    final reminders = <String?>[];
    await _export(archive,
        format: NoteBulkExportFormat.pdf,
        reminderFor: (note) => 'Reminder: tomorrow',
        buildPdf: (note, reminder) async {
          reminders.add(reminder);
          return Uint8List.fromList([1, 2, 3]);
        }).run([_note('a', title: 'A', description: 'body')]);
    expect(reminders, ['Reminder: tomorrow']);
  });

  test('an empty note produces no PDF', () async {
    final archive = _Archive();
    var builds = 0;
    final result = await _export(archive, format: NoteBulkExportFormat.pdf,
        buildPdf: (note, _) async {
      builds++;
      return Uint8List.fromList([1]);
    }).run([_note('blank')]);
    expect(result.skipped, 1);
    expect(builds, 0);
    expect(archive.names, isEmpty);
  });

  test('a failure to write the archive itself stops the export', () async {
    final archive = _Archive()..failEverythingWith = StateError('Disk full');
    await expectLater(
        _export(archive).run([_note('a', title: 'A', description: 'body')]),
        throwsA(isA<Exception>()));
    expect(archive.names, isEmpty);
  });

  test('progress is reported once per note, including skipped ones', () async {
    final archive = _Archive();
    final steps = <String>[];
    await _export(archive,
        format: NoteBulkExportFormat.plainText,
        onProgress: (done, total) => steps.add('$done/$total')).run([
      _note('a', title: 'A', description: 'body'),
      _note('blank'),
      _note('c', title: 'C', description: 'body'),
    ]);
    expect(steps, ['1/3', '2/3', '3/3']);
  });

  test('every note is skipped when no PDF builder was supplied', () async {
    final archive = _Archive();
    final result = await _export(archive, format: NoteBulkExportFormat.pdf)
        .run([_note('a', title: 'A', description: 'body')]);
    expect(result.exported, 0);
    expect(result.skipped, 1);
    expect(archive.names, isEmpty);
  });
}
