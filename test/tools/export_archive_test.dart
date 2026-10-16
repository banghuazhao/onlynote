import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/export_archive.dart';
import 'package:onlynote/services/note_bulk_export.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-export');
  });
  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('bytes and source files land in one readable archive', () async {
    final photo = File('${directory.path}/one.jpg')
      ..writeAsBytesSync(Uint8List.fromList([7, 8, 9]));
    final archive = ExportArchive.create('${directory.path}/notes.zip');
    await archive.add(
        NoteExportBytes('Trip.md', Uint8List.fromList(utf8.encode('# 旅行'))));
    await archive.add(NoteExportSourceFile('Trip-photo-1.jpg', photo.path));
    await archive.close();

    final unpacked = ZipDecoder().decodeBytes(archive.file.readAsBytesSync());
    expect(unpacked.files.map((file) => file.name).toList(),
        ['Trip.md', 'Trip-photo-1.jpg']);
    expect(utf8.decode(unpacked.findFile('Trip.md')!.content as List<int>),
        '# 旅行');
    expect(unpacked.findFile('Trip-photo-1.jpg')!.content, [7, 8, 9]);
  });

  test('a missing source file fails that entry alone', () async {
    final archive = ExportArchive.create('${directory.path}/notes.zip');
    await archive.add(NoteExportBytes('Kept.md', Uint8List.fromList([1])));
    await expectLater(
        archive.add(
            NoteExportSourceFile('gone.jpg', '${directory.path}/missing.jpg')),
        throwsA(anything));
    await archive.close();
    final unpacked = ZipDecoder().decodeBytes(archive.file.readAsBytesSync());
    expect(unpacked.files.map((file) => file.name), ['Kept.md']);
  });

  test('discarding removes a partial archive', () async {
    final archive = ExportArchive.create('${directory.path}/notes.zip');
    await archive.add(NoteExportBytes('Trip.md', Uint8List.fromList([1])));
    await archive.discard();
    expect(await archive.file.exists(), isFalse);
    // Discarding twice, or after a close that already failed, is still safe.
    await archive.discard();
  });

  test('the archive name carries a sortable stamp', () {
    expect(ExportArchive.nameFor(DateTime(2026, 10, 16, 9, 5, 3)),
        'Onlynote-notes-2026-10-16T09-05-03.zip');
    expect(ExportArchive.nameFor(DateTime(2026, 1, 2, 3, 4, 5)),
        startsWith(ExportArchive.namePrefix));
  });

  test('sweeping clears earlier exports and nothing else', () async {
    final earlier =
        File('${directory.path}/${ExportArchive.nameFor(DateTime(2026, 1, 1))}')
          ..writeAsBytesSync([1]);
    final alsoMine =
        File('${directory.path}/${ExportArchive.namePrefix}stray.zip')
          ..writeAsBytesSync([1]);
    // A backup, a photo and a folder of someone else's temporary files are
    // not this app's export archives and must survive.
    final backup = File('${directory.path}/Onlynote-2026-01-01.onlynote')
      ..writeAsBytesSync([1]);
    final photo = File('${directory.path}/${ExportArchive.namePrefix}1.jpg')
      ..writeAsBytesSync([1]);
    final other = File('${directory.path}/something-else.zip')
      ..writeAsBytesSync([1]);
    final nested = await Directory('${directory.path}/nested').create();

    await ExportArchive.sweep(directory);

    expect(earlier.existsSync(), isFalse);
    expect(alsoMine.existsSync(), isFalse);
    expect(backup.existsSync(), isTrue);
    expect(photo.existsSync(), isTrue);
    expect(other.existsSync(), isTrue);
    expect(nested.existsSync(), isTrue);
  });

  test('a fresh export survives its own sweep', () async {
    await ExportArchive.sweep(directory);
    final archive = ExportArchive.create(
        '${directory.path}/${ExportArchive.nameFor(DateTime.now())}');
    await archive.add(NoteExportBytes('Trip.md', Uint8List.fromList([1])));
    await archive.close();
    expect(archive.file.existsSync(), isTrue);
  });

  test('sweeping a directory that is not there is not an error', () async {
    final missing = Directory('${directory.path}/gone');
    await expectLater(ExportArchive.sweep(missing), completes);
  });
}
