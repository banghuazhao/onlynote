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
}
