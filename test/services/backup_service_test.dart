import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/backup/backup_service.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/saved_note_views.dart';

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
  late Box notes, folders, journal, drafts, historyBox;
  late NoteHistory history;
  late BackupService service;
  late List<Reminder> reminders;
  late CustomNoteTemplateStore templates;
  late SavedNoteViewStore savedViews;
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
    historyBox = await Hive.openBox('history');
    history = NoteHistory(box: historyBox, repository: BoxRepository(notes));
    reminders = [];
    failWrite = false;
    templates = CustomNoteTemplateStore(
      preferences: MemoryPreferences(),
      documentsPath: directory.path,
    );
    savedViews = SavedNoteViewStore(preferences: MemoryPreferences());
    service = BackupService(
        notes: notes,
        folders: folders,
        journal: journal,
        documents: directory,
        templateStore: templates,
        history: history,
        savedViewStore: savedViews,
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
    savedViews.dispose();
    history.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
      'daily association and card style survive Hive reopen and portable restore',
      () async {
    const style = NoteCardStyle(
        fontFamily: 'Kalam',
        fontSize: AppFontSize.large,
        cardSize: NoteCardSize.large,
        paperStyle: NoteCardPaperStyle.plain,
        showDate: false);
    final source = NoteDto(
        id: 'daily',
        title: 'Renamed daily note',
        description: 'Keep my thoughts',
        cardStyle: style.toMap(),
        dailyNoteDateKey: '2026-10-06');
    await notes.put('daily', source);
    await notes.flush();
    await notes.close();
    notes = await Hive.openBox('notes');
    expect((notes.get('daily') as NoteDto).dailyNoteDateKey, '2026-10-06');
    expect((notes.get('daily') as NoteDto).toDomain().cardStyle, style);
    final contents = BackupContents(
        createdAt: DateTime(2026, 10, 6),
        notes: [(notes.get('daily') as NoteDto)],
        folders: [],
        photos: {},
        reminders: []);
    final portable = decodeBackup(encodeBackup(contents));
    expect(portable.toJson()['version'], 8);
    expect(portable.notes.single.dailyNoteDateKey, '2026-10-06');
    expect(portable.notes.single.toDomain().cardStyle, style);
    await notes.clear();
    final restoredService = BackupService(
        notes: notes,
        folders: folders,
        journal: journal,
        documents: directory,
        readReminders: () => reminders,
        writeReminders: (values) async => reminders = values);
    await restoredService.restore(portable);
    final restored = notes.values.cast<NoteDto>().single;
    expect(restored.id, isNot('daily'));
    expect(restored.dailyNoteDateKey, '2026-10-06');
    expect(restored.title, 'Renamed daily note');
    expect(restored.description, 'Keep my thoughts');
    expect(restored.toDomain().cardStyle, style);
  });

  test('highlight survives Hive reopen and portable note restore', () async {
    const styles = [
      NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.bold),
      NoteTextStyleRange(start: 0, end: 4, kind: NoteTextStyleKind.highlight),
    ];
    final original = NoteDto.fromNote(
        Note(id: 'marked', description: 'Keep this', textStyles: styles));
    await notes.put(original.id, original);
    await notes.flush();
    await notes.close();
    notes = await Hive.openBox('notes');
    final saved = notes.get('marked') as NoteDto;
    expect(saved.toDomain().textStyles, styles);
    final portable = decodeBackup(encodeBackup(BackupContents(
        createdAt: DateTime(2026, 10, 7),
        notes: [saved],
        folders: [],
        photos: {},
        reminders: [])));
    await notes.clear();
    final restarted = BackupService(
        notes: notes,
        folders: folders,
        journal: journal,
        documents: directory,
        readReminders: () => reminders,
        writeReminders: (values) async => reminders = values);
    await restarted.restore(portable);
    final restored = notes.values.cast<NoteDto>().single;
    expect(restored.toDomain().textStyles, styles);
    expect(restored.description, 'Keep this');
  });

  test(
      'daily restore keeps existing association and imports content separately',
      () async {
    final existing = NoteDto(
        id: 'existing', title: 'Original', dailyNoteDateKey: '2026-10-06');
    await notes.put(existing.id, existing);
    final incoming = BackupContents(createdAt: DateTime(2026, 10, 6), notes: [
      NoteDto(
          id: 'incoming',
          title: 'Imported thoughts',
          description: 'Keep imported content',
          dailyNoteDateKey: '2026-10-06')
    ], folders: [], photos: {}, reminders: []);
    await service.restore(incoming);
    expect((notes.get('existing') as NoteDto).dailyNoteDateKey, '2026-10-06');
    final imported = notes.values
        .cast<NoteDto>()
        .singleWhere((note) => note.id != 'existing');
    expect(imported.dailyNoteDateKey, isNull);
    expect(imported.description, 'Keep imported content');
  });

  test(
      'daily restore chooses one live imported owner and ignores deleted owners',
      () async {
    await notes.put(
        'deleted',
        NoteDto(
          id: 'deleted',
          title: 'Deleted existing thoughts',
          dailyNoteDateKey: '2026-10-06',
          deletedAt: DateTime(2026, 10, 6).toIso8601String(),
        ));
    final incoming = BackupContents(createdAt: DateTime(2026, 10, 6), notes: [
      NoteDto(
          id: 'archive',
          title: 'Archived import',
          isArchived: true,
          dailyNoteDateKey: '2026-10-06'),
      NoteDto(
          id: 'active', title: 'Active import', dailyNoteDateKey: '2026-10-06'),
    ], folders: [], photos: {}, reminders: []);
    await service.restore(incoming);
    final live = notes.values.cast<NoteDto>().where((note) => !note.isDeleted);
    expect(
        live
            .singleWhere((note) => note.title == 'Active import')
            .dailyNoteDateKey,
        '2026-10-06');
    expect(
        live
            .singleWhere((note) => note.title == 'Archived import')
            .dailyNoteDateKey,
        isNull);
    expect((notes.get('deleted') as NoteDto).isDeleted, isTrue);
  });

  test('legacy backups have no daily identity and v7 rejects invalid dates',
      () {
    final contents = BackupContents(
        createdAt: DateTime(2026, 10, 6),
        notes: [NoteDto(id: 'old', title: '2026-10-06')],
        folders: [],
        photos: {},
        reminders: []);
    for (var version = 1; version <= 6; version++) {
      final json = contents.toJson()..['version'] = version;
      expect(
          BackupContents.fromJson(json).notes.single.dailyNoteDateKey, isNull);
    }
    for (final bad in ['2026-02-30', '2026-2-3', '0000-01-01', 123]) {
      final json = contents.toJson();
      (json['notes'] as List).single['dailyNoteDateKey'] = bad;
      expect(() => BackupContents.fromJson(json), throwsFormatException);
    }
  });

  test(
      'v4 restores archive tags saved views and remaps links in current and history notes',
      () async {
    final target = NoteDto(
        id: 'target', title: 'Reference', isArchived: true, tags: ['Work']);
    final original = NoteDto(
        id: 'source',
        title: 'Project',
        tags: ['Work'],
        linkedNoteIds: ['target', 'missing']);
    await folders.put('folder', FolderDto(id: 'folder', name: 'Projects'));
    await notes.putAll({'target': target, 'source': original});
    await history.recordBeforeSave(
        original, original.copyWith(title: 'Project updated'),
        forceBoundary: true);
    await notes.put('source',
        original.copyWith(title: 'Project updated', isArchived: true));
    await savedViews.create(
        name: 'Projects',
        tags: ['Work'],
        folderId: 'folder',
        archiveScope: NoteArchiveScope.all);
    final backup = decodeBackup(await service.export());
    expect(backup.toJson()['version'], 8);
    await service.restore(backup);
    final imported = notes.values
        .cast<NoteDto>()
        .where((note) => note.id != 'target' && note.id != 'source')
        .toList();
    final newTarget = imported.singleWhere((note) => note.title == 'Reference');
    final newSource =
        imported.singleWhere((note) => note.title == 'Project updated');
    expect(newTarget.isArchived, isTrue);
    expect(newTarget.tags, ['Work']);
    expect(newSource.linkedNoteIds, [newTarget.id]);
    expect(history.versionsFor(newSource.id!).single.note.linkedNoteIds,
        [newTarget.id]);
    final importedView = savedViews.views.singleWhere(
        (view) => view.name == 'Projects' && view.folderId != 'folder');
    expect(importedView.archiveScope, NoteArchiveScope.all);
    expect(importedView.tags, ['Work']);
    expect(folders.get(importedView.folderId).name, 'Projects');
  });

  test(
      'v4 failed restore rolls back imported saved views and leaves existing views',
      () async {
    await savedViews.create(name: 'Existing');
    final backup = BackupContents(
        createdAt: DateTime.now(),
        notes: [NoteDto(id: 'incoming', title: 'Incoming')],
        folders: [],
        photos: {},
        reminders: [],
        savedViews: [SavedNoteView(id: 'view', name: 'Imported')]);
    failWrite = true;
    await expectLater(
        service.restore(backup), throwsA(isA<FileSystemException>()));
    expect(savedViews.views.map((view) => view.name), ['Existing']);
    expect(notes.values, isEmpty);
    expect(journal.get('pending'), isNull);
  });

  test('v6 preserves and remaps photo layout in notes history and templates',
      () async {
    const path = 'note_images/photo.jpg';
    final photo = File('${directory.path}/$path');
    await photo.parent.create(recursive: true);
    await photo.writeAsBytes([1, 2, 3, 4]);
    const body = 'First\nSecond';
    const layout = NoteImageLayout(
        path: path,
        textOffset: 6,
        widthFactor: .55,
        xFactor: .8,
        aspectRatio: 1.5);
    final before = NoteDto(
        id: 'photo-note',
        description: body,
        imagePaths: [path],
        imageLayouts: [layout.toMap()]);
    final after = before.copyWith(imageLayouts: [
      layout.copyWith(widthFactor: .75, textOffset: 0).toMap(),
    ]);
    await history.recordBeforeSave(before, after);
    await notes.put(before.id, after);
    final template =
        await templates.saveFromNote(before.toDomain(), name: 'Photo');
    expect(template.imageLayouts.single.path, template.imagePaths.single);
    final backup = decodeBackup(await service.export());
    expect(backup.toJson()['version'], 8);
    final archivedLayout = backup.notes.single.toDomain().imageLayouts.single;
    expect(archivedLayout.path, backup.notes.single.imagePaths!.single);
    expect(archivedLayout.textOffset, 0);
    expect(archivedLayout.widthFactor, .75);
    await service.restore(backup);
    final restored =
        notes.values.cast<NoteDto>().singleWhere((n) => n.id != before.id);
    final restoredLayout = restored.toDomain().imageLayouts.single;
    expect(restoredLayout.path, restored.imagePaths!.single);
    expect(restoredLayout.path, isNot(path));
    expect(restoredLayout.widthFactor, .75);
    expect(restoredLayout.xFactor, .8);
    expect(restoredLayout.aspectRatio, 1.5);
    final version = history.versionsFor(restored.id!).single;
    expect(version.note.toDomain().imageLayouts.single,
        layout.copyWith(path: restoredLayout.path));
    expect(await history.restore(restored.id!, version.id),
        NoteHistoryRestoreResult.restored);
    expect(
        (notes.get(restored.id) as NoteDto)
            .toDomain()
            .imageLayouts
            .single
            .textOffset,
        6);
    final restoredTemplate =
        templates.templates.singleWhere((t) => t.id != template.id);
    expect(restoredTemplate.imageLayouts.single,
        layout.copyWith(path: restoredTemplate.imagePaths.single));
    expect(await File('${directory.path}/${restoredLayout.path}').readAsBytes(),
        [1, 2, 3, 4]);
  });

  test('v1 through v5 place legacy photos after the body', () {
    for (var version = 1; version <= 5; version++) {
      final json = BackupContents(createdAt: DateTime.now(), notes: [
        NoteDto(id: 'legacy', description: 'Body', imagePaths: ['photo'])
      ], folders: [], photos: {
        'photo': BackupPhoto('png', Uint8List.fromList([1]))
      }, reminders: []).toJson();
      json['version'] = version;
      (json['notes'] as List).single['imageLayouts'] = [42];
      final restored = BackupContents.fromJson(json).notes.single.toDomain();
      expect(restored.imageLayouts.single.path, 'photo');
      expect(restored.imageLayouts.single.textOffset, 4);
    }
  });

  test('v6 rejects malformed photo layouts before any import', () {
    final json = BackupContents(createdAt: DateTime.now(), notes: [
      NoteDto(id: 'note', description: 'Body\nTail', imagePaths: ['photo'])
    ], folders: [], photos: {
      'photo': BackupPhoto('png', Uint8List.fromList([1]))
    }, reminders: []).toJson();
    final map = (json['notes'] as List).single as Map;
    const valid = NoteImageLayout(path: 'photo', textOffset: 5);
    for (final change in [
      {'path': 'missing'},
      {'textOffset': 100},
      {'textOffset': 2},
      {'widthFactor': 0},
      {'xFactor': 2},
      {'aspectRatio': -1},
    ]) {
      map['imageLayouts'] = [
        {...valid.toMap(), ...change}
      ];
      expect(() => BackupContents.fromJson(json), throwsFormatException);
    }
    map['imageLayouts'] = [valid.toMap(), valid.toMap()];
    expect(() => BackupContents.fromJson(json), throwsFormatException);
  });

  test('v5 preserves formatting in notes, historical versions, and templates',
      () async {
    const body = 'Heading\n• Item\nBold';
    const styles = [
      NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.heading),
      NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.highlight),
      NoteTextStyleRange(start: 15, end: 19, kind: NoteTextStyleKind.bold),
    ];
    final before = NoteDto(
        id: 'formatted',
        description: body,
        isArchived: true,
        tags: ['Work'],
        textStyles: [for (final style in styles) style.toMap()]);
    final after = before.copyWith(textStyles: []);
    await notes.put('formatted', after);
    await history.recordBeforeSave(before, after);
    final template =
        await templates.saveFromNote(before.toDomain(), name: 'Formatted');
    final backup = decodeBackup(await service.export());
    expect(backup.toJson()['version'], 8);
    expect(backup.notes.single.toDomain().textStyles, isEmpty);
    expect(backup.histories['formatted']!.single.note.toDomain().textStyles,
        styles);
    expect(backup.templates.single.textStyles, styles);
    await service.restore(backup);
    final restored = notes.values
        .cast<NoteDto>()
        .singleWhere((note) => note.id != 'formatted');
    expect(restored.description, body);
    expect(restored.isArchived, isTrue);
    expect(restored.tags, ['Work']);
    final restoredVersion = history.versionsFor(restored.id!).single;
    expect(restoredVersion.note.toDomain().textStyles, styles);
    expect(await history.restore(restored.id!, restoredVersion.id),
        NoteHistoryRestoreResult.restored);
    expect((notes.get(restored.id) as NoteDto).toDomain().textStyles, styles);
    expect(
        templates.templates.singleWhere((t) => t.id != template.id).textStyles,
        styles);
  });

  test(
      'v4 literal body markers stay literal and missing v5 styles default empty',
      () {
    final json = BackupContents(
        createdAt: DateTime.now(),
        notes: [NoteDto(id: 'legacy', description: '# Heading\n**not bold**')],
        folders: [],
        photos: {},
        reminders: []).toJson();
    (json['notes'] as List).single.remove('textStyles');
    final v5 = BackupContents.fromJson(json);
    expect(v5.notes.single.toDomain().textStyles, isEmpty);
    json['version'] = 4;
    (json['notes'] as List).single['textStyles'] = [42];
    final v4 = BackupContents.fromJson(json);
    expect(v4.notes.single.description, '# Heading\n**not bold**');
    expect(v4.notes.single.toDomain().textStyles, isEmpty);
  });

  test('v5 malformed formatting fails validation before any restore writes',
      () async {
    final original = BackupContents(
        createdAt: DateTime.now(),
        notes: [NoteDto(id: 'incoming', description: '😊x')],
        folders: [],
        photos: {},
        reminders: []).toJson();
    for (final raw in [
      {'start': 0, 'end': 2, 'kind': 'unknown'},
      {'start': -1, 'end': 2, 'kind': 'bold'},
      {'start': 0, 'end': 20, 'kind': 'bold'},
      {'start': 1, 'end': 2, 'kind': 'bold'},
      {'start': 2, 'end': 2, 'kind': 'bold'},
      {'start': true, 'end': 2, 'kind': 'bold'},
    ]) {
      final changed = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      (changed['notes'] as List).single['textStyles'] = [raw];
      expect(() => BackupContents.fromJson(changed), throwsFormatException);
    }
    expect(notes.isEmpty, isTrue);
    expect(journal.isEmpty, isTrue);
  });

  test(
      'v3 restores without new metadata and retains audio/history compatibility',
      () async {
    final json = BackupContents(
        createdAt: DateTime.now(),
        notes: [NoteDto(id: 'old', title: 'Old')],
        folders: [],
        photos: {},
        reminders: []).toJson();
    json['version'] = 3;
    json.remove('savedViews');
    for (final note in json['notes'] as List) {
      (note as Map)
        ..remove('tags')
        ..remove('isArchived')
        ..remove('linkedNoteIds');
    }
    final backup = BackupContents.fromJson(json);
    expect(backup.notes.single.toDomain().isArchived, isFalse);
    expect(backup.notes.single.toDomain().tags, isEmpty);
    expect(backup.notes.single.toDomain().linkedNoteIds, isEmpty);
    expect(backup.savedViews, isEmpty);
    await service.restore(backup);
    expect(notes.length, 1);
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

  Future<VoiceMemo> audioMemo({String id = 'source-audio'}) async {
    final memo = VoiceMemo(
        id: id,
        path: 'note_audio/$id.m4a',
        durationMs: 12000,
        createdAt: DateTime(2026, 10, 6),
        transcript: 'Keep this transcript 保留转录');
    final file = File('${directory.path}/${memo.path}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes([6, 7, 8, 9], flush: true);
    return memo;
  }

  test(
      'v3 restores owned note/template audio with metadata and fresh identities',
      () async {
    await seed();
    final memo = await audioMemo();
    final original =
        (notes.get('original') as NoteDto).copyWith(voiceMemos: [memo.toMap()]);
    await notes.put('original', original);
    final template =
        await templates.saveFromNote(original.toDomain(), name: 'Audio');
    final backup = decodeBackup(await service.export());
    expect(backup.audio, hasLength(2));
    expect(backup.audio.values.first.bytes, [6, 7, 8, 9]);
    expect(backup.notes.first.voiceMemos!.single['path'], startsWith('audio_'));
    await service.restore(backup);
    final restored = notes.values.cast<NoteDto>().singleWhere(
        (note) => note.title == original.title && note.id != original.id);
    final restoredMemo = VoiceMemo.tryFromMap(restored.voiceMemos!.single)!;
    expect(restoredMemo.id, isNot(memo.id));
    expect(restoredMemo.path, isNot(memo.path));
    expect(restoredMemo.path, startsWith('note_audio/'));
    expect(restoredMemo.durationMs, memo.durationMs);
    expect(restoredMemo.createdAt, memo.createdAt);
    expect(restoredMemo.transcript, memo.transcript);
    final restoredTemplate =
        templates.templates.singleWhere((t) => t.id != template.id);
    final templateMemo = restoredTemplate.voiceMemos.single;
    expect(templateMemo.id, isNot(template.voiceMemos.single.id));
    expect(templateMemo.path, startsWith('template_audio/'));
    expect(templateMemo.path, isNot(restoredMemo.path));
    await File('${directory.path}/${memo.path}').delete();
    await templates.delete(template.id);
    for (final restoredAudio in [restoredMemo, templateMemo]) {
      expect(
          await File('${directory.path}/${restoredAudio.path}').readAsBytes(),
          [6, 7, 8, 9]);
    }
  });

  test(
      'v3 preserves snapshot-only media and restores older versions of new notes',
      () async {
    await seed();
    final memo = await audioMemo();
    final before =
        (notes.get('original') as NoteDto).copyWith(voiceMemos: [memo.toMap()]);
    final after =
        before.copyWith(title: 'Current', imagePaths: [], voiceMemos: []);
    await history.recordBeforeSave(before, after);
    await notes.put('original', after);
    final originalVersion = history.versionsFor('original').single;
    final backup = decodeBackup(await service.export());
    expect(backup.audio, hasLength(1));
    expect(backup.photos, hasLength(1));
    expect(backup.histories['original']!.single.note.voiceMemos, hasLength(1));
    await service.restore(backup);
    final restored = notes.values
        .cast<NoteDto>()
        .singleWhere((n) => n.title == 'Current' && n.id != 'original');
    final version = history.versionsFor(restored.id!).single;
    expect(version.id, isNot(originalVersion.id));
    expect(version.note.id, restored.id);
    expect(version.note.todoList!.single.id, isNot('todo'));
    expect(version.note.voiceMemos!.single['id'], isNot(memo.id));
    expect(version.note.imagePaths!.single, isNot('note_images/a.png'));
    final restoredAudio =
        VoiceMemo.tryFromMap(version.note.voiceMemos!.single)!;
    expect(await File('${directory.path}/${restoredAudio.path}').readAsBytes(),
        [6, 7, 8, 9]);
    expect(await history.restore(restored.id!, version.id),
        NoteHistoryRestoreResult.restored);
    final older = notes.get(restored.id) as NoteDto;
    expect(older.title, 'Keep me');
    expect(older.voiceMemos!.single['path'], restoredAudio.path);
    expect(
        await File('${directory.path}/${older.imagePaths!.single}')
            .readAsBytes(),
        [1, 2, 3, 4]);
    expect(history.versionsFor('original').single.id, originalVersion.id);
  });

  test(
      'restored current and historical content share stable fresh media/task IDs',
      () async {
    await seed();
    final memo = await audioMemo();
    final before =
        (notes.get('original') as NoteDto).copyWith(voiceMemos: [memo.toMap()]);
    final after = before.copyWith(title: 'Current');
    await history.recordBeforeSave(before, after);
    await notes.put('original', after);
    await service.restore(decodeBackup(await service.export()));
    final restored = notes.values
        .cast<NoteDto>()
        .singleWhere((n) => n.title == 'Current' && n.id != 'original');
    final snapshot = history.versionsFor(restored.id!).single.note;
    expect(snapshot.voiceMemos, restored.voiceMemos);
    expect(snapshot.imagePaths, restored.imagePaths);
    expect(snapshot.todoList!.single.id, restored.todoList!.single.id);
    expect(snapshot.todoList!.single.id, isNot('todo'));
  });

  test('failed restore removes new history and audio while retaining originals',
      () async {
    await seed();
    final memo = await audioMemo();
    final before =
        (notes.get('original') as NoteDto).copyWith(voiceMemos: [memo.toMap()]);
    final after = before.copyWith(title: 'Current');
    await history.recordBeforeSave(before, after);
    await notes.put('original', after);
    final template =
        await templates.saveFromNote(before.toDomain(), name: 'Keep');
    final backup = decodeBackup(await service.export());
    failWrite = true;
    await expectLater(
        service.restore(backup), throwsA(isA<FileSystemException>()));
    expect(notes.keys.toSet(), {'original', 'trash'});
    expect(historyBox.keys.toList(), ['original']);
    expect(templates.templates.single.id, template.id);
    expect(await Directory('${directory.path}/note_audio').list().length, 1);
    expect(
        await Directory('${directory.path}/template_audio').list().length, 1);
    expect(await File('${directory.path}/${memo.path}').readAsBytes(),
        [6, 7, 8, 9]);
    expect(journal.isEmpty, isTrue);
  });

  test(
      'interrupted restore purges imported histories and audio with safe paths',
      () async {
    await seed();
    final originalMemo = await audioMemo();
    final partialMemo = await audioMemo(id: 'partial');
    final partial = NoteDto(
        id: 'partial', title: 'Partial', voiceMemos: [partialMemo.toMap()]);
    await notes.put('partial', partial);
    await history.importVersions({
      'partial': [
        NoteHistoryVersion(
            id: 'version', savedAt: DateTime(2026), note: partial)
      ]
    });
    await journal.put('pending', {
      'notes': ['partial'],
      'folders': [],
      'photos': [],
      'audio': [partialMemo.path, '../note_audio/source-audio.m4a'],
      'histories': ['partial'],
    });
    await service.recoverInterruptedRestore();
    expect(notes.containsKey('partial'), isFalse);
    expect(history.versionsFor('partial'), isEmpty);
    expect(
        await File('${directory.path}/${partialMemo.path}').exists(), isFalse);
    expect(
        await File('${directory.path}/${originalMemo.path}').exists(), isTrue);
    expect(journal.isEmpty, isTrue);
  });

  test('missing source audio fails export without silently losing recordings',
      () async {
    await seed();
    final memo = await audioMemo();
    await notes.put(
        'original',
        (notes.get('original') as NoteDto)
            .copyWith(voiceMemos: [memo.toMap()]));
    await File('${directory.path}/${memo.path}').delete();
    await expectLater(service.export(), throwsA(isA<FileSystemException>()));
  });

  test('v2 backups without voice or history fields retain compatibility',
      () async {
    await seed();
    final json = decodeBackup(await service.export()).toJson();
    json['version'] = 2;
    json.remove('audio');
    json.remove('histories');
    for (final note in json['notes'] as List) {
      (note as Map).remove('voiceMemos');
    }
    final backup = BackupContents.fromJson(json);
    expect(backup.audio, isEmpty);
    expect(backup.histories, isEmpty);
    expect(backup.notes.every((n) => n.voiceMemos!.isEmpty), isTrue);
    await service.restore(backup);
    expect(notes.length, 4);
  });

  test(
      'v3 rejects unsafe, missing, duplicate and invalid recording/history data',
      () async {
    await seed();
    final memo = await audioMemo();
    final before =
        (notes.get('original') as NoteDto).copyWith(voiceMemos: [memo.toMap()]);
    final after = before.copyWith(title: 'Current');
    await history.recordBeforeSave(before, after);
    await notes.put('original', after);
    final original = decodeBackup(await service.export()).toJson();
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (m) => m.remove('audio'),
      (m) => m.remove('histories'),
      (m) => (m['audio'] as Map).values.first['extension'] = 'mp3',
      (m) => (m['audio'] as Map).values.first['data'] = '',
      (m) => (m['notes'] as List).first['voiceMemos'].first['path'] =
          '../source.m4a',
      (m) => (m['notes'] as List).first['voiceMemos'].first['path'] = 'missing',
      (m) => (m['notes'] as List).first['voiceMemos'].first['durationMs'] = -1,
      (m) => (m['notes'] as List).first['voiceMemos'].first['durationMs'] = 0,
      (m) => (m['notes'] as List).first['voiceMemos'].first['createdAt'] =
          'bad date',
      (m) => (m['notes'] as List).first['voiceMemos'].first['transcript'] = 42,
      (m) {
        final list = (m['notes'] as List).first['voiceMemos'] as List;
        list.add(list.first);
      },
      (m) {
        final note = (m['notes'] as List).first;
        note['voiceMemos'] = List.filled(101, note['voiceMemos'].first);
      },
      (m) => (m['histories'] as Map).values.first.first['note']['id'] =
          'missing-note',
      (m) => (m['histories'] as Map).values.first.first['savedAt'] = 'bad date',
      (m) {
        final versions = (m['histories'] as Map).values.first as List;
        versions.add(versions.first);
      },
    ]) {
      final changed = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      mutate(changed);
      expect(
          () => decodeBackup(
              Uint8List.fromList(utf8.encode(jsonEncode(changed)))),
          throwsFormatException);
    }
    expect(notes.length, 2);
    expect(historyBox.keys.toList(), ['original']);
    expect(journal.isEmpty, isTrue);
  });

  test('oversized individual recordings are rejected before restore writes',
      () async {
    await seed();
    final memo = await audioMemo();
    await notes.put(
        'original',
        (notes.get('original') as NoteDto)
            .copyWith(voiceMemos: [memo.toMap()]));
    final json = decodeBackup(await service.export()).toJson();
    (json['audio'] as Map).values.first['data'] =
        base64Encode(Uint8List(maxBackupAudioBytes + 1));
    expect(() => BackupContents.fromJson(json), throwsFormatException);
    expect(notes.length, 2);
    expect(journal.isEmpty, isTrue);
  });

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
    expect(backup.toJson()['version'], 8);
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
