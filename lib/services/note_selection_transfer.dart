import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:uuid/uuid.dart';

typedef NoteSelectionEditorApply = Future<bool> Function(
    NoteTextSelection selection);

/// Copies a snapshot through the destination's own autosave queue when it is
/// open. A hidden editor must never overwrite newer copied text on returning.
class NoteSelectionTransfer {
  NoteSelectionTransfer({
    required this.repository,
    required this.store,
    required this.readDraft,
  });

  final NoteRepository repository;
  final NoteAutosaveStore store;
  final Note? Function(String id) readDraft;
  static final _editors = <String, List<NoteSelectionEditorApply>>{};
  static Future<void>? _writes;

  static VoidCallback registerEditor(
      String noteId, NoteSelectionEditorApply apply) {
    (_editors[noteId] ??= []).add(apply);
    return () {
      final editors = _editors[noteId];
      editors?.remove(apply);
      if (editors?.isEmpty ?? false) _editors.remove(noteId);
    };
  }

  Future<bool> copyToExisting(String id, NoteTextSelection selection) {
    return _serialize(() async {
      if (selection.text.trim().isEmpty) return false;
      final latest = (await repository.getNote(id)).toDomain();
      if (latest.id != id || latest.isDeleted || latest.isArchived) {
        return false;
      }
      final editors = _editors[id];
      if (editors?.isNotEmpty ?? false) {
        // Busy editors reject the action; writing around them would lose edits.
        return editors!.last(selection);
      }
      final draft = readDraft(id);
      final destination = draft == null || draft.id != id
          ? latest
          : draft.copyWith(
              isArchived: latest.isArchived,
              isPinned: latest.isPinned,
              folderId: latest.folderId,
              dailyNoteDateKey: latest.dailyNoteDateKey,
              sortOrder: latest.sortOrder,
              deletedAt: latest.deletedAt,
            );
      final next = appendSelectionToNote(destination, selection)
          .copyWith(dateTime: DateTime.now());
      return _save(next);
    });
  }

  Future<bool> copyToNew(NoteTextSelection selection, {Color? color}) {
    return _serialize(() {
      if (selection.text.trim().isEmpty) return Future.value(false);
      final now = DateTime.now();
      final note = appendSelectionToNote(
          Note(
              id: const Uuid().v4(),
              color: color,
              dateTime: now,
              sortOrder: -now.millisecondsSinceEpoch),
          selection);
      return _save(note);
    });
  }

  /// Release the idle queue before resolving callers. This also avoids keeping
  /// a completed future and its originating widget/test zone alive forever.
  static Future<bool> _serialize(Future<bool> Function() operation) async {
    final previous = _writes;
    final completion = Completer<void>();
    _writes = completion.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } catch (_) {
      return false;
    } finally {
      if (identical(_writes, completion.future)) _writes = null;
      completion.complete();
    }
  }

  Future<bool> _save(Note note) async {
    final autosave = NoteAutosave(store: store, initial: note, exists: false);
    try {
      // saveInitial journals the complete result before updating the library.
      autosave.saveInitial();
      return await autosave.flush();
    } finally {
      autosave.dispose();
    }
  }
}
