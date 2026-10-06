import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/widgets.dart' show TextAffinity, TextSelection;
import 'package:shared_preferences/shared_preferences.dart';

/// Local navigation state. This is deliberately independent of note content,
/// editing history, autosave recovery and backup records.
abstract interface class NotePositionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class MemoryNotePositionStorage implements NotePositionStorage {
  MemoryNotePositionStorage([Map<String, String>? values])
      : values = values ?? <String, String>{};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

class _PreferencesNotePositionStorage implements NotePositionStorage {
  SharedPreferencesAsync? _preferences;

  // Keep platform initialization inside the store's optional-storage guards.
  SharedPreferencesAsync get _instance =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _instance.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _instance.setString(key, value);

  @override
  Future<void> remove(String key) => _instance.remove(key);
}

/// Clamp UTF-16 positions to complete user-perceived characters. A collapsed
/// caret rounds backwards; a selection can round its trailing end forwards.
int clampNotePositionOffset(String text, int offset, {bool roundUp = false}) {
  final target = offset.clamp(0, text.length);
  var before = 0;
  for (final character in text.characters) {
    final after = before + character.length;
    if (target == before) return before;
    if (target < after) return roundUp ? after : before;
    before = after;
  }
  return text.length;
}

/// A bounded text context relocates an offset when earlier text changes.
/// The occurrence disambiguates identical paragraphs; offsets remain UTF-16,
/// as expected by native Flutter fields and saved formatting.
class NoteTextAnchor {
  const NoteTextAnchor._({
    required this.offset,
    required this.textLength,
    required this.before,
    required this.after,
    required this.occurrence,
  });

  factory NoteTextAnchor.capture(String text, int offset) {
    final safe = clampNotePositionOffset(text, offset);
    final start =
        clampNotePositionOffset(text, safe - _contextLength, roundUp: true);
    final end = clampNotePositionOffset(text, safe + _contextLength);
    final before = text.substring(start, safe);
    final after = text.substring(safe, end);
    final context = '$before$after';
    var occurrence = 0;
    if (context.isNotEmpty) {
      var match = text.indexOf(context);
      while (match >= 0 && match < start) {
        occurrence++;
        match = text.indexOf(context, match + 1);
      }
    }
    return NoteTextAnchor._(
      offset: safe,
      textLength: text.length,
      before: before,
      after: after,
      occurrence: occurrence,
    );
  }

  static const _contextLength = 72;
  final int offset;
  final int textLength;
  final String before;
  final String after;
  final int occurrence;

  int resolve(String text, {bool roundUp = false}) {
    int safe(int value) =>
        clampNotePositionOffset(text, value, roundUp: roundUp);
    final context = '$before$after';
    if (context.isEmpty || text.isEmpty) return safe(offset);
    final matches = _matches(text, context);
    if (matches.isNotEmpty) {
      final match = matches[occurrence.clamp(0, matches.length - 1)];
      return safe(match + before.length);
    }

    // If the caret's immediate text was edited or removed, retain the nearest
    // surviving side of its context. Shortening in stages also tolerates an
    // edit elsewhere in the bounded context without storing the whole note.
    final leftCandidates = <int>{};
    final rightCandidates = <int>{};
    for (final size in [_contextLength, 48, 32, 16, 8, 4]) {
      if (before.isNotEmpty) {
        final suffix = before.substring(math.max(0, before.length - size));
        leftCandidates
            .addAll(_matches(text, suffix).map((hit) => hit + suffix.length));
      }
      if (after.isNotEmpty) {
        final prefix = after.substring(0, math.min(size, after.length));
        rightCandidates.addAll(_matches(text, prefix));
      }
    }
    final leftThreshold = math.min(16, before.length);
    final rightThreshold = math.min(16, after.length);
    final leftBoundaries = leftCandidates
        .where((candidate) =>
            _matchingBefore(text, candidate, before) >= leftThreshold)
        .toList()
      ..sort();
    final rightBoundaries = rightCandidates
        .where((candidate) =>
            _matchingAfter(text, candidate, after) >= rightThreshold)
        .toList()
      ..sort();
    var best = offset.clamp(0, text.length);
    var bestScore = 0;
    var bestGap = double.infinity;
    for (final candidate in {...leftCandidates, ...rightCandidates}) {
      final left = _matchingBefore(text, candidate, before);
      final right = _matchingAfter(text, candidate, after);
      // A shared newline or punctuation mark on the edited side is not
      // evidence for moving to the next repeated paragraph. Require the
      // same minimum context that is used for the final fallback decision.
      final score = (left >= math.min(4, before.length) ? left : 0) +
          (right >= math.min(4, after.length) ? right : 0);
      // A prefix insertion can put several repeated paragraphs closer to the
      // old numeric offset. Use the other surviving side to identify the
      // matching boundary before falling back to that old offset.
      final gap = math.min(
        left >= leftThreshold && before.isNotEmpty
            ? _oppositeGap(rightBoundaries, candidate, following: true)
            : double.infinity,
        right >= rightThreshold && after.isNotEmpty
            ? _oppositeGap(leftBoundaries, candidate, following: false)
            : double.infinity,
      );
      if (score > bestScore ||
          (score == bestScore &&
              (gap < bestGap ||
                  (gap == bestGap &&
                      (candidate - offset).abs() < (best - offset).abs())))) {
        best = candidate;
        bestScore = score;
        bestGap = gap;
      }
    }
    return safe(bestScore >= math.min(4, context.length) ? best : offset);
  }

