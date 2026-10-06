import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';

const draftDatabaseBox = 'note_recovery_drafts';

abstract interface class NoteAutosaveStore {
  Future<void> writeDraft(Note note);
  Future<void> removeDraft(String id);
  Future<void> saveNote(Note note);
}

class HiveNoteAutosaveStore implements NoteAutosaveStore {
  HiveNoteAutosaveStore(this.repository, this.drafts);
  final NoteRepository repository;
  final Box drafts;

  @override
  Future<void> writeDraft(Note note) async {
    await drafts.put(note.id!, NoteDto.fromNote(note));
    await drafts.flush();
  }

  @override
  Future<void> removeDraft(String id) => drafts.delete(id);

  @override
  Future<void> saveNote(Note note) async {
    await repository.addUpdateNote(NoteDto.fromNote(note));
  }

  /// Replay interrupted saves before image cleanup or the first library read.
  /// Failed drafts stay on disk and retain their photo references for retry.
  Future<void> recover() async {
    for (final entry in drafts.toMap().entries) {
      final draft = entry.value;
      if (draft is! NoteDto || draft.id == null) continue;
      try {
        if (NoteAutosave.hasContent(draft.toDomain()) ||
            repository.getAllNotes().any((n) => n.id == draft.id)) {
          await repository.addUpdateNote(draft);
        }
        await drafts.delete(entry.key);
      } catch (error) {
        debugPrint('Draft recovery deferred: $error');
      }
    }
  }
}

enum AutosaveStatus { saved, pending, saving, failed }

/// Serializes commits while accepting new edits; an older save can never clear
/// a newer recovery draft. The editor owns one stable note ID for its lifetime.
class NoteAutosave extends ChangeNotifier {
  NoteAutosave(
      {required this.store,
      required Note initial,
      required bool exists,
      this.delay = const Duration(milliseconds: 650)})
      : _note = initial,
        _exists = exists;

  final NoteAutosaveStore store;
  final Duration delay;
  Note _note;
  bool _exists;
  int _revision = 0;
  int _savedRevision = 0;
  Timer? _timer;
  Future<void> _journal = Future.value();
  Future<bool>? _inFlight;
  bool _disposed = false;
  AutosaveStatus _status = AutosaveStatus.saved;
  AutosaveStatus get status => _status;
  Note get note => _note;
  bool get dirty => _revision != _savedRevision;

  static bool hasContent(Note note) =>
      (note.title?.trim().isNotEmpty ?? false) ||
      (note.description?.trim().isNotEmpty ?? false) ||
      note.todo.any((todo) => todo.title?.trim().isNotEmpty ?? false) ||
      note.imagePaths.isNotEmpty || note.voiceMemos.isNotEmpty;

  void update(Note note) {
    if (_disposed || note == _note) return;
    assert(note.id == _note.id);
    _note = note;
    _queueSave(note);
  }

  /// Persist intentionally seeded content, such as a selected template,
  /// through the same recovery journal and debounce used for ordinary edits.
  void saveInitial() {
    if (_disposed || _exists || dirty || !hasContent(_note)) return;
    _queueSave(_note);
  }

  void _queueSave(Note note) {
    _revision++;
    _setStatus(AutosaveStatus.pending);
    _journal =
        _journal.then((_) => store.writeDraft(note)).catchError((Object error) {
      _setStatus(AutosaveStatus.failed);
    });
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  Future<bool> flush() {
    _timer?.cancel();
    return _inFlight ??= _drain().whenComplete(() => _inFlight = null);
  }

  Future<bool> _drain() async {
    while (dirty) {
      final revision = _revision;
      final snapshot = _note;
      _setStatus(AutosaveStatus.saving);
      try {
        await _journal;
        // Retry a failed journal write before touching the saved note.
        _journal = _journal.then((_) async {
          if (_revision == revision) await store.writeDraft(snapshot);
        });
        await _journal;
        if (_revision != revision) continue;
        if (_exists || hasContent(snapshot)) {
          await store.saveNote(snapshot);
          _exists = true;
        }
        _savedRevision = revision;
        _journal = _journal.then((_) async {
          if (_revision == revision) await store.removeDraft(snapshot.id!);
        });
        await _journal;
      } catch (_) {
        // Keep the queue usable after an I/O error; retry remains explicit.
        _journal = _journal.catchError((Object _) {});
        _setStatus(AutosaveStatus.failed);
        return false;
      }
    }
    _setStatus(AutosaveStatus.saved);
    return true;
  }

  void _setStatus(AutosaveStatus value) {
    _status = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
