import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_autosave.dart';

class MemoryStore implements NoteAutosaveStore {
  final drafts = <String, Note>{};
  final notes = <String, Note>{};
  final saves = <Note>[];
  Completer<void>? pauseSave;
  bool failSave = false;
  bool failDraft = false;
  @override
  Future<void> writeDraft(Note note) async {
    if (failDraft) throw StateError('Disk full');
    drafts[note.id!] = note;
  }

  @override
  Future<void> removeDraft(String id) async {
    drafts.remove(id);
  }

  @override
  Future<void> saveNote(Note note) async {
    saves.add(note);
    await pauseSave?.future;
    if (failSave) throw StateError('Disk full');
    notes[note.id!] = note;
  }
}

void main() {
  late MemoryStore store;
  late NoteAutosave autosave;
  late Note initial;
  setUp(() {
    store = MemoryStore();
    initial =
        Note(id: 'one', folderId: 'folder', sortOrder: -12, isPinned: true);
    autosave = NoteAutosave(
        store: store,
        initial: initial,
        exists: false,
        delay: const Duration(days: 1));
  });
  tearDown(() => autosave.dispose());

  test('writes recovery draft before committing and preserves note identity',
      () async {
    final edited = initial.copyWith(
        title: 'Ideas',
        imagePaths: ['note_images/a.jpg'],
        todo: [Todo(id: 'todo', title: 'Read', completed: true)]);
    autosave.update(edited);
    await Future<void>.delayed(Duration.zero);
    expect(store.drafts['one'], edited);
    expect(store.notes, isEmpty);
    expect(await autosave.flush(), isTrue);
    expect(store.notes['one'], edited);
    expect(store.drafts, isEmpty);
    expect(autosave.status, AutosaveStatus.saved);
    autosave.update(edited.copyWith(description: 'More ideas'));
    await autosave.flush();
    expect(store.notes.keys, ['one']);
    expect(store.notes['one']!.folderId, 'folder');
    expect(store.notes['one']!.isPinned, isTrue);
  });

  test('newer edits arriving during a save win and retain a recovery draft',
      () async {
    store.pauseSave = Completer<void>();
    autosave.update(initial.copyWith(title: 'First'));
    final flushing = autosave.flush();
    await Future<void>.delayed(Duration.zero);
    autosave.update(initial.copyWith(title: 'Latest'));
    await Future<void>.delayed(Duration.zero);
    expect(store.drafts['one']!.title, 'Latest');
    store.pauseSave!.complete();
    expect(await flushing, isTrue);
    expect(store.notes['one']!.title, 'Latest');
    expect(store.drafts, isEmpty);
  });

  test('failed commit retains recoverable content and allows retry', () async {
    store.failSave = true;
    autosave.update(initial.copyWith(description: 'Do not lose this'));
    expect(await autosave.flush(), isFalse);
    expect(store.drafts['one']!.description, 'Do not lose this');
    expect(autosave.dirty, isTrue);
    expect(autosave.status, AutosaveStatus.failed);
    store.failSave = false;
    expect(await autosave.flush(), isTrue);
    expect(store.notes['one']!.description, 'Do not lose this');
  });

  test('failed draft write never reports a successful save', () async {
    store.failDraft = true;
    autosave.update(initial.copyWith(title: 'New'));
    expect(await autosave.flush(), isFalse);
    expect(store.notes, isEmpty);
    store.failDraft = false;
    expect(await autosave.flush(), isTrue);
  });

  test('blank new notes are skipped but clearing an existing note is saved',
      () async {
    autosave.update(initial.copyWith(title: '   '));
    await autosave.flush();
    expect(store.notes, isEmpty);
    autosave.update(initial.copyWith(title: 'Something'));
    await autosave.flush();
    autosave.update(initial.copyWith(title: ''));
    await autosave.flush();
    expect(store.notes['one']!.title, '');
  });

  test('debounce saves typing automatically', () async {
    final automatic = NoteAutosave(
        store: store,
        initial: initial,
        exists: false,
        delay: const Duration(milliseconds: 10));
    automatic.update(initial.copyWith(title: 'A'));
    automatic.update(initial.copyWith(title: 'AB'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(store.notes['one']!.title, 'AB');
    expect(store.saves, hasLength(1));
    automatic.dispose();
  });
}
