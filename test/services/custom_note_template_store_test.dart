import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/audio_storage.dart';
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

  Future<VoiceMemo> sourceAudio() async {
    final file = File('${documents.path}/note_audio/source.m4a');
    await file.parent.create(recursive: true);
    await file.writeAsBytes([4, 5, 6, 7], flush: true);
    return VoiceMemo(
        id: 'original-recording',
        path: 'note_audio/source.m4a',
        durationMs: 42000,
        createdAt: DateTime(2026, 10, 6),
        transcript: 'Meeting notes 会议记录');
  }

  test('photo layouts follow independent copies when a template is reused',
      () async {
    await sourcePhoto();
    const layout = NoteImageLayout(
        path: 'note_images/source.jpg',
        textOffset: 6,
        widthFactor: .45,
        xFactor: 1,
        aspectRatio: 2);
    final template = await store.saveFromNote(
        Note(
            description: 'First\nSecond',
            imagePaths: [layout.path],
            imageLayouts: [layout]),
        name: 'Photo');
    expect(template.imageLayouts.single,
        layout.copyWith(path: template.imagePaths.single));
    final restarted = CustomNoteTemplateStore(
        preferences: preferences, documentsPath: documents.path);
    addTearDown(restarted.dispose);
    await restarted.load();
    final first = await restarted.createNote(template.id);
    final second = await restarted.createNote(template.id);
    expect(first.imagePaths.single, isNot(second.imagePaths.single));
    for (final note in [first, second]) {
      expect(note.imageLayouts.single,
          layout.copyWith(path: note.imagePaths.single));
      expect(
          await File('${documents.path}/${note.imagePaths.single}')
              .readAsBytes(),
          [1, 2, 3, 4]);
    }
  });

  test(
      'legacy templates place their photos after the body and reject bad layouts',
      () {
    final json = CustomNoteTemplate(
            id: 'old',
            name: 'Photo',
            body: 'Body',
            imagePaths: ['template_images/photo.jpg'],
            createdAt: DateTime(2026))
        .toJson()
      ..remove('imageLayouts');
    final template = CustomNoteTemplate.fromJson(json);
    expect(template.imageLayouts.single.textOffset, 4);
    json['imageLayouts'] = [
      NoteImageLayout(path: 'missing.jpg', textOffset: 4).toMap()
    ];
    expect(() => CustomNoteTemplate.fromJson(json), throwsFormatException);
  });

  test('recordings own independent template and reusable note files', () async {
    final memo = await sourceAudio();
    final template =
        await store.saveFromNote(Note(voiceMemos: [memo]), name: 'Meeting');
    final savedMemo = template.voiceMemos.single;
    expect(savedMemo.path, startsWith('template_audio/'));
    expect(savedMemo.id, isNot(memo.id));
    expect(savedMemo.durationMs, memo.durationMs);
    expect(savedMemo.transcript, memo.transcript);
    expect(savedMemo.createdAt, memo.createdAt);
    await File('${documents.path}/${memo.path}').delete();

    final restarted = CustomNoteTemplateStore(
        preferences: preferences,
        audio: AudioStorage(documentsPath: documents.path),
        documentsPath: documents.path);
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.templates.single.voiceMemos, [savedMemo]);
    final first = await restarted.createNote(template.id);
    final second = await restarted.createNote(template.id);
    expect(first.voiceMemos.single.path, startsWith('note_audio/'));
    expect(first.voiceMemos.single.path, isNot(second.voiceMemos.single.path));
    expect(first.voiceMemos.single.id, isNot(second.voiceMemos.single.id));
    expect(first.voiceMemos.single.id, isNot(savedMemo.id));
    expect(first.voiceMemos.single.transcript, memo.transcript);
    await restarted.delete(template.id);
    expect(await File('${documents.path}/${savedMemo.path}').exists(), isFalse);
    for (final note in [first, second]) {
      expect(
          await File('${documents.path}/${note.voiceMemos.single.path}')
              .readAsBytes(),
          [4, 5, 6, 7]);
    }
  });

  test('old templates without recordings still load', () async {
    final old =
        CustomNoteTemplate(id: 'old', name: 'Old', createdAt: DateTime(2026))
            .toJson()
          ..remove('voiceMemos');
    preferences.values[CustomNoteTemplateStore.storageKey] = jsonEncode({
      'version': 1,
      'templates': [old]
    });
    await store.load();
    expect(store.templates.single.voiceMemos, isEmpty);
    expect((await store.createNote('old')).voiceMemos, isEmpty);
  });

  test('formatted templates preserve readable body and styling through reuse',
      () async {
    const body = 'Summary\n• Bring tea\nImportant';
    const styles = [
      NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.highlight),
      NoteTextStyleRange(start: 20, end: 29, kind: NoteTextStyleKind.bold),
    ];
    final template = await store.saveFromNote(
        Note(description: body, textStyles: styles),
        name: 'Meeting');
    final restarted = CustomNoteTemplateStore(
        preferences: preferences, documentsPath: documents.path);
    addTearDown(restarted.dispose);
    await restarted.load();
    expect(restarted.templates.single.body, body);
    expect(restarted.templates.single.textStyles, styles);
    final note = await restarted.createNote(template.id);
    expect(note.description, body);
    expect(note.textStyles, styles);
  });

  test('legacy template body markers are never interpreted as formatting', () {
    final json = CustomNoteTemplate(
            id: 'old',
            name: 'Old',
            body: '# Heading\n**literal**',
            createdAt: DateTime(2026))
        .toJson()
      ..remove('textStyles');
    final template = CustomNoteTemplate.fromJson(json);
    expect(template.textStyles, isEmpty);
    expect(template.createNote(imageCopies: []).description,
        '# Heading\n**literal**');
    json['textStyles'] = [
      {'start': 0, 'end': 1000, 'kind': 'bold'}
    ];
    expect(() => CustomNoteTemplate.fromJson(json), throwsFormatException);
  });

  test('failed persistence removes audio copies and retains original audio',
      () async {
    final memo = await sourceAudio();
    final original =
        await store.saveFromNote(Note(title: 'Keep'), name: 'Keep');
    preferences.failWrites = true;
    await expectLater(store.saveFromNote(Note(voiceMemos: [memo]), name: 'New'),
        throwsStateError);
    expect(store.templates.single.id, original.id);
    expect(await Directory('${documents.path}/template_audio').list().toList(),
        isEmpty);
    expect(await File('${documents.path}/${memo.path}').readAsBytes(),
        [4, 5, 6, 7]);
  });

  test('failed photo capture removes already copied template audio', () async {
    final memo = await sourceAudio();
    await expectLater(
        store.saveFromNote(
            Note(voiceMemos: [memo], imagePaths: ['note_images/missing.jpg']),
            name: 'Missing'),
        throwsA(isA<FileSystemException>()));
    expect(store.templates, isEmpty);
    expect(await Directory('${documents.path}/template_audio').list().toList(),
        isEmpty);
    expect(await File('${documents.path}/${memo.path}').exists(), isTrue);
  });

  test('missing audio rolls back partial capture without saving a template',
      () async {
    final memo = await sourceAudio();
    await expectLater(
        store.saveFromNote(
            Note(voiceMemos: [
              memo,
              memo.copyWith(id: 'missing', path: 'note_audio/missing.m4a')
            ]),
            name: 'Missing'),
        throwsA(isA<FileSystemException>()));
    expect(store.templates, isEmpty);
    expect(await Directory('${documents.path}/template_audio').list().toList(),
        isEmpty);
    expect(preferences.values, isEmpty);
  });

  test('failed reuse removes fresh note audio while preserving template media',
      () async {
    final memo = await sourceAudio();
    await sourcePhoto();
    final template = await store.saveFromNote(
        Note(voiceMemos: [memo], imagePaths: ['note_images/source.jpg']),
        name: 'Keep');
    await File('${documents.path}/${template.imagePaths.single}').delete();
    await expectLater(
        store.createNote(template.id), throwsA(isA<FileSystemException>()));
    final noteAudio =
        await Directory('${documents.path}/note_audio').list().toList();
    expect(
        noteAudio.map((file) => file.path), ['${documents.path}/${memo.path}']);
    expect(
        await File('${documents.path}/${template.voiceMemos.single.path}')
            .readAsBytes(),
        [4, 5, 6, 7]);
    expect(store.templates.single.id, template.id);
  });

  test('unsafe template audio blocks mutation and retains existing files',
      () async {
    final memo = await sourceAudio();
    final record = CustomNoteTemplate(
        id: 'unsafe-audio',
        name: 'Unsafe',
        voiceMemos: [memo],
        createdAt: DateTime(2026));
    final saved = jsonEncode({
      'version': 1,
      'templates': [record.toJson()]
    });
    preferences.values[CustomNoteTemplateStore.storageKey] = saved;
    await expectLater(store.load(), throwsFormatException);
    await expectLater(store.delete('unsafe-audio'), throwsFormatException);
    expect(preferences.values[CustomNoteTemplateStore.storageKey], saved);
    expect(await File('${documents.path}/${memo.path}').exists(), isTrue);
  });

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
