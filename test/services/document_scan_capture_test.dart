import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:onlynote/services/note_autosave.dart';

const _id = '12345678-1234-1234-1234-123456789abc';
const _otherId = '87654321-1234-1234-1234-123456789abc';
const _root = '/app/support/document_scans/$_id';
const _page0 = '$_root/page_0.jpg';
const _page1 = '$_root/page_1.jpg';
const _saved0 = 'note_images/scanned-0.jpg';
const _saved1 = 'note_images/scanned-1.jpg';

class _Notes implements NoteRepository {
  final records = <String, NoteDto>{};
  int writes = 0;
  bool failSave = false;
  @override
  List<NoteDto> getAllNotes() => records.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => records[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (failSave) throw StateError('Note storage unavailable');
    writes++;
    records[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => records.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      records.remove(id);
    }
  }
}

class _Scanner extends DocumentScanner {
  _Scanner()
      : super(channel: const MethodChannel('onlynote.test/scan-capture'));
  final inbox = <String, DocumentScanResult>{};
  final scans = <String>[];
  final acknowledged = <String>[];
  Future<DocumentScanResult> Function(String)? onScan;
  Future<List<DocumentScanResult>> Function()? onPending;
  Future<void> Function(String)? onAck;
  bool failAck = false;

  @override
  Future<DocumentScanResult> scan(
      {required String id, int pageLimit = 20}) async {
    scans.add(id);
    final response = await onScan?.call(id) ??
        DocumentScanResult(
            id: id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
    inbox[id] = response;
    return response;
  }

  @override
  Future<List<DocumentScanResult>> pending() async =>
      await onPending?.call() ?? inbox.values.toList();
  @override
  Future<void> acknowledge(String id) async {
    await onAck?.call(id);
    if (failAck) throw StateError('Native acknowledgement unavailable');
    acknowledged.add(id);
    inbox.remove(id);
  }
}

class _Journal extends Fake implements Box {
  _Journal(this.delegate);
  final Box delegate;
  bool failAllWrites = false;
  bool failFirstPage = false;
  @override
  Iterable<dynamic> get keys => delegate.keys;
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      delegate.get(key, defaultValue: defaultValue);
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failAllWrites) throw StateError('Journal storage unavailable');
    if (failFirstPage && value is Map && (value['saved'] as List).length == 1) {
      failFirstPage = false;
      throw StateError('Page acknowledgement unavailable');
    }
    await delegate.put(key, value);
  }

  @override
  Future<void> delete(dynamic key) => delegate.delete(key);
  @override
  Future<void> flush() => delegate.flush();
}

class _BlockingJournal extends _Journal {
  _BlockingJournal(super.delegate);
  final entered = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<void> flush() async {
    if (!entered.isCompleted) {
      entered.complete();
      await resume.future;
    }
    await super.flush();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box journal;
  late _Notes notes;
  late _Scanner scanner;
  late List<DocumentScanCapture> captures;
  late List<String> copies;
  late DateTime now;

  DocumentScanCapture capture({
    Box? journalOverride,
    Future<String> Function(File)? save,
  }) {
    final instance = DocumentScanCapture(
      journalBox: journalOverride ?? journal,
      repository: notes,
      scanner: scanner,
      createId: () => _id,
      now: () => now,
      save: save ??
          (source) async {
            copies.add(source.path);
            return source.path.endsWith('page_0.jpg') ? _saved0 : _saved1;
          },
    );
    captures.add(instance);
    return instance;
  }

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('onlynote-document-scan-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    journal = await Hive.openBox('scan_journal');
    notes = _Notes();
    scanner = _Scanner();
    captures = [];
    copies = [];
    now = DateTime.utc(2026, 10, 7, 10);
  });
  tearDown(() async {
    for (final capture in captures) {
      capture.release();
    }
    scanner.dispose();
    await journal.close();
    await directory.delete(recursive: true);
  });

