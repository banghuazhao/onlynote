import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:uuid/uuid.dart';

/// Journals the origin of Android's external camera/gallery activity, which
/// can outlive the Flutter process. This metadata is separate from note drafts.
class NotePhotoRecovery {
  NotePhotoRecovery({
    required this.drafts,
    required this.notes,
    Future<List<String>> Function()? retrieve,
    Future<String> Function(File source)? save,
  })  : _retrieve = retrieve ?? _retrieveLostPhotos,
        _save = save ?? ImageStorage.saveImage;

  static const recordKey = '_pending_photo_capture_v1';
  final Box drafts;
  final NoteRepository notes;
  final Future<List<String>> Function() _retrieve;
  final Future<String> Function(File source) _save;

  Iterable<String> get _captureKeys => drafts.keys.whereType<String>().where(
      (key) => key == recordKey || key.startsWith('$recordKey.deferred.'));

  bool get hasPendingCapture => _captureKeys.isNotEmpty;

  static Future<List<String>> _retrieveLostPhotos() async {
    final response = await ImagePicker().retrieveLostData();
    if (response.exception != null) throw response.exception!;
    return response.files?.map((file) => file.path).toList() ?? const [];
  }

  _PhotoRecord? _read([String key = recordKey]) =>
      _PhotoRecord.parse(drafts.get(key));

  Future<void> _write(_PhotoRecord record, {String key = recordKey}) async {
    await drafts.put(key, record.toMap());
    await drafts.flush();
  }

  Future<String> begin(Note note) async {
    final prior = _read();
    if (prior != null && (prior.sources.isNotEmpty || prior.saved.isNotEmpty)) {
      final missing = prior.sources.isNotEmpty &&
          (await Future.wait(prior.sources.map((path) => File(path).exists())))
              .every((exists) => !exists);
      if (!missing) {
        throw StateError('A captured photo is still awaiting a durable save');
      }
      // Camera cache files can disappear before a later startup. Retain this
      // record and any completed copies without blocking future captures.
      await _write(prior, key: '$recordKey.deferred.${prior.token}');
      await drafts.delete(recordKey);
    }
    final existed = notes.getAllNotes().any((saved) => saved.id == note.id);
    final record = _PhotoRecord(
      token: const Uuid().v4(),
      note: NoteDto.fromNote(note),
      existed: existed,
      sources: const [],
      saved: const [],
    );
    await _write(record);
    return record.token;
  }

  Future<void> selected(String token, String source) async {
    await selectedMany(token, [source]);
  }

  Future<void> selectedMany(String token, List<String> sources) async {
    final record = _read();
    if (record == null ||
        record.token != token ||
        sources.any((source) => !_validSource(source))) {
      throw StateError('The photo capture journal is unavailable');
    }
    await _write(record.copyWith(
        sources: sources
            .where((source) => !record.copiedSources.contains(source))
            .toSet()
            .toList()));
  }

  Future<void> copied(String token, String path, {String? sourcePath}) async {
    final record = _read();
    if (record == null ||
        record.token != token ||
        !_validSaved(path) ||
        (sourcePath != null && !_validSource(sourcePath))) {
      throw StateError('The photo capture journal is unavailable');
    }
    final source = sourcePath ?? record.sources.firstOrNull;
    await _write(record.copyWith(
      sources: record.sources.where((item) => item != source).toList(),
      saved: {...record.saved, path}.toList(),
      copiedSources:
          {...record.copiedSources, if (source != null) source}.toList(),
    ));
  }

  Future<void> complete(String token) async {
    for (final key in _captureKeys.toList()) {
      if (_read(key)?.token == token) await drafts.delete(key);
    }
  }

