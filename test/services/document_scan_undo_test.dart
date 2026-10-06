import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/document_scan_capture.dart';

const _id = '12345678-1234-1234-1234-123456789abc';
const _page0 = '/app/support/document_scans/$_id/page_0.jpg';
const _page1 = '/app/support/document_scans/$_id/page_1.jpg';
const _saved0 = 'note_images/page-0.jpg';
const _saved1 = 'note_images/page-1.jpg';

class _Notes extends Fake implements NoteRepository {
  final notes = <String, NoteDto>{};
  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<void> addUpdateNote(NoteDto note) async => notes[note.id!] = note;
}

class _Scanner extends DocumentScanner {
  _Scanner() : super(channel: const MethodChannel('onlynote.test/scan-undo'));
  bool acknowledged = false;
  final result = const DocumentScanResult(
      id: _id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
  @override
  Future<DocumentScanResult> scan(
          {required String id, int pageLimit = 20}) async =>
      result;
  @override
  Future<List<DocumentScanResult>> pending() async =>
      acknowledged ? [] : [result];
  @override
  Future<void> acknowledge(String id) async => acknowledged = true;
}

class _Journal extends Fake implements Box {
  _Journal(this.box);
  final Box box;
  bool failPut = false;
  int writes = 0;
  @override
  Iterable<dynamic> get keys => box.keys;
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      box.get(key, defaultValue: defaultValue);
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failPut) throw StateError('Cannot save scan intent');
    writes++;
    await box.put(key, value);
  }

  @override
  Future<void> delete(dynamic key) => box.delete(key);
  @override
  Future<void> flush() => box.flush();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box box;
  late _Journal journal;
  late _Notes repository;
  late _Scanner scanner;
  late DocumentScanCapture capture;
  late Note origin;
  late bool failSecondCopy;
  final copies = <String>[];

  List<dynamic> discarded() =>
      (box.get('${DocumentScanCapture.journalPrefix}$_id') as Map)['discarded']
          as List;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-scan-undo-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    box = await Hive.openBox('scanner_undo');
    journal = _Journal(box);
    repository = _Notes();
    scanner = _Scanner();
    origin = Note(id: 'note', description: 'Caption');
    repository.notes['note'] = NoteDto.fromNote(origin);
    failSecondCopy = false;
    copies.clear();
    capture = DocumentScanCapture(
      journalBox: journal,
      repository: repository,
      scanner: scanner,
      createId: () => _id,
      save: (source) async {
        copies.add(source.path);
        if (source.path == _page1 && failSecondCopy) {
          throw StateError('Cannot copy second page');
        }
        return source.path == _page0 ? _saved0 : _saved1;
      },
    );
  });
  tearDown(() async {
    capture.release();
    scanner.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('undo restores a discarded page and complete requires its durable save',
      () async {
    await capture.scan(origin);
    await capture.discardPage(_saved0);
    expect(discarded(), [_saved0]);
    await capture.restorePage(_saved0);
    expect(discarded(), isEmpty);
    repository.notes['note'] =
        NoteDto.fromNote(origin.copyWith(imagePaths: [_saved1]));
    await expectLater(capture.complete(), throwsStateError);
    expect(scanner.acknowledged, isFalse);
    repository.notes['note'] =
        NoteDto.fromNote(origin.copyWith(imagePaths: [_saved0, _saved1]));
    await capture.complete();
    expect(scanner.acknowledged, isTrue);
  });

  test('replay reconciles several page intents with one journal write',
      () async {
    await capture.scan(origin);
    await capture.discardPage(_saved0);
    final writesBeforeReplay = journal.writes;
    await capture.reconcilePages([_saved0, 'note_images/unrelated.jpg']);
    expect(journal.writes, writesBeforeReplay + 1);
    expect(discarded(), [_saved1]);
    await capture.reconcilePages([_saved0]);
    expect(journal.writes, writesBeforeReplay + 1);
    repository.notes['note'] =
        NoteDto.fromNote(origin.copyWith(imagePaths: [_saved0]));
    await capture.complete();
    expect(scanner.acknowledged, isTrue);
  });

  test('failed intent write preserves every preceding page intent', () async {
    await capture.scan(origin);
    await capture.discardPage(_saved0);
    journal.failPut = true;
    await expectLater(capture.reconcilePages([_saved0]), throwsStateError);
    expect(discarded(), [_saved0]);
    journal.failPut = false;
    await capture.reconcilePages([_saved0]);
    expect(discarded(), [_saved1]);
  });

  test('undo and redo during partial copy survive abandoned editor recovery',
      () async {
    failSecondCopy = true;
    final result = await capture.scan(origin);
    expect(result.savedPaths, [_saved0]);
    await capture.reconcilePages([]); // Undo the copied first page.
    expect(discarded(), [_saved0]);
    await capture.reconcilePages([_saved0]); // Redo before the second copy.
    expect(discarded(), isEmpty);
    capture.release();
    failSecondCopy = false;
    final recovery = DocumentScanCapture(
      journalBox: journal,
      repository: repository,
      scanner: scanner,
      save: (source) async {
        copies.add(source.path);
        return _saved1;
      },
    );
    try {
      await recovery.recover();
      expect(repository.notes['note']!.imagePaths, [_saved0, _saved1]);
      expect(copies.where((path) => path == _page0), hasLength(1));
      expect(scanner.acknowledged, isTrue);
    } finally {
      recovery.release();
    }
  });
}
