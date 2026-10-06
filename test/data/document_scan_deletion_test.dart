import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/data/repository/note_repository.dart';
import 'package:onlynote/domain/database/database.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:onlynote/services/note_autosave.dart';

const _scanID = 'ca118157-a3e4-47d4-97e2-1216a77b2c4a';
const _otherID = 'ca118157-a3e4-47d4-97e2-1216a77b2c4b';

class _Database implements Database {
  _Database(this.box);
  @override
  final Box box;
  @override
  T get<T>(String id) => box.get(id) as T;
  @override
  List<T> getAll<T>() => box.values.cast<T>().toList();
  @override
  Future<void> addUpdate<T>(String id, T item) => box.put(id, item);
  @override
  Future<void> delete(String id) => box.delete(id);
  @override
  Future<void> deleteAll(List<String> ids) => box.deleteAll(ids);
}

class _Scanner extends DocumentScanner {
  _Scanner()
      : super(channel: const MethodChannel('onlynote.scan.deletion.test'));
  final inbox = <DocumentScanResult>[];
  final acknowledgements = <String>[];
  bool failAck = false;

  @override
  Future<List<DocumentScanResult>> pending() async => inbox.toList();
  @override
  Future<void> acknowledge(String id) async {
    if (failAck) throw StateError('Native inbox unavailable');
    acknowledgements.add(id);
    inbox.removeWhere((entry) => entry.id == id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box drafts;
  late Box notes;
  late NoteRepositoryImplementation repository;
  late _Scanner scanner;
  late DocumentScanCapture capture;
  var copies = 0;

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('onlynote-scan-deletion-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    drafts = await Hive.openBox(draftDatabaseBox);
    notes = await Hive.openBox('scan_deletion_notes');
    repository = NoteRepositoryImplementation(_Database(notes));
    scanner = _Scanner();
    DocumentScanner.configure(scanner);
    DocumentScanCapture.initializedInstance = null;
    copies = 0;
    capture = DocumentScanCapture(
      journalBox: drafts,
      repository: repository,
      scanner: scanner,
      save: (_) async {
        copies++;
        return 'note_images/copied.jpg';
      },
    );
  });

  tearDown(() async {
    capture.release();
    DocumentScanCapture.initializedInstance = null;
    scanner.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> seed(String id, String noteID, {bool finished = false}) =>
      drafts.put('${DocumentScanCapture.journalPrefix}$id', {
        'version': 1,
        'id': id,
        'note': NoteDto(id: noteID, title: 'Unsaved scanner origin'),
        'existed': false,
        'sources': finished
            ? ['/ApplicationSupport/document_scans/$id/page_0.jpg']
            : <String>[],
        'saved': finished ? ['note_images/copied.jpg'] : <String>[],
        'status': finished ? 'pages' : 'pending',
        'committed': false,
        'abandoned': false,
      });

  for (final configured in [true, false]) {
    test(
        'deletion abandons pending scanner seed with configured owner: $configured',
        () async {
      if (configured) DocumentScanCapture.configure(capture);
      await seed(_scanID, 'removed');
      await seed(_otherID, 'kept');
      scanner.inbox.add(const DocumentScanResult(
          id: _scanID, status: DocumentScanStatus.pending));

      await repository.deleteNote('removed');
      final record =
          drafts.get('${DocumentScanCapture.journalPrefix}$_scanID') as Map;
      expect(record['abandoned'], isTrue);
      expect(record['note'], isA<NoteDto>());
      expect(
          (drafts.get('${DocumentScanCapture.journalPrefix}$_otherID')
              as Map)['abandoned'],
          isFalse);
      expect(scanner.acknowledgements, isEmpty);

      scanner.inbox[0] = const DocumentScanResult(
        id: _scanID,
        status: DocumentScanStatus.pages,
        paths: ['/ApplicationSupport/document_scans/$_scanID/page_0.jpg'],
      );
      await capture.recover();
      expect(repository.getAllNotes(), isEmpty);
      expect(copies, 0);
      expect(scanner.acknowledgements, [_scanID]);
      expect(drafts.containsKey('${DocumentScanCapture.journalPrefix}$_scanID'),
          isFalse);
      expect(
          drafts.containsKey('${DocumentScanCapture.journalPrefix}$_otherID'),
          isTrue);
    });
  }

  test('startup deletion intent runs before completed scan recovery', () async {
    DocumentScanCapture.configure(capture);
    await seed(_scanID, 'removed', finished: true);
    await drafts.put('${NoteRepositoryImplementation.deletionPrefix}crash', {
      'version': 1,
      'ids': ['removed'],
    });

    expect(await repository.recoverPendingDeletions(), isTrue);
    await capture.recover();
    await HiveNoteAutosaveStore(repository, drafts).recover();
    expect(repository.getAllNotes(), isEmpty);
    expect(copies, 0);
    expect(scanner.acknowledgements, [_scanID]);
    expect(drafts.keys, isEmpty);
  });

  test('failed scanner acknowledgement retains permanent deletion retry intent',
      () async {
    DocumentScanCapture.configure(capture);
    await notes.put('removed', NoteDto(id: 'removed', title: 'Stored note'));
    await seed(_scanID, 'removed', finished: true);
    scanner.failAck = true;

    await repository.deleteNote('removed');
    expect(notes.containsKey('removed'), isFalse);
    expect(
        (drafts.get('${DocumentScanCapture.journalPrefix}$_scanID')
            as Map)['abandoned'],
        isTrue);
    expect(await repository.recoverPendingDeletions(), isFalse);
    expect(
        drafts.keys.whereType<String>().any((key) =>
            key.startsWith(NoteRepositoryImplementation.deletionPrefix)),
        isTrue);

    scanner.failAck = false;
    expect(await repository.recoverPendingDeletions(), isTrue);
    expect(drafts.keys, isEmpty);
    expect(scanner.acknowledgements, [_scanID]);
    expect(repository.getAllNotes(), isEmpty);
  });
}
