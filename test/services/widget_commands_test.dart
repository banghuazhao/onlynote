import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';

class _Repository implements NoteRepository {
  final notes = <String, NoteDto>{};
  int saves = 0;
  bool fail = false;
  Completer<void>? pause;
  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    saves++;
    await pause?.future;
    if (fail) throw StateError('Disk full');
    notes[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => notes.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      notes.remove(id);
    }
  }
}

Map<String, Object> _command(String id, bool completed,
        {int time = 1, String todoId = 'item'}) =>
    {
      'id': id,
      'noteId': 'note',
      'todoId': todoId,
      'completed': completed,
      'createdAt': time,
    };

void main() {
  late _Repository repository;
  late WidgetCommands commands;
  late List<Object?> pending;
  late Map<String, NoteDto> drafts;
  late List<String> acknowledgements;
  late int syncs;
  setUp(() {
    repository = _Repository();
    repository.notes['note'] = NoteDto(
        id: 'note',
        title: 'Saved',
        description: 'Body',
        imagePaths: ['note_images/photo.jpg'],
        folderId: 'folder',
        isPinned: true,
        sortOrder: 17,
        todoList: [TodoDto(id: 'item', title: 'Milk', completed: false)]);
    pending = [];
    drafts = {};
    acknowledgements = [];
    syncs = 0;
    commands = WidgetCommands(
        repository: repository,
        readPending: () async => List<Object?>.of(pending),
        acknowledge: (ids) async {
          acknowledgements.addAll(ids);
          pending.removeWhere(
              (value) => value is Map && ids.contains(value['id']));
        },
        readDraft: (id) => drafts[id],
        writeDraft: (note) async => drafts[note.id!] = note,
        removeDraft: (id) async => drafts.remove(id),
        syncWidgets: () async {
          syncs++;
        });
  });
  tearDown(() => commands.updates.dispose());

  test('applies explicit completion and preserves all other fields', () async {
    pending.add(_command('one', true));
    await commands.importPending();
    final note = repository.notes['note']!;
    expect(note.todoList!.single.completed, true);
    expect(note.title, 'Saved');
    expect(note.description, 'Body');
    expect(note.imagePaths, ['note_images/photo.jpg']);
    expect(note.folderId, 'folder');
    expect(note.isPinned, true);
    expect(note.sortOrder, 17);
    expect(drafts, isEmpty);
    expect(acknowledgements, ['one']);
    expect(syncs, 1);
  });

  test('merges a newer durable recovery draft instead of overwriting it',
      () async {
    drafts['note'] = repository.notes['note']!
        .copyWith(title: 'New typing', description: 'Latest text');
    pending.add(_command('one', true));
    await commands.importPending();
    expect(repository.notes['note']!.title, 'New typing');
    expect(repository.notes['note']!.description, 'Latest text');
    expect(repository.notes['note']!.todoList!.single.completed, true);
  });

  test(
      'acknowledges missing notes, trashed notes, deleted and legacy todo IDs without mutation',
      () async {
    pending.add(_command('gone', true));
    repository.notes.clear();
    await commands.importPending();
    expect(repository.notes, isEmpty);
    repository.notes['note'] = NoteDto(
        id: 'note', deletedAt: '2026-10-06', todoList: [TodoDto(id: 'item')]);
    pending.add(_command('trash', true));
    await commands.importPending();
    expect(repository.notes['note']!.isDeleted, true);
    repository.notes['note'] =
        NoteDto(id: 'note', todoList: [TodoDto(title: 'Legacy')]);
    pending.add(_command('legacy', true));
    await commands.importPending();
    expect(repository.saves, 0);
    expect(acknowledgements, ['gone', 'trash', 'legacy']);
  });

  test('failure retains recovery data and older command before newer state',
      () async {
    repository.fail = true;
    pending
        .addAll([_command('first', true), _command('second', false, time: 2)]);
    await commands.importPending();
    expect(acknowledgements, isEmpty);
    expect(drafts['note']!.todoList!.single.completed, true);
    expect(pending, hasLength(2));
    repository.fail = false;
    await commands.importPending();
    expect(repository.notes['note']!.todoList!.single.completed, false);
    expect(acknowledgements, ['first', 'second']);
    expect(drafts, isEmpty);
  });

  test('replayed and duplicate commands are idempotent', () async {
    pending.addAll([_command('one', true), _command('one', true)]);
    await commands.importPending();
    expect(repository.saves, 1);
    pending.add(_command('one', true));
    await commands.importPending();
    expect(repository.saves, 1);
    expect(repository.notes['note']!.todoList!.single.completed, true);
  });

  test('uses current editor autosave and unregisters when editor closes',
      () async {
    final applied = <WidgetTodoCommand>[];
    var durable = false;
    final unregister = commands.registerEditor('note', (command) async {
      applied.add(command);
      return durable;
    });
    pending.add(_command('one', true));
    await commands.importPending();
    expect(acknowledgements, isEmpty);
    durable = true;
    await commands.importPending();
    expect(applied, hasLength(2));
    expect(repository.saves, 0);
    expect(commands.updates.value!.completed, true);
    unregister();
    pending.add(_command('two', true));
    await commands.importPending();
    expect(repository.saves, 1);
  });

  test('a warm action arriving during import triggers another drain', () async {
    repository.pause = Completer<void>();
    pending.add(_command('one', true));
    final first = commands.importPending();
    await Future<void>.delayed(Duration.zero);
    pending.add(_command('two', false, time: 2));
    final second = commands.importPending();
    repository.pause!.complete();
    await Future.wait([first, second]);
    expect(repository.notes['note']!.todoList!.single.completed, false);
    expect(acknowledgements, ['one', 'two']);
    expect(pending, isEmpty);
  });

  test('malformed commands cannot target the database', () async {
    pending.addAll([
      {},
      {'id': 'x'},
      {..._command('bad', true), 'completed': 'true'},
      {..._command('bad2', true), 'createdAt': -1}
    ]);
    await commands.importPending();
    expect(repository.saves, 0);
    expect(acknowledgements, isEmpty);
  });
}
