import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/photo_text_extraction.dart';

/// A rebuildable, on-device search cache. Recognition never edits source notes
/// or their timestamps, and only the photos currently attached to a note match.
class PhotoSearchIndex extends ChangeNotifier {
  PhotoSearchIndex({
    required this.notes,
    required this.cache,
    Future<PhotoTextResult> Function(String)? recognize,
    Future<bool> Function(String)? exists,
    DateTime Function()? now,
    this.retryCooldown = const Duration(minutes: 5),
  })  : _recognize = recognize ?? PhotoTextExtraction().extract,
        _exists = exists ?? _fileExists,
        _now = now ?? DateTime.now;

  static const boxName = 'photo_search_index_v1';
  static PhotoSearchIndex? _instance;
  static PhotoSearchIndex? get initializedInstance => _instance;
  static void configure(PhotoSearchIndex service) => _instance = service;

  final Box notes;
  final Box cache;
  final Duration retryCooldown;
  final Future<PhotoTextResult> Function(String) _recognize;
  final Future<bool> Function(String) _exists;
  final DateTime Function() _now;
  final Map<String, _PhotoTextEntry> _entries = {};
  final Map<String, DateTime> _retryAfter = {};
  final Map<String, int> _generations = {};
  final Set<String> _probes = {};
  Set<String> _referenced = {};
  StreamSubscription<BoxEvent>? _subscription;
  Future<void> _storageWrites = Future.value();
  Timer? _scheduled;
  bool _started = false;
  bool _disposed = false;
  bool _active = true;
  bool _unsupported = false;
  bool _running = false;
  bool _isIndexing = false;

  bool get isIndexing => _isIndexing;

