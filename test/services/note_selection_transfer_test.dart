import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_selection.dart';
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
  bool failSave = false;
  @override
  Future<void> writeDraft(Note note) async => drafts[note.id!] = note;
  @override
  Future<void> removeDraft(String id) async => drafts.remove(id);
  @override
  Future<void> saveNote(Note note) async {
    if (failSave) throw StateError('disk unavailable');
    await repository.addUpdateNote(NoteDto.fromNote(note));
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
}
