import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_photo_recovery.dart';

/// Keeps a selected camera image available when its first durable copy fails.
class NotePhotoCapture {
  NotePhotoCapture({
    Future<XFile?> Function(ImageSource source)? pick,
    Future<String> Function(File source)? save,
    NotePhotoRecovery? recovery,
  })  : _pick = pick ??
            ((source) =>
                ImagePicker().pickImage(source: source, imageQuality: 85)),
        _save = save ?? ImageStorage.saveImage,
        _recovery = recovery ?? _nativeRecovery();

  final Future<XFile?> Function(ImageSource source) _pick;
  final Future<String> Function(File source) _save;
  final NotePhotoRecovery? _recovery;
  XFile? _pending;
  String? _token;

  bool get canRetry => _pending != null;
  bool get isJournaled => _token != null;

  static NotePhotoRecovery? _nativeRecovery() {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !Hive.isBoxOpen(draftDatabaseBox) ||
        !getIt.isRegistered<NoteRepository>()) {
      return null;
    }
    return NotePhotoRecovery(
      drafts: Hive.box(draftDatabaseBox),
      notes: getIt<NoteRepository>(),
    );
  }

  Future<void> prepare(Note origin) async {
    if (_recovery != null && _token == null) {
      _token = await _recovery.begin(origin);
    }
  }

  /// The editor calls this only after its note has been durably autosaved.
  Future<void> complete() async {
    if (_pending != null) return;
    if (_token != null) await _recovery?.complete(_token!);
    _token = null;
  }

  Future<String?> capture(ImageSource source) async {
    if (_pending != null) return retry();
    try {
      final picked = await _pick(source);
      if (picked == null) {
        await complete();
        return null;
      }
      _pending = picked;
      return await retry();
    } catch (_) {
      if (_pending == null) await complete();
      rethrow;
    }
  }

  Future<String?> retry() async {
    final source = _pending;
    if (source == null) return null;
    if (_token != null) await _recovery?.selected(_token!, source.path);
    final saved = await _save(File(source.path));
    if (_token != null) await _recovery?.copied(_token!, saved);
    _pending = null;
    return saved;
  }
}
