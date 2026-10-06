import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/document_scan.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/scanned_note.dart';
import 'package:uuid/uuid.dart';

export 'document_scan.dart';

class DocumentScanCaptureResult {
  const DocumentScanCaptureResult({
    required this.status,
    this.savedPaths = const [],
    this.error,
  });
  final DocumentScanStatus status;

  /// Newly copied pages, in reviewed order. Retries return only new copies.
  final List<String> savedPaths;
  final Object? error;
}

/// Journals the editor's origin before opening native UI, then retains every
/// completed page until a durable note save and native acknowledgement succeed.
class DocumentScanCapture {
  DocumentScanCapture({
    Box? journalBox,
    NoteRepository? repository,
    DocumentScanner? scanner,
    Future<String> Function(File source)? save,
    DateTime Function()? now,
    String Function()? createId,
    Note Function(Note note, List<String> paths)? decorate,
  })  : _journal = journalBox ??
            (Hive.isBoxOpen(draftDatabaseBox)
                ? Hive.box(draftDatabaseBox)
                : null),
        _repository = repository ??
            (getIt.isRegistered<NoteRepository>()
                ? getIt<NoteRepository>()
                : null),
        _scanner = scanner ?? DocumentScanner.instance,
        _save = save ?? ImageStorage.saveImage,
        _now = now ?? DateTime.now,
        _createId = createId ?? const Uuid().v4,
        _decorate =
            decorate ?? ((note, paths) => appendScannedPages(note, paths));

  static const journalPrefix = '_document_scan_capture_v1.';
  static DocumentScanCapture? initializedInstance;
  static void configure(DocumentScanCapture capture) =>
      initializedInstance = capture;
  static final Set<String> _activeTokens = {};
  static final Map<String, String> _copiesAwaitingJournal = {};
  // Editor capture and startup/resume recovery share the same durable journal.
  static Future<void> _operations = Future.value();

  final Box? _journal;
  final NoteRepository? _repository;
  final DocumentScanner _scanner;
  final Future<String> Function(File source) _save;
  final DateTime Function() _now;
  final String Function() _createId;
  final Note Function(Note, List<String>) _decorate;
  String? _token;
  bool _released = false;

  bool get hasPending => _keys.isNotEmpty || _copiesAwaitingJournal.isNotEmpty;
  bool get canRetry {
    final record = _token == null ? null : _read(_token!);
    return record != null &&
        !record.abandoned &&
        (record.status == DocumentScanStatus.pending ||
            record.saved.length < record.sources.length);
  }

  bool get isJournaled => _token != null;

  Iterable<String> get _keys => _journal == null
      ? const []
      : _journal.keys
          .whereType<String>()
          .where((key) => key.startsWith(journalPrefix));

  Set<String> get referencedImages => {
        for (final key in _keys)
          if (_readKey(key) case final record?) ...[
            ...record.note.imagePaths ?? const <String>[],
            ...record.saved,
          ],
        ..._copiesAwaitingJournal.values,
      };

  Future<DocumentScanCaptureResult> scan(Note origin) async {
    if (_released) return _failure(StateError('The editor was released'));
    if (_token != null) return retry();
    var launched = false;
    String? preparedToken;
    try {
      await _serialized(() async {
        if (_released) throw StateError('The editor was released');
        if (_journal == null || _repository == null) {
          throw StateError('Document scan recovery storage is unavailable');
        }
        if (origin.id == null ||
            origin.id!.trim().isEmpty ||
            origin.isDeleted) {
          throw const FormatException('Invalid document scan origin');
        }
        final stored = _stored(origin.id!);
        if (stored?.isDeleted == true) {
          throw StateError('The note is no longer available');
        }
        final token = _createId().toLowerCase();
        if (!DocumentScanResult.validId(token)) {
          throw const FormatException('Invalid document scan request ID');
        }
        preparedToken = token;
        _token = token;
        _activeTokens.add(token);
        await _write(_ScanRecord(
          id: token,
          note: NoteDto.fromNote(origin),
          existed: stored != null,
          sources: const [],
          saved: const [],
          status: DocumentScanStatus.pending,
        ));
        if (_released) throw StateError('The editor was released');
      });
      if (_released) throw StateError('The editor was released');
      final token = preparedToken!;
      launched = true;
      final response = await _scanner.scan(id: token);
      return await _serialized(() => _acceptAndCopy(token, response));
    } catch (error) {
      final token = preparedToken;
      if (!launched && token != null) {
        // No native UI was launched, so this failed preparation cannot own
        // selected pages. Remove its editor lock even if storage is failing.
        _releaseToken(token);
        try {
          await _serialized(() async {
            await _journal?.delete('$journalPrefix$token');
            await _journal?.flush();
          });
        } catch (_) {
          // Any remaining durable seed can still be inspected on startup.
        }
      }
      return _failure(error);
    }
  }

