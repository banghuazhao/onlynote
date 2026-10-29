import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/services/markdown_import.dart';
import 'package:onlynote/services/markdown_import_service.dart';

class MarkdownImportPickedFile {
  const MarkdownImportPickedFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

Future<List<MarkdownImportPickedFile>> pickMarkdownImportFiles() async {
  final files = await openFiles(acceptedTypeGroups: const [
    XTypeGroup(label: 'Markdown and ZIP', extensions: [
      'md',
      'markdown',
      'zip'
    ], uniformTypeIdentifiers: [
      'net.daringfireball.markdown',
      'public.plain-text',
      'public.zip-archive'
    ])
  ]);
  if (files.length > MarkdownImportReader.maxDocuments) {
    throw const FormatException('Too many files');
  }
  final selected = <MarkdownImportPickedFile>[];
  var total = 0;
  for (final file in files) {
    final length = await file.length();
    total += length;
    if (total > MarkdownImportReader.maxInputBytes) {
      throw const FormatException('Import too large');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length != length ||
        bytes.length > MarkdownImportReader.maxInputBytes) {
      throw const FormatException('File changed');
    }
    selected.add(MarkdownImportPickedFile(name: file.name, bytes: bytes));
  }
  return selected;
}

class LocalMarkdownImportImageStore implements MarkdownImportImageStore {
  @override
  Future<String> write(MarkdownImportImage image) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/note_images');
    await directory.create(recursive: true);
    final name = '${const Uuid().v4()}.${image.extension}';
    final pending = File('${directory.path}/$name.partial');
    try {
      await pending.writeAsBytes(image.bytes, flush: true);
      await pending.rename('${directory.path}/$name');
      return 'note_images/$name';
    } catch (_) {
      if (await pending.exists()) await pending.delete();
      rethrow;
    }
  }

  @override
  Future<void> delete(List<String> paths) => ImageStorage.deleteImages(paths);
}
