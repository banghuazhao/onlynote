import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Persists note images outside the OS-managed cache/temp directories that
/// `image_picker` returns files in, so they survive app restarts and OS
/// cache clears.
///
/// Notes store *relative* paths (e.g. `note_images/<uuid>.jpg`), not
/// absolute ones — on iOS the app's container directory gets a new UUID on
/// every reinstall/restore/OS update, so an absolute path saved today can
/// 404 tomorrow even though the file itself is still there. [resolvePath]
/// rebuilds the absolute path against wherever the documents directory
/// currently lives, and also repairs paths saved back when this bug
/// existed (see the "/Documents/" fallback below).
class ImageStorage {
  static const _uuid = Uuid();
  static String? _documentsPath;

  /// Call once at app startup so [resolvePath] can work synchronously.
  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _documentsPath = directory.path;
  }

  static Future<String> _documentsPathAsync() async {
    if (_documentsPath != null) return _documentsPath!;
    final directory = await getApplicationDocumentsDirectory();
    _documentsPath = directory.path;
    return _documentsPath!;
  }

  /// Turns a stored path into an absolute path valid for *this* app launch.
  static String resolvePath(String storedPath) {
    final documentsPath = _documentsPath;

    if (!storedPath.startsWith('/')) {
      // Already relative — the expected, current format.
      return documentsPath != null ? '$documentsPath/$storedPath' : storedPath;
    }

    // Legacy absolute path saved before this fix. The container UUID prefix
    // may now be stale; rebase everything from "Documents/" onward onto the
    // current documents directory.
    const marker = '/Documents/';
    final index = storedPath.indexOf(marker);
    if (index != -1 && documentsPath != null) {
      final relative = storedPath.substring(index + marker.length);
      return '$documentsPath/$relative';
    }
    return storedPath;
  }

  static Future<String> saveImage(File source) async {
    final documentsPath = await _documentsPathAsync();
    final imagesDir = Directory('$documentsPath/note_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = source.path.split('.').last;
    final fileName = '${_uuid.v4()}.$extension';
    await source.copy('${imagesDir.path}/$fileName');
    return 'note_images/$fileName';
  }

  static Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(resolvePath(path));
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best-effort cleanup; a missing/locked file shouldn't block the user.
      }
    }
  }
}
