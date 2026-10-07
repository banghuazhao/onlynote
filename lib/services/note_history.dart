import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:uuid/uuid.dart';

const noteHistoryBox = 'note_history';

enum NoteHistoryRestoreResult { restored, unchanged, unavailable, failed }

@immutable
class NoteHistoryVersion {
  const NoteHistoryVersion({
    required this.id,
    required this.savedAt,
    required this.note,
  });
  final String id;
  final DateTime savedAt;
  final NoteDto note;
}

/// Keeps previous durable content separately from the current note. Snapshots
/// own references to media, so deleting current content need not destroy Undo.
class NoteHistory extends ChangeNotifier {
  NoteHistory({
    required this.box,
    required this.repository,
    DateTime Function()? now,
    this.maxVersions = 20,
    this.coalesceWindow = const Duration(seconds: 30),
  }) : _now = now ?? DateTime.now;

  static NoteHistory? initializedInstance;
  static void configure(NoteHistory history) => initializedInstance = history;

  final Box box;
  final NoteRepository repository;
  final int maxVersions;
  final Duration coalesceWindow;
  final DateTime Function() _now;
  final Map<String, Future<void>> _writes = {};
  final Map<String, Future<void>> _restores = {};
  final Set<String> _restoreBoundaries = {};

  List<NoteHistoryVersion> versionsFor(String noteId) =>
      List.unmodifiable(_read(noteId).versions);

  Set<String> get referencedImages => {
        for (final id in box.keys.whereType<String>())
          for (final version in _read(id).versions)
            ...version.note.imagePaths ?? const <String>[],
      };

  Set<String> get referencedAudio => {
        for (final id in box.keys.whereType<String>())
          for (final version in _read(id).versions)
            for (final memo in version.note.voiceMemos ?? const <Map>[])
              if (memo['path'] is String) memo['path'] as String,
      };

  /// The repository awaits this before committing a changed note. A history
  /// failure therefore leaves the previous note intact and the editor retryable.
  Future<void> recordBeforeSave(NoteDto before, NoteDto after,
      {bool forceBoundary = false}) {
    final id = before.id;
    if (id == null ||
        id.isEmpty ||
        after.id != id ||
        before.isDeleted ||
        after.isDeleted ||
        !_hasContent(before) ||
        _sameContent(before, after)) {
      return Future.value();
    }
    // Own immutable copies before entering the asynchronous write queue.
    final snapshot = _clone(before);
    final structuralChange = !_sameStructure(before, after);
    return _serialized(_writes, id, () async {
      final state = _read(id);
      final now = _now().toUtc();
      final elapsed = state.lastChangedAt == null
          ? null
          : now.difference(state.lastChangedAt!);
      final boundary = structuralChange ||
          forceBoundary ||
          state.forceNext ||
          elapsed == null ||
          elapsed.isNegative ||
          elapsed >= coalesceWindow;
      final versions = state.versions.toList();
      if (boundary &&
          (versions.isEmpty || !_sameContent(versions.first.note, snapshot))) {
        versions.insert(
            0,
            NoteHistoryVersion(
                id: const Uuid().v4(), savedAt: now, note: snapshot));
      }
      await _write(
          id,
          _HistoryState(versions.take(maxVersions.clamp(1, 100)).toList(), now,
              forceNext: structuralChange || _restoreBoundaries.contains(id)));
      notifyListeners();
    });
  }

  /// Force a content boundary through the ordinary repository history hook.
  /// Persisting this flag also preserves the boundary across process restarts.
  Future<void> forceNextSave(String id) => _serialized(_writes, id, () async {
        final state = _read(id);
        await _write(
            id,
            _HistoryState(state.versions, state.lastChangedAt,
                forceNext: true));
      });

