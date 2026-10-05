import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/custom_note_template_store.dart';

import '../support/memory_preferences.dart';

// Changes write availability between calls to exercise recovery behavior.
// ignore: must_be_immutable
class _Preferences extends MemoryPreferences {
  bool failWrites = false;
  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('Storage unavailable');
    await super.setString(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());
  late Directory documents;
  late _Preferences preferences;
  late CustomNoteTemplateStore store;
  setUp(() async {
    documents = await Directory.systemTemp.createTemp('onlynote_templates_');
    preferences = _Preferences();
    store = CustomNoteTemplateStore(
        preferences: preferences, documentsPath: documents.path);
  });
  tearDown(() async {
    store.dispose();
    await documents.delete(recursive: true);
  });

  Future<File> sourcePhoto() async {
    final file = File('${documents.path}/note_images/source.jpg');
    await file.parent.create(recursive: true);
    return file.writeAsBytes([1, 2, 3, 4], flush: true);
  }

  test(
      'save, restart and reuse preserves content with independent photos and IDs',
      () async {
    final source = await sourcePhoto();
    final note = Note(
      id: 'source-note',
      title: 'Trip',
      description: 'Travel notes',
      color: const Color(0xffd3ede4),
      folderId: 'old-folder',
      isPinned: true,
      imagePaths: ['note_images/source.jpg'],
      todo: [Todo(id: 'source-task', title: 'Passport', completed: true)],
    );
    final template = await store.saveFromNote(note, name: 'Packing routine');
    expect(template.name, 'Packing routine');
    expect(template.title, 'Trip');
    expect(template.imagePaths.single, startsWith('template_images/'));
    final templatePhoto =
        File('${documents.path}/${template.imagePaths.single}');
    expect(await templatePhoto.readAsBytes(), [1, 2, 3, 4]);
    await source.delete();

    final restarted = CustomNoteTemplateStore(
        preferences: preferences, documentsPath: documents.path);
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.templates.single.toJson(), template.toJson());
    final first =
        await restarted.createNote(template.id, folderId: 'new-folder');
    final second =
        await restarted.createNote(template.id, folderId: 'new-folder');
    expect(first.id, isNot(second.id));
    expect(first.id, isNot(note.id));
    expect(first.title, 'Trip');
    expect(first.description, 'Travel notes');
    expect(first.color, note.color);
    expect(first.folderId, 'new-folder');
    expect(first.isPinned, isFalse);
    expect(first.todo.single.completed, isFalse);
    expect(first.todo.single.id, isNot(second.todo.single.id));
    expect(first.todo.single.id, isNot('source-task'));
    expect(first.imagePaths.single, startsWith('note_images/'));
    expect(first.imagePaths.single, isNot(second.imagePaths.single));
    expect(first.imagePaths.single, isNot('note_images/source.jpg'));
    expect(
        await File('${documents.path}/${first.imagePaths.single}')
            .readAsBytes(),
        [1, 2, 3, 4]);

    await restarted.rename(template.id, 'Holiday packing');
    expect(restarted.templates.single.name, 'Holiday packing');
    expect(restarted.templates.single.title, 'Trip');
    await restarted.delete(template.id);
    expect(await templatePhoto.exists(), isFalse);
    expect(await File('${documents.path}/${first.imagePaths.single}').exists(),
        isTrue);
    expect(await File('${documents.path}/${second.imagePaths.single}').exists(),
        isTrue);
  });

  test('failed persistence rolls back copied template photos and retains data',
      () async {
    await sourcePhoto();
    final original =
        await store.saveFromNote(Note(title: 'Original'), name: 'Original');
    final saved = preferences.values[CustomNoteTemplateStore.storageKey];
    preferences.failWrites = true;
    await expectLater(
      store.saveFromNote(
          Note(title: 'New', imagePaths: ['note_images/source.jpg']),
          name: 'New'),
      throwsStateError,
    );
    expect(store.templates.single.id, original.id);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
    final photos =
        await Directory('${documents.path}/template_images').list().toList();
    expect(photos, isEmpty);
    await expectLater(store.rename(original.id, 'Renamed'), throwsStateError);
    await expectLater(store.delete(original.id), throwsStateError);
    expect(store.templates.single.name, 'Original');
  });

  test('missing photo fails the whole capture and removes partial copies',
      () async {
    await sourcePhoto();
    await expectLater(
      store.saveFromNote(
          Note(imagePaths: [
            'note_images/source.jpg',
            'note_images/missing.jpg'
          ]),
          name: 'Photos'),
      throwsA(isA<FileSystemException>()),
    );
    expect(store.templates, isEmpty);
    expect(preferences.values, isEmpty);
    expect(await Directory('${documents.path}/template_images').list().toList(),
        isEmpty);
  });

  test('unreadable or unsafe storage blocks mutations and deletes no files',
      () async {
    final source = await sourcePhoto();
    final record = CustomNoteTemplate(
      id: 'unsafe',
      name: 'Unsafe',
      createdAt: DateTime(2026),
      imagePaths: ['../note_images/source.jpg'],
    );
    final unreadable = jsonEncode({
      'version': 1,
      'templates': [record.toJson()]
    });
    preferences.values[CustomNoteTemplateStore.storageKey] = unreadable;
    await expectLater(store.load(), throwsFormatException);
    await expectLater(store.saveFromNote(Note(title: 'Keep'), name: 'Keep'),
        throwsFormatException);
    await expectLater(store.deleteTemplates({'unsafe'}), throwsFormatException);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], unreadable);
    expect(await source.exists(), isTrue);
  });

  test(
      'backup import preserves staged IDs/photos and recovery deletes only imports',
      () async {
    final path = 'template_images/restored.jpg';
    final staged = File('${documents.path}/$path');
    await staged.parent.create(recursive: true);
    await staged.writeAsBytes([7, 8]);
    final imported = CustomNoteTemplate(
        id: 'restored',
        name: 'Restored',
        imagePaths: [path],
        createdAt: DateTime(2026));
    await store.importTemplates([imported]);
    expect(store.templates.single.toJson(), imported.toJson());
    expect(await staged.exists(), isTrue);
    final retained =
        await store.saveFromNote(Note(title: 'Keep'), name: 'Keep');
    await store.deleteTemplates({'restored'});
    expect(store.templates.single.id, retained.id);
    expect(await staged.exists(), isFalse);
  });

  test('concurrent saves serialize instead of dropping either template',
      () async {
    await Future.wait([
      store.saveFromNote(Note(title: 'One'), name: 'One'),
      store.saveFromNote(Note(title: 'Two'), name: 'Two'),
    ]);
    expect(store.templates.map((template) => template.name), ['One', 'Two']);
    final readback = CustomNoteTemplateStore(
        preferences: preferences, documentsPath: documents.path);
    addTearDown(readback.dispose);
    await readback.load();
    expect(readback.templates, hasLength(2));
  });
}
