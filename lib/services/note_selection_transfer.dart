import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_mutations.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_checklist.dart';
import 'package:uuid/uuid.dart';

typedef NoteSelectionEditorApply = Future<bool> Function(
    NoteTextSelection selection);

typedef NoteChecklistEditorApply = Future<NoteSelectionChecklistResult?>
    Function(NoteTextSelection selection);

class _ChecklistEditor {
  const _ChecklistEditor(this.add, this.undo);
  final NoteChecklistEditorApply add;
  final Future<bool> Function(List<String> ids) undo;
}

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
  static final _checklistEditors = <String, List<_ChecklistEditor>>{};

  static VoidCallback registerEditor(
      String noteId, NoteSelectionEditorApply apply) {
    (_editors[noteId] ??= []).add(apply);
    return () {
      final editors = _editors[noteId];
      editors?.remove(apply);
      if (editors?.isEmpty ?? false) _editors.remove(noteId);
    };
  }

  static VoidCallback registerChecklistEditor(String noteId,
      {required NoteChecklistEditorApply add,
      required Future<bool> Function(List<String> ids) undo}) {
    final editor = _ChecklistEditor(add, undo);
    (_checklistEditors[noteId] ??= []).add(editor);
    return () {
      final editors = _checklistEditors[noteId];
      editors?.remove(editor);
      if (editors?.isEmpty ?? false) _checklistEditors.remove(noteId);
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
              cardStyle: latest.cardStyle,
              folderId: latest.folderId,
              dailyNoteDateKey: latest.dailyNoteDateKey,
              sortOrder: latest.sortOrder,
              deletedAt: latest.deletedAt,
            );
      final next = appendSelectionToNote(destination, selection)
          .copyWith(dateTime: DateTime.now());
      return _save(next);
    }, onError: false);
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
    }, onError: false);
  }

  Future<NoteSelectionChecklistResult?> addToChecklist(
      String id, NoteTextSelection selection) {
    return _serialize<NoteSelectionChecklistResult?>(() async {
      final destination = await _checklistDestination(id);
      if (destination == null) return null;
      final editors = _checklistEditors[id];
      if (editors?.isNotEmpty ?? false) return editors!.last.add(selection);
      final result = appendSelectionToChecklist(destination, selection);
      if (result.status != NoteSelectionChecklistStatus.ready) return result;
      return await _save(result.note!.copyWith(dateTime: DateTime.now()))
          ? result
          : null;
    }, onError: null);
  }

  Future<bool> undoChecklist(String id, List<String> addedIds) {
    return _serialize(() async {
      final destination = await _checklistDestination(id);
      if (destination == null) return false;
      final editors = _checklistEditors[id];
      if (editors?.isNotEmpty ?? false) return editors!.last.undo(addedIds);
      final next = undoSelectionChecklist(destination, addedIds);
      // A failed save can leave the removal only in a recovery draft. Retry
      // that draft even though its checklist already lacks the created rows.
      if (identical(next, destination) && readDraft(id)?.id != id) return true;
      return _save(next.copyWith(dateTime: DateTime.now()));
    }, onError: false);
  }

  Future<Note?> _checklistDestination(String id) async {
    final latest = (await repository.getNote(id)).toDomain();
    if (latest.id != id || latest.isDeleted) return null;
    final draft = readDraft(id);
    return draft == null || draft.id != id
        ? latest
        : draft.copyWith(
            isArchived: latest.isArchived,
            isPinned: latest.isPinned,
            cardStyle: latest.cardStyle,
            folderId: latest.folderId,
            dailyNoteDateKey: latest.dailyNoteDateKey,
            sortOrder: latest.sortOrder,
            deletedAt: latest.deletedAt);
  }

  static Future<T> _serialize<T>(Future<T> Function() operation,
      {required T onError}) async {
    try {
      return await NoteMutations.run(operation);
    } catch (_) {
      return onError;
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