  static double _oppositeGap(List<int> boundaries, int candidate,
      {required bool following}) {
    var low = 0;
    var high = boundaries.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (boundaries[middle] < candidate ||
          (!following && boundaries[middle] == candidate)) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final index = following ? low : low - 1;
    return index < 0 || index >= boundaries.length
        ? double.infinity
        : (boundaries[index] - candidate).abs().toDouble();
  }

  static List<int> _matches(String text, String context) {
    if (context.isEmpty) return const [];
    final matches = <int>[];
    var hit = text.indexOf(context);
    while (hit >= 0) {
      matches.add(hit);
      hit = text.indexOf(context, hit + 1);
    }
    return matches;
  }

  static int _matchingBefore(String text, int offset, String context) {
    var count = 0;
    while (count < offset &&
        count < context.length &&
        text.codeUnitAt(offset - count - 1) ==
            context.codeUnitAt(context.length - count - 1)) {
      count++;
    }
    return count;
  }

  static int _matchingAfter(String text, int offset, String context) {
    var count = 0;
    while (offset + count < text.length &&
        count < context.length &&
        text.codeUnitAt(offset + count) == context.codeUnitAt(count)) {
      count++;
    }
    return count;
  }

  Map<String, Object> toJson() => {
        'offset': offset,
        'textLength': textLength,
        'before': before,
        'after': after,
        'occurrence': occurrence,
      };

  static NoteTextAnchor? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final offset = value['offset'];
    final length = value['textLength'];
    final before = value['before'];
    final after = value['after'];
    final occurrence = value['occurrence'];
    if (offset is! int ||
        length is! int ||
        offset < 0 ||
        length < offset ||
        before is! String ||
        after is! String ||
        before.length > _contextLength ||
        after.length > _contextLength ||
        occurrence is! int ||
        occurrence < 0) {
      return null;
    }
    return NoteTextAnchor._(
      offset: offset,
      textLength: length,
      before: before,
      after: after,
      occurrence: occurrence,
    );
  }
}

enum NoteWritingField { title, body, todo }

class ResolvedNoteWritingPosition {
  const ResolvedNoteWritingPosition({
    required this.field,
    required this.selection,
    this.todoId,
  });

  final NoteWritingField field;
  final String? todoId;
  final TextSelection selection;
}

class NoteWritingPosition {
  const NoteWritingPosition._({
    required this.field,
    required this.base,
    required this.extent,
    required this.bodyFallback,
    required this.affinity,
    required this.isDirectional,
    this.todoId,
  });

  factory NoteWritingPosition.capture({
    required NoteWritingField field,
    required String text,
    required TextSelection selection,
    String? todoId,
    String bodyText = '',
    TextSelection? bodySelection,
  }) {
    final normalized = _safeSelection(text, selection);
    final fallback = field == NoteWritingField.body
        ? normalized.extentOffset
        : bodySelection?.extentOffset ?? 0;
    return NoteWritingPosition._(
      field: field,
      todoId: field == NoteWritingField.todo ? todoId : null,
      base: NoteTextAnchor.capture(text, normalized.baseOffset),
      extent: NoteTextAnchor.capture(text, normalized.extentOffset),
      bodyFallback: NoteTextAnchor.capture(
          field == NoteWritingField.body ? text : bodyText, fallback),
      affinity: normalized.affinity,
      isDirectional: normalized.isDirectional,
    );
  }

