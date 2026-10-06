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

/// Successful copies are usable even when a later selected photo cannot save.
class NotePhotoCaptureResult {
  const NotePhotoCaptureResult({this.savedPaths = const [], this.error});
  final List<String> savedPaths;
  final Object? error;
}

/// Retains selected photos until their durable copies and journal writes finish.
class NotePhotoCapture {
  NotePhotoCapture({
    Future<XFile?> Function(ImageSource source)? pick,
    Future<List<XFile>> Function()? pickMany,
    Future<String> Function(File source)? save,
    NotePhotoRecovery? recovery,
  })  : _pick = pick ??
            ((source) =>
                ImagePicker().pickImage(source: source, imageQuality: 85)),
        _pickMany = pickMany ??
            (pick != null
                ? (() async {
                    final photo = await pick(ImageSource.gallery);
                    return photo == null ? <XFile>[] : [photo];
                  })
                : (() => ImagePicker().pickMultiImage(imageQuality: 85))),
        _save = save ?? ImageStorage.saveImage,
        _recovery = recovery ?? _nativeRecovery();

  final Future<XFile?> Function(ImageSource source) _pick;
  final Future<List<XFile>> Function() _pickMany;
  final Future<String> Function(File source) _save;
  final NotePhotoRecovery? _recovery;
  final List<XFile> _pending = [];
  String? _copiedPending;
  String? _token;
  bool _selectionJournaled = false;

  bool get canRetry => _pending.isNotEmpty;
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
    if (canRetry) return;
    if (_token != null) await _recovery?.complete(_token!);
    _token = null;
    _selectionJournaled = false;
  }

  /// Single-photo compatibility API, including the original throwing retry.
  Future<String?> capture(ImageSource source) async {
    if (canRetry) return retry();
    try {
      final picked = await _pick(source);
      if (picked == null) {
        await complete();
        return null;
      }
      _pending.add(picked);
      _selectionJournaled = false;
      return await retry();
    } catch (_) {
      if (!canRetry) await complete();
      rethrow;
    }
  }

  Future<String?> retry() async {
    if (!canRetry) return null;
    await _journalSelection();
    return _copyFirst();
  }

  /// Gallery opens the platform multi-picker once; camera still captures one.
  Future<NotePhotoCaptureResult> captureMany(ImageSource source) async {
    if (canRetry) return retryMany();
    try {
      final selected = source == ImageSource.gallery
          ? await _pickMany()
          : [if (await _pick(source) case final photo?) photo];
      final seen = <String>{};
      _pending.addAll(selected.where((photo) => seen.add(photo.path)));
      if (!canRetry) {
        await complete();
        return const NotePhotoCaptureResult();
      }
      _selectionJournaled = false;
      return await retryMany();
    } catch (error) {
      if (!canRetry) await complete();
      return NotePhotoCaptureResult(error: error);
    }
  }

  /// Returns only newly completed copies. Retrying never reopens the picker.
  Future<NotePhotoCaptureResult> retryMany() async {
    final saved = <String>[];
    try {
      if (!canRetry) return const NotePhotoCaptureResult();
      await _journalSelection();
      while (canRetry) {
        saved.add(await _copyFirst());
      }
      return NotePhotoCaptureResult(savedPaths: saved);
    } catch (error) {
      return NotePhotoCaptureResult(savedPaths: saved, error: error);
    }
  }

  Future<void> _journalSelection() async {
    if (_selectionJournaled) return;
    if (_token != null) {
      await _recovery?.selectedMany(
          _token!, _pending.map((photo) => photo.path).toList());
    }
    _selectionJournaled = true;
  }

  Future<String> _copyFirst() async {
    final source = _pending.first;
    // Retain a completed copy if the journal acknowledgement needs a retry.
    // This avoids making another file for the same source in this session.
    final saved = _copiedPending ??= await _save(File(source.path));
    if (_token != null) {
      await _recovery?.copied(_token!, saved, sourcePath: source.path);
    }
    _pending.removeAt(0);
    _copiedPending = null;
    return saved;
  }
}
