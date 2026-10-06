import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_links.dart';

class _FieldsReader extends Fake implements BinaryReader {
  _FieldsReader(Map<int, dynamic> fields)
      : bytes = [fields.length, ...fields.keys],
        values = fields.values.toList();
  final List<int> bytes;
  final List<dynamic> values;
  int byte = 0;
  int value = 0;
  @override
  int readByte() => bytes[byte++];
  @override
  dynamic read([int? typeId]) => values[value++];
}

void main() {
  test('links preserve selection order, remove duplicates, and exclude self',
      () {
    final links = normalizeLinkedNoteIds(
        ['research', 'current', 'packing', 'research', 'packing'],
        noteId: 'current');
    expect(links, ['research', 'packing']);
    expect(() => links.add('other'), throwsUnsupportedError);
  });

  test('invalid and oversized link lists cannot be stored', () {
    expect(() => normalizeLinkedNoteIds(['']), throwsFormatException);
    expect(() => normalizeLinkedNoteIds(['a' * 513]), throwsFormatException);
    expect(
        () => normalizeLinkedNoteIds(
            [for (var index = 0; index <= maxLinkedNotes; index++) '$index']),
        throwsFormatException);
    final exactly100 = [
      for (var index = 0; index < maxLinkedNotes; index++) 'note-$index'
    ];
    expect(
        normalizeLinkedNoteIds([...exactly100, exactly100.first]), exactly100);
  });

  test('backlinks include archived sources and exclude trash and self', () {
    final target = Note(id: 'target', linkedNoteIds: const ['target']);
    final active = Note(id: 'active', linkedNoteIds: const ['target']);
    final archived =
        Note(id: 'archived', isArchived: true, linkedNoteIds: const ['target']);
    final trash = Note(
        id: 'trash',
        deletedAt: DateTime(2026),
        linkedNoteIds: const ['target']);
    expect(
        noteBacklinks(target, [target, active, archived, trash, Note(id: 'x')]),
        [active, archived]);
    expect(noteBacklinks(Note(), [active, archived]), isEmpty);
  });

  test('link resolution opens archived notes while trash stays unavailable',
      () {
    final archived = Note(id: 'archived', isArchived: true);
    final trash = Note(id: 'trash', deletedAt: DateTime(2026));
    expect(availableLinkedNote('archived', [archived, trash]), archived);
    expect(availableLinkedNote('trash', [archived, trash]), isNull);
    expect(availableLinkedNote('missing', [archived, trash]), isNull);
  });

  test('legacy Hive fields retain metadata and default archive, tags and links',
      () {
    final memo = VoiceMemo(
        id: 'memo',
        path: 'note_audio/memo.m4a',
        durationMs: 5000,
        createdAt: DateTime.utc(2026, 10, 6));
    final note = NoteDtoAdapter()
        .read(_FieldsReader({
          0: 'legacy',
          1: 'Old note',
          2: 'Original body',
          5: [TodoDto(id: 'task', title: 'Keep task', completed: true)],
          6: <String>[],
          8: true,
          10: 'folder',
          11: [memo.toMap()],
        }))
        .toDomain();
    expect(note.id, 'legacy');
    expect(note.title, 'Old note');
    expect(note.description, 'Original body');
    expect(note.isPinned, isTrue);
    expect(note.folderId, 'folder');
    expect(note.todo.single.completed, isTrue);
    expect(note.voiceMemos, [memo]);
    expect(note.isArchived, isFalse);
    expect(note.tags, isEmpty);
    expect(note.linkedNoteIds, isEmpty);
  });

  test('new Hive fields survive a read alongside existing note metadata', () {
    final dto = NoteDtoAdapter().read(_FieldsReader({
      0: 'note',
      8: true,
      10: 'folder',
      12: true,
      13: ['Work', 'Travel'],
      14: ['linked'],
    }));
    final note = dto.toDomain();
    expect(note.isArchived, isTrue);
    expect(note.tags, ['Work', 'Travel']);
    expect(note.linkedNoteIds, ['linked']);
    expect(note.isPinned, isTrue);
    expect(note.folderId, 'folder');
    final copied = dto.copyWith(title: 'New title').toDomain();
    expect(copied.isArchived, isTrue);
    expect(copied.tags, note.tags);
    expect(copied.linkedNoteIds, note.linkedNoteIds);
  });
}
