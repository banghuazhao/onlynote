import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/backup/backup_service.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/custom_note_template_store.dart';

import '../support/memory_preferences.dart';

class BoxRepository implements NoteRepository {
  BoxRepository(this.box);
  final Box box;
  @override
  List<NoteDto> getAllNotes() => box.values.cast<NoteDto>().toList();
  @override
  Future<NoteDto> getNote(String id) async => box.get(id) as NoteDto;
  @override
  Future addUpdateNote(NoteDto note) => box.put(note.id, note);
  @override
  Future deleteNote(String id) => box.delete(id);
  @override
  Future deleteMultiNotes(List<String> ids) => box.deleteAll(ids);
}

void main() {
  late Directory directory;
  late Box notes, folders, journal, drafts;
  late BackupService service;
  late List<Reminder> reminders;
  late CustomNoteTemplateStore templates;
  var failWrite = false;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-backup-test-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FolderDtoAdapter());
    notes = await Hive.openBox('notes');
    folders = await Hive.openBox('folders');
    journal = await Hive.openBox('journal');
    drafts = await Hive.openBox('drafts');
    reminders = [];
    failWrite = false;
    templates = CustomNoteTemplateStore(
      preferences: MemoryPreferences(),
      documentsPath: directory.path,
    );
    service = BackupService(
        notes: notes,
        folders: folders,
        journal: journal,
        documents: directory,
        templateStore: templates,
        readReminders: () => reminders,
        writeReminders: (values) async {
          if (failWrite) {
            failWrite = false;
            throw const FileSystemException('Disk full');
          }
          reminders = values;
        });
  });
  tearDown(() async {
    templates.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> seed() async {
    await Directory('${directory.path}/note_images').create();
    await File('${directory.path}/note_images/a.png')
        .writeAsBytes([1, 2, 3, 4]);
    await folders.put(
        'folder', FolderDto(id: 'folder', name: 'Ideas', sortOrder: 5));
    await notes.put(
        'original',
        NoteDto(
            id: 'original',
            title: 'Keep me',
            description: '正文',
            colorValue: 0xffffcc00,
            dateTime: '2026-09-13T10:00:00.000',
            isPinned: true,
            sortOrder: -4,
            folderId: 'folder',
            imagePaths: ['note_images/a.png'],
            todoList: [TodoDto(id: 'todo', title: 'Read', completed: true)]));
    await notes.put(
        'trash',
        NoteDto(
            id: 'trash',
            title: 'In trash',
            deletedAt: '2026-09-12T09:00:00.000'));
    reminders = [
      Reminder(
          noteId: 'original',
          reminderId: 1,
          reminderDate: DateTime(2027, 1, 1, 9))
    ];
  }

  test(
      'roundtrip includes photos, checklists, trash, folders and reminder dates',
      () async {
    await seed();
    final backup = decodeBackup(await service.export());
    expect(backup.notes, hasLength(2));
    expect(backup.photos.values.single.bytes, [1, 2, 3, 4]);
    final restored = await service.restore(backup);
    expect(notes.length, 4);
    expect(folders.length, 2);
    expect((notes.get('original') as NoteDto).title, 'Keep me');
    final copy = notes.values
        .cast<NoteDto>()
        .singleWhere((n) => n.id != 'original' && n.title == 'Keep me');
    expect(copy.folderId, isNot('folder'));
    expect(copy.isPinned, isTrue);
    expect(copy.sortOrder, -4);
    expect(copy.todoList!.single.completed, isTrue);
    expect(copy.description, '正文');
    expect(copy.imagePaths, isNot(['note_images/a.png']));
    expect(
        await File('${directory.path}/${copy.imagePaths!.single}')
            .readAsBytes(),
        [1, 2, 3, 4]);
    expect(restored.single.noteId, copy.id);
    expect(restored.single.reminderDate, DateTime(2027, 1, 1, 9));
    expect(restored.single.repeat, ReminderRepeat.none);
    expect(restored.single.reminderId, isNot(1));
    expect(journal.isEmpty, isTrue);
  });

  test('custom templates and their independent photos survive backup restore',
      () async {
    await seed();
    final original = await templates.saveFromNote(
      (notes.get('original') as NoteDto).toDomain(),
      name: 'Weekly list',
    );
    final backup = decodeBackup(await service.export());
    expect(backup.toJson()['version'], 2);
    expect(backup.templates.single.name, 'Weekly list');
    expect(backup.templates.single.items, ['Read']);
    await service.restore(backup);
    final restored =
        templates.templates.singleWhere((t) => t.id != original.id);
    expect(restored.title, original.title);
    expect(restored.body, original.body);
    expect(restored.color, original.color);
    expect(restored.imagePaths, isNot(original.imagePaths));
    expect(
        await File('${directory.path}/${restored.imagePaths.single}')
            .readAsBytes(),
        [1, 2, 3, 4]);
    await templates.delete(original.id);
    final freshNote = await templates.createNote(restored.id);
    expect(freshNote.todo.single.completed, isFalse);
    expect(freshNote.imagePaths.single, startsWith('note_images/'));
    expect(
        await File('${directory.path}/${freshNote.imagePaths.single}').exists(),
        isTrue);
    expect(await File('${directory.path}/note_images/a.png').exists(), isTrue);
  });

  test('failed restore rolls back imported templates and photos only',
      () async {
    await seed();
    final original = await templates.saveFromNote(
      (notes.get('original') as NoteDto).toDomain(),
      name: 'Keep my template',
    );
    final backup = decodeBackup(await service.export());
    failWrite = true;
    await expectLater(
        service.restore(backup), throwsA(isA<FileSystemException>()));
    expect(templates.templates.single.id, original.id);
    expect(notes.length, 2);
    expect(folders.length, 1);
    expect(journal.isEmpty, isTrue);
    final photos = await Directory('${directory.path}/template_images')
        .list()
        .where((file) => file is File)
        .toList();
    expect(photos, hasLength(1));
    expect(
        photos.single.path, '${directory.path}/${original.imagePaths.single}');
  });

  test('v1 loads without templates; v2 requires valid template metadata',
      () async {
    await seed();
    final json = decodeBackup(await service.export()).toJson();
    final legacy = {...json, 'version': 1}..remove('templates');
    expect(BackupContents.fromJson(legacy).templates, isEmpty);
    final missing = {...json}..remove('templates');
    expect(() => BackupContents.fromJson(missing), throwsFormatException);
    expect(() => BackupContents.fromJson({...json, 'templates': null}),
        throwsFormatException);
    final template = await templates.saveFromNote(
        (notes.get('original') as NoteDto).toDomain(),
        name: 'Photo template');
    expect(
        () => BackupContents.fromJson({
              ...json,
              'templates': [
                {
                  ...template.toJson(),
                  'imagePaths': ['missing-photo']
                }
              ],
            }),
        throwsFormatException);
  });

  test('backup and restore retain daily and weekly past reminder anchors',
      () async {
    await seed();
    final anchor = DateTime(2020, 1, 6, 9, 30);
    reminders = [
      Reminder(
          noteId: 'original',
          reminderId: 1,
          reminderDate: anchor,
          repeat: ReminderRepeat.daily),
      Reminder(
          noteId: 'trash',
          reminderId: 2,
          reminderDate: anchor,
          repeat: ReminderRepeat.weekly),
    ];
    final backup = decodeBackup(await service.export());
    expect(backup.reminders.map((r) => r.repeat),
        [ReminderRepeat.daily, ReminderRepeat.weekly]);
    expect(backup.reminders.every((r) => r.date == anchor), isTrue);
    expect(
        backup.reminders.every((r) => r.isSchedulable(DateTime.now())), isTrue);

    final restored = await service.restore(backup);
    expect(restored.map((r) => r.repeat),
        [ReminderRepeat.daily, ReminderRepeat.weekly]);
    expect(restored.every((r) => r.reminderDate == anchor), isTrue);
    expect(restored.every((r) => r.isSchedulable(DateTime.now())), isTrue);
    expect(
        restored
            .map((r) => r.noteId)
            .toSet()
            .intersection({'original', 'trash'}),
        isEmpty);
    expect((notes.get(restored.last.noteId) as NoteDto).isDeleted, isTrue);
    expect(journal.isEmpty, isTrue);
  });

  test('version 1 backups without repeat restore as one-time reminders',
      () async {
    await seed();
    final json = decodeBackup(await service.export()).toJson();
    json['version'] = 1;
    json.remove('templates');
    for (final reminder in json['reminders'] as List) {
      (reminder as Map<String, dynamic>).remove('repeat');
      reminder['date'] = DateTime(2020).toIso8601String();
    }
    final backup = BackupContents.fromJson(json);
    expect(backup.reminders.single.repeat, ReminderRepeat.none);
    expect(backup.reminders.single.isSchedulable(DateTime.now()), isFalse);
    final restored = await service.restore(backup);
    expect(restored.single.repeat, ReminderRepeat.none);
    expect(restored.single.isSchedulable(DateTime.now()), isFalse);
  });

  test('failed restore rolls back only the newly created data', () async {
    await seed();
    final backup = decodeBackup(await service.export());
    failWrite = true;
    await expectLater(
        service.restore(backup), throwsA(isA<FileSystemException>()));
    expect(notes.keys.toSet(), {'original', 'trash'});
    expect(folders.keys, ['folder']);
    expect(reminders.single.noteId, 'original');
    expect(await Directory('${directory.path}/note_images').list().length, 1);
    expect(journal.isEmpty, isTrue);
  });

  test('startup rolls back an interrupted import from its journal', () async {
    await seed();
    await notes.put('partial', NoteDto(id: 'partial', title: 'Partial import'));
    await folders.put(
        'partial-folder', FolderDto(id: 'partial-folder', name: 'Partial'));
    await File('${directory.path}/note_images/partial.png').writeAsBytes([9]);
    await journal.put('pending', {
      'notes': ['partial'],
      'folders': ['partial-folder'],
      'photos': ['note_images/partial.png']
    });
    await service.recoverInterruptedRestore();
    expect(notes.keys.toSet(), {'original', 'trash'});
    expect(folders.keys, ['folder']);
    expect(await File('${directory.path}/note_images/partial.png').exists(),
        isFalse);
  });

  test('recovery replays an unfinished edit including its photos', () async {
    await seed();
    final pending = Note(
        id: 'original', title: 'Recovered', imagePaths: ['note_images/a.png']);
    final store = HiveNoteAutosaveStore(BoxRepository(notes), drafts);
    await store.writeDraft(pending);
    await store.recover();
    expect((notes.get('original') as NoteDto).title, 'Recovered');
    expect(
        (notes.get('original') as NoteDto).imagePaths, ['note_images/a.png']);
    expect(drafts.isEmpty, isTrue);
  });

  test('missing source photos fail export rather than silently omitting them',
      () async {
    await seed();
    await File('${directory.path}/note_images/a.png').delete();
    await expectLater(service.export(), throwsA(isA<FileSystemException>()));
  });

  test(
      'invalid backup references, versions and paths are rejected before import',
      () async {
    await seed();
    final original = (decodeBackup(await service.export())).toJson();
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (m) => m['version'] = 99,
      (m) => (m['notes'] as List).first['photos'] = ['missing'],
      (m) => (m['notes'] as List).first['folderId'] = 'missing',
      (m) => (m['photos'] as Map).values.first['extension'] = '../outside',
      (m) => (m['notes'] as List).add((m['notes'] as List).first),
      (m) => (m['reminders'] as List).first['repeat'] = 'monthly',
      (m) => (m['reminders'] as List).first['repeat'] = 1,
      (m) => (m['reminders'] as List).first['repeat'] = null,
    ]) {
      final changed = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      mutation(changed);
      expect(
          () => decodeBackup(
              Uint8List.fromList(utf8.encode(jsonEncode(changed)))),
          throwsFormatException);
    }
    expect(notes.length, 2);
  });
}
