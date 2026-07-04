import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Persists note images outside the OS-managed cache/temp directories that
/// `image_picker` returns files in, so they survive app restarts and OS
/// cache clears.
class ImageStorage {
  static const _uuid = Uuid();

  static Future<String> saveImage(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/note_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = source.path.split('.').last;
    final fileName = '${_uuid.v4()}.$extension';
    final savedFile = await source.copy('${imagesDir.path}/$fileName');
    return savedFile.path;
  }

  static Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best-effort cleanup; a missing/locked file shouldn't block the user.
      }
    }
  }
}
