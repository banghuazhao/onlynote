import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_section_link.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/backup/backup_service.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_links.dart';
import 'package:onlynote/services/note_section_links.dart';

const _self = NoteSectionLink(
    noteId: 'source', headingId: 'plan', headingText: 'Original plan');
const _external = NoteSectionLink(
    noteId: 'target', headingId: 'details', headingText: 'Details');

Note _source() => Note(
      id: 'source',
      title: 'Source',
      description: 'Plan\nBody',
      textStyles: const [
        NoteTextStyleRange(
            start: 0, end: 4, kind: NoteTextStyleKind.heading, anchorId: 'plan')
      ],
      sectionLinks: const [_self, _external],
    );

BackupContents _backup(List<NoteDto> notes) => BackupContents(
      createdAt: DateTime(2026, 10, 29),
      notes: notes,
      folders: [],
      photos: {},
      reminders: [],
    );

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
  test('section destinations are unique, ordered, bounded and allow self', () {
    final links = normalizeNoteSectionLinks([_self, _external, _self]);
    expect(links, [_self, _external]);
    expect(() => links.add(_self), throwsUnsupportedError);
    expect(
        () => normalizeNoteSectionLinks([
              const NoteSectionLink(
                  noteId: '', headingId: 'id', headingText: 'Heading')
            ]),
        throwsFormatException);
    expect(
        () => normalizeNoteSectionLinks([
              for (var index = 0; index <= maxNoteSectionLinks; index++)
                NoteSectionLink(
                    noteId: 'source',
                    headingId: 'section-$index',
                    headingText: 'Heading')
            ]),
        throwsFormatException);
    expect(() => parseNoteSectionLinks([{}]), throwsFormatException);
    expect(() => parseNoteSectionLinks('source'), throwsFormatException);
    expect(NoteAutosave.hasContent(Note(sectionLinks: [_external])), isTrue);
    expect(NoteDto.fromNote(Note(sectionLinks: [_external])).validNote, isTrue);
  });

  test('stable heading links survive rename and earlier text insertion', () {
    final renamed = Note(
      id: 'source',
      isArchived: true,
      description: 'Introduction\nUpdated plan\nBody',
      textStyles: const [
        NoteTextStyleRange(
            start: 13,
            end: 25,
            kind: NoteTextStyleKind.heading,
            anchorId: 'plan')
      ],
    );
    final resolved = resolveNoteSectionLink(_self, [renamed]);
    expect(resolved?.note, renamed);
    expect(resolved?.heading.start, 13);
    expect(resolved?.heading.text, 'Updated plan');
    expect(resolved?.heading.anchorId, 'plan');
    final duplicateTitle = renamed.copyWith(textStyles: const [
      NoteTextStyleRange(
          start: 13,
          end: 25,
          kind: NoteTextStyleKind.heading,
          anchorId: 'different-heading')
    ]);
    expect(resolveNoteSectionLink(_self, [duplicateTitle]), isNull);
    expect(
        resolveNoteSectionLink(
            _self, [renamed.copyWith(deletedAt: DateTime(2026))]),
        isNull);
    expect(resolveNoteSectionLink(_self, []), isNull);
  });

  test('section backlinks include archived sources once and exclude trash', () {
    final target = Note(id: 'target');
    final source =
        _source().copyWith(linkedNoteIds: ['target'], isArchived: true);
    final trash = source.copyWith(id: 'trash', deletedAt: DateTime(2026));
    expect(noteBacklinks(target, [target, source, trash]), [source]);
  });

  test('legacy Hive notes default to no section links; field19 retains them',
      () {
    final legacy = NoteDtoAdapter()
        .read(_FieldsReader({0: 'legacy', 1: 'Title'}))
        .toDomain();
    expect(legacy.sectionLinks, isEmpty);
    final saved = NoteDtoAdapter()
        .read(_FieldsReader({
          0: 'source',
          19: [_self.toMap()]
        }))
        .toDomain();
    expect(saved.sectionLinks, [_self]);
    expect(
        NoteDto.fromNote(saved)
            .copyWith(title: 'Changed')
            .toDomain()
            .sectionLinks,
        [_self]);
  });

  test('portable notes retain section links and heading IDs', () {
    final source = NoteDto.fromNote(_source());
    final restored = decodeBackup(encodeBackup(_backup([source])));
    final note = restored.notes.single.toDomain();
    expect(restored.toJson()['version'], 9);
    expect(note.sectionLinks, [_self, _external]);
    expect(note.textStyles.single.anchorId, 'plan');
    expect(resolveNoteSectionLink(_self, [note])?.heading.text, 'Plan');
  });

  test('malformed portable links reject import and old backups default empty',
      () {
    for (final invalid in [
      'bad',
      [null],
      [<String, dynamic>{}],
      [
        <String, dynamic>{..._self.toMap(), 'headingId': ''}
      ],
      [
        <String, dynamic>{..._self.toMap(), 'headingText': 3}
      ],
      [
        <String, dynamic>{..._self.toMap(), 'noteId': 'a' * 513}
      ],
    ]) {
      final json = _backup([NoteDto.fromNote(_source())]).toJson();
      (json['notes'] as List).single['sectionLinks'] = invalid;
      expect(() => BackupContents.fromJson(json), throwsFormatException);
    }
    for (var version = 1; version <= 8; version++) {
      final json = _backup([NoteDto.fromNote(_source())]).toJson()
        ..['version'] = version;
      (json['notes'] as List).single.remove('sectionLinks');
      expect(BackupContents.fromJson(json).notes.single.toDomain().sectionLinks,
          isEmpty,
          reason: 'Backup version $version');
    }
  });

  test('template reuse remaps self links while retaining external targets', () {
    final template = CustomNoteTemplate.fromNote(_source(),
        name: 'Planning', imageCopies: []);
    final portable = CustomNoteTemplate.fromJson(template.toJson());
    final first = portable.createNote(imageCopies: []);
    final second = portable.createNote(imageCopies: []);
    for (final note in [first, second]) {
      expect(note.sectionLinks.first.noteId, note.id);
      expect(note.sectionLinks.last, _external);
      expect(
          resolveNoteSectionLink(note.sectionLinks.first, [note])?.heading.text,
          'Plan');
    }
    expect(first.id, isNot(second.id));
    final malformed = template.toJson()
      ..['sectionLinks'] = [
        <String, dynamic>{..._self.toMap(), 'headingId': 9}
      ];
    expect(() => CustomNoteTemplate.fromJson(malformed), throwsFormatException);
  });

  group('durable section links', () {
    late Directory directory;
    late Box notes, folders, journal;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('onlynote-sections-');
      Hive.init(directory.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
      notes = await Hive.openBox('section-notes');
      folders = await Hive.openBox('section-folders');
      journal = await Hive.openBox('section-journal');
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('Hive reopen and backup import preserve links to new target IDs',
        () async {
      final source = _source();
      final target = Note(
          id: 'target',
          title: 'Target',
          description: 'Details',
          textStyles: const [
            NoteTextStyleRange(
                start: 0,
                end: 7,
                kind: NoteTextStyleKind.heading,
                anchorId: 'details')
          ]);
      await notes.put('source', NoteDto.fromNote(source));
      await notes.flush();
      await notes.close();
      notes = await Hive.openBox('section-notes');
      expect((notes.get('source') as NoteDto).toDomain().sectionLinks,
          [_self, _external]);
      final backup = decodeBackup(encodeBackup(_backup([
        notes.get('source') as NoteDto,
        NoteDto.fromNote(target),
      ])));
      final service = BackupService(
          notes: notes,
          folders: folders,
          journal: journal,
          documents: directory,
          readReminders: () => [],
          writeReminders: (_) async {});
      await service.restore(backup);
      final imported = notes.values
          .cast<NoteDto>()
          .map((n) => n.toDomain())
          .where((note) => note.id != 'source')
          .toList();
      final importedSource = imported.singleWhere((n) => n.title == 'Source');
      final importedTarget = imported.singleWhere((n) => n.title == 'Target');
      expect(importedSource.sectionLinks.first.noteId, importedSource.id);
      expect(importedSource.sectionLinks.last.noteId, importedTarget.id);
      expect(
          resolveNoteSectionLink(importedSource.sectionLinks.first, imported)
              ?.heading
              .text,
          'Plan');
      expect(
          resolveNoteSectionLink(importedSource.sectionLinks.last, imported)
              ?.heading
              .text,
          'Details');
      expect((notes.get('source') as NoteDto).toDomain().sectionLinks,
          [_self, _external]);
    });
  });
}