  test(
      'origin is durably journaled before native scanner opens; ordered copies',
      () async {
    final origin = Note(id: 'origin', description: 'Caption');
    scanner.onScan = (id) async {
      final record =
          journal.get('${DocumentScanCapture.journalPrefix}$id') as Map;
      expect((record['note'] as NoteDto).description, 'Caption');
      expect(record['sources'], isEmpty);
      expect(record['status'], 'pending');
      return DocumentScanResult(
          id: id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
    };
    final service = capture();
    final result = await service.scan(origin);
    expect(result.status, DocumentScanStatus.pages);
    expect(result.savedPaths, [_saved0, _saved1]);
    expect(copies, [_page0, _page1]);
    expect(notes.records, isEmpty);
    expect(scanner.acknowledged, isEmpty);
    expect(service.canRetry, isFalse);
    expect(service.hasPending, isTrue);
    expect(service.referencedImages, containsAll([_saved0, _saved1]));
    await notes.addUpdateNote(
        NoteDto.fromNote(origin.copyWith(imagePaths: result.savedPaths)));
    await service.complete();
    expect(service.hasPending, isFalse);
  });

  for (final status in [
    DocumentScanStatus.cancelled,
    DocumentScanStatus.unsupported,
    DocumentScanStatus.failed,
    DocumentScanStatus.tooManyPages,
    DocumentScanStatus.permissionDenied,
  ]) {
    test('$status changes no note and leaves no dangling capture', () async {
      scanner.onScan = (id) async => DocumentScanResult(id: id, status: status);
      final original = NoteDto(id: 'origin', title: 'Keep me');
      notes.records['origin'] = original;
      final service = capture();
      final result = await service.scan(original.toDomain());
      expect(result.status, status);
      expect(result.savedPaths, isEmpty);
      expect(notes.records['origin'], same(original));
      expect(notes.writes, 0);
      expect(copies, isEmpty);
      expect(service.hasPending, isFalse);
      expect(service.isJournaled, isFalse);
      expect(scanner.acknowledged, [_id]);
    });
  }

  test('copy failure retains completed pages and retries without rescanning',
      () async {
    var failSecond = true;
    final service = capture(save: (source) async {
      copies.add(source.path);
      if (source.path == _page1 && failSecond) {
        throw const FileSystemException('Storage temporarily full');
      }
      return source.path == _page0 ? _saved0 : _saved1;
    });
    final first = await service.scan(Note(id: 'origin'));
    expect(first.savedPaths, [_saved0]);
    expect(first.error, isNotNull);
    expect(service.canRetry, isTrue);
    failSecond = false;
    final retried = await service.retry();
    expect(retried.savedPaths, [_saved1]);
    expect(retried.error, isNull);
    expect(copies, [_page0, _page1, _page1]);
    expect(scanner.scans, [_id]);
    expect(service.canRetry, isFalse);
    await notes
        .addUpdateNote(NoteDto(id: 'origin', imagePaths: [_saved0, _saved1]));
    await service.complete();
  });

  test('a copied page survives its journal-write failure without another copy',
      () async {
    final storage = _Journal(journal)..failFirstPage = true;
    final service = capture(journalOverride: storage);
    final first = await service.scan(Note(id: 'origin'));
    expect(first.savedPaths, isEmpty);
    expect(first.error, isNotNull);
    expect(copies, [_page0]);
    expect(service.referencedImages, contains(_saved0));
    final retry = await service.retry();
    expect(retry.savedPaths, [_saved0, _saved1]);
    expect(copies, [_page0, _page1]);
    await notes
        .addUpdateNote(NoteDto(id: 'origin', imagePaths: retry.savedPaths));
    await service.complete();
  });

  test('complete refuses acknowledgement until note save owns every page',
      () async {
    final service = capture();
    await service.scan(Note(id: 'origin', title: 'Scans'));
    await expectLater(service.complete(), throwsStateError);
    notes.records['origin'] = NoteDto(id: 'origin', imagePaths: [_saved0]);
    await expectLater(service.complete(), throwsStateError);
    expect(scanner.acknowledged, isEmpty);
    notes.records['origin'] =
        NoteDto(id: 'origin', imagePaths: [_saved0, _saved1]);
    scanner.onAck = (id) async {
      final record =
          journal.get('${DocumentScanCapture.journalPrefix}$id') as Map;
      expect(record['committed'], isTrue);
      expect(notes.records['origin']!.imagePaths, [_saved0, _saved1]);
    };
    await service.complete();
    expect(scanner.acknowledged, [_id]);
    expect(service.hasPending, isFalse);
  });

  test('restart while native is pending retains the empty origin journal',
      () async {
    scanner.onScan = (id) async =>
        DocumentScanResult(id: id, status: DocumentScanStatus.pending);
    final first = capture();
    await first.scan(Note(id: 'origin', description: 'Never lose this seed'));
    first.release();
    await journal.close();
    journal = await Hive.openBox('scan_journal');
    final recovery = capture();
    await recovery.recover();
    expect(recovery.hasPending, isTrue);
    expect(notes.records, isEmpty);
    expect(copies, isEmpty);
    expect(scanner.acknowledged, isEmpty);
    scanner.inbox.clear();
    await recovery.recover();
    expect(recovery.hasPending, isTrue,
        reason: 'No inbox result is not a cancellation signal');
    scanner.inbox[_id] = const DocumentScanResult(
        id: _id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
    await recovery.recover();
    expect(notes.records['origin']!.description, 'Never lose this seed');
    expect(notes.records['origin']!.imagePaths, [_saved0, _saved1]);
    expect(recovery.hasPending, isFalse);
  });

  test('app recovery skips active editor until release then merges newest data',
      () async {
    final origin = Note(
        id: 'origin',
        title: 'Original',
        description: 'Original text',
        folderId: 'old-folder',
        dailyNoteDateKey: '2026-10-06');
    notes.records['origin'] = NoteDto.fromNote(origin);
    final editor = capture();
    final result = await editor.scan(origin);
    final recovery = capture();
    await recovery.recover();
    expect(notes.writes, 0);
    expect(scanner.acknowledged, isEmpty);
    expect(copies.length, 2);
    notes.records['origin'] = NoteDto.fromNote(origin.copyWith(
      title: 'Latest saved title',
      folderId: 'new-folder',
      isPinned: true,
      isArchived: true,
      sortOrder: 99,
      dailyNoteDateKey: null,
    ));
    await journal.put(
        'origin',
        NoteDto.fromNote(origin.copyWith(
          title: 'Newest draft title',
          description: 'Keep recent typing',
          todo: [Todo(id: 'task', title: 'Draft task')],
          imagePaths: ['note_images/existing.jpg'],
        )));
    editor.release();
    await recovery.recover();
    final recovered = notes.records['origin']!.toDomain();
    expect(recovered.title, 'Newest draft title');
    expect(recovered.description, 'Keep recent typing');
    expect(recovered.todo.single.title, 'Draft task');
    expect(recovered.folderId, 'new-folder');
    expect(recovered.isPinned, isTrue);
    expect(recovered.isArchived, isTrue);
    expect(recovered.sortOrder, 99);
    expect(recovered.dailyNoteDateKey, isNull);
    expect(recovered.dateTime, now);
    expect(recovered.imagePaths,
        ['note_images/existing.jpg', ...result.savedPaths]);
    expect(
        recovered.imageLayouts.where((item) => item.isDocumentPage).length, 2);
    expect(copies.length, 2);
    expect(recovery.hasPending, isFalse);
    expect(journal.get('origin'), isNull);
  });

  for (final trashed in [false, true]) {
    test(
        'recovery never copies or resurrects ${trashed ? 'trashed' : 'deleted'} origin',
        () async {
      final origin = Note(id: 'origin', title: 'Existing');
      notes.records['origin'] = NoteDto.fromNote(origin);
      scanner.onScan = (id) async =>
          DocumentScanResult(id: id, status: DocumentScanStatus.pending);
      final editor = capture();
      await editor.scan(origin);
      editor.release();
      if (trashed) {
        notes.records['origin'] = NoteDto.fromNote(
            origin.copyWith(deletedAt: DateTime.utc(2026, 10, 7)));
      } else {
        notes.records.remove('origin');
      }
      scanner.inbox[_id] = const DocumentScanResult(
          id: _id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
      final recovery = capture();
      await recovery.recover();
      expect(copies, isEmpty);
      expect(notes.writes, 0);
      expect(notes.records['origin']?.isDeleted, trashed ? true : isNull);
      expect(recovery.hasPending, isFalse);
    });
  }

  test('permanent deletion also abandons an originally unsaved seed', () async {
    scanner.onScan = (id) async =>
        DocumentScanResult(id: id, status: DocumentScanStatus.pending);
    final editor = capture();
    await editor.scan(Note(id: 'origin', title: 'Seed'));
    final recovery = capture();
    await recovery.purgeNotes({'origin'});
    editor.release();
    expect(recovery.hasPending, isTrue);
    scanner.inbox[_id] = const DocumentScanResult(
        id: _id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
    await recovery.recover();
    expect(notes.records, isEmpty);
    expect(copies, isEmpty);
    expect(recovery.hasPending, isFalse);
  });

  test('durable deletion intent prevents an unsaved seed from being recreated',
      () async {
    scanner.onScan = (id) async =>
        DocumentScanResult(id: id, status: DocumentScanStatus.pending);
    final editor = capture();
    await editor.scan(Note(id: 'origin', title: 'Seed'));
    editor.release();
    await journal.put('_note_delete_pending_v1.intent', {
      'version': 1,
      'ids': ['origin'],
    });
    scanner.inbox[_id] = const DocumentScanResult(
        id: _id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
    final recovery = capture();
    await recovery.recover();
    expect(notes.records, isEmpty);
    expect(copies, isEmpty);
    expect(recovery.hasPending, isFalse);
  });

  test('failed recovery note save retains copies through normal draft recovery',
      () async {
    final editor = capture();
    await editor.scan(Note(id: 'origin', description: 'Scanned caption'));
    editor.release();
    final recovery = capture();
    notes.failSave = true;
    await recovery.recover();
    expect(recovery.hasPending, isTrue);
    expect(journal.get('origin'), isA<NoteDto>());
    expect(scanner.acknowledged, isEmpty);
    notes.failSave = false;
    await HiveNoteAutosaveStore(notes, journal).recover();
    final savedDate = notes.records['origin']!.dateTime;
    now = now.add(const Duration(days: 1));
    await recovery.recover();
    expect(copies.length, 2);
    expect(notes.records['origin']!.description, 'Scanned caption');
    expect(notes.records['origin']!.imagePaths, [_saved0, _saved1]);
    expect(notes.records['origin']!.dateTime, savedDate);
    expect(recovery.hasPending, isFalse);
  });

  test(
      'ack failure preserves committed identity and later edits are not undone',
      () async {
    final editor = capture();
    await editor.scan(Note(id: 'origin', title: 'Scans'));
    notes.records['origin'] =
        NoteDto(id: 'origin', title: 'Scans', imagePaths: [_saved0, _saved1]);
    scanner.failAck = true;
    await expectLater(editor.complete(), throwsStateError);
    expect(editor.hasPending, isTrue);
    notes.records['origin'] = NoteDto(
        id: 'origin',
        title: 'Later title',
        imagePaths: [],
        dateTime: '2027-01-01');
    editor.release();
    scanner.failAck = false;
    final recovery = capture();
    await recovery.recover();
    expect(notes.records['origin']!.title, 'Later title');
    expect(notes.records['origin']!.imagePaths, isEmpty);
    expect(notes.records['origin']!.dateTime, '2027-01-01');
    expect(notes.writes, 0);
    expect(copies.length, 2);
    expect(recovery.hasPending, isFalse);
  });

  test('a committed scan deleted during ack failure is never resurrected',
      () async {
    final editor = capture();
    await editor.scan(Note(id: 'origin'));
    notes.records['origin'] =
        NoteDto(id: 'origin', imagePaths: [_saved0, _saved1]);
    scanner.failAck = true;
    await expectLater(editor.complete(), throwsStateError);
    notes.records.remove('origin');
    editor.release();
    scanner.failAck = false;
    final recovery = capture();
    await recovery.recover();
    expect(notes.records, isEmpty);
    expect(recovery.hasPending, isFalse);
  });

  test(
      'origin deleted during page copying is checked again before recovery save',
      () async {
    final origin = Note(id: 'origin', title: 'Existing');
    notes.records['origin'] = NoteDto.fromNote(origin);
    scanner.onScan = (id) async =>
        DocumentScanResult(id: id, status: DocumentScanStatus.pending);
    final editor = capture();
    await editor.scan(origin);
    editor.release();
    scanner.inbox[_id] = const DocumentScanResult(
        id: _id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
    final recovery = capture(save: (source) async {
      copies.add(source.path);
      notes.records.remove('origin');
      return source.path == _page0 ? _saved0 : _saved1;
    });
    await recovery.recover();
    expect(notes.records, isEmpty);
    expect(notes.writes, 0);
    expect(recovery.hasPending, isFalse);
  });

  test('native orphan pages clean up safely while pending orphans remain',
      () async {
    scanner.inbox[_id] = const DocumentScanResult(
        id: _id, status: DocumentScanStatus.pages, paths: [_page0, _page1]);
    scanner.inbox[_otherId] = const DocumentScanResult(
        id: _otherId, status: DocumentScanStatus.pending);
    final recovery = capture();
    await recovery.recover();
    expect(scanner.acknowledged, [_id]);
    expect(scanner.inbox.keys, [_otherId]);
    expect(notes.records, isEmpty);
    expect(copies, isEmpty);
  });

  test(
      'journal preparation failure never opens native UI or leaves token stuck',
      () async {
    final failing = _Journal(journal)..failAllWrites = true;
    final service = capture(journalOverride: failing);
    final result = await service.scan(Note(id: 'origin'));
    expect(result.error, isNotNull);
    expect(scanner.scans, isEmpty);
    expect(service.isJournaled, isFalse);
    expect(service.hasPending, isFalse);
    failing.failAllWrites = false;
    final retried = await service.scan(Note(id: 'origin'));
    expect(retried.savedPaths, [_saved0, _saved1]);
    notes.records['origin'] =
        NoteDto(id: 'origin', imagePaths: retried.savedPaths);
    await service.complete();
  });

  test('release while queued prevents a late scanner launch or active token',
      () async {
    final entered = Completer<void>();
    final resume = Completer<void>();
    scanner.onPending = () async {
      entered.complete();
      await resume.future;
      return [];
    };
    final recovering = capture().recover();
    await entered.future;
    final editor = capture();
    final scanning = editor.scan(Note(id: 'origin', title: 'Keep seed'));
    editor.release();
    resume.complete();
    await recovering;
    final result = await scanning;
    expect(result.status, DocumentScanStatus.failed);
    expect(scanner.scans, isEmpty);
    expect(editor.isJournaled, isFalse);
    expect(editor.hasPending, isFalse);
  });

  test('release during origin flush removes only the never-launched journal',
      () async {
    final storage = _BlockingJournal(journal);
    final editor = capture(journalOverride: storage);
    final scanning = editor.scan(Note(id: 'origin', description: 'Caption'));
    await storage.entered.future;
    expect(editor.isJournaled, isTrue);
    editor.release();
    storage.resume.complete();
    final result = await scanning;
    expect(result.status, DocumentScanStatus.failed);
    expect(scanner.scans, isEmpty);
    expect(editor.isJournaled, isFalse);
    expect(editor.hasPending, isFalse);
    expect(notes.records, isEmpty);
    expect(copies, isEmpty);
  });

  test('partial scan can remove a copied page then complete remaining pages',
      () async {
    var failSecond = true;
    final service = capture(save: (source) async {
      copies.add(source.path);
      if (source.path == _page1 && failSecond) {
        throw const FileSystemException('Second page copy failed');
      }
      return source.path == _page0 ? _saved0 : _saved1;
    });
    final initial = await service.scan(Note(id: 'origin', title: 'Receipt'));
    expect(initial.savedPaths, [_saved0]);
    notes.records['origin'] =
        NoteDto(id: 'origin', title: 'Receipt', imagePaths: [_saved0]);
    await service.discardPage(_saved0);
    notes.records['origin'] = notes.records['origin']!.copyWith(imagePaths: []);
    await expectLater(service.complete(), throwsStateError);
    expect(scanner.acknowledged, isEmpty,
        reason: 'Discarding a copied page does not finish the pending pages');
    failSecond = false;
    final retry = await service.retry();
    expect(retry.savedPaths, [_saved1]);
    final record =
        journal.get('${DocumentScanCapture.journalPrefix}$_id') as Map;
    expect(record['saved'], [_saved0, _saved1]);
    expect(record['discarded'], [_saved0]);
    notes.records['origin'] =
        notes.records['origin']!.copyWith(imagePaths: retry.savedPaths);
    await service.complete();
    expect(notes.records['origin']!.imagePaths, [_saved1]);
    expect(scanner.scans, [_id]);
    expect(copies, [_page0, _page1, _page1]);
    expect(service.hasPending, isFalse);
  });

  test(
      'partial replacement persists across restart and recovery keeps edited page',
      () async {
    var failSecond = true;
    final editor = capture(save: (source) async {
      copies.add(source.path);
      if (source.path == _page1 && failSecond) {
        throw const FileSystemException('Second page copy failed');
      }
      return source.path == _page0 ? _saved0 : _saved1;
    });
    final first = await editor.scan(Note(id: 'origin', description: 'Caption'));
    expect(first.savedPaths, [_saved0]);
    notes.records['origin'] =
        NoteDto(id: 'origin', description: 'Caption', imagePaths: [_saved0]);
    await editor.discardPage(_saved0);
    const edited = 'note_images/cropped-page.jpg';
    notes.records['origin'] = notes.records['origin']!
        .copyWith(description: 'Latest caption', imagePaths: [edited]);
    editor.release();
    await journal.close();
    journal = await Hive.openBox('scan_journal');
    failSecond = false;
    final recovery = capture();
    await recovery.recover();
    expect(notes.records['origin']!.imagePaths, [edited, _saved1]);
    expect(notes.records['origin']!.description, 'Latest caption');
    expect(copies, [_page0, _page1, _page1]);
    expect(scanner.scans, [_id]);
    expect(recovery.hasPending, isFalse);
  });

  test('discard journal failure leaves page ownership intact and is retryable',
      () async {
    final storage = _Journal(journal);
    final editor = capture(journalOverride: storage);
    await editor.discardPage('note_images/unrelated.jpg');
    expect(journal.isEmpty, isTrue);
    await editor.scan(Note(id: 'origin'));
    storage.failAllWrites = true;
    await editor.discardPage('note_images/unrelated.jpg');
    await expectLater(editor.discardPage(_saved0), throwsStateError);
    final record =
        journal.get('${DocumentScanCapture.journalPrefix}$_id') as Map;
    expect(record['discarded'], isEmpty);
    notes.records['origin'] = NoteDto(id: 'origin', imagePaths: [_saved1]);
    await expectLater(editor.complete(), throwsStateError);
    expect(scanner.acknowledged, isEmpty);
    storage.failAllWrites = false;
    await editor.discardPage(_saved0);
    await editor.discardPage(_saved0);
    await editor.complete();
    expect(editor.hasPending, isFalse);
  });

  for (final recoverAfterRelease in [false, true]) {
    test(
        'all pages discarded from an unsaved empty note ${recoverAfterRelease ? 'recover' : 'complete'} without creating a blank note',
        () async {
      final editor = capture();
      await editor.scan(Note(id: 'origin'));
      await editor.discardPage(_saved0);
      await editor.discardPage(_saved1);
      expect(notes.records, isEmpty);
      if (recoverAfterRelease) {
        editor.release();
        await capture().recover();
      } else {
        await editor.complete();
      }
      expect(notes.records, isEmpty);
      expect(notes.writes, 0);
      expect(scanner.acknowledged, [_id]);
      expect(editor.hasPending, isFalse);
      expect(copies, [_page0, _page1]);
    });
  }

  test('unsafe injected sources and malformed journals never access files',
      () async {
    scanner.onScan = (id) async => DocumentScanResult(
        id: id, status: DocumentScanStatus.pages, paths: ['/etc/private.jpg']);
    final service = capture();
    expect((await service.scan(Note(id: 'origin'))).error, isNotNull);
    expect(copies, isEmpty);
    service.release();
    scanner.inbox.clear();
    await journal.put('${DocumentScanCapture.journalPrefix}$_otherId', {
      'version': 1,
      'id': _otherId,
      'note': NoteDto(id: 'unsafe'),
      'existed': false,
      'status': 'pages',
      'sources': ['/etc/private.jpg'],
      'saved': [],
    });
    await capture().recover();
    expect(copies, isEmpty);
    expect(notes.records, isEmpty);
  });
}
