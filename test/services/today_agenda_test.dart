import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/today_agenda.dart';

void main() {
  final now = DateTime(2026, 10, 29, 10);

  test(
      'Today combines due reminders with unfinished work without assigning task dates',
      () {
    final current = Note(
      id: 'current',
      title: 'Work',
      todo: [
        Todo(id: 'unfinished', title: 'Write draft'),
        Todo(id: 'complete', title: 'Sent', completed: true),
        Todo(id: 'empty', title: '  '),
      ],
    );
    final archived = Note(
        id: 'archive',
        isArchived: true,
        todo: [Todo(id: 'archived-task', title: 'Archived task')]);
    final deleted = Note(
        id: 'trash',
        deletedAt: now,
        todo: [Todo(id: 'deleted-task', title: 'Deleted task')]);
    Reminder reminder(String id, int key, DateTime date) =>
        Reminder(noteId: id, reminderId: key, reminderDate: date);
    final result = buildTodayAgenda(
      notes: [current, archived, deleted],
      reminders: [
        reminder('current', 1, DateTime(2026, 10, 28, 9)),
        reminder('current', 2, DateTime(2026, 10, 29, 18)),
        reminder('current', 3, DateTime(2026, 10, 30)),
        reminder('trash', 4, now),
        reminder('missing', 5, now),
      ],
      now: now,
    );
    expect(result.reminders.map((entry) => entry.reminder.reminderId), [1, 2]);
    expect(result.tasks.map((entry) => entry.todo.id), ['unfinished']);
    expect(result.tasks.single.note.id, 'current');
  });

  test(
      'daily-note selection shares existing identity and rolls at local midnight',
      () {
    final notes = [
      Note(id: 'ordinary', title: '2026-10-29'),
      Note(
          id: 'today',
          title: 'Renamed journal',
          dailyNoteDateKey: '2026-10-29'),
      Note(id: 'tomorrow', dailyNoteDateKey: '2026-10-30', isArchived: true),
      Note(id: 'trashed', dailyNoteDateKey: '2026-10-29', deletedAt: now),
    ];
    expect(
        buildTodayAgenda(notes: notes, reminders: [], now: now).dailyNote?.id,
        'today');
    expect(
        buildTodayAgenda(
                notes: notes, reminders: [], now: DateTime(2026, 10, 30))
            .dailyNote
            ?.id,
        'tomorrow');
  });

  test(
      'daily repeating reminders use their next occurrence and respect snoozes',
      () {
    final note = Note(id: 'repeat');
    final recurring = Reminder(
        noteId: 'repeat',
        reminderId: 1,
        reminderDate: DateTime(2026, 10, 20, 9),
        repeat: ReminderRepeat.daily);
    final earlier = buildTodayAgenda(
        notes: [note], reminders: [recurring], now: DateTime(2026, 10, 29, 8));
    expect(earlier.reminders.single.dueDate, DateTime(2026, 10, 29, 9));
    final later =
        buildTodayAgenda(notes: [note], reminders: [recurring], now: now);
    expect(later.reminders, isEmpty);
    final snoozed = buildTodayAgenda(
        notes: [note],
        reminders: [recurring],
        now: now,
        pendingSnoozes: {1: DateTime(2026, 10, 29, 10, 10)});
    expect(snoozed.reminders.single.dueDate, DateTime(2026, 10, 29, 10, 10));
    expect(snoozed.reminders.single.snoozed, isTrue);
  });

  test(
      'legacy and duplicate task IDs remain visible without unsafe checkbox actions',
      () {
    final result = buildTodayAgenda(notes: [
      Note(id: 'note', todo: [
        Todo(title: 'Legacy'),
        Todo(id: 'duplicate', title: 'One'),
        Todo(id: 'duplicate', title: 'Two'),
        Todo(id: 'stable', title: 'Three'),
      ]),
    ], reminders: [], now: now);
    expect(result.tasks.map((entry) => entry.canComplete),
        [false, false, false, true]);
    expect(result.tasks.map((entry) => entry.key).toSet().length, 4);
  });

  test('completion reads latest note and preserves content, order and metadata',
      () async {
    final initial = Note(id: 'note', description: 'Earlier', todo: [
      Todo(id: 'task', title: 'Write draft'),
      Todo(id: 'other', title: 'Other'),
    ]);
    final store = _Store([initial]);
    final controller = store.controller(now);
    addTearDown(controller.dispose);
    await controller.refresh();
    final entry = controller.agenda.tasks.first;
    store.notes['note'] = initial
        .copyWith(description: 'Latest text', folderId: 'new-folder', tags: [
      'important'
    ], todo: [
      initial.todo[1].copyWith(completed: true),
      initial.todo[0],
    ]);
    expect(await controller.completeTask(entry), TodayTaskActionResult.saved);
    final saved = store.notes['note']!;
    expect(saved.description, 'Latest text');
    expect(saved.folderId, 'new-folder');
    expect(saved.tags, ['important']);
    expect(saved.todo.map((todo) => todo.id), ['other', 'task']);
    expect(saved.todo.every((todo) => todo.completed), isTrue);
    expect(controller.agenda.tasks, isEmpty);
    expect(store.writes, 1);
  });

  for (final change in [
    'renamed',
    'completed',
    'archived',
    'deleted',
    'removed'
  ]) {
    test('a $change task cannot be mutated through a stale Today row',
        () async {
      final initial =
          Note(id: 'note', todo: [Todo(id: 'task', title: 'Original')]);
      final store = _Store([initial]);
      final controller = store.controller(now);
      addTearDown(controller.dispose);
      await controller.refresh();
      final entry = controller.agenda.tasks.single;
      store.notes['note'] = switch (change) {
        'renamed' => initial
            .copyWith(todo: [initial.todo.single.copyWith(title: 'Changed')]),
        'completed' => initial
            .copyWith(todo: [initial.todo.single.copyWith(completed: true)]),
        'archived' => initial.copyWith(isArchived: true),
        'deleted' => initial.copyWith(deletedAt: now),
        _ => initial.copyWith(todo: []),
      };
      final result = await controller.completeTask(entry);
      expect(
          result,
          ['renamed', 'completed'].contains(change)
              ? TodayTaskActionResult.changed
              : TodayTaskActionResult.unavailable);
      expect(store.writes, 0);
    });
  }

  test('failed saves preserve the unfinished row and can be retried', () async {
    final store = _Store([
      Note(id: 'note', todo: [Todo(id: 'task', title: 'Task')])
    ]);
    final controller = store.controller(now);
    addTearDown(controller.dispose);
    await controller.refresh();
    final entry = controller.agenda.tasks.single;
    store.failWrite = true;
    expect(await controller.completeTask(entry), TodayTaskActionResult.failed);
    expect(controller.agenda.tasks.single.todo.completed, isFalse);
    expect(controller.busyTaskKey, isNull);
    store.failWrite = false;
    expect(await controller.completeTask(entry), TodayTaskActionResult.saved);
  });

  test(
      'rapid completion requests write once and disposal cancels a pending read',
      () async {
    final store = _Store([
      Note(id: 'note', todo: [Todo(id: 'task', title: 'Task')])
    ]);
    final controller = store.controller(now);
    await controller.refresh();
    final entry = controller.agenda.tasks.single;
    store.readGate = Completer<void>();
    final first = controller.completeTask(entry);
    expect(await controller.completeTask(entry), TodayTaskActionResult.busy);
    controller.dispose();
    store.readGate!.complete();
    expect(await first, TodayTaskActionResult.busy);
    expect(store.writes, 0);
  });

  test('late refresh cannot replace a newer snapshot', () async {
    final first = Completer<List<Note>>();
    var reads = 0;
    final controller = TodayAgendaController(
      readNotes: () => ++reads == 1
          ? first.future
          : Future.value([
              Note(id: 'new', todo: [Todo(id: 'task', title: 'New task')]),
            ]),
      readNote: (_) async => null,
      readReminders: () => [],
      readPendingSnoozes: (_) async => {},
      saveNote: (_) async {},
      now: () => now,
    );
    addTearDown(controller.dispose);
    final pending = controller.refresh();
    await controller.refresh();
    first.complete([
      Note(id: 'old', todo: [Todo(id: 'task', title: 'Old task')])
    ]);
    await pending;
    expect(controller.agenda.tasks.single.todo.title, 'New task');
  });
}

class _Store {
  _Store(List<Note> initial)
      : notes = {for (final note in initial) note.id!: note};
  final Map<String, Note> notes;
  int writes = 0;
  bool failWrite = false;
  Completer<void>? readGate;

  TodayAgendaController controller(DateTime now) => TodayAgendaController(
        readNotes: () async => notes.values.toList(),
        readNote: (id) async {
          await readGate?.future;
          return notes[id];
        },
        readReminders: () => [],
        readPendingSnoozes: (_) async => {},
        saveNote: (note) async {
          writes++;
          if (failWrite) throw StateError('Storage unavailable');
          notes[note.id!] = note;
        },
        now: () => now,
      );
}
