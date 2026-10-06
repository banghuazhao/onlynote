import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_archive.dart';

class _Notes extends Fake implements NoteRepository {
  final saved = <String, NoteDto>{};
  int writes = 0;
  bool fail = false;
  @override
  Future<NoteDto> getNote(String id) async => saved[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (fail) throw StateError('Storage unavailable');
    writes++;
    saved[note.id!] = note;
  }
}

void main() {
  test('archive and undo preserve all note content and metadata', () async {
    final notes = _Notes();
    final original = NoteDto(
        id: 'note',
        title: 'Saved note',
        description: 'Body',
        folderId: 'folder',
        isPinned: true,
        sortOrder: 9,
        dateTime: DateTime.utc(2026).toIso8601String(),
        tags: [
          'Work'
        ],
        linkedNoteIds: [
          'linked'
        ],
        imagePaths: [
          'note_images/photo.jpg'
        ],
        voiceMemos: [
          {'id': 'memo', 'path': 'note_audio/memo.m4a'}
        ],
        todoList: [
          TodoDto(id: 'task', title: 'Task', completed: true)
        ]);
    notes.saved['note'] = original;
    final change = await setNoteArchived(notes, 'note', true);
    expect(change!.previousArchived, isFalse);
    final archived = notes.saved['note']!;
    expect(archived.isArchived, isTrue);
    expect(archived.title, original.title);
    expect(archived.description, original.description);
    expect(archived.dateTime, original.dateTime);
    expect(archived.folderId, 'folder');
    expect(archived.isPinned, isTrue);
    expect(archived.sortOrder, 9);
    expect(archived.tags, ['Work']);
    expect(archived.linkedNoteIds, ['linked']);
    expect(archived.imagePaths, original.imagePaths);
    expect(archived.voiceMemos, original.voiceMemos);
    expect(archived.todoList!.single.completed, isTrue);
    await setNoteArchived(notes, 'note', change.previousArchived);
    expect(notes.saved['note']!.isArchived, isFalse);
  });

  test('already matching archive state performs no mutation', () async {
    final notes = _Notes()..saved['note'] = NoteDto(id: 'note', title: 'Note');
    expect(await setNoteArchived(notes, 'note', false), isNull);
    expect(notes.writes, 0);
  });

  test('trashed and permanently removed notes cannot be archived', () async {
    final notes = _Notes()
      ..saved['note'] = NoteDto(
          id: 'note',
          title: 'Note',
          deletedAt: DateTime.utc(2026).toIso8601String());
    await expectLater(setNoteArchived(notes, 'note', true), throwsStateError);
    await expectLater(
        setNoteArchived(notes, 'missing', true), throwsA(anything));
    expect(notes.writes, 0);
  });

  test('failed archive save leaves stored content visible', () async {
    final notes = _Notes()..saved['note'] = NoteDto(id: 'note', title: 'Note');
    notes.fail = true;
    await expectLater(setNoteArchived(notes, 'note', true), throwsStateError);
    expect(notes.saved['note']!.isArchived, isFalse);
  });
}
