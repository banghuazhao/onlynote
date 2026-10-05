import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'custom_template_images.dart';

CustomTemplateImages createDeviceTemplateImages({String? documentsPath}) =>
    FileCustomTemplateImages(documentsPath: documentsPath);

class FileCustomTemplateImages implements CustomTemplateImages {
  FileCustomTemplateImages({String? documentsPath})
      : _documentsPath = documentsPath;
  String? _documentsPath;

  Future<String> _documents() async =>
      _documentsPath ??= (await getApplicationDocumentsDirectory()).path;

  String _resolve(String path, String documents) {
    if (!path.startsWith('/')) {
      if (path.split('/').contains('..')) {
        throw const FormatException('Unsafe image path');
      }
      return '$documents/$path';
    }
    const marker = '/Documents/';
    final position = path.indexOf(marker);
    return position < 0
        ? path
        : '$documents/${path.substring(position + marker.length)}';
  }

  Future<List<String>> _copy(List<String> paths, String folder) async {
    if (paths.isEmpty) return [];
    final documents = await _documents();
    final directory = Directory('$documents/$folder');
    await directory.create(recursive: true);
    final copied = <String>[];
    try {
      for (final path in paths) {
        final suffix = path.split('.').last.toLowerCase();
        final extension =
            RegExp(r'^[a-z0-9]{1,10}$').hasMatch(suffix) ? suffix : 'jpg';
        final destination = '$folder/${const Uuid().v4()}.$extension';
        await File(_resolve(path, documents)).copy('$documents/$destination');
        copied.add(destination);
      }
      return copied;
    } catch (_) {
      for (final path in copied) {
        try {
          await File('$documents/$path').delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<List<String>> copyToTemplate(List<String> sources) =>
      _copy(sources, 'template_images');
  @override
  Future<List<String>> copyToNote(List<String> sources) {
    if (sources.any((path) => !isOwnedTemplateImagePath(path))) {
      throw const FormatException('Unsafe template image path');
    }
    return _copy(sources, 'note_images');
  }

  @override
  Future<void> deleteTemplates(List<String> paths) async {
    if (paths.isEmpty) return;
    final documents = await _documents();
    for (final path in paths.where(isOwnedTemplateImagePath)) {
      try {
        final file = File('$documents/$path');
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> pruneTemplates(Set<String> keep) async {
    final documents = await _documents();
    final directory = Directory('$documents/template_images');
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final path = 'template_images/${entity.uri.pathSegments.last}';
      if (!isOwnedTemplateImagePath(path) || keep.contains(path)) continue;
      try {
        await entity.delete();
      } catch (_) {}
    }
  }
}