  /// Never reopens native UI. Pending native work is rechecked, while copied
  /// pages and any interrupted journal writes continue from their saved index.
  Future<DocumentScanCaptureResult> retry() async {
    final token = _token;
    if (_released || token == null) {
      return _failure(StateError('No document scan is awaiting retry'));
    }
    try {
      return await _serialized(() async {
        final record = _read(token);
        if (record == null) {
          throw StateError('Document scan journal is missing');
        }
        final response = (await _scanner.pending())
            .where((item) => item.id == token)
            .firstOrNull;
        if (response != null) return _acceptAndCopy(token, response);
        if (record.status == DocumentScanStatus.pending) {
          return const DocumentScanCaptureResult(
              status: DocumentScanStatus.pending);
        }
        return _copy(record);
      });
    } catch (error) {
      return _failure(error);
    }
  }

  Future<DocumentScanCaptureResult> _acceptAndCopy(
      String token, DocumentScanResult response,
      {bool copy = true}) async {
    var record = _read(token);
    if (record == null) throw StateError('Document scan journal is missing');
    // Also validate injected scanner results before any file access.
    final validated = DocumentScanResult.parse({
      'id': response.id,
      'status': _statusName(response.status),
      'paths': response.paths,
    }, expectedId: token);
    if (validated == null) {
      throw const FormatException('Invalid document scan pages');
    }
    if (response.status == DocumentScanStatus.pending) {
      return const DocumentScanCaptureResult(
          status: DocumentScanStatus.pending);
    }
    if (response.status != DocumentScanStatus.pages) {
      if (record.sources.isNotEmpty) {
        throw const FormatException('Document scan page identity changed');
      }
      record = record.copyWith(status: response.status);
      await _write(record);
      await _ackAndRemove(record);
      return DocumentScanCaptureResult(
          status: response.status, error: response.error);
    }
    if (record.sources.isNotEmpty &&
        !listEquals(record.sources.map(_filename).toList(),
            response.paths.map(_filename).toList())) {
      throw const FormatException('Document scan page identity changed');
    }
    record = record.copyWith(
        sources: response.paths, status: DocumentScanStatus.pages);
    await _write(record);
    if (record.abandoned) {
      await _ackAndRemove(record);
      return const DocumentScanCaptureResult(
          status: DocumentScanStatus.cancelled);
    }
    if (copy && await _latestNote(record) == null) {
      final abandoned = record.copyWith(abandoned: true);
      await _write(abandoned);
      await _ackAndRemove(abandoned);
      return const DocumentScanCaptureResult(
          status: DocumentScanStatus.cancelled);
    }
    return copy
        ? _copy(record)
        : const DocumentScanCaptureResult(status: DocumentScanStatus.pages);
  }

  Future<DocumentScanCaptureResult> _copy(_ScanRecord initial) async {
    var record = initial;
    final newlySaved = <String>[];
    try {
      if (record.status != DocumentScanStatus.pages) {
        await _ackAndRemove(record);
        return DocumentScanCaptureResult(status: record.status);
      }
      while (record.saved.length < record.sources.length) {
        if (_read(record.id)?.abandoned == true) {
          await _ackAndRemove(record.copyWith(abandoned: true));
          return const DocumentScanCaptureResult(
              status: DocumentScanStatus.cancelled);
        }
        final source = record.sources[record.saved.length];
        final identity = '${record.id}:${record.saved.length}';
        final saved =
            _copiesAwaitingJournal[identity] ??= await _save(File(source));
        if (!_validSaved(saved)) {
          _copiesAwaitingJournal.remove(identity);
          throw const FormatException('Invalid copied document page path');
        }
        if (record.saved.contains(saved)) {
          throw const FormatException(
              'Document pages must own distinct copies');
        }
        final next = record.copyWith(saved: [...record.saved, saved]);
        await _write(next);
        _copiesAwaitingJournal.remove(identity);
        record = next;
        newlySaved.add(saved);
      }
      return DocumentScanCaptureResult(
          status: DocumentScanStatus.pages,
          savedPaths: List.unmodifiable(newlySaved));
    } catch (error) {
      return DocumentScanCaptureResult(
          status: DocumentScanStatus.failed,
          savedPaths: List.unmodifiable(newlySaved),
          error: error);
    }
  }