  /// Run before ordinary draft recovery and image pruning. On failure, both
  /// the camera's cache path and any completed copies remain in the journal.
  Future<void> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await recoverPending();
  }

  @visibleForTesting
  Future<void> recoverPending() async {
    try {
      var record = _read();
      final lost = await _retrieve();
      final validLost = lost.where(_validSource).toList();
      if (validLost.isNotEmpty) {
        record ??= _PhotoRecord(
          token: const Uuid().v4(),
          note: NoteDto.fromNote(Note(
            id: const Uuid().v4(),
            dateTime: DateTime.now(),
            sortOrder: -DateTime.now().millisecondsSinceEpoch,
          )),
          existed: false,
          sources: const [],
          saved: const [],
        );
        record = record.copyWith(
            sources: {
          ...record.sources,
          ...validLost.where((path) => !record!.copiedSources.contains(path)),
        }.toList());
        // retrieveLostData consumes plugin state; retain its paths before I/O.
        await _write(record);
      }
      if (record != null) await _recoverRecord(record, recordKey);
      for (final key
          in _captureKeys.where((key) => key != recordKey).toList()) {
        final deferred = _read(key);
        if (deferred != null) await _recoverRecord(deferred, key);
      }
    } catch (error) {
      debugPrint('Photo recovery deferred: $error');
    }
  }

  Future<void> _recoverRecord(_PhotoRecord initial, String key) async {
    var active = initial;
    try {
      if (active.sources.isEmpty && active.saved.isEmpty) {
        // Camera cancellation or termination before a photo was taken.
        await complete(active.token);
        return;
      }
      final latest = await _latestNote(active);
      if (latest == null || latest.isDeleted) {
        // Never resurrect a trashed or permanently removed existing note.
        await complete(active.token);
        return;
      }
      while (active.sources.isNotEmpty) {
        final source = active.sources.first;
        final path = await _save(File(source));
        if (!_validSaved(path)) {
          throw StateError('Recovered photo path is invalid');
        }
        active = active.copyWith(
          sources: active.sources.skip(1).toList(),
          saved: [...active.saved, path],
          copiedSources: {...active.copiedSources, source}.toList(),
        );
        await _write(active, key: key);
      }
      final merged = latest.copyWith(
        imagePaths: {...latest.imagePaths, ...active.saved}.toList(),
        dateTime: DateTime.now(),
      );
      // Journal the complete note first so a failed repository write is also
      // recoverable by the app's existing autosave recovery path.
      await drafts.put(merged.id!, NoteDto.fromNote(merged));
      await drafts.flush();
      await notes.addUpdateNote(NoteDto.fromNote(merged));
      await drafts.delete(merged.id!);
      await complete(active.token);
    } catch (error) {
      debugPrint('Photo recovery deferred: $error');
    }
  }

  Future<Note?> _latestNote(_PhotoRecord record) async {
    NoteDto? stored;
    for (final saved in notes.getAllNotes()) {
      if (saved.id == record.note.id) {
        stored = saved;
        break;
      }
    }
    if (stored == null && record.existed) return null;
    if (stored?.isDeleted ?? false) return null;
    final draft = drafts.get(record.note.id!);
    final content = draft is NoteDto && draft.id == record.note.id
        ? draft
        : stored ?? record.note;
    return (stored == null
            ? content
            : content.copyWith(
                dailyNoteDateKey: stored.dailyNoteDateKey,
                clearDailyNoteDateKey: stored.dailyNoteDateKey == null))
        .toDomain();
  }

  static bool _validSource(String path) =>
      path.startsWith('/') &&
      path.length <= 4096 &&
      !path.contains('\u0000') &&
      !path.split('/').contains('..');

  static bool _validSaved(String path) =>
      RegExp(r'^note_images/[^/\\]+\.[a-zA-Z0-9]+$').hasMatch(path) &&
      !path.contains('..') &&
      path.length <= 512;
}

class _PhotoRecord {
  const _PhotoRecord({
    required this.token,
    required this.note,
    required this.existed,
    required this.sources,
    required this.saved,
    this.copiedSources = const [],
  });
  final String token;
  final NoteDto note;
  final bool existed;
  final List<String> sources;
  final List<String> saved;
  final List<String> copiedSources;

  static _PhotoRecord? parse(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    final token = value['token'];
    final note = value['note'];
    final sources = value['sources'];
    final saved = value['saved'];
    final existed = value['existed'];
    final copiedSources = value['copiedSources'] ?? const <String>[];
    if (token is! String ||
        token.isEmpty ||
        note is! NoteDto ||
        note.id == null ||
        note.id!.isEmpty ||
        existed is! bool ||
        sources is! List ||
        saved is! List ||
        copiedSources is! List ||
        copiedSources.any((path) =>
            path is! String || !NotePhotoRecovery._validSource(path)) ||
        sources.any((path) =>
            path is! String || !NotePhotoRecovery._validSource(path)) ||
        saved.any((path) =>
            path is! String || !NotePhotoRecovery._validSaved(path))) {
      return null;
    }
    return _PhotoRecord(
      token: token,
      note: note,
      existed: existed,
      sources: sources.cast<String>(),
      saved: saved.cast<String>(),
      copiedSources: copiedSources.cast<String>(),
    );
  }

  Map<String, Object> toMap() => {
        'version': 1,
        'token': token,
        'note': note,
        'existed': existed,
        'sources': sources,
        'saved': saved,
        'copiedSources': copiedSources,
      };

  _PhotoRecord copyWith(
          {List<String>? sources,
          List<String>? saved,
          List<String>? copiedSources}) =>
      _PhotoRecord(
        token: token,
        note: note,
        existed: existed,
        sources: sources ?? this.sources,
        saved: saved ?? this.saved,
        copiedSources: copiedSources ?? this.copiedSources,
      );
}
