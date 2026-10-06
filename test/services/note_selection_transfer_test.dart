import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_checklist.dart';
import 'package:onlynote/services/note_selection_transfer.dart';

class _Notes implements NoteRepository {
  final notes = <String, NoteDto>{};
  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async => notes[note.id!] = note;
  @override
  Future<void> deleteNote(String id) async => notes.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      notes.remove(id);
    }
  }
}

class _Store implements NoteAutosaveStore {
  _Store(this.repository);
  final _Notes repository;
  final drafts = <String, Note>{};
  final saves = <Note>[];
  final draftWrites = <Note>[];
  bool failSave = false;
  Future<void> Function(Note)? beforeSave;
  @override
  Future<void> writeDraft(Note note) async {
    draftWrites.add(note);
    drafts[note.id!] = note;
  }

  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    await beforeSave?.call(note);
    if (failSave) throw StateError('disk unavailable');
    await repository.addUpdateNote(NoteDto.fromNote(note));
    saves.add(note);
  }
}

void main() {
  late _Notes repository;
  late _Store store;
  late NoteSelectionTransfer transfer;
  setUp(() {
    repository = _Notes();
    store = _Store(repository);
    transfer = NoteSelectionTransfer(
        repository: repository,
        store: store,
        readDraft: (id) => store.drafts[id]);
  });

  test('serial copies append to newest content without losing either copy',
      () async {
    repository.notes['to'] =
        NoteDto.fromNote(Note(id: 'to', description: 'Original'));
    final first =
        transfer.copyToExisting('to', NoteTextSelection(text: 'First'));
    final second =
        transfer.copyToExisting('to', NoteTextSelection(text: 'Second'));
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect((await repository.getNote('to')).description,
        'Original\n\nFirst\n\nSecond');
    expect(store.drafts, isEmpty);
  });

  test('recovery content merges with latest library metadata', () async {
    repository.notes['to'] = NoteDto.fromNote(Note(
        id: 'to',
        description: 'Saved',
        isPinned: true,
        folderId: 'new-folder',
        sortOrder: 9,
        dailyNoteDateKey: '2026-10-07'));
    store.drafts['to'] =
        Note(id: 'to', description: 'Latest draft', folderId: 'old-folder');
    expect(
        await transfer.copyToExisting(
            'to', NoteTextSelection(text: 'Selected')),
        isTrue);
    final result = (await repository.getNote('to')).toDomain();
    expect(result.description, 'Latest draft\n\nSelected');
    expect(result.isPinned, isTrue);
    expect(result.folderId, 'new-folder');
    expect(result.sortOrder, 9);
    expect(result.dailyNoteDateKey, '2026-10-07');
  });

  test('busy live editor rejects copy without saving around it', () async {
    repository.notes['to'] =
        NoteDto.fromNote(Note(id: 'to', description: 'Saved'));
    final unregister =
        NoteSelectionTransfer.registerEditor('to', (_) async => false);
    try {
      expect(
          await transfer.copyToExisting(
              'to', NoteTextSelection(text: 'Selected')),
          isFalse);
      expect((await repository.getNote('to')).description, 'Saved');
      expect(store.drafts, isEmpty);
    } finally {
      unregister();
    }
  });

  test('deleted archived and missing destinations cannot be resurrected',
      () async {
    repository.notes['deleted'] =
        NoteDto.fromNote(Note(id: 'deleted', deletedAt: DateTime(2026)));
    repository.notes['archived'] =
        NoteDto.fromNote(Note(id: 'archived', isArchived: true));
    final selection = NoteTextSelection(text: 'Selected');
    expect(await transfer.copyToExisting('deleted', selection), isFalse);
    expect(await transfer.copyToExisting('archived', selection), isFalse);
    expect(await transfer.copyToExisting('missing', selection), isFalse);
    expect(store.drafts, isEmpty);
  });

  test('save failure retains recovery draft and saved destination', () async {
    repository.notes['to'] =
        NoteDto.fromNote(Note(id: 'to', description: 'Saved'));
    store.failSave = true;
    expect(
        await transfer.copyToExisting(
            'to', NoteTextSelection(text: 'Selected')),
        isFalse);
    expect((await repository.getNote('to')).description, 'Saved');
    expect(store.drafts['to']!.description, 'Saved\n\nSelected');
  });

  test('new copy owns a stable new id and no source attachments or identity',
      () async {
    expect(
        await transfer.copyToNew(NoteTextSelection(text: 'Selected')), isTrue);
    final result = repository.getAllNotes().single.toDomain();
    expect(result.id, isNotEmpty);
    expect(result.description, 'Selected');
    expect(result.dailyNoteDateKey, isNull);
    expect(result.imagePaths, isEmpty);
    expect(result.voiceMemos, isEmpty);
    expect(store.drafts, isEmpty);
  });

  test('checklist additions retain draft content and latest archived metadata',
      () async {
    repository.notes['source'] = NoteDto.fromNote(Note(
      id: 'source',
      title: 'Saved title',
      description: 'Saved prose',
      isArchived: true,
      isPinned: true,
      folderId: 'latest-folder',
      sortOrder: 17,
      dailyNoteDateKey: '2026-10-07',
    ));
    final oldTodo = Todo(id: 'old', title: 'Unsaved task', completed: true);
    store.drafts['source'] = Note(
      id: 'source',
      title: 'Unsaved title',
      description: 'Unsaved prose',
      todo: [oldTodo],
      tags: ['draft-tag'],
      folderId: 'old-folder',
      sortOrder: 2,
    );
    final result = await transfer.addToChecklist(
        'source', NoteTextSelection(text: '• Coffee\n2. Tea'));
    expect(result!.status, NoteSelectionChecklistStatus.ready);
    final saved = (await repository.getNote('source')).toDomain();
    expect(saved.title, 'Unsaved title');
    expect(saved.description, 'Unsaved prose');
    expect(saved.todo.first, oldTodo);
    expect(saved.todo.map((todo) => todo.title),
        ['Unsaved task', 'Coffee', 'Tea']);
    expect(saved.todo.skip(1).map((todo) => todo.id), result.addedTodoIds);
    expect(saved.tags, ['draft-tag']);
    expect(saved.isArchived, isTrue);
    expect(saved.isPinned, isTrue);
    expect(saved.folderId, 'latest-folder');
    expect(saved.sortOrder, 17);
    expect(saved.dailyNoteDateKey, '2026-10-07');
    expect(store.drafts, isEmpty);
    expect(store.saves, hasLength(1));
  });

  test('deleted missing and mismatched checklist sources are rejected',
      () async {
    repository.notes['deleted'] = NoteDto.fromNote(Note(
        id: 'deleted',
        description: 'Retain deleted prose',
        deletedAt: DateTime(2026, 10, 7)));
    repository.notes['wrong-id'] =
        NoteDto.fromNote(Note(id: 'different', description: 'Wrong note'));
    final unregister = NoteSelectionTransfer.registerChecklistEditor(
      'deleted',
      add: (_) async => fail('Deleted note reached a live editor'),
      undo: (_) async => fail('Deleted note Undo reached a live editor'),
    );
    try {
      for (final id in ['deleted', 'missing', 'wrong-id']) {
        expect(
            await transfer.addToChecklist(id, NoteTextSelection(text: 'Task')),
            isNull);
        expect(await transfer.undoChecklist(id, ['new-row']), isFalse);
      }
      expect(store.drafts, isEmpty);
      expect(store.saves, isEmpty);
      expect(repository.notes['deleted']!.isDeleted, isTrue);
      expect(repository.notes['wrong-id']!.id, 'different');
    } finally {
      unregister();
    }
  });

  test('invalid checklist transactions create no rows or recovery writes',
      () async {
    repository.notes['source'] =
        NoteDto.fromNote(Note(id: 'source', description: 'Selected prose'));
    final empty = await transfer.addToChecklist(
        'source', NoteTextSelection(text: '•\n- [ ]'));
    final long = await transfer.addToChecklist(
        'source', NoteTextSelection(text: 'Good row\n${'😀' * 51}'));
    expect(empty!.status, NoteSelectionChecklistStatus.empty);
    expect(long!.status, NoteSelectionChecklistStatus.tooLong);
    expect(empty.note, isNull);
    expect(long.note, isNull);
    expect((await repository.getNote('source')).toDomain().todo, isEmpty);
    expect(store.drafts, isEmpty);
    expect(store.draftWrites, isEmpty);
    expect(store.saves, isEmpty);
  });

  test(
      'failed checklist save retains complete draft and later action recovers it',
      () async {
    repository.notes['source'] = NoteDto.fromNote(Note(
        id: 'source',
        description: 'Selected prose',
        todo: [Todo(id: 'old', title: 'Existing task')]));
    store.failSave = true;
    expect(
        await transfer.addToChecklist(
            'source', NoteTextSelection(text: 'Coffee')),
        isNull);
    expect((await repository.getNote('source')).toDomain().todo,
        [Todo(id: 'old', title: 'Existing task')]);
    final recovery = store.drafts['source']!;
    expect(recovery.description, 'Selected prose');
    expect(
        recovery.todo.map((todo) => todo.title), ['Existing task', 'Coffee']);
    final failedRowId = recovery.todo.last.id;
    store.failSave = false;
    final second =
        await transfer.addToChecklist('source', NoteTextSelection(text: 'Tea'));
    expect(second!.status, NoteSelectionChecklistStatus.ready);
    final saved = (await repository.getNote('source')).toDomain();
    expect(saved.description, 'Selected prose');
    expect(saved.todo.map((todo) => todo.title),
        ['Existing task', 'Coffee', 'Tea']);
    expect(saved.todo[1].id, failedRowId);
    expect(saved.todo.last.id, second.addedTodoIds.single);
    expect(store.drafts, isEmpty);
  });

  test(
      'newest busy checklist editor rejects add and Undo without fallback saves',
      () async {
    repository.notes['source'] =
        NoteDto.fromNote(Note(id: 'source', description: 'Saved prose'));
    var olderAdds = 0;
    var olderUndos = 0;
    var latestAdds = 0;
    var latestUndos = 0;
    final unregisterOlder = NoteSelectionTransfer.registerChecklistEditor(
      'source',
      add: (_) async {
        olderAdds++;
        return null;
      },
      undo: (_) async {
        olderUndos++;
        return false;
      },
    );
    final unregisterLatest = NoteSelectionTransfer.registerChecklistEditor(
      'source',
      add: (_) async {
        latestAdds++;
        return null;
      },
      undo: (_) async {
        latestUndos++;
        return false;
      },
    );
    try {
      expect(
          await transfer.addToChecklist(
              'source', NoteTextSelection(text: 'Task')),
          isNull);
      expect(await transfer.undoChecklist('source', ['created']), isFalse);
      expect(latestAdds, 1);
      expect(latestUndos, 1);
      expect(olderAdds, 0);
      expect(olderUndos, 0);
      expect(store.drafts, isEmpty);
      expect(store.saves, isEmpty);
      expect((await repository.getNote('source')).description, 'Saved prose');
      unregisterLatest();
      expect(
          await transfer.addToChecklist(
              'source', NoteTextSelection(text: 'Task')),
          isNull);
      expect(await transfer.undoChecklist('source', ['created']), isFalse);
      expect(olderAdds, 1);
      expect(olderUndos, 1);
      expect(store.drafts, isEmpty);
      expect(store.saves, isEmpty);
    } finally {
      unregisterLatest();
      unregisterOlder();
    }
  });

  test('registered checklist editor owns journal save and targeted Undo',
      () async {
    repository.notes['source'] =
        NoteDto.fromNote(Note(id: 'source', description: 'Saved prose'));
    var editorNote = Note(
        id: 'source',
        description: 'Unsaved editor prose',
        todo: [Todo(id: 'old', title: 'Unsaved task')]);
    Future<void> persistEditor(Note next) async {
      await store.writeDraft(next);
      await store.saveNote(next);
      await store.removeDraft(next.id!);
      editorNote = next;
    }

    final unregister = NoteSelectionTransfer.registerChecklistEditor(
      'source',
      add: (selection) async {
        final result = appendSelectionToChecklist(editorNote, selection);
        if (result.note != null) await persistEditor(result.note!);
        return result;
      },
      undo: (ids) async {
        await persistEditor(undoSelectionChecklist(editorNote, ids));
        return true;
      },
    );
    try {
      final result = await transfer.addToChecklist(
          'source', NoteTextSelection(text: 'Coffee\nTea'));
      expect(result!.status, NoteSelectionChecklistStatus.ready);
      expect(editorNote.todo.map((todo) => todo.title),
          ['Unsaved task', 'Coffee', 'Tea']);
      expect((await repository.getNote('source')).description,
          'Unsaved editor prose');
      expect(store.saves, hasLength(1));
      expect(store.draftWrites, hasLength(1));
      expect(store.drafts, isEmpty);
      expect(
          await transfer.undoChecklist('source', result.addedTodoIds), isTrue);
      expect(editorNote.todo, [Todo(id: 'old', title: 'Unsaved task')]);
      expect((await repository.getNote('source')).description,
          'Unsaved editor prose');
      expect(store.saves, hasLength(2));
      expect(store.draftWrites, hasLength(2));
      expect(store.drafts, isEmpty);
    } finally {
      unregister();
    }
  });

  test(
      'checklist Undo preserves newer prose tasks and metadata and is idempotent',
      () async {
    repository.notes['source'] = NoteDto.fromNote(Note(
        id: 'source',
        description: 'Selected prose',
        todo: [Todo(id: 'old', title: 'Existing task')]));
    final result = await transfer.addToChecklist(
        'source', NoteTextSelection(text: 'Coffee\nTea'));
    final withItems = (await repository.getNote('source')).toDomain();
    repository.notes['source'] = NoteDto.fromNote(withItems.copyWith(
      description: 'Newer edited prose',
      tags: ['new-tag'],
      isArchived: true,
      todo: [
        withItems.todo.first.copyWith(title: 'Updated task', completed: true),
        withItems.todo[1].copyWith(title: 'Edited added task', completed: true),
        Todo(id: 'later', title: 'Later unrelated task'),
        withItems.todo[2],
      ],
    ));
    expect(
        await transfer.undoChecklist('source', result!.addedTodoIds), isTrue);
    final undone = (await repository.getNote('source')).toDomain();
    expect(undone.description, 'Newer edited prose');
    expect(undone.tags, ['new-tag']);
    expect(undone.isArchived, isTrue);
    expect(undone.todo, [
      Todo(id: 'old', title: 'Updated task', completed: true),
      Todo(id: 'later', title: 'Later unrelated task'),
    ]);
    expect(store.drafts, isEmpty);
    final savesBeforeRetry = store.saves.length;
    final draftWritesBeforeRetry = store.draftWrites.length;
    expect(await transfer.undoChecklist('source', result.addedTodoIds), isTrue);
    expect(store.saves.length, savesBeforeRetry);
    expect(store.draftWrites.length, draftWritesBeforeRetry);
    expect((await repository.getNote('source')).toDomain(), undone);
  });

  test('checklist Undo retries recoverable removal after a failed save',
      () async {
    repository.notes['source'] =
        NoteDto.fromNote(Note(id: 'source', description: 'Selected prose'));
    final result = await transfer.addToChecklist(
        'source', NoteTextSelection(text: 'Coffee'));
    store.failSave = true;
    expect(
        await transfer.undoChecklist('source', result!.addedTodoIds), isFalse);
    expect((await repository.getNote('source')).toDomain().todo, hasLength(1));
    expect(store.drafts['source']!.todo, isEmpty);
    expect(store.drafts['source']!.description, 'Selected prose');
    store.failSave = false;
    expect(await transfer.undoChecklist('source', result.addedTodoIds), isTrue);
    expect((await repository.getNote('source')).toDomain().todo, isEmpty);
    expect((await repository.getNote('source')).description, 'Selected prose');
    expect(store.drafts, isEmpty);
  });

  test(
      'concurrent checklist add Undo and copy writes share one serialized queue',
      () async {
    repository.notes['source'] = NoteDto.fromNote(Note(
      id: 'source',
      description: 'Selected prose',
      todo: [
        Todo(id: 'old', title: 'Existing task'),
        Todo(id: 'prior-added', title: 'Earlier added task'),
      ],
    ));
    final firstSaveStarted = Completer<void>();
    final releaseFirstSave = Completer<void>();
    var inFlight = 0;
    var maximumInFlight = 0;
    var saveEntries = 0;
    store.beforeSave = (_) async {
      inFlight++;
      saveEntries++;
      if (inFlight > maximumInFlight) maximumInFlight = inFlight;
      if (saveEntries == 1) {
        firstSaveStarted.complete();
        await releaseFirstSave.future;
      }
      inFlight--;
    };
    final first =
        transfer.addToChecklist('source', NoteTextSelection(text: 'Coffee'));
    await firstSaveStarted.future;
    final undo = transfer.undoChecklist('source', ['prior-added']);
    final second =
        transfer.addToChecklist('source', NoteTextSelection(text: 'Tea'));
    final copy = transfer.copyToExisting(
        'source', NoteTextSelection(text: 'Copied prose'));
    await Future<void>.delayed(Duration.zero);
    final entriesWhileBlocked = saveEntries;
    final savesWhileBlocked = store.saves.length;
    releaseFirstSave.complete();
    final firstResult = await first;
    final undoResult = await undo;
    final secondResult = await second;
    final copyResult = await copy;
    expect(entriesWhileBlocked, 1);
    expect(savesWhileBlocked, 0);
    expect(firstResult!.status, NoteSelectionChecklistStatus.ready);
    expect(undoResult, isTrue);
    expect(secondResult!.status, NoteSelectionChecklistStatus.ready);
    expect(copyResult, isTrue);
    final saved = (await repository.getNote('source')).toDomain();
    expect(saved.description, 'Selected prose\n\nCopied prose');
    expect(saved.todo.map((todo) => todo.title),
        ['Existing task', 'Coffee', 'Tea']);
    expect(saved.todo.map((todo) => todo.id).toSet(), hasLength(3));
    expect(store.saves, hasLength(4));
    expect(maximumInFlight, 1);
    expect(store.drafts, isEmpty);
  });
}
