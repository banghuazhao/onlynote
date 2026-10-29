import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_mutations.dart';
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

  for (final undo in [false, true]) {
    test(
        'disposed queued ${undo ? 'Undo' : 'completion'} does not read or write',
        () async {
      var note = Note(id: 'note', todo: [Todo(id: 'task', title: 'Task')]);
      var flushes = 0;
      var writes = 0;
      var reads = 0;
      final controller = TodayAgendaController(
        readNotes: () async => [note],
        readNote: (_) async {
          reads++;
          return note;
        },
        readReminders: () => [],
        readPendingSnoozes: (_) async => {},
        beforeTaskWrite: () async => flushes++,
        saveNote: (value) async {
          writes++;
          note = value;
        },
        now: () => now,
      );
      await controller.refresh();
      final entry = controller.agenda.tasks.single;
      if (undo) {
        expect(
            await controller.completeTask(entry), TodayTaskActionResult.saved);
      }
      final entered = Completer<void>();
      final release = Completer<void>();
      final blocker = NoteMutations.run(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final pending = undo
          ? controller.undoTaskCompletion(controller.lastCompletionUndo!)
          : controller.completeTask(entry);
      // Let the pre-write flush finish while the mutation reservation is held.
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      release.complete();
      await blocker;
      expect(await pending, TodayTaskActionResult.busy);
      expect(flushes, undo ? 2 : 1);
      expect(reads, undo ? 1 : 0);
      expect(writes, undo ? 1 : 0);
    });
  }

  test('task search matches words across task and note titles without mutation',
      () {
    final agenda = buildTodayAgenda(notes: [
      Note(id: 'work', title: 'Website Project', todo: [
        Todo(id: 'draft', title: 'Write first draft'),
        Todo(id: 'photos', title: 'Choose photos'),
      ]),
      Note(id: 'home', title: 'Home', todo: [Todo(id: 'plants', title: '浇花')]),
    ], reminders: [], now: now);
    expect(searchTodayTasks(agenda.tasks, ' PROJECT  draft ').single.todo.id,
        'draft');
    expect(searchTodayTasks(agenda.tasks, 'website').length, 2);
    expect(searchTodayTasks(agenda.tasks, '浇花').single.note.id, 'home');
    expect(searchTodayTasks(agenda.tasks, 'missing'), isEmpty);
    expect(searchTodayTasks(agenda.tasks, ' '), agenda.tasks);
    expect(agenda.tasks.every((task) => !task.todo.completed), isTrue);
  });

  test('Undo reads latest note and clears only its intended completion flag',
      () async {
    final initial = Note(id: 'note', description: 'Earlier', todo: [
      Todo(id: 'task', title: 'Write draft'),
      Todo(id: 'other', title: 'Other'),
    ]);
    final store = _Store([initial]);
    final controller = store.controller(now);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(await controller.completeTask(controller.agenda.tasks.first),
        TodayTaskActionResult.saved);
    final receipt = controller.lastCompletionUndo!;
    final completed = store.notes['note']!;
    store.notes['note'] = completed
        .copyWith(description: 'Newer writing', folderId: 'work', tags: [
      'important'
    ], todo: [
      completed.todo[1].copyWith(completed: true),
      completed.todo[0],
      Todo(id: 'new', title: 'Added later'),
    ]);
    expect(await controller.undoTaskCompletion(receipt),
        TodayTaskActionResult.saved);
    final saved = store.notes['note']!;
    expect(saved.description, 'Newer writing');
    expect(saved.folderId, 'work');
    expect(saved.tags, ['important']);
    expect(saved.todo.map((value) => (value.id, value.completed)),
        [('other', true), ('task', false), ('new', false)]);
    expect(controller.lastCompletionUndo, isNull);
    expect(await controller.undoTaskCompletion(receipt),
        TodayTaskActionResult.changed);
    expect(store.writes, 2);
  });

  for (final change in [
    'renamed',
    'unfinished',
    'archived',
    'deleted',
    'removed',
    'duplicate'
  ]) {
    test('Undo rejects $change tasks without replacing newer data', () async {
      final initial =
          Note(id: 'note', todo: [Todo(id: 'task', title: 'Original')]);
      final store = _Store([initial]);
      final controller = store.controller(now);
      addTearDown(controller.dispose);
      await controller.refresh();
      await controller.completeTask(controller.agenda.tasks.single);
      final receipt = controller.lastCompletionUndo!;
      final current = store.notes['note']!;
      store.notes['note'] = switch (change) {
        'renamed' => current
            .copyWith(todo: [current.todo.single.copyWith(title: 'New name')]),
        'unfinished' => current
            .copyWith(todo: [current.todo.single.copyWith(completed: false)]),
        'archived' => current.copyWith(isArchived: true),
        'deleted' => current.copyWith(deletedAt: now),
        'duplicate' =>
          current.copyWith(todo: [current.todo.single, current.todo.single]),
        _ => current.copyWith(todo: []),
      };
      final changed = store.notes['note'];
      expect(
          await controller.undoTaskCompletion(receipt),
          ['renamed', 'unfinished'].contains(change)
              ? TodayTaskActionResult.changed
              : TodayTaskActionResult.unavailable);
      expect(store.notes['note'], same(changed));
      expect(store.writes, 1);
      expect(controller.lastCompletionUndo, isNull);
    });
  }

  test('a newer completion replaces the old Undo receipt', () async {
    final store = _Store([
      Note(id: 'note', todo: [
        Todo(id: 'first', title: 'First'),
        Todo(id: 'second', title: 'Second'),
      ])
    ]);
    final controller = store.controller(now);
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.completeTask(controller.agenda.tasks.first);
    final older = controller.lastCompletionUndo!;
    await controller.completeTask(controller.agenda.tasks.single);
    final newer = controller.lastCompletionUndo!;
    expect(await controller.undoTaskCompletion(older),
        TodayTaskActionResult.changed);
    expect(await controller.undoTaskCompletion(newer),
        TodayTaskActionResult.saved);
    expect(store.notes['note']!.todo.map((value) => value.completed),
        [true, false]);
  });

  test(
      'a failed Undo preserves its receipt for retry and leaves storage unchanged',
      () async {
    final store = _Store([
      Note(id: 'note', todo: [Todo(id: 'task', title: 'Task')])
    ]);
    final controller = store.controller(now);
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.completeTask(controller.agenda.tasks.single);
    final receipt = controller.lastCompletionUndo!;
    store.failWrite = true;
    expect(await controller.undoTaskCompletion(receipt),
        TodayTaskActionResult.failed);
    expect(controller.lastCompletionUndo, same(receipt));
    expect(store.notes['note']!.todo.single.completed, isTrue);
    store.failWrite = false;
    expect(await controller.undoTaskCompletion(receipt),
        TodayTaskActionResult.saved);
    expect(store.notes['note']!.todo.single.completed, isFalse);
  });

  test(
      'duplicate Undo requests serialize and disposal cancels its pending read',
      () async {
    final store = _Store([
      Note(id: 'note', todo: [Todo(id: 'task', title: 'Task')])
    ]);
    final controller = store.controller(now);
    await controller.refresh();
    await controller.completeTask(controller.agenda.tasks.single);
    final receipt = controller.lastCompletionUndo!;
    store.readGate = Completer<void>();
    final first = controller.undoTaskCompletion(receipt);
    expect(await controller.undoTaskCompletion(receipt),
        TodayTaskActionResult.busy);
    controller.dispose();
    store.readGate!.complete();
    expect(await first, TodayTaskActionResult.busy);
    expect(store.notes['note']!.todo.single.completed, isTrue);
    expect(store.writes, 1);
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