  /// Call after editor autosave succeeds. Acknowledgement is deliberately
  /// refused until every retained page belongs to a durable, non-trashed note.
  Future<void> complete() async {
    final token = _token;
    if (token == null) return;
    await _serialized(() async {
      final record = _read(token);
      if (record == null) {
        _releaseToken(token);
        return;
      }
      if (record.status == DocumentScanStatus.pending ||
          record.saved.length < record.sources.length) {
        throw StateError('Document scan pages are still pending');
      }
      if (record.committed || record.abandoned) {
        await _ackAndRemove(record);
      } else if (record.status == DocumentScanStatus.pages) {
        final stored = _stored(record.note.id!);
        if (record.retained.isNotEmpty &&
            (stored == null ||
                stored.isDeleted ||
                !record.retained.every(
                    (path) => stored.imagePaths?.contains(path) == true))) {
          throw StateError('Document scan pages have not been durably saved');
        }
        final committed = record.copyWith(committed: true);
        await _write(committed);
        await _ackAndRemove(committed);
      } else {
        await _ackAndRemove(record);
      }
    });
  }

  /// Persist an explicit removal or replacement before the editor changes the
  /// photo. Its copy index remains completed, so retry never recaptures it and
  /// recovery cannot restore the page the user intentionally discarded.
  Future<void> discardPage(String path) async {
    final token = _token;
    if (token == null) return;
    await _serialized(() async {
      final record = _read(token);
      if (record == null ||
          !record.saved.contains(path) ||
          record.discarded.contains(path)) {
        return;
      }
      await _write(record.copyWith(discarded: [...record.discarded, path]));
    });
  }

  /// An editor relinquishes recovery ownership when it unmounts. The journal
  /// and native inbox remain available to the app's next resume/startup pass.
  void release() {
    _released = true;
    if (_token case final token?) _activeTokens.remove(token);
    _token = null;
    if (identical(initializedInstance, this)) initializedInstance = null;
  }

  /// Permanent deletion marks even an originally unsaved seed as abandoned.
  /// Pending native UI is retained until its terminal result can be cleaned up.
  Future<void> purgeNotes(Set<String> ids) => _serialized(() async {
        for (final key in _keys.toList()) {
          final record = _readKey(key);
          if (record == null || !ids.contains(record.note.id)) continue;
          final abandoned = record.copyWith(abandoned: true);
          await _write(abandoned);
          if (abandoned.status != DocumentScanStatus.pending) {
            await _ackAndRemove(abandoned);
          }
        }
      });