  Future<NoteHistoryRestoreResult> restore(String noteId, String versionId) {
    var result = NoteHistoryRestoreResult.failed;
    final operation = _serialized(_restores, noteId, () async {
      try {
        final matching = versionsFor(noteId).where((v) => v.id == versionId);
        if (matching.isEmpty) {
          result = NoteHistoryRestoreResult.unavailable;
          return;
        }
        final snapshot = matching.first.note;
        var current = _activeNote(noteId);
        if (current == null) {
          result = NoteHistoryRestoreResult.unavailable;
          return;
        }
        if (_sameContent(current, snapshot)) {
          result = NoteHistoryRestoreResult.unchanged;
          return;
        }
        await forceNextSave(noteId);
        // Resolve again after history I/O so recently changed library metadata
        // is retained, and a note removed while waiting cannot be resurrected.
        current = _activeNote(noteId);
        if (current == null) {
          result = NoteHistoryRestoreResult.unavailable;
          return;
        }
        final restored = NoteDto(
          id: current.id,
          title: snapshot.title,
          description: snapshot.description,
          colorValue: snapshot.colorValue,
          todoList: _cloneTodos(snapshot.todoList),
          imagePaths: List.of(snapshot.imagePaths ?? const []),
          voiceMemos: _cloneMemos(snapshot.voiceMemos),
          dateTime: _now().toUtc().toIso8601String(),
          sortOrder: current.sortOrder,
          isPinned: current.isPinned,
          folderId: current.folderId,
          deletedAt: current.deletedAt,
          isArchived: current.isArchived,
          dailyNoteDateKey: current.dailyNoteDateKey,
          cardStyle: current.cardStyle == null
              ? null
              : Map.unmodifiable(current.cardStyle!),
          tags: List.of(current.tags ?? []),
          linkedNoteIds: List.of(snapshot.linkedNoteIds ?? []),
          textStyles: _cloneMemos(snapshot.textStyles),
          imageLayouts: _cloneMemos(snapshot.imageLayouts),
        );
        // Repository hook captures current content before replacing it. The
        // restore queue is separate from the snapshot queue to allow that hook.
        _restoreBoundaries.add(noteId);
        try {
          await repository.addUpdateNote(restored);
        } finally {
          _restoreBoundaries.remove(noteId);
        }
        notifyListeners();
        result = NoteHistoryRestoreResult.restored;
      } catch (error) {
        debugPrint('Note history restore failed: $error');
      }
    });
    return operation.then((_) => result);
  }

  Future<void> purge(Iterable<String> noteIds) async {
    for (final id in noteIds.toSet()) {
      await _serialized(_writes, id, () async {
        await box.delete(id);
        await box.flush();
      });
    }
    notifyListeners();
  }

  /// Backup restore assigns fresh note, media, and version IDs before import.
  /// Merge without replacing an existing immutable version of the same ID.
  Future<void> importVersions(
      Map<String, List<NoteHistoryVersion>> imported) async {
    final owned = <String, List<NoteHistoryVersion>>{};
    for (final entry in imported.entries) {
      if (entry.key.isEmpty ||
          entry.value.any((version) =>
              version.note.id != entry.key ||
              version.id.isEmpty ||
              version.id.length > 128 ||
              !_hasContent(version.note))) {
        throw const FormatException('Invalid imported note history');
      }
      owned[entry.key] = [
        for (final version in entry.value)
          NoteHistoryVersion(
              id: version.id,
              savedAt: version.savedAt.toUtc(),
              note: _clone(version.note)),
      ];
    }
    for (final entry in owned.entries) {
      await _serialized(_writes, entry.key, () async {
        final versions = _read(entry.key).versions.toList();
        final ids = versions.map((version) => version.id).toSet();
        versions.addAll(entry.value.where((version) => ids.add(version.id)));
        _sortVersions(versions);
        await _write(
            entry.key,
            _HistoryState(versions.take(maxVersions.clamp(1, 100)).toList(),
                _now().toUtc(),
                forceNext: true));
      });
    }
    notifyListeners();
  }

  NoteDto? _activeNote(String id) {
    for (final note in repository.getAllNotes()) {
      if (note.id == id && !note.isDeleted) return note;
    }
    return null;
  }

  Future<void> _serialized(Map<String, Future<void>> queues, String id,
      Future<void> Function() operation) {
    final previous = queues[id] ?? Future.value();
    final current = previous.then((_) => operation());
    final settled = current.catchError((Object _) {});
    queues[id] = settled;
    unawaited(settled.whenComplete(() {
      if (identical(queues[id], settled)) queues.remove(id);
    }));
    return current;
  }

