import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/daily_note_calendar.dart';
import 'package:onlynote/services/note_mutations.dart';
import 'package:onlynote/services/reminder_agenda.dart';

/// One unfinished checklist item, with its source note and stable saved ID.
/// Legacy items without unique IDs can still be opened in their source note.
class TodayTaskEntry {
  const TodayTaskEntry({
    required this.note,
    required this.todo,
    required this.index,
    this.canComplete = true,
  });

  final Note note;
  final Todo todo;
  final int index;
  final bool canComplete;

  String get key => '${note.id}:${todo.id ?? 'legacy-$index'}:$index';
}

class TodayAgenda {
  const TodayAgenda({
    this.dailyNote,
    this.reminders = const [],
    this.tasks = const [],
  });

  final Note? dailyNote;
  final List<ReminderAgendaEntry> reminders;
  final List<TodayTaskEntry> tasks;
}

/// Calendar due dates apply only to reminders. Checklist items are explicitly
/// all unfinished work in active notes, without inventing individual due dates.
TodayAgenda buildTodayAgenda({
  required Iterable<Note> notes,
  required List<Reminder> reminders,
  required DateTime now,
  Map<int, DateTime> pendingSnoozes = const {},
}) {
  final allNotes = notes.toList();
  final active = allNotes
      .where((note) =>
          !note.isDeleted &&
          !note.isArchived &&
          note.id?.trim().isNotEmpty == true)
      .toList()
    ..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final byOrder = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
      return byOrder != 0 ? byOrder : a.id!.compareTo(b.id!);
    });
  final tasks = <TodayTaskEntry>[];
  for (final note in active) {
    final counts = <String, int>{};
    for (final todo in note.todo) {
      if (todo.id?.trim().isNotEmpty == true) {
        counts.update(todo.id!, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    for (var index = 0; index < note.todo.length; index++) {
      final todo = note.todo[index];
      if (!todo.completed && todo.title?.trim().isNotEmpty == true) {
        tasks.add(TodayTaskEntry(
          note: note,
          todo: todo,
          index: index,
          canComplete: todo.id != null && counts[todo.id] == 1,
        ));
      }
    }
  }
  return TodayAgenda(
    dailyNote: DailyNoteCalendarIndex.fromNotes(allNotes).noteForDay(now),
    reminders: List.unmodifiable(buildReminderAgenda(
      reminders: reminders,
      notes: allNotes,
      now: now,
      pendingSnoozes: pendingSnoozes,
    ).where((entry) => entry.groupAt(now) != ReminderAgendaGroup.upcoming)),
    tasks: List.unmodifiable(tasks),
  );
}

/// Searches unfinished task text and its source note title only. Calendar
/// sections stay independent of this query.
List<TodayTaskEntry> searchTodayTasks(
    Iterable<TodayTaskEntry> tasks, String query) {
  final words = query
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return List.unmodifiable(tasks);
  return List.unmodifiable(tasks.where((entry) {
    final text =
        '${entry.todo.title ?? ''}\n${entry.note.title ?? ''}'.toLowerCase();
    return words.every(text.contains);
  }));
}

enum TodayTaskActionResult { saved, unavailable, changed, failed, busy }

/// A single-use in-session receipt. It never stores a whole note snapshot,
/// so Undo cannot overwrite edits made after the completion.
class TodayTaskCompletionUndo {
  const TodayTaskCompletionUndo._(
      {required this.noteId,
      required this.todoId,
      required this.title,
      required this.generation});
  final String noteId;
  final String todoId;
  final String? title;
  final int generation;
}

/// Injectable state shared by the live screen and interaction tests. Every
/// checklist action starts from current storage, preserving unrelated edits.
class TodayAgendaController extends ChangeNotifier {
  TodayAgendaController({
    required this.readNotes,
    required this.readNote,
    required this.readReminders,
    required this.readPendingSnoozes,
    required this.saveNote,
    this.beforeTaskWrite,
    this.reminderChanges,
    Stream<Object?>? noteChanges,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    referenceTime = this.now();
    reminderChanges?.addListener(_changed);
    _notesSubscription = noteChanges?.listen((_) => _changed());
  }

  final Future<List<Note>> Function() readNotes;
  final Future<Note?> Function(String id) readNote;
  final List<Reminder> Function() readReminders;
  final Future<Map<int, DateTime>> Function(List<Reminder>) readPendingSnoozes;
  final Future<void> Function(Note note) saveNote;
  final Future<void> Function()? beforeTaskWrite;
  final Listenable? reminderChanges;
  final DateTime Function() now;
  StreamSubscription<Object?>? _notesSubscription;

  TodayAgenda agenda = const TodayAgenda();
  late DateTime referenceTime;
  bool loading = false;
  bool loadFailed = false;
  String? busyTaskKey;
  int _loadRevision = 0;
  bool _disposed = false;
  int _completionGeneration = 0;
  TodayTaskCompletionUndo? _lastCompletionUndo;

  TodayTaskCompletionUndo? get lastCompletionUndo => _lastCompletionUndo;

  void _changed() => unawaited(refresh());

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_loadRevision;
    loading = true;
    _notify();
    try {
      final reminders = List<Reminder>.of(readReminders());
      final notes = await readNotes();
      final snoozes = await readPendingSnoozes(reminders);
      if (_disposed || revision != _loadRevision) return;
      referenceTime = now();
      agenda = buildTodayAgenda(
          notes: notes,
          reminders: reminders,
          now: referenceTime,
          pendingSnoozes: snoozes);
      loadFailed = false;
    } catch (_) {
      if (!_disposed && revision == _loadRevision) loadFailed = true;
    } finally {
      if (!_disposed && revision == _loadRevision) {
        loading = false;
        _notify();
      }
    }
  }

  Future<Note?> resolveNote(String id) async {
    final note = await readNote(id);
    return note == null || note.isDeleted ? null : note;
  }

  Future<TodayTaskActionResult> completeTask(TodayTaskEntry entry) async {
    if (_disposed || busyTaskKey != null) return TodayTaskActionResult.busy;
    if (!entry.canComplete || entry.note.id == null || entry.todo.id == null) {
      return TodayTaskActionResult.unavailable;
    }
    busyTaskKey = entry.key;
    _notify();
    try {
      await beforeTaskWrite?.call();
      if (_disposed) return TodayTaskActionResult.busy;
      return await NoteMutations.run(() async {
        if (_disposed) return TodayTaskActionResult.busy;
        final note = await resolveNote(entry.note.id!);
        if (_disposed) return TodayTaskActionResult.busy;
        if (note == null || note.isArchived) {
          await refresh();
          return TodayTaskActionResult.unavailable;
        }
        final matches =
            note.todo.where((todo) => todo.id == entry.todo.id).toList();
        if (matches.length != 1) {
          await refresh();
          return TodayTaskActionResult.unavailable;
        }
        final current = matches.single;
        if (current.title != entry.todo.title || current.completed) {
          await refresh();
          return TodayTaskActionResult.changed;
        }
        final updated = note.copyWith(todo: [
          for (final todo in note.todo)
            if (todo.id == current.id) todo.copyWith(completed: true) else todo,
        ]);
        await saveNote(updated);
        if (!_disposed) {
          _lastCompletionUndo = TodayTaskCompletionUndo._(
              noteId: note.id!,
              todoId: current.id!,
              title: current.title,
              generation: ++_completionGeneration);
        }
        await refresh();
        return TodayTaskActionResult.saved;
      });
    } catch (_) {
      return TodayTaskActionResult.failed;
    } finally {
      busyTaskKey = null;
      _notify();
    }
  }

  Future<TodayTaskActionResult> undoTaskCompletion(
      TodayTaskCompletionUndo receipt) async {
    if (_disposed || busyTaskKey != null) return TodayTaskActionResult.busy;
    if (!identical(receipt, _lastCompletionUndo)) {
      return TodayTaskActionResult.changed;
    }
    busyTaskKey = 'undo:${receipt.generation}';
    _notify();
    try {
      await beforeTaskWrite?.call();
      if (_disposed) return TodayTaskActionResult.busy;
      return await NoteMutations.run(() async {
        if (_disposed) return TodayTaskActionResult.busy;
        final note = await resolveNote(receipt.noteId);
        if (_disposed) return TodayTaskActionResult.busy;
        if (note == null || note.isArchived) {
          _lastCompletionUndo = null;
          await refresh();
          return TodayTaskActionResult.unavailable;
        }
        final matches =
            note.todo.where((todo) => todo.id == receipt.todoId).toList();
        if (matches.length != 1) {
          _lastCompletionUndo = null;
          await refresh();
          return TodayTaskActionResult.unavailable;
        }
        final task = matches.single;
        if (task.title != receipt.title || !task.completed) {
          _lastCompletionUndo = null;
          await refresh();
          return TodayTaskActionResult.changed;
        }
        await saveNote(note.copyWith(todo: [
          for (final value in note.todo)
            if (value.id == receipt.todoId)
              value.copyWith(completed: false)
            else
              value,
        ]));
        _lastCompletionUndo = null;
        await refresh();
        return TodayTaskActionResult.saved;
      });
    } catch (_) {
      // Retain this receipt after a failed write so Retry can use the same
      // identity, while every attempt still reads current storage afresh.
      return TodayTaskActionResult.failed;
    } finally {
      busyTaskKey = null;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _lastCompletionUndo = null;
    _loadRevision++;
    reminderChanges?.removeListener(_changed);
    unawaited(_notesSubscription?.cancel());
    super.dispose();
  }
}