  /// Run before ordinary draft recovery and image pruning. Active editors own
  /// their own attachment adoption; this pass only replays abandoned sessions.
  Future<void> recover() => _serialized(() async {
        if (_journal == null || _repository == null) return;
        List<DocumentScanResult> pending;
        try {
          pending = await _scanner.pending();
        } catch (error) {
          debugPrint('Document scan recovery deferred: $error');
          return;
        }
        final inbox = {for (final result in pending) result.id: result};
        for (final result in pending) {
          if (result.status == DocumentScanStatus.pending ||
              _activeTokens.contains(result.id) ||
              _read(result.id) != null) {
            continue;
          }
          try {
            // Reviewed native pages without an origin cannot safely create a
            // note. Release their inbox ownership without adopting any files.
            await _scanner.acknowledge(result.id);
            await _journal.delete('$journalPrefix${result.id}');
            await _journal.flush();
          } catch (error) {
            debugPrint('Orphan document scan cleanup deferred: $error');
          }
        }
        for (final key in _keys.toList()) {
          var record = _readKey(key);
          if (record == null || _activeTokens.contains(record.id)) continue;
          try {
            final response = inbox[record.id];
            if (response?.status == DocumentScanStatus.pending ||
                (response == null &&
                    record.status == DocumentScanStatus.pending)) {
              // The scanner may still be open or the native method may not yet
              // have reached its durable inbox. An empty source list isn't a
              // cancellation signal and must not erase its origin.
              continue;
            }
            if (response != null) {
              final result =
                  await _acceptAndCopy(record.id, response, copy: false);
              if (result.error != null) throw result.error!;
              record = _read(record.id);
              if (record == null) continue;
            }
            if (record.abandoned || record.committed) {
              await _ackAndRemove(record);
              continue;
            }
            if (record.status != DocumentScanStatus.pages) {
              await _ackAndRemove(record);
              continue;
            }
            if (await _latestNote(record) == null) {
              final abandoned = record.copyWith(abandoned: true);
              await _write(abandoned);
              await _ackAndRemove(abandoned);
              continue;
            }
            final copied = await _copy(record);
            if (copied.error != null) throw copied.error!;
            record = _read(record.id);
            if (record == null) continue;
            // Resolve again after file I/O so the latest edits and deletions
            // decide the merge, rather than the pre-scanner editor snapshot.
            final latest = await _latestNote(record);
            if (latest == null) {
              final abandoned = record.copyWith(abandoned: true);
              await _write(abandoned);
              await _ackAndRemove(abandoned);
              continue;
            }
            final stored = _stored(record.note.id!);
            if (record.retained.isEmpty && !NoteAutosave.hasContent(latest)) {
              // A new empty editor never creates a blank note just to save an
              // explicitly discarded scan. Every native page is still copied
              // before this terminal acknowledgement releases its originals.
              final committed = record.copyWith(committed: true);
              await _write(committed);
              await _ackAndRemove(committed);
              continue;
            }
            final alreadySaved = stored != null &&
                record.retained
                    .every((path) => stored.imagePaths?.contains(path) == true);
            if (!alreadySaved) {
              final merged =
                  _decorate(latest, record.retained).copyWith(dateTime: _now());
              final dto = NoteDto.fromNote(merged);
              await _journal.put(merged.id!, dto);
              await _journal.flush();
              // Draft I/O is another suspension point: don't resurrect a note
              // that was deleted while its recovery draft was being written.
              if (await _latestNote(record) == null) {
                await _journal.delete(merged.id!);
                final abandoned = record.copyWith(abandoned: true);
                await _write(abandoned);
                await _ackAndRemove(abandoned);
                continue;
              }
              await _repository.addUpdateNote(dto);
              await _journal.delete(merged.id!);
            }
            final committed = record.copyWith(committed: true);
            await _write(committed);
            await _ackAndRemove(committed);
          } catch (error) {
            debugPrint('Document scan recovery deferred: $error');
          }
        }
      });

  Future<Note?> _latestNote(_ScanRecord record) async {
    if (record.abandoned) return null;
    final stored = _stored(record.note.id!);
    if (stored == null &&
        (record.existed ||
            record.committed ||
            _deletionPending(record.note.id!))) {
      return null;
    }
    if (stored?.isDeleted == true) return null;
    final draft = _journal?.get(record.note.id!);
    final content =
        draft is NoteDto && draft.id == record.note.id && !draft.isDeleted
            ? draft
            : stored ?? record.note;
    return (stored == null
            ? content
            : content.copyWith(
                isArchived: stored.isArchived,
                isPinned: stored.isPinned,
                folderId: stored.folderId,
                clearFolderId: stored.folderId == null,
                sortOrder: stored.sortOrder,
                dailyNoteDateKey: stored.dailyNoteDateKey,
                clearDailyNoteDateKey: stored.dailyNoteDateKey == null))
        .toDomain();
  }

  NoteDto? _stored(String id) =>
      _repository?.getAllNotes().where((note) => note.id == id).firstOrNull;

  bool _deletionPending(String id) =>
      _journal?.keys.whereType<String>().any((key) {
        if (!key.startsWith('_note_delete_pending_v1.')) return false;
        final value = _journal.get(key);
        return value is Map &&
            value['version'] == 1 &&
            value['ids'] is List &&
            (value['ids'] as List).contains(id);
      }) ??
      false;

  _ScanRecord? _read(String id) => _readKey('$journalPrefix$id');
  _ScanRecord? _readKey(String key) => _ScanRecord.read(_journal?.get(key));
  Future<void> _write(_ScanRecord record) async {
    if (_journal == null) throw StateError('Document scan journal unavailable');
    await _journal.put('$journalPrefix${record.id}', record.toMap());
    await _journal.flush();
  }

  Future<void> _ackAndRemove(_ScanRecord record) async {
    await _scanner.acknowledge(record.id);
    await _journal!.delete('$journalPrefix${record.id}');
    await _journal.flush();
    _copiesAwaitingJournal
        .removeWhere((key, _) => key.startsWith('${record.id}:'));
    _releaseToken(record.id);
  }