  final NoteWritingField field;
  final String? todoId;
  final NoteTextAnchor base;
  final NoteTextAnchor extent;
  final NoteTextAnchor bodyFallback;
  final TextAffinity affinity;
  final bool isDirectional;

  ResolvedNoteWritingPosition resolve({
    required String title,
    required String body,
    Map<String, String> todos = const {},
  }) {
    final text = switch (field) {
      NoteWritingField.title => title,
      NoteWritingField.body => body,
      NoteWritingField.todo => todos[todoId],
    };
    if (text == null) {
      return ResolvedNoteWritingPosition(
        field: NoteWritingField.body,
        selection: TextSelection.collapsed(offset: bodyFallback.resolve(body)),
      );
    }
    final forward = base.offset <= extent.offset;
    final collapsed = base.offset == extent.offset;
    final selection = TextSelection(
      baseOffset: base.resolve(text, roundUp: !collapsed && !forward),
      extentOffset: extent.resolve(text, roundUp: !collapsed && forward),
      affinity: affinity,
      isDirectional: isDirectional,
    );
    return ResolvedNoteWritingPosition(
      field: field,
      todoId: todoId,
      selection: selection,
    );
  }

  static TextSelection _safeSelection(String text, TextSelection selection) {
    if (!selection.isValid) return const TextSelection.collapsed(offset: 0);
    final forward = selection.baseOffset <= selection.extentOffset;
    return TextSelection(
      baseOffset: clampNotePositionOffset(text, selection.baseOffset,
          roundUp: !selection.isCollapsed && !forward),
      extentOffset: clampNotePositionOffset(text, selection.extentOffset,
          roundUp: !selection.isCollapsed && forward),
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  Map<String, Object?> toJson() => {
        'field': field.name,
        if (todoId != null) 'todoId': todoId,
        'base': base.toJson(),
        'extent': extent.toJson(),
        'bodyFallback': bodyFallback.toJson(),
        'affinity': affinity.name,
        'directional': isDirectional,
      };

  static NoteWritingPosition? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final field = NoteWritingField.values
        .where((field) => field.name == value['field'])
        .firstOrNull;
    final base = NoteTextAnchor.tryFromJson(value['base']);
    final extent = NoteTextAnchor.tryFromJson(value['extent']);
    final fallback = NoteTextAnchor.tryFromJson(value['bodyFallback']);
    final todoId = value['todoId'];
    if (field == null ||
        base == null ||
        extent == null ||
        fallback == null ||
        (field == NoteWritingField.todo &&
            (todoId is! String || todoId.isEmpty || todoId.length > 512))) {
      return null;
    }
    return NoteWritingPosition._(
      field: field,
      todoId: field == NoteWritingField.todo ? todoId as String : null,
      base: base,
      extent: extent,
      bodyFallback: fallback,
      affinity: value['affinity'] == 'upstream'
          ? TextAffinity.upstream
          : TextAffinity.downstream,
      isDirectional: value['directional'] == true,
    );
  }
}

class NoteReadingPosition {
  const NoteReadingPosition._({
    required this.anchor,
    required this.leadingDisplacement,
    this.imagePath,
    this.imageFraction = 0,
  });

  factory NoteReadingPosition.capture({
    required String text,
    required int offset,
    double leadingDisplacement = 0,
    String? imagePath,
    double imageFraction = 0,
  }) =>
      NoteReadingPosition._(
        anchor: NoteTextAnchor.capture(text, offset),
        leadingDisplacement:
            leadingDisplacement.isFinite ? leadingDisplacement : 0,
        imagePath: imagePath,
        imageFraction: imageFraction.isFinite ? imageFraction.clamp(0, 1) : 0,
      );

  final NoteTextAnchor anchor;

  /// Supplemental alignment in layout pixels; the content anchor is primary.
  /// This can be signed when a title or checklist lies beyond the body.
  final double leadingDisplacement;
  final String? imagePath;

  /// A visible photo is identified by path and a fraction of its own height,
  /// so resized photos and media-only notes retain their place as well.
  final double imageFraction;

