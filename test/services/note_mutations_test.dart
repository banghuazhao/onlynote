import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_mutations.dart';
import 'package:onlynote/services/shortcuts_append.dart';
import 'package:onlynote/services/today_agenda.dart';

class _Notes extends Fake implements NoteRepository {
  NoteDto saved = NoteDto.fromNote(Note(
      id: 'note',
      title: 'Shopping',
      description: 'Keep this paragraph',
      todo: [Todo(id: 'task', title: 'Buy milk')]));
  Completer<void>? pauseNextSave;
  Completer<void>? saveStarted;
  int writes = 0;

  @override
  List<NoteDto> getAllNotes() => [saved];
  @override
  Future<NoteDto> getNote(String id) async => saved;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    final pause = pauseNextSave;
    pauseNextSave = null;
    if (pause != null) {
      saveStarted!.complete();
      await pause.future;
    }
    saved = note;
    writes++;
  }
}

class _Store implements NoteAutosaveStore {
  _Store(this.notes);
  final _Notes notes;
  final drafts = <String, Note>{};
  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) =>
      notes.addUpdateNote(NoteDto.fromNote(note));
}

class _Journal implements ShortcutAppendJournal {
  final values = <String, Object>{};
  @override
  Iterable<String> get keys => values.keys;
  @override
  Object? read(String key) => values[key];
  @override
  Future<void> write(String key, Object value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

void main() {
  test('transactions run in order, nest safely and recover from errors',
      () async {
    final gate = Completer<void>();
    final events = <String>[];
    final first = NoteMutations.run(() async {
      events.add('start');
      await gate.future;
      await NoteMutations.run(() async => events.add('nested'));
      throw StateError('Failed save');
    });
    final failed = expectLater(first, throwsStateError);
    final second = NoteMutations.run(() async => events.add('next'));
    await Future<void>.delayed(Duration.zero);
    expect(events, ['start']);
    gate.complete();
    await failed;
    await second;
    expect(events, ['start', 'nested', 'next']);
  });

  for (final appendFirst in [false, true]) {
    for (final undo in [false, true]) {
      test(
          'Today ${undo ? 'Undo' : 'completion'} and Siri retain both edits '
          'when ${appendFirst ? 'Siri' : 'Today'} saves first', () async {
        final notes = _Notes();
        final store = _Store(notes);
        final service = ShortcutsAppendService(
            repository: notes,
            store: store,
            journal: _Journal(),
            readDraft: (id) => store.drafts[id]);
        final controller = TodayAgendaController(
            readNotes: () async => [notes.saved.toDomain()],
            readNote: (_) async => notes.saved.toDomain(),
            readReminders: () => [],
            readPendingSnoozes: (_) async => {},
            saveNote: (note) => notes.addUpdateNote(NoteDto.fromNote(note)));
        addTearDown(controller.dispose);
        await controller.refresh();
        final task = controller.agenda.tasks.single;
        if (undo) {
          expect(
              await controller.completeTask(task), TodayTaskActionResult.saved);
        }
        final receipt = controller.lastCompletionUndo;
        Future<TodayTaskActionResult> today() => undo
            ? controller.undoTaskCompletion(receipt!)
            : controller.completeTask(task);
        Future<Note?> append() => service.apply(
            const ShortcutAppendRequest(
                id: '12345678-1234-1234-1234-000000000001',
                text: 'Siri capture',
                destination: ShortcutAppendDestination.note,
                noteId: 'note',
                createdAt: 1793221200000),
            acknowledge: (_) async {},
            titleForDay: (_) => 'Today',
            inboxTitle: 'Inbox');
        notes.saveStarted = Completer<void>();
        final release = Completer<void>();
        notes.pauseNextSave = release;
        final writesBefore = notes.writes;
        final first = appendFirst ? append() : today();
        await notes.saveStarted!.future;
        final second = appendFirst ? today() : append();
        await Future<void>.delayed(Duration.zero);
        // The second action must wait before reading an obsolete snapshot.
        expect(notes.writes, writesBefore);
        release.complete();
        await Future.wait([first, second]);
        expect(notes.saved.description, 'Keep this paragraph\n\nSiri capture');
        expect(notes.saved.todoList!.single.completed, !undo);
        expect(notes.writes, writesBefore + 2);
        expect(store.drafts, isEmpty);
      });
    }
  }

  test('widget import and Siri capture retain both edits', () async {
    final notes = _Notes();
    final store = _Store(notes);
    final service = ShortcutsAppendService(
        repository: notes,
        journal: _Journal(),
        store: store,
        readDraft: (id) => store.drafts[id]);
    final widget = WidgetCommands(
        repository: notes,
        readDraft: (id) => store.drafts[id] == null
            ? null
            : NoteDto.fromNote(store.drafts[id]!),
        writeDraft: (dto) => store.writeDraft(dto.toDomain()),
        removeDraft: store.removeDraft,
        enabled: true,
        readPending: () async => [
              {
                'id': 'widget-command',
                'noteId': 'note',
                'todoId': 'task',
                'completed': true,
                'createdAt': 1793221200000,
              }
            ],
        acknowledge: (_) async {},
        syncWidgets: () async {});
    notes.saveStarted = Completer<void>();
    final release = Completer<void>();
    notes.pauseNextSave = release;
    final imported = widget.importPending();
    await notes.saveStarted!.future;
    final appended = service.apply(
        const ShortcutAppendRequest(
            id: '12345678-1234-1234-1234-000000000002',
            text: 'Captured while widget saves',
            destination: ShortcutAppendDestination.note,
            noteId: 'note',
            createdAt: 1793221200001),
        acknowledge: (_) async {},
        titleForDay: (_) => 'Today',
        inboxTitle: 'Inbox');
    await Future<void>.delayed(Duration.zero);
    release.complete();
    await Future.wait([imported, appended]);
    expect(notes.saved.description,
        'Keep this paragraph\n\nCaptured while widget saves');
    expect(notes.saved.todoList!.single.completed, isTrue);
    expect(notes.writes, 2);
    expect(store.drafts, isEmpty);
  });
}
