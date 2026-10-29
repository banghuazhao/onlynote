import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/markdown_import.dart';
import 'package:onlynote/services/markdown_import_service.dart';
import 'package:onlynote/services/note_export.dart';
import 'package:onlynote/services/note_outline.dart';

import '../support/premium_test_fakes.dart';

Uint8List _png() => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6S58AAAAASUVORK5CYII=');

Uint8List _zip(Map<String, List<int>> entries) {
  final archive = Archive();
  for (final entry in entries.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

class _Notes extends Fake implements NoteRepository {
  final values = <String, NoteDto>{};
  int writes = 0;
  int? failAt;
  bool failAfterWrite = false;
  bool unreadable = false;
  bool becomeUnreadableAfterFailure = false;
  @override
  List<NoteDto> getAllNotes() {
    if (unreadable) throw StateError('Read unavailable');
    return values.values.toList();
  }

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    if (writes == failAt && !failAfterWrite) {
      if (becomeUnreadableAfterFailure) unreadable = true;
      throw StateError('Storage unavailable');
    }
    values[note.id!] = note;
    if (writes == failAt) {
      if (becomeUnreadableAfterFailure) unreadable = true;
      throw StateError('Failure after write');
    }
  }
}

class _Images implements MarkdownImportImageStore {
  final saved = <String>[];
  final deleted = <String>[];
  int? failAt;
  bool cleanupFails = false;
  @override
  Future<String> write(MarkdownImportImage image) async {
    if (saved.length == failAt) throw StateError('Image write failed');
    final path = 'note_images/${saved.length}.${image.extension}';
    saved.add(path);
    return path;
  }

  @override
  Future<void> delete(List<String> paths) async {
    if (cleanupFails) throw StateError('Locked file');
    deleted.addAll(paths);
  }
}

void main() {
  test('imports title, rich headings, bold, literal escapes, tasks and divider',
      () {
    final document = MarkdownImportParser.parse(
        '# Trip\n\n## Plans\nPack **light** and \\*keep\\* this.\n\n---\n\n- [ ] Passport\n- [x] Tickets',
        sourceName: 'trip.md');
    expect(document.note.title, 'Trip');
    expect(
        document.note.description, 'Plans\nPack light and *keep* this.\n\n─');
    expect(
        buildNoteOutline(document.note.description!, document.note.textStyles)
            .single
            .text,
        'Plans');
    final bold = document.note.textStyles
        .singleWhere((range) => range.kind == NoteTextStyleKind.bold);
    expect(document.note.description!.substring(bold.start, bold.end), 'light');
    expect(
        document.note.textStyles
            .where((range) => range.kind == NoteTextStyleKind.divider),
        hasLength(1));
    expect(document.note.todo.map((todo) => (todo.title, todo.completed)),
        [('Passport', false), ('Tickets', true)]);
  });

  test(
      'literal hashes and intraword underscores survive heading and plain text parsing',
      () {
    final document = MarkdownImportParser.parse(
        '# C#\n\n## A heading ##\nA__name__value',
        sourceName: 'hash.md');
    expect(document.note.title, 'C#');
    expect(document.note.description, 'A heading\nA__name__value');
    expect(
        document.note.textStyles
            .where((range) => range.kind == NoteTextStyleKind.bold),
        isEmpty);
    final roundtrip = MarkdownImportParser.parse(
        NoteExport.markdown(Note(title: 'C#')),
        sourceName: 'export.md');
    expect(roundtrip.note.title, 'C#');
  });

  test(
      'unsupported indented code retains whitespace and literal Markdown markers',
      () {
    const source = '    **literal**\n    print("hello")';
    final document = MarkdownImportParser.parse(source, sourceName: 'code.md');
    expect(document.note.description, source);
    expect(document.note.textStyles, isEmpty);
    final fenced = MarkdownImportParser.parse(
        '```dart\n```not a closing fence\n**literal**\n```',
        sourceName: 'code.md');
    expect(fenced.note.description, contains('**literal**'));
    expect(fenced.note.textStyles, isEmpty);
  });

  test('code, unsupported links and missing remote images remain readable', () {
    const source =
        '```dart\n**literal**\n```\n[Source](https://example.com)\n![Remote](https://example.com/a.png)';
    final result =
        MarkdownImportParser.parse(source, sourceName: 'research.md');
    expect(result.note.description, source);
    expect(result.note.textStyles, isEmpty);
    expect(
        result.warnings,
        containsAll([
          MarkdownImportWarning.plainTextFormatting,
          MarkdownImportWarning.missingImages
        ]));
  });

  test('unsupported inline code and links retain their literal source', () {
    const source =
        'Use `**pattern**` then [source](https://example.com/__token__).\n'
        'https://example.com/__token__\n'
        '<span title="**literal**">HTML</span>';
    final document =
        MarkdownImportParser.parse(source, sourceName: 'reference.md');
    expect(document.note.description, source);
    expect(document.note.textStyles, isEmpty);
    expect(
        document.warnings, contains(MarkdownImportWarning.plainTextFormatting));
    final structured = MarkdownImportParser.parse(
        '# `**literal**`\n\n- [ ] Use `**pattern**`',
        sourceName: 'structured.md');
    expect(structured.note.title, '`**literal**`');
    expect(structured.note.todo.single.title, 'Use `**pattern**`');
    final exported = NoteExport.markdown(Note(description: source));
    expect(
        MarkdownImportParser.parse(exported, sourceName: 'export.md')
            .note
            .description,
        source);
  });

  test('large unmatched Markdown delimiters preserve their source', () {
    final source = '${'[' * 50000}\n${'<' * 50000}';
    final document = MarkdownImportReader.readBytes(
            'delimiters.md', Uint8List.fromList(utf8.encode(source)))
        .documents
        .single;
    expect(document.note.description, source);
    expect(document.note.textStyles, isEmpty);
  });

  test('Unicode offsets and setext headings are intact', () {
    final result = MarkdownImportParser.parse(
        'Travel\n======\n\n👩🏽‍💻 **Ideas**\nDetail\n------',
        sourceName: 'unicode.md');
    expect(result.note.title, 'Travel');
    final bold = result.note.textStyles
        .singleWhere((range) => range.kind == NoteTextStyleKind.bold);
    expect(result.note.description!.substring(bold.start, bold.end), 'Ideas');
    expect(
        buildNoteOutline(result.note.description!, result.note.textStyles)
            .single
            .text,
        'Detail');
  });

  test('long task and title content cannot be silently clipped by persistence',
      () {
    final long = '🪴' * 100;
    final document = MarkdownImportParser.parse('# $long\n\n- [ ] $long',
        sourceName: 'long.md');
    final saved = NoteDto.fromNote(document.note).toDomain();
    expect(saved.title!.length, lessThanOrEqualTo(140));
    expect(saved.description, contains(long));
    expect(saved.todo, isEmpty);
    expect(saved.description, contains('[ ] $long'));
  });

  test('ZIP preserves nested paths and does not confuse duplicate basenames',
      () {
    final batch = MarkdownImportReader.readBytes(
        'notes.zip',
        _zip({
          'a/note.md': utf8.encode('# First\n![Photo](image.png)'),
          'b/note.md': utf8.encode('# Second\n![Photo](../a/image.png)'),
          'a/image.png': _png(),
        }));
    expect(batch.documents.map((doc) => doc.note.title), ['First', 'Second']);
    expect(batch.documents.map((doc) => doc.sourceName),
        ['a/note.md', 'b/note.md']);
    expect(batch.documents.every((doc) => doc.images.length == 1), isTrue);
    expect(batch.documents.first.images.single.bytes, _png());
  });

  test(
      'current Markdown exports roundtrip image placement and supported content',
      () {
    final original = Note(
        id: 'original',
        title: 'A **literal** title',
        description: 'Before\nHeading\nAfter',
        textStyles: const [
          NoteTextStyleRange(start: 7, end: 14, kind: NoteTextStyleKind.heading)
        ],
        todo: [
          Todo(title: 'Buy *paper*', completed: true)
        ],
        imagePaths: const [
          'photo'
        ],
        imageLayouts: const [
          NoteImageLayout(
              path: 'photo', textOffset: 7, widthFactor: .6, xFactor: 1)
        ]);
    final markdown = NoteExport.markdown(original, photos: ['my photo.png']);
    final imported = MarkdownImportReader.readBytes(
        'export.zip',
        _zip({
          'note.md': utf8.encode(markdown),
          'my photo.png': _png(),
        })).documents.single;
    expect(imported.note.title, original.title);
    expect(imported.note.todo.single.title, 'Buy *paper*');
    expect(imported.note.todo.single.completed, isTrue);
    expect(imported.images, hasLength(1));
    final layout = imported.note.imageLayouts.single;
    expect(layout.widthFactor, .6);
    expect(layout.xFactor, 1);
    expect(imported.note.description!.substring(0, layout.textOffset),
        contains('Before'));
    expect(
        buildNoteOutline(imported.note.description!, imported.note.textStyles)
            .single
            .text,
        'Heading');
  });

  test('empty files skipped and unsupported or unsafe ZIP inputs rejected', () {
    expect(
        MarkdownImportReader.readBytes('empty.md', Uint8List(0)).skippedEmpty,
        1);
    for (final name in [
      '/absolute.md',
      '../escape.md',
      'x/../escape.md',
      'x\\escape.md'
    ]) {
      expect(
          () => MarkdownImportReader.readBytes(
              'bad.zip', _zip({name: utf8.encode('Content')})),
          throwsFormatException);
    }
    expect(() => MarkdownImportReader.readBytes('notes.txt', Uint8List(0)),
        throwsFormatException);
    expect(
        () => MarkdownImportReader.readBytes(
            'bad.zip', Uint8List.fromList([1, 2])),
        throwsFormatException);
    expect(resolveMarkdownImagePath('note.md', '../../secret.png'), isNull);
    expect(resolveMarkdownImagePath('folder/note.md', '../image.png'),
        'image.png');
    expect(resolveMarkdownImagePath('note.md', 'file:///secret.png'), isNull);
  });

  test('declared large archive is rejected before it decompresses', () {
    final archive = _zip({'large.md': utf8.encode('small')});
    // Forge both local and central uncompressed lengths beyond our budget.
    final bytes = ByteData.sublistView(archive);
    for (var i = 0; i + 46 < archive.length; i++) {
      if (bytes.getUint32(i, Endian.little) == 0x02014b50) {
        bytes.setUint32(
            i + 24, MarkdownImportReader.maxExpandedBytes + 1, Endian.little);
        break;
      }
    }
    expect(() => MarkdownImportReader.readBytes('bad.zip', archive),
        throwsFormatException);
  });

  test(
      'forged smaller uncompressed lengths cannot bypass bounded decompression',
      () {
    final archive = _zip({'large.md': utf8.encode('x' * 10000)});
    final bytes = ByteData.sublistView(archive);
    for (var i = 0; i + 46 < archive.length; i++) {
      if (bytes.getUint32(i, Endian.little) == 0x02014b50) {
        bytes.setUint32(i + 24, 1, Endian.little);
        break;
      }
    }
    expect(() => MarkdownImportReader.readBytes('bad.zip', archive),
        throwsFormatException);
  });

  test(
      'import uses fresh identities and saved image layouts without modifying source',
      () async {
    final notes = _Notes();
    final images = _Images();
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    addTearDown(fixture.dispose);
    final source = MarkdownImportParser.parse(
        '# New\n![Photo](photo.png)\n- [ ] Task',
        sourceName: 'new.md',
        attachments: {'photo.png': _png()});
    final result = await MarkdownImportService(
            repository: notes,
            imageStore: images,
            premiumAccess: fixture.access)
        .importDocuments([source]);
    expect(result.failure, isNull);
    final saved = notes.values.values.single.toDomain();
    expect(saved.id, isNotNull);
    expect(saved.todo.single.id, isNotNull);
    expect(saved.imagePaths, images.saved);
    expect(saved.imageLayouts.single.path, images.saved.single);
    expect(source.note.id, isNull);
    expect(source.note.imagePaths, ['markdown-image-0']);
  });

  test(
      'failed note cleans only its own attachments and retries only remaining notes',
      () async {
    final notes = _Notes()..failAt = 2;
    final images = _Images();
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    addTearDown(fixture.dispose);
    MarkdownImportDocument doc(String name) =>
        MarkdownImportParser.parse('# $name\n![Photo](photo.png)',
            sourceName: '$name.md', attachments: {'photo.png': _png()});
    final service = MarkdownImportService(
        repository: notes, imageStore: images, premiumAccess: fixture.access);
    final result = await service
        .importDocuments([doc('First'), doc('Second'), doc('Third')]);
    expect(result.failure, MarkdownImportFailure.save);
    expect(result.importedIds, hasLength(1));
    expect(result.remaining.map((doc) => doc.note.title), ['Second', 'Third']);
    expect(images.deleted, [images.saved[1]]);
    notes.failAt = null;
    final retry = await service.importDocuments(result.remaining);
    expect(retry.importedIds, hasLength(2));
    expect(notes.values.values.map((note) => note.title),
        ['First', 'Second', 'Third']);
  });

  test(
      'failure reported after durable save does not delete owned photos or duplicate retry',
      () async {
    final notes = _Notes()
      ..failAt = 1
      ..failAfterWrite = true;
    final images = _Images();
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    addTearDown(fixture.dispose);
    final document = MarkdownImportParser.parse('# New\n![Photo](photo.png)',
        sourceName: 'new.md', attachments: {'photo.png': _png()});
    final result = await MarkdownImportService(
            repository: notes,
            imageStore: images,
            premiumAccess: fixture.access)
        .importDocuments([document]);
    expect(result.importedIds, hasLength(1));
    expect(result.remaining, isEmpty);
    expect(images.deleted, isEmpty);
  });

  test('Premium preflight is all-or-none before images or notes are written',
      () async {
    final notes = _Notes();
    for (var i = 0; i < 9; i++) {
      notes.values['$i'] = NoteDto(id: '$i', title: 'Existing');
    }
    final images = _Images();
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    final document =
        MarkdownImportParser.parse('Content', sourceName: 'new.md');
    final result = await MarkdownImportService(
            repository: notes,
            imageStore: images,
            premiumAccess: fixture.access)
        .importDocuments([document, document]);
    expect(result.failure, MarkdownImportFailure.premium);
    expect(result.remaining, hasLength(2));
    expect(notes.writes, 0);
    expect(images.saved, isEmpty);
  });
  for (final durable in [false, true]) {
    test(
        'ambiguous save retains stable ID and never claims success before verification durable=$durable',
        () async {
      final notes = _Notes()
        ..failAt = 1
        ..failAfterWrite = durable
        ..becomeUnreadableAfterFailure = true;
      final images = _Images();
      final fixture = PremiumTestFixture(premium: true);
      await fixture.init();
      addTearDown(fixture.dispose);
      final document = MarkdownImportParser.parse('# New\n![Photo](photo.png)',
          sourceName: 'new.md', attachments: {'photo.png': _png()});
      final service = MarkdownImportService(
          repository: notes, imageStore: images, premiumAccess: fixture.access);
      final result = await service.importDocuments([document]);
      expect(result.importedIds, isEmpty);
      expect(result.remaining, [document]);
      expect(result.failure, MarkdownImportFailure.save);
      expect(images.saved, hasLength(1));
      expect(images.deleted, isEmpty);
      notes.unreadable = false;
      notes.failAt = null;
      expect(service.requiredNewNotes(result.remaining), durable ? 0 : 1);
      final retry = await service.importDocuments(result.remaining);
      expect(retry.failure, isNull);
      expect(retry.importedIds, hasLength(1));
      expect(notes.values, hasLength(1));
      expect(images.saved, hasLength(1));
      expect(notes.writes, durable ? 1 : 2);
    });
  }

  test(
      'cleanup failure keeps prior successes out of retry and imported sorting uses milliseconds',
      () async {
    final notes = _Notes()..failAt = 2;
    final images = _Images()..cleanupFails = true;
    final fixture = PremiumTestFixture(premium: true);
    await fixture.init();
    addTearDown(fixture.dispose);
    final document = MarkdownImportParser.parse('# New\n![Photo](photo.png)',
        sourceName: 'new.md', attachments: {'photo.png': _png()});
    final second = MarkdownImportParser.parse('# Second\n![Photo](photo.png)',
        sourceName: 'second.md', attachments: {'photo.png': _png()});
    final now = DateTime(2026, 10, 29);
    final result = await MarkdownImportService(
        repository: notes,
        imageStore: images,
        premiumAccess: fixture.access,
        now: () => now).importDocuments([document, second]);
    expect(result.failure, MarkdownImportFailure.save);
    expect(result.importedIds, hasLength(1));
    expect(result.remaining, [second]);
    expect(notes.values.values.single.sortOrder, -now.millisecondsSinceEpoch);
  });
}