  /// Loads existing results and observes durable note changes. This completes
  /// without awaiting the recognition backlog, which runs one photo at a time.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _subscription = notes.watch().listen((_) => _synchronize());
    _referenced = _currentPaths();
    for (final key in cache.keys.toList()) {
      if (key is! String ||
          _managedPath(key) != key ||
          !_referenced.contains(key)) {
        continue;
      }
      final entry = _PhotoTextEntry.read(cache.get(key));
      if (entry != null) _entries[key] = entry;
    }
    _probes.addAll(_entries.keys);
    _synchronize(forcePrune: true);
    if (_entries.isNotEmpty) notifyListeners();
  }

  /// Backgrounding prevents the next native request. An already running native
  /// request may finish, but removed photos and disposed services drop results.
  void setActive(bool active) {
    if (_disposed) return;
    _active = active;
    if (!active) {
      _scheduled?.cancel();
      _scheduled = null;
      _updateIndexing();
    } else if (_started) {
      // Resume also permits a cooled-down failure to retry, without a timer
      // keeping recognition alive while the app is in the background.
      _probes.addAll(_entries.keys);
      _synchronize();
    }
  }

  Iterable<String> textsForNote(Note note) sync* {
    if (_disposed) return;
    final seen = <String>{};
    for (final raw in note.imagePaths) {
      final path = _managedPath(raw);
      if (path == null || !seen.add(path)) continue;
      final text = _entries[path]?.text;
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  String? matchingText(Note note, String query) {
    final pattern = searchPattern(query);
    if (pattern == null) return null;
    for (final text in textsForNote(note)) {
      if (pattern.hasMatch(text)) return text;
    }
    return null;
  }

  /// Return the original attachment path so a result card can show the photo
  /// that explains the match, including notes with legacy absolute paths.
  String? matchingPhotoPath(Note note, String query) {
    final pattern = searchPattern(query);
    if (pattern == null || _disposed) return null;
    for (final raw in note.imagePaths) {
      final text = _entries[_managedPath(raw)]?.text;
      if (text != null && text.isNotEmpty && pattern.hasMatch(text)) return raw;
    }
    return null;
  }

  Set<String> _currentPaths() => {
        for (final value in notes.values)
          for (final raw in switch (value) {
            NoteDto note => note.imagePaths ?? const <String>[],
            Note note => note.imagePaths,
            _ => const <String>[],
          })
            if (_managedPath(raw) case final String path) path,
      };

  void _synchronize({bool forcePrune = false}) {
    if (_disposed || !_started) return;
    final current = _currentPaths();
    final membershipChanged = !setEquals(current, _referenced);
    var changed = false;
    for (final path in _referenced.difference(current)) {
      // A remove/readd while OCR is running must not publish that old request.
      _generations[path] = (_generations[path] ?? 0) + 1;
      changed = _entries.remove(path) != null || changed;
      _retryAfter.remove(path);
      _probes.remove(path);
    }
    _referenced = current;
    final now = _now();
    _retryAfter.removeWhere((path, after) => !now.isBefore(after));
    if (forcePrune || membershipChanged) _pruneCache();
    if (changed) notifyListeners();
    _schedule();
  }

  void _pruneCache() {
    _serializeStorage(() async {
      // Recheck at execution time: a photo may have returned since this prune
      // was queued, or a result may have been queued behind another write.
      final remove = cache.keys.where((key) {
        return key is! String ||
            _managedPath(key) != key ||
            !_referenced.contains(key) ||
            _PhotoTextEntry.read(cache.get(key)) == null;
      }).toList();
      if (remove.isNotEmpty) await cache.deleteAll(remove);
    });
  }

  String? _nextPath() {
    for (final path in _referenced) {
      if (_entries.containsKey(path)) continue;
      if (!_retryAfter.containsKey(path)) return path;
    }
    return null;
  }

  void _schedule() {
    if (_disposed || !_active || _running) {
      _updateIndexing();
      return;
    }
    if (_scheduled == null && _hasWork) {
      // Yield between startup/saves and native OCR, keeping those flows quick.
      _scheduled = Timer(Duration.zero, () {
        _scheduled = null;
        unawaited(_drain());
      });
    }
    _updateIndexing();
  }

  Future<void> _drain() async {
    if (_disposed || !_active || _running) return;
    _running = true;
    _updateIndexing();
    try {
      while (!_disposed && _active) {
        final path = _probes.isNotEmpty
            ? _probes.first
            : _unsupported
                ? null
                : _nextPath();
        if (path == null) break;
        _probes.remove(path);
        final generation = _generations[path] ?? 0;
        bool exists;
        try {
          exists = await _exists(path);
        } catch (_) {
          _retryAfter[path] = _now().add(retryCooldown);
          continue;
        }
        if (_disposed) break;
        if (!_isCurrent(path, generation)) continue;
        if (!exists) {
          final removed = _entries.remove(path) != null;
          _retryAfter[path] = _now().add(retryCooldown);
          if (removed) notifyListeners();
          await _serializeStorage(() async {
            if (_isCurrent(path, generation)) await cache.delete(path);
          });
          continue;
        }
        if (_entries.containsKey(path)) continue;
        if (!_active) break;
        PhotoTextResult result;
        try {
          result = await _recognize(path);
        } catch (_) {
          result = const PhotoTextResult(PhotoTextStatus.failed);
        }
        if (_disposed) break;
        if (result.status == PhotoTextStatus.unsupported) {
          _unsupported = true;
          continue;
        }
        if (!_isCurrent(path, generation)) {
          continue;
        }
        final entry = _PhotoTextEntry.fromResult(result);
        if (entry == null) {
          // A recognition/storage failure must not make note saving fail, or
          // create a native hot loop. Retry on a later change or resume only.
          _retryAfter[path] = _now().add(retryCooldown <= Duration.zero
              ? const Duration(seconds: 1)
              : retryCooldown);
          continue;
        }
        _entries[path] = entry;
        _retryAfter.remove(path);
        notifyListeners();
        await _serializeStorage(() async {
          if (_isCurrent(path, generation) &&
              identical(_entries[path], entry)) {
            await cache.put(path, entry.toMap());
          }
        });
      }
    } finally {
      _running = false;
      if (!_disposed) _updateIndexing();
    }
  }

  bool _isCurrent(String path, int generation) =>
      _referenced.contains(path) &&
      (_generations[path] ?? 0) == generation &&
      _currentPaths().contains(path);

  bool get _hasWork =>
      _probes.isNotEmpty || (!_unsupported && _nextPath() != null);

  Future<void> _serializeStorage(Future<void> Function() operation) {
    final write = _storageWrites.then((_) async {
      if (!_disposed) await operation();
    }).catchError((Object _) {
      // The cache is disposable. In-memory results still work if disk is full.
    });
    _storageWrites = write;
    return write;
  }

  void _updateIndexing() {
    final next = !_disposed && _started && _active && (_running || _hasWork);
    if (_isIndexing == next) return;
    _isIndexing = next;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _isIndexing = false;
    _scheduled?.cancel();
    _scheduled = null;
    unawaited(_subscription?.cancel());
    if (identical(_instance, this)) _instance = null;
    super.dispose();
  }
}

Future<bool> _fileExists(String path) =>
    File(ImageStorage.resolvePath(path)).exists();

/// Legacy absolute paths are rebased to the same owned filename as current
/// relative paths. Native recognition always receives this safe relative form.
String? _managedPath(String path) {
  if (path.contains('\\') || RegExp(r'[\x00-\x1f\x7f]').hasMatch(path)) {
    return null;
  }
  if (path.startsWith('/')) {
    final marker = path.lastIndexOf('/note_images/');
    if (marker < 0) return null;
    path = path.substring(marker + 1);
  }
  const prefix = 'note_images/';
  if (!path.startsWith(prefix)) return null;
  final filename = path.substring(prefix.length);
  if (filename.isEmpty ||
      filename == '.' ||
      filename == '..' ||
      filename.length > 255 ||
      filename.contains('/')) {
    return null;
  }
  return path;
}

class _PhotoTextEntry {
  const _PhotoTextEntry(this.text);
  final String text;

  static _PhotoTextEntry? fromResult(PhotoTextResult result) {
    if (result.status == PhotoTextStatus.noText) {
      return const _PhotoTextEntry('');
    }
    if (result.status != PhotoTextStatus.text ||
        result.text.length > maxPhotoTextLength) {
      return null;
    }
    final text =
        result.text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    return _PhotoTextEntry(text);
  }

  static _PhotoTextEntry? read(dynamic value) {
    if (value is! Map || value['version'] != 1) return null;
    final text = value['text'];
    if (text is! String || text.length > maxPhotoTextLength) return null;
    if (value['status'] == 'no_text' && text.isEmpty) {
      return const _PhotoTextEntry('');
    }
    if (value['status'] != 'text' || text.trim().isEmpty) return null;
    return fromResult(PhotoTextResult(PhotoTextStatus.text, text: text));
  }

  Map<String, Object> toMap() => {
        'version': 1,
        'status': text.isEmpty ? 'no_text' : 'text',
        'text': text,
      };
}