  void _releaseToken(String token) {
    _activeTokens.remove(token);
    if (_token == token) _token = null;
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final task = _operations.then((_) => operation());
    _operations = task.then<void>((_) {}).catchError((Object _) {});
    return task;
  }

  static DocumentScanCaptureResult _failure(Object error) =>
      DocumentScanCaptureResult(
          status: DocumentScanStatus.failed, error: error);
}

String _filename(String path) => path.substring(path.lastIndexOf('/') + 1);
bool _validSaved(Object? path) =>
    path is String &&
    path.length <= 512 &&
    RegExp(r'^note_images/[^/\\]+\.[a-zA-Z0-9]+$').hasMatch(path) &&
    !RegExp(r'[\x00-\x1f\x7f]').hasMatch(path) &&
    !path.contains('..');

String _statusName(DocumentScanStatus status) => switch (status) {
      DocumentScanStatus.pages => 'pages',
      DocumentScanStatus.cancelled => 'cancelled',
      DocumentScanStatus.unsupported => 'unsupported',
      DocumentScanStatus.failed => 'failed',
      DocumentScanStatus.pending => 'pending',
      DocumentScanStatus.tooManyPages => 'too_many_pages',
      DocumentScanStatus.permissionDenied => 'permission_denied',
    };

class _ScanRecord {
  const _ScanRecord({
    required this.id,
    required this.note,
    required this.existed,
    required this.sources,
    required this.saved,
    required this.status,
    this.committed = false,
    this.abandoned = false,
    this.discarded = const [],
  });
  final String id;
  final NoteDto note;
  final bool existed;
  final List<String> sources;
  final List<String> saved;
  final DocumentScanStatus status;
  final bool committed;
  final bool abandoned;
  final List<String> discarded;
  List<String> get retained =>
      saved.where((path) => !discarded.contains(path)).toList();

  static _ScanRecord? read(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    final id = value['id'];
    final note = value['note'];
    final existed = value['existed'];
    final sources = value['sources'];
    final saved = value['saved'];
    final committed = value['committed'] ?? false;
    final abandoned = value['abandoned'] ?? false;
    final discarded = value['discarded'] ?? const <String>[];
    if (id is! String ||
        !DocumentScanResult.validId(id) ||
        note is! NoteDto ||
        note.id?.trim().isNotEmpty != true ||
        existed is! bool ||
        sources is! List ||
        sources.length > DocumentScanner.maxPageCount ||
        sources.any((path) =>
            path is! String || !DocumentScanResult.validSource(path, id)) ||
        sources.toSet().length != sources.length ||
        saved is! List ||
        saved.length > sources.length ||
        saved.any((path) => !_validSaved(path)) ||
        saved.toSet().length != saved.length ||
        discarded is! List ||
        discarded.any((path) => path is! String || !saved.contains(path)) ||
        discarded.toSet().length != discarded.length ||
        committed is! bool ||
        abandoned is! bool) {
      return null;
    }
    final statusResult = DocumentScanResult.parse({
      'id': id,
      'status': value['status'],
      'paths': value['status'] == 'pages' ? sources : const <String>[],
    });
    if (statusResult == null ||
        (statusResult.status != DocumentScanStatus.pages &&
            (sources.isNotEmpty || saved.isNotEmpty))) {
      return null;
    }
    return _ScanRecord(
      id: id,
      note: note,
      existed: existed,
      sources: sources.cast<String>().toList(),
      saved: saved.cast<String>().toList(),
      status: statusResult.status,
      committed: committed,
      abandoned: abandoned,
      discarded: discarded.cast<String>().toList(),
    );
  }

  Map<String, Object> toMap() => {
        'version': 1,
        'id': id,
        'note': note,
        'existed': existed,
        'sources': sources,
        'saved': saved,
        'status': _statusName(status),
        'committed': committed,
        'abandoned': abandoned,
        'discarded': discarded,
      };

  _ScanRecord copyWith({
    List<String>? sources,
    List<String>? saved,
    DocumentScanStatus? status,
    bool? committed,
    bool? abandoned,
    List<String>? discarded,
  }) =>
      _ScanRecord(
        id: id,
        note: note,
        existed: existed,
        sources: sources ?? this.sources,
        saved: saved ?? this.saved,
        status: status ?? this.status,
        committed: committed ?? this.committed,
        abandoned: abandoned ?? this.abandoned,
        discarded: discarded ?? this.discarded,
      );
}