  _HistoryState _read(String id) {
    final raw = box.get(id);
    if (raw is! Map || raw['version'] != 1 || raw['entries'] is! List) {
      return const _HistoryState([], null);
    }
    final versions = <NoteHistoryVersion>[];
    final seen = <String>{};
    for (final entry in raw['entries'] as List) {
      if (entry is! Map) continue;
      final versionId = entry['id'];
      final timestamp = entry['savedAt'];
      final note = entry['note'];
      final date = timestamp is String ? DateTime.tryParse(timestamp) : null;
      if (versionId is! String ||
          versionId.isEmpty ||
          versionId.length > 128 ||
          date == null ||
          note is! NoteDto ||
          note.id != id ||
          !seen.add(versionId)) {
        continue;
      }
      versions.add(NoteHistoryVersion(
          id: versionId, savedAt: date.toUtc(), note: _clone(note)));
    }
    _sortVersions(versions);
    final changed = raw['lastChangedAt'];
    return _HistoryState(versions.take(maxVersions.clamp(1, 100)).toList(),
        changed is String ? DateTime.tryParse(changed)?.toUtc() : null,
        forceNext: raw['forceNext'] == true);
  }

  static void _sortVersions(List<NoteHistoryVersion> versions) {
    final originalOrder = {
      for (final (index, version) in versions.indexed) version.id: index,
    };
    versions.sort((a, b) {
      final timestamp = b.savedAt.compareTo(a.savedAt);
      return timestamp != 0
          ? timestamp
          : originalOrder[a.id]!.compareTo(originalOrder[b.id]!);
    });
  }

  Future<void> _write(String id, _HistoryState state) async {
    await box.put(id, {
      'version': 1,
      'entries': [
        for (final version in state.versions)
          {
            'id': version.id,
            'savedAt': version.savedAt.toUtc().toIso8601String(),
            'note': version.note,
          },
      ],
      'lastChangedAt': state.lastChangedAt?.toUtc().toIso8601String(),
      'forceNext': state.forceNext,
    });
    await box.flush();
  }

  static bool _hasContent(NoteDto note) =>
      (note.title?.trim().isNotEmpty ?? false) ||
      (note.description?.trim().isNotEmpty ?? false) ||
      (note.todoList?.any((todo) => todo.title?.trim().isNotEmpty ?? false) ??
          false) ||
      (note.imagePaths?.isNotEmpty ?? false) ||
      (note.voiceMemos?.isNotEmpty ?? false) ||
      (note.linkedNoteIds?.isNotEmpty ?? false);

  static bool _sameContent(NoteDto a, NoteDto b) =>
      (a.title ?? '') == (b.title ?? '') &&
      (a.description ?? '') == (b.description ?? '') &&
      _sameStructure(a, b);

  // Rebased ranges are part of body typing. Changing formatting itself makes
  // a discrete version, like a task or attachment change.
  static bool _sameStructure(NoteDto a, NoteDto b) =>
      _sameFormatting(a, b) &&
      _sameImageLayouts(a, b) &&
      _equal([
        a.colorValue,
        [
          for (final todo in a.todoList ?? const <TodoDto>[])
            [todo.id, todo.title ?? '', todo.completed ?? false],
        ],
        a.imagePaths ?? const <String>[],
        a.voiceMemos ?? const <Map>[],
        a.linkedNoteIds ?? const <String>[],
      ], [
        b.colorValue,
        [
          for (final todo in b.todoList ?? const <TodoDto>[])
            [todo.id, todo.title ?? '', todo.completed ?? false],
        ],
        b.imagePaths ?? const <String>[],
        b.voiceMemos ?? const <Map>[],
        b.linkedNoteIds ?? const <String>[],
      ]);

  static bool _sameFormatting(NoteDto a, NoteDto b) {
    if ((a.textStyles?.isEmpty ?? true) && (b.textStyles?.isEmpty ?? true)) {
      return true;
    }
    final before = a.description ?? '';
    final after = b.description ?? '';
    final stylesBefore = normalizeNoteTextStyles([
      for (final raw in a.textStyles ?? const <Map>[])
        if (NoteTextStyleRange.tryFromMap(raw) case final style?) style,
    ], before);
    final stylesAfter = normalizeNoteTextStyles([
      for (final raw in b.textStyles ?? const <Map>[])
        if (NoteTextStyleRange.tryFromMap(raw) case final style?) style,
    ], after);
    return _equal([
      for (final style in before == after
          ? stylesBefore
          : rebaseNoteTextStyles(before, after, stylesBefore))
        style.toMap(),
    ], [
      for (final style in stylesAfter) style.toMap()
    ]);
  }

