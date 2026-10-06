import 'dart:io';

import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Managed recordings use immutable files. Duplicates and templates receive
/// their own copies; history can safely retain an older recording reference.
class AudioStorage {
  AudioStorage({String? documentsPath}) : _documentsPath = documentsPath;
  static final instance = AudioStorage();
  String? _documentsPath;

  Future<String> init() async =>
      _documentsPath ??= (await getApplicationDocumentsDirectory()).path;

  Future<String> resolvePath(String path) async {
    if (!VoiceMemo.isManagedPath(path)) {
      throw const FormatException('Unsafe recording path');
    }
    return '${await init()}/$path';
  }

  Future<VoiceMemo> createMemo() async {
    final id = const Uuid().v4();
    await Directory('${await init()}/note_audio').create(recursive: true);
    return VoiceMemo(
        id: id,
        path: 'note_audio/$id.m4a',
        durationMs: 0,
        createdAt: DateTime.now());
  }

  Future<void> flush(VoiceMemo memo) async {
    final file = File(await resolvePath(memo.path));
    final length = await file.length();
    if (length <= 0 || length > 32 * 1024 * 1024 || memo.durationMs <= 0) {
      throw const FormatException('Invalid recording');
    }
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  Future<List<VoiceMemo>> copyToNote(List<VoiceMemo> source) =>
      _copy(source, 'note_audio');
  Future<List<VoiceMemo>> copyToTemplate(List<VoiceMemo> source) =>
      _copy(source, 'template_audio');

  Future<List<VoiceMemo>> _copy(List<VoiceMemo> source, String folder) async {
    if (source.isEmpty) return [];
    final documents = await init();
    await Directory('$documents/$folder').create(recursive: true);
    final copied = <VoiceMemo>[];
    final temporary = <File>[];
    try {
      for (final memo in source) {
        final id = const Uuid().v4();
        final path = '$folder/$id.m4a';
        final pending = File('$documents/$path.pending');
        temporary.add(pending);
        final original = File(await resolvePath(memo.path));
        if (await original.length() <= 0) {
          throw const FormatException('Empty recording');
        }
        await original.copy(pending.path);
        final handle = await pending.open(mode: FileMode.append);
        try {
          await handle.flush();
        } finally {
          await handle.close();
        }
        await pending.rename('$documents/$path');
        copied.add(memo.copyWith(id: id, path: path));
      }
      return copied;
    } catch (_) {
      await deletePaths(copied.map((memo) => memo.path));
      for (final file in temporary) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> deletePaths(Iterable<String> paths) async {
    for (final path in paths.toSet().where(VoiceMemo.isManagedPath)) {
      try {
        final file = File(await resolvePath(path));
        if (await file.exists()) await file.delete();
      } catch (_) {/* Housekeeping can retry at next startup. */}
    }
  }

  Future<void> prune(Set<String> keep) async {
    final documents = await init();
    for (final folder in ['note_audio', 'template_audio']) {
      final directory = Directory('$documents/$folder');
      if (!await directory.exists()) continue;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        final path = '$folder/${entity.uri.pathSegments.last}';
        if (!VoiceMemo.isManagedPath(path) || keep.contains(path)) continue;
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }
}
