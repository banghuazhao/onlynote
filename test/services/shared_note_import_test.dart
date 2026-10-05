import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/shared_note_import.dart';

class SharedTestNotes implements NoteRepository {
  final saved = <String, NoteDto>{};
  bool failSave = false;
  int writes = 0;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    if (failSave) throw StateError('Disk unavailable');
    saved[note.id!] = note;
  }

  @override
  List<NoteDto> getAllNotes() => saved.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => saved[id]!;
  @override
  Future<void> deleteNote(String id) async => saved.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      saved.remove(id);
    }
  }
}

const sharedId = '5c9e12d2-8b04-44c1-903b-c4a38174e722';
const secondSharedId = '6c9e12d2-8b04-44c1-903b-c4a38174e722';

void main() {
  late Directory directory;
  late Box journal;
  late SharedTestNotes notes;
  late List<String> acknowledged;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-share-import-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    journal = await Hive.openBox('share_import_test');
    notes = SharedTestNotes();
    acknowledged = [];
  });
  tearDown(() async {
    await journal.close();
    await directory.delete(recursive: true);
  });
  Future<void> acknowledge(String id) async => acknowledged.add(id);

  test('text and URL preserve exact content with a stable imported note ID',
      () async {
    final importer = SharedNoteImport(journal: journal, notes: notes);
    final payload = SharedNotePayload.parse({
      'version': 1,
      'id': sharedId,
      'title': 'Recipe',
      'text': 'Bake for 20 minutes\n\nhttps://example.com/recipe',
      'images': <String>[],
    })!;
    final result = await importer.import(payload, acknowledge: acknowledge);
    expect(result!.id, 'share-$sharedId');
    expect(result.title, 'Recipe');
    expect(result.description,
        'Bake for 20 minutes\n\nhttps://example.com/recipe');
    expect(acknowledged, [sharedId]);
    expect(importer.hasPendingImports, isFalse);
    expect(notes.writes, 1);
  });

  test('photos are copied and journaled before native attachment deletion',
      () async {
    final importer = SharedNoteImport(
        journal: journal,
        notes: notes,
        copyImage: (file, id, index) async {
          expect(journal.isNotEmpty, isTrue);
          return 'note_images/shared-$index.jpg';
        });
    final result = await importer.import(
      const SharedNotePayload(
          id: sharedId,
          images: ['/tmp/inbox/first.jpg', '/tmp/inbox/second.jpg']),
      acknowledge: (id) async {
        expect(notes.saved['share-$id']!.imagePaths,
            ['note_images/shared-0.jpg', 'note_images/shared-1.jpg']);
        expect(journal.isNotEmpty, isTrue);
        acknowledged.add(id);
      },
    );
    expect(result!.imagePaths,
        ['note_images/shared-0.jpg', 'note_images/shared-1.jpg']);
    expect(acknowledged, [sharedId]);
  });

  test('duplicate delivery preserves subsequent edits without a second write',
      () async {
    final importer = SharedNoteImport(journal: journal, notes: notes);
    const payload = SharedNotePayload(id: sharedId, text: 'Shared original');
    final note = await importer.import(payload, acknowledge: acknowledge);
    notes.saved[note!.id!] = NoteDto.fromNote(note.copyWith(title: 'Edited'));
    final repeated = await importer.import(payload, acknowledge: acknowledge);
    expect(notes.saved.length, 1);
    expect(notes.writes, 1);
    expect(repeated!.title, 'Edited');
  });

  test('attachment failure retains source and completed copies for recovery',
      () async {
    final copied = <int>[];
    var failing = true;
    final importer = SharedNoteImport(
        journal: journal,
        notes: notes,
        copyImage: (file, id, index) async {
          copied.add(index);
          if (index == 1 && failing) throw const FileSystemException('Full');
          return 'note_images/shared-$index.jpg';
        });
    const payload = SharedNotePayload(
        id: sharedId, images: ['/tmp/first.jpg', '/tmp/second.jpg']);
    await expectLater(importer.import(payload, acknowledge: acknowledge),
        throwsA(isA<FileSystemException>()));
    expect(notes.saved, isEmpty);
    expect(acknowledged, isEmpty);
    expect(importer.hasPendingImports, isTrue);
    failing = false;
    final recovered = await importer.recover(acknowledge: acknowledge);
    expect(copied, [0, 1, 1]);
    expect(recovered.single.imagePaths.length, 2);
    expect(importer.hasPendingImports, isFalse);
  });

  test('failed note write retains durable photos without acknowledging inbox',
      () async {
    var copies = 0;
    notes.failSave = true;
    final importer = SharedNoteImport(
        journal: journal,
        notes: notes,
        copyImage: (_, id, index) async {
          copies++;
          return 'note_images/shared-$index.jpg';
        });
    const payload =
        SharedNotePayload(id: sharedId, images: ['/tmp/source.jpg']);
    await expectLater(
        importer.import(payload, acknowledge: acknowledge), throwsStateError);
    expect(acknowledged, isEmpty);
    expect(importer.hasPendingImports, isTrue);
    notes.failSave = false;
    await importer.recover(acknowledge: acknowledge);
    expect(copies, 1);
    expect(notes.saved.length, 1);
  });

  test('failed native acknowledgement retries without reverting edited content',
      () async {
    final importer = SharedNoteImport(journal: journal, notes: notes);
    await expectLater(
        importer.import(const SharedNotePayload(id: sharedId, text: 'Original'),
            acknowledge: (_) async => throw StateError('Native disk busy')),
        throwsStateError);
    expect(notes.saved.length, 1);
    expect(importer.hasPendingImports, isTrue);
    final note = notes.saved.values.single.toDomain();
    notes.saved[note.id!] = NoteDto.fromNote(note.copyWith(title: 'Latest'));
    final recovered = await importer.recover(acknowledge: acknowledge);
    expect(recovered.single.title, 'Latest');
    expect(notes.writes, 1);
    expect(importer.hasPendingImports, isFalse);
  });

  test('retry does not resurrect a note removed after acknowledgement failed',
      () async {
    final importer = SharedNoteImport(journal: journal, notes: notes);
    await expectLater(
        importer.import(const SharedNotePayload(id: sharedId, text: 'Original'),
            acknowledge: (_) async => throw StateError('Native disk busy')),
        throwsStateError);
    notes.saved.clear();
    final recovered = await importer.recover(acknowledge: acknowledge);
    expect(recovered, isEmpty);
    expect(notes.saved, isEmpty);
    expect(notes.writes, 1);
    expect(acknowledged, [sharedId]);
  });

  test('retry acknowledges a trashed import without reopening it', () async {
    final importer = SharedNoteImport(journal: journal, notes: notes);
    const payload = SharedNotePayload(id: sharedId, text: 'Original');
    final note = await importer.import(payload, acknowledge: acknowledge);
    notes.saved[note!.id!] =
        NoteDto.fromNote(note.copyWith(deletedAt: DateTime.now()));
    expect(await importer.import(payload, acknowledge: acknowledge), isNull);
    expect(notes.saved.values.single.isDeleted, isTrue);
  });

  test('concurrent duplicate deliveries serialize into one note', () async {
    final importer = SharedNoteImport(journal: journal, notes: notes);
    const payload = SharedNotePayload(id: sharedId, text: 'Original');
    await Future.wait([
      importer.import(payload, acknowledge: acknowledge),
      importer.import(payload, acknowledge: acknowledge),
    ]);
    expect(notes.saved.length, 1);
    expect(notes.writes, 1);
  });

  test('invalid delivery limits and paths are rejected before storage', () {
    Map<String, Object> value(
            {String id = sharedId,
            List<String> images = const [],
            String text = 'Text'}) =>
        {
          'version': 1,
          'id': id,
          'title': '',
          'text': text,
          'images': images,
        };
    expect(SharedNotePayload.parse(value(id: '../../other')), isNull);
    expect(SharedNotePayload.parse(value(images: ['/tmp/../private.jpg'])),
        isNull);
    expect(
        SharedNotePayload.parse(value(images: List.filled(11, '/tmp/a.jpg'))),
        isNull);
    expect(SharedNotePayload.parse(value(text: 'a' * 100001)), isNull);
    expect(SharedNotePayload.parse(value(text: ' ')), isNull);
  });

  test('ordinary editor drafts survive imports unchanged', () async {
    await journal.put('active-editor', {'text': 'Keep my unfinished note'});
    final importer = SharedNoteImport(journal: journal, notes: notes);
    await importer.import(const SharedNotePayload(id: sharedId, text: 'Share'),
        acknowledge: acknowledge);
    expect(journal.get('active-editor'), {'text': 'Keep my unfinished note'});
    expect(importer.hasPendingImports, isFalse);
  });

  test('fresh native paths repair an inbox container moved during restore',
      () async {
    final seen = <String>[];
    final importer = SharedNoteImport(
        journal: journal,
        notes: notes,
        copyImage: (file, id, index) async {
          seen.add(file.path);
          if (file.path.contains('/old/')) {
            throw const FileSystemException('Container moved');
          }
          return 'note_images/rebased.jpg';
        });
    await expectLater(
        importer.import(
            const SharedNotePayload(
                id: sharedId, images: ['/old/share/source.jpg']),
            acknowledge: acknowledge),
        throwsA(isA<FileSystemException>()));
    await importer.import(
        const SharedNotePayload(
            id: sharedId, images: ['/current/share/source.jpg']),
        acknowledge: acknowledge);
    expect(seen, ['/old/share/source.jpg', '/current/share/source.jpg']);
    expect(notes.saved.values.single.imagePaths, ['note_images/rebased.jpg']);
    expect(importer.hasPendingImports, isFalse);
  });

  test('long subjects survive in body and persisted titles keep full graphemes',
      () async {
    final importer = SharedNoteImport(journal: journal, notes: notes);
    final asciiSubject = 'A' * 151;
    final ascii = await importer.import(
        SharedNotePayload(
            id: sharedId, title: asciiSubject, text: 'Original body'),
        acknowledge: acknowledge);
    expect(ascii!.title, 'A' * 140);
    expect(ascii.description, '$asciiSubject\n\nOriginal body');
    expect(ascii, notes.saved[ascii.id]!.toDomain());

    final emojiSubject = '${'B' * 139}👨‍👩‍👧‍👦';
    final emoji = await importer.import(
        SharedNotePayload(id: secondSharedId, title: emojiSubject),
        acknowledge: acknowledge);
    expect(emoji!.title, 'B' * 139);
    expect(emoji.description, emojiSubject);
    expect(emoji, notes.saved[emoji.id]!.toDomain());
    expect(acknowledged, [sharedId, secondSharedId]);
  });
}