  static bool _sameImageLayouts(NoteDto a, NoteDto b) {
    final before = a.description ?? '';
    final after = b.description ?? '';
    List<NoteImageLayout> layouts(NoteDto note, String body) =>
        normalizeNoteImageLayouts([
          for (final raw in note.imageLayouts ?? const <Map>[])
            if (NoteImageLayout.tryFromMap(raw) case final layout?) layout,
        ], note.imagePaths ?? const [], body);
    final layoutsBefore = layouts(a, before);
    final layoutsAfter = layouts(b, after);
    List<List<Object>> geometry(Iterable<NoteImageLayout> values) => [
          for (final layout in values)
            [
              layout.path,
              layout.widthFactor,
              layout.xFactor,
              layout.aspectRatio
            ],
        ];
    if (!_equal(geometry(layoutsBefore), geometry(layoutsAfter))) return false;
    bool matches(Iterable<NoteImageLayout> expected) => _equal([
          for (final layout in expected) layout.toMap(),
        ], [
          for (final layout in layoutsAfter) layout.toMap(),
        ]);
    if (before == after) return matches(layoutsBefore);
    if (matches(rebaseNoteImageLayouts(
        before, after, layoutsBefore, a.imagePaths ?? const []))) {
      return true;
    }
    // Editing a text block after a photo gives its starting anchor a different
    // insertion affinity. Repeated text can make a global diff ambiguous too.
    // Try each valid edited block context before declaring a layout change.
    final preceding = <String>{};
    for (final part in noteDocumentParts(before, layoutsBefore)) {
      if (part is NoteImagePart) preceding.add(part.layout.path);
      if (part is NoteTextPart &&
          matches(rebaseNoteImageLayouts(
              before, after, layoutsBefore, a.imagePaths ?? const [],
              editedPartStart: part.start,
              editedPartEnd: part.end,
              precedingImagePaths: preceding))) {
        return true;
      }
    }
    return false;
  }

  static bool _equal(Object? a, Object? b) {
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (index) => index)
              .every((index) => _equal(a[index], b[index]));
    }
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every((key) => b.containsKey(key) && _equal(a[key], b[key]));
    }
    return a == b;
  }

  static NoteDto _clone(NoteDto note) => NoteDto(
        id: note.id,
        title: note.title,
        description: note.description,
        colorValue: note.colorValue,
        dateTime: note.dateTime,
        todoList: _cloneTodos(note.todoList),
        imagePaths: List.unmodifiable(note.imagePaths ?? const <String>[]),
        voiceMemos: _cloneMemos(note.voiceMemos),
        sortOrder: note.sortOrder,
        isPinned: note.isPinned,
        deletedAt: note.deletedAt,
        folderId: note.folderId,
        isArchived: note.isArchived,
        dailyNoteDateKey: note.dailyNoteDateKey,
        cardStyle:
            note.cardStyle == null ? null : Map.unmodifiable(note.cardStyle!),
        tags: List.unmodifiable(note.tags ?? const <String>[]),
        linkedNoteIds:
            List.unmodifiable(note.linkedNoteIds ?? const <String>[]),
        textStyles: _cloneMemos(note.textStyles),
        imageLayouts: _cloneMemos(note.imageLayouts),
      );

  static List<TodoDto> _cloneTodos(List<TodoDto>? todos) => List.unmodifiable([
        for (final todo in todos ?? const <TodoDto>[])
          TodoDto(id: todo.id, title: todo.title, completed: todo.completed),
      ]);

  static List<Map> _cloneMemos(List<Map>? memos) => List.unmodifiable([
        for (final memo in memos ?? const <Map>[])
          Map.unmodifiable(_cloneValue(memo) as Map),
      ]);

  static Object? _cloneValue(Object? value) {
    if (value is List) return List.unmodifiable(value.map(_cloneValue));
    if (value is Map) {
      return Map.unmodifiable(
          value.map((key, value) => MapEntry(key, _cloneValue(value))));
    }
    return value;
  }
}

class _HistoryState {
  const _HistoryState(this.versions, this.lastChangedAt,
      {this.forceNext = false});
  final List<NoteHistoryVersion> versions;
  final DateTime? lastChangedAt;
  final bool forceNext;
}
