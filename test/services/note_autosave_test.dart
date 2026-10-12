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

  test('clean editor adopts child route changes before subsequent typing',
      () async {
    final fresh = initial.copyWith(
        title: 'Changed elsewhere',
        isArchived: true,
        tags: ['Project'],
        linkedNoteIds: ['reference']);
    expect(autosave.adoptSavedNote(fresh), isTrue);
    expect(autosave.dirty, isFalse);
    expect(store.saves, isEmpty);
    autosave.update(autosave.note.copyWith(description: 'More detail'));
    expect(await autosave.flush(), isTrue);
    expect(store.notes['one']!.isArchived, isTrue);
    expect(store.notes['one']!.tags, ['Project']);
    expect(store.notes['one']!.linkedNoteIds, ['reference']);
  });

  test('adopting child state cannot replace pending or in-flight typing',
      () async {
    autosave.update(initial.copyWith(title: 'Pending'));
    expect(
        autosave.adoptSavedNote(initial.copyWith(title: 'External')), isFalse);
    store.pauseSave = Completer<void>();
    final pending = autosave.flush();
    await Future<void>.delayed(Duration.zero);
    expect(
        autosave.adoptSavedNote(initial.copyWith(title: 'External')), isFalse);
    store.pauseSave!.complete();
    expect(await pending, isTrue);
    expect(autosave.note.title, 'Pending');
    expect(autosave.adoptSavedNote(initial.copyWith(id: 'another')), isFalse);
  });

  test('seeded content is journaled and saved without fabricated edits',
      () async {
    final timestamp = DateTime(2026, 10, 5, 9, 30);
    final note = initial.copyWith(
      title: 'Packing list',
      dateTime: timestamp,
      todo: [Todo(id: 'passport', title: 'Travel documents')],
    );
    final seeded = NoteAutosave(
      store: store,
      initial: note,
      exists: false,
      delay: const Duration(days: 1),
    );
    addTearDown(seeded.dispose);
    seeded.saveInitial();
    seeded.saveInitial();
    await Future<void>.delayed(Duration.zero);
    expect(store.drafts['one'], note);
    expect(store.notes, isEmpty);
    expect(seeded.dirty, isTrue);
    expect(await seeded.flush(), isTrue);
    expect(store.notes['one'], note);
    expect(store.notes['one']!.dateTime, timestamp);
    expect(store.saves, hasLength(1));
    expect(store.drafts, isEmpty);

    seeded.saveInitial();
    await seeded.flush();
    expect(store.saves, hasLength(1));
  });

  test('saveInitial skips empty notes and existing notes', () async {
    autosave.saveInitial();
    await autosave.flush();
    expect(store.drafts, isEmpty);
    expect(store.saves, isEmpty);
    final existing = NoteAutosave(
      store: store,
      initial: initial.copyWith(title: 'Already saved'),
      exists: true,
    );
    addTearDown(existing.dispose);
    existing.saveInitial();
    await existing.flush();
    expect(store.drafts, isEmpty);
    expect(store.saves, isEmpty);
  });

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

  testWidgets('debounce saves typing automatically', (tester) async {
    final automatic = NoteAutosave(
        store: store,
        initial: initial,
        exists: false,
        delay: const Duration(milliseconds: 10));
    addTearDown(automatic.dispose);
    automatic.update(initial.copyWith(title: 'A'));
    await tester.pump(const Duration(milliseconds: 9));
    expect(store.saves, isEmpty);
    automatic.update(initial.copyWith(title: 'AB'));
    await tester.pump(const Duration(milliseconds: 9));
    expect(store.saves, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(store.notes['one']?.title, 'AB');
    expect(store.saves, hasLength(1));
    expect(store.drafts, isEmpty);
    expect(automatic.status, AutosaveStatus.saved);
  });
}
