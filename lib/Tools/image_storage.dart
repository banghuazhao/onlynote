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

  /// Copies [paths] to fresh files so the copy owns its own images — used
  /// when a note is duplicated, otherwise both notes point at the same file
  /// and deleting either one breaks the other.
  static Future<List<String>> copyImages(List<String> paths) async {
    final copies = <String>[];
    for (final path in paths) {
      try {
        final source = File(resolvePath(path));
        if (!await source.exists()) continue;
        copies.add(await saveImage(source));
      } catch (_) {
        // Best-effort: a failed copy just means the duplicate has one
        // image fewer, which beats failing the whole duplication.
      }
    }
    return copies;
  }

  /// Deletes image files no note points at any more — drafts abandoned
  /// without saving, or files orphaned by an interrupted delete. [keep] holds
  /// the absolute paths (see [resolvePath]) that are still referenced.
  static Future<void> pruneOrphans(Set<String> keep) async {
    try {
      final documentsPath = await _documentsPathAsync();
      final imagesDir = Directory('$documentsPath/note_images');
      if (!await imagesDir.exists()) return;

      await for (final entity in imagesDir.list()) {
        if (entity is! File) continue;
        if (keep.contains(entity.path)) continue;
        try {
          await entity.delete();
        } catch (_) {
          // Locked or already gone — nothing to do.
        }
      }
    } catch (_) {
      // Housekeeping only; never let it break startup.
    }
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