  int resolve(String text) => anchor.resolve(text);

  Map<String, Object?> toJson() => {
        'anchor': anchor.toJson(),
        'leadingDisplacement': leadingDisplacement,
        if (imagePath != null) 'imagePath': imagePath,
        if (imagePath != null) 'imageFraction': imageFraction,
      };

  static NoteReadingPosition? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final anchor = NoteTextAnchor.tryFromJson(value['anchor']);
    final displacement = value['leadingDisplacement'];
    final path = value['imagePath'];
    final fraction = value['imageFraction'] ?? 0;
    if (anchor == null ||
        displacement is! num ||
        !displacement.isFinite ||
        (path != null &&
            (path is! String || path.isEmpty || path.length > 4096)) ||
        fraction is! num ||
        !fraction.isFinite ||
        fraction < 0 ||
        fraction > 1) {
      return null;
    }
    return NoteReadingPosition._(
      anchor: anchor,
      leadingDisplacement: displacement.toDouble(),
      imagePath: path as String?,
      imageFraction: fraction.toDouble(),
    );
  }
}

class NotePositions {
  const NotePositions({this.writing, this.reading});
  final NoteWritingPosition? writing;
  final NoteReadingPosition? reading;
}

class NotePositionStore {
  NotePositionStore({NotePositionStorage? storage})
      : _storage = storage ?? _PreferencesNotePositionStorage();

  NotePositionStore.memory() : _storage = MemoryNotePositionStorage();

  static final instance = NotePositionStore();
  static const storagePrefix = 'note_positions_v1.';
  final NotePositionStorage _storage;
  final Map<String, NotePositions> _cache = {};
  Future<void>? _tail;

  /// Each note has its own preference record. Deleting note content and
  /// exporting backups therefore cannot accidentally serialize navigation.
  static String storageKey(String noteId) =>
      '$storagePrefix${Uri.encodeComponent(noteId)}';

  Future<T> _serial<T>(Future<T> Function() operation) async {
    final previous = _tail;
    final completion = Completer<void>();
    _tail = completion.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      // Release an idle queue before its caller resumes, including its test
      // zone. A queued operation still retains its predecessor until complete.
      if (identical(_tail, completion.future)) _tail = null;
      completion.complete();
    }
  }

  Future<NotePositions> read(String noteId) => _serial(() => _read(noteId));

  Future<NotePositions> _read(String noteId) async {
    if (noteId.isEmpty) return const NotePositions();
    if (_cache.containsKey(noteId)) return _cache[noteId]!;
    var positions = const NotePositions();
    try {
      final raw = await _storage.read(storageKey(noteId));
      final value = raw == null ? null : jsonDecode(raw);
      if (value is Map && value['version'] == 1) {
        positions = NotePositions(
          writing: NoteWritingPosition.tryFromJson(value['writing']),
          reading: NoteReadingPosition.tryFromJson(value['reading']),
        );
      }
    } catch (_) {
      // A malformed record or unavailable platform preference plugin must
      // never prevent opening a note. The session can still retain positions.
    }
    _cache[noteId] = positions;
    return positions;
  }

  Future<void> saveWriting(String noteId, NoteWritingPosition position) =>
      _serial(() async {
        if (noteId.isEmpty) return;
        final current = await _read(noteId);
        await _write(
            noteId, NotePositions(writing: position, reading: current.reading));
      });

  Future<void> saveReading(String noteId, NoteReadingPosition position) =>
      _serial(() async {
        if (noteId.isEmpty) return;
        final current = await _read(noteId);
        await _write(
            noteId, NotePositions(writing: current.writing, reading: position));
      });

  Future<void> _write(String noteId, NotePositions positions) async {
    _cache[noteId] = positions;
    try {
      await _storage.write(
          storageKey(noteId),
          jsonEncode({
            'version': 1,
            if (positions.writing != null)
              'writing': positions.writing!.toJson(),
            if (positions.reading != null)
              'reading': positions.reading!.toJson(),
          }));
    } catch (_) {
      // Navigation state is optional; storage failures cannot fail a save.
    }
  }

  Future<void> remove(String noteId) => _serial(() async {
        _cache.remove(noteId);
        try {
          await _storage.remove(storageKey(noteId));
        } catch (_) {
          // Optional navigation cleanup cannot fail deletion of note content.
        }
      });
}
