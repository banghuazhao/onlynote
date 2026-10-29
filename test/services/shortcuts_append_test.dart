import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_transfer.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:onlynote/services/shortcuts_append.dart';
import '../support/premium_test_fakes.dart';

class AppendTestNotes extends Fake implements NoteRepository {
  final values = <String, NoteDto>{};
  bool failSave = false;
  int writes = 0;
  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (failSave) throw StateError('Disk unavailable');
    writes++;
    values[note.id!] = note;
  }
}

class AppendTestStore implements NoteAutosaveStore {
  AppendTestStore(this.notes);
  final AppendTestNotes notes;
  final drafts = <String, Note>{};
  bool failRemove = false;
  bool failDraftWrite = false;
  @override
  Future<void> writeDraft(Note note) async {
    if (failDraftWrite) throw StateError('Draft write failed');
    drafts[note.id!] = note;
  }

  @override
  Future<void> removeDraft(String id) async {
    if (failRemove) throw StateError('Cleanup failed');
    drafts.remove(id);
  }

  @override
  Future<void> saveNote(Note note) =>
      notes.addUpdateNote(NoteDto.fromNote(note));
}

class AppendTestJournal implements ShortcutAppendJournal {
  final values = <String, Object>{};
  bool failCommit = false;
  @override
  Object? read(String key) => values[key];
  @override
  Iterable<String> get keys => values.keys;
  @override
  Future<void> write(String key, Object value) async {
    if (failCommit && value is Map && value['committed'] == true) {
      throw StateError('Interrupted after note save');
    }
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async => values.remove(key);
}

ShortcutAppendRequest appendRequest(
        {int sequence = 1,
        ShortcutAppendDestination destination = ShortcutAppendDestination.note,
        String text = 'Added',
        String? noteId = 'target',
        DateTime? createdAt}) =>
    ShortcutAppendRequest(
        id: '12345678-1234-1234-1234-${sequence.toString().padLeft(12, '0')}',
        destination: destination,
        text: text,
        noteId: destination == ShortcutAppendDestination.note ? noteId : null,
        createdAt:
            (createdAt ?? DateTime(2026, 10, 29, 10)).millisecondsSinceEpoch);

void main() {
  late AppendTestNotes notes;
  late AppendTestStore store;
  late AppendTestJournal journal;
  late ShortcutsAppendService service;
  late List<String> acknowledgements;
  setUp(() {
    notes = AppendTestNotes();
    store = AppendTestStore(notes);
    journal = AppendTestJournal();
    acknowledgements = [];
    service = ShortcutsAppendService(
        repository: notes,
        journal: journal,
        store: store,
        readDraft: (id) => store.drafts[id],
        createId: () => 'inbox-note',
        now: () => DateTime(2026, 10, 29, 10));
    notes.values['target'] = NoteDto.fromNote(Note(
        id: 'target',
        title: 'Shopping',
        description: 'Heading\nBody',
        textStyles: [
          const NoteTextStyleRange(
              start: 0,
              end: 7,
              kind: NoteTextStyleKind.heading,
              anchorId: 'heading')
        ],
        imagePaths: [
          'note_images/photo.jpg'
        ],
        imageLayouts: [
          const NoteImageLayout(path: 'note_images/photo.jpg', textOffset: 12)
        ]));
  });

  Future<Note?> apply(ShortcutAppendRequest request,
          {Future<void> Function(String)? acknowledge}) =>
      service.apply(request,
          acknowledge: acknowledge ??
              (id) async {
                acknowledgements.add(id);
              },
          titleForDay: (day) => '${day.year}-${day.month}-${day.day}',
          inboxTitle: 'Inbox');

  test('request parsing validates identity, text, destination and limits', () {
    final request = appendRequest();
    expect(ShortcutAppendRequest.parse(request.toMap())?.text, 'Added');
    for (final changes in <Map<String, Object?>>[
      {'id': '../bad'},
      {'text': '  '},
      {'text': 'a' * 100001},
      {'destination': 'unknown'},
      {'noteId': null},
      {'createdAt': -1},
      {'version': 2},
    ]) {
      expect(ShortcutAppendRequest.parse({...request.toMap(), ...changes}),
          isNull);
    }
  });

  test('append preserves formatting, photos, heading identity and metadata',
      () async {
    final original = notes.values['target']!.toDomain();
    final result = await apply(appendRequest());
    expect(result!.description, 'Heading\nBody\n\nAdded');
    expect(result.textStyles, original.textStyles);
    expect(result.imageLayouts.single.path, original.imagePaths.single);
    expect(result.imageLayouts.single.textOffset,
        lessThan(result.description!.indexOf('Added')));
    expect(result.imageLayouts.single.widthFactor,
        original.imageLayouts.single.widthFactor);
    expect(result.imagePaths, original.imagePaths);
    expect(result.title, 'Shopping');
    expect(acknowledgements, [appendRequest().id]);
    expect(store.drafts, isEmpty);
    expect(service.retainedRequests, isEmpty);
  });

  test('same UUID after native ack and service recreation is exactly once',
      () async {
    final request = appendRequest();
    await apply(request);
    final body = notes.values['target']!.description;
    final writes = notes.writes;
    service = ShortcutsAppendService(
        repository: notes,
        journal: journal,
        store: store,
        readDraft: (id) => store.drafts[id]);
    await apply(request);
    expect(notes.values['target']!.description, body);
    expect(notes.writes, writes);
    expect(acknowledgements, [request.id, request.id]);
  });

  test('native ack failure retains receipt and retry preserves later edits',
      () async {
    final request = appendRequest();
    await expectLater(
        apply(request, acknowledge: (_) async {
          throw StateError('ack failed');
        }),
        throwsStateError);
    notes.values['target'] = notes.values['target']!
        .copyWith(title: 'Renamed', description: 'Newer text');
    await apply(request);
    expect(notes.values['target']!.description, 'Newer text');
    expect(notes.values['target']!.title, 'Renamed');
    expect(service.retainedRequests, isEmpty);
  });

  test('interruption after note commit retries without another append',
      () async {
    journal.failCommit = true;
    await expectLater(apply(appendRequest()), throwsStateError);
    expect(notes.values['target']!.description, 'Heading\nBody\n\nAdded');
    journal.failCommit = false;
    await apply(appendRequest());
    expect(notes.values['target']!.description, 'Heading\nBody\n\nAdded');
    expect(notes.writes, 1);
  });

  test('ambiguous interrupted edits are retained for review, never guessed',
      () async {
    journal.failCommit = true;
    await expectLater(apply(appendRequest()), throwsStateError);
    journal.failCommit = false;
    notes.values['target'] =
        notes.values['target']!.copyWith(description: 'Unrelated replacement');
    await expectLater(
        apply(appendRequest()),
        throwsA(isA<ShortcutAppendException>().having(
            (e) => e.failure, 'failure', ShortcutAppendFailure.conflict)));
    expect(notes.values['target']!.description, 'Unrelated replacement');
    expect(service.retainedRequests.single.text, 'Added');
    await service.discard(appendRequest().id, acknowledge: (id) async {
      acknowledgements.add(id);
    });
    expect(service.retainedRequests, isEmpty);
    await apply(appendRequest());
    expect(notes.values['target']!.description, 'Unrelated replacement');
  });

  test('live editor registry owns append and busy editor can retry', () async {
    var active = notes.values['target']!
        .toDomain()
        .copyWith(description: 'Unsaved typing');
    var busy = true;
    final unregister =
        NoteSelectionTransfer.registerEditor('target', (selection) async {
      if (busy) return false;
      active = appendSelectionToNote(active, selection);
      await store.saveNote(active);
      return true;
    });
    addTearDown(unregister);
    await expectLater(
        apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
    expect(notes.values['target']!.description, 'Heading\nBody');
    busy = false;
    await apply(appendRequest());
    expect(active.description, 'Unsaved typing\n\nAdded');
    expect(notes.values['target']!.description, active.description);
  });

  test('failed save keeps draft and retry flushes it without duplicate text',
      () async {
    notes.failSave = true;
    await expectLater(
        apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
    expect(store.drafts['target']!.description, 'Heading\nBody\n\nAdded');
    notes.failSave = false;
    await apply(appendRequest());
    expect(notes.values['target']!.description, 'Heading\nBody\n\nAdded');
    expect(store.drafts, isEmpty);
  });

  test('today captures intended local day and reuses existing daily note',
      () async {
    final request = appendRequest(
        destination: ShortcutAppendDestination.today,
        createdAt: DateTime(2026, 10, 28, 23, 59));
    final result = await apply(request);
    expect(result!.dailyNoteDateKey, '2026-10-28');
    final second = await apply(appendRequest(
        sequence: 2,
        destination: ShortcutAppendDestination.today,
        createdAt: DateTime(2026, 10, 28, 23, 59),
        text: 'Second'));
    expect(second!.id, result.id);
    expect(second.description, 'Added\n\nSecond');
  });

  test(
      'Inbox creates once, survives title edits and appends subsequent requests',
      () async {
    final first = await apply(
        appendRequest(destination: ShortcutAppendDestination.inbox));
    notes.values[first!.id!] =
        notes.values[first.id!]!.copyWith(title: 'My capture box');
    final second = await apply(appendRequest(
        sequence: 2,
        destination: ShortcutAppendDestination.inbox,
        text: 'Second'));
    expect(second!.id, first.id);
    expect(second.title, 'My capture box');
    expect(second.description, 'Added\n\nSecond');
    expect(notes.values.length, 2);
  });

  test('free limit blocks new destinations but permits existing note append',
      () async {
    final fixture = PremiumTestFixture();
    await fixture.init();
    addTearDown(fixture.dispose);
    for (var i = 0; i < 9; i++) {
      notes.values['note-$i'] =
          NoteDto.fromNote(Note(id: 'note-$i', title: 'Saved'));
    }
    service = ShortcutsAppendService(
        repository: notes,
        journal: journal,
        store: store,
        readDraft: (id) => store.drafts[id],
        premiumAccess: fixture.access,
        createId: () => 'new-inbox');
    await expectLater(
        apply(appendRequest(destination: ShortcutAppendDestination.inbox)),
        throwsA(isA<PremiumRequired>()));
    expect(notes.values.length, 10);
    await apply(appendRequest(sequence: 2));
    expect(notes.values['target']!.description, endsWith('Added'));
  });

  test('deleted and archived notes stay unavailable and are never recreated',
      () async {
    notes.values['target'] = notes.values['target']!
        .copyWith(deletedAt: DateTime(2026).toIso8601String());
    await expectLater(
        apply(appendRequest()),
        throwsA(isA<ShortcutAppendException>().having(
            (e) => e.failure, 'failure', ShortcutAppendFailure.unavailable)));
    notes.values.remove('target');
    await expectLater(
        apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
    expect(notes.values, isEmpty);
  });
  for (final archive in [false, true]) {
    test(
        'recovery never reverts ${archive ? 'Archive' : 'Trash'} after failed save',
        () async {
      notes.failSave = true;
      await expectLater(
          apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
      notes.failSave = false;
      notes.values['target'] = notes.values['target']!.copyWith(
          isArchived: archive,
          deletedAt: archive ? null : DateTime(2026).toIso8601String());
      await expectLater(
          apply(appendRequest()),
          throwsA(isA<ShortcutAppendException>().having(
              (error) => error.failure,
              'reason',
              ShortcutAppendFailure.unavailable)));
      expect(notes.writes, 0);
      expect(notes.values['target']!.isArchived, archive);
      expect(notes.values['target']!.isDeleted, !archive);
    });
  }

  test('recovery cannot recreate a permanently removed existing destination',
      () async {
    notes.failSave = true;
    await expectLater(
        apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
    notes.failSave = false;
    notes.values.remove('target');
    await expectLater(
        apply(appendRequest()),
        throwsA(isA<ShortcutAppendException>().having((error) => error.failure,
            'reason', ShortcutAppendFailure.unavailable)));
    expect(notes.values, isEmpty);
    expect(notes.writes, 0);
  });

  test('recovery retains latest library flags, colors, tags and relationships',
      () async {
    notes.failSave = true;
    await expectLater(
        apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
    notes.failSave = false;
    final saved = notes.values['target']!.toDomain().copyWith(
        folderId: 'new-folder',
        isPinned: true,
        sortOrder: 123,
        tags: ['fresh'],
        linkedNoteIds: ['other-note'],
        dailyNoteDateKey: '2026-10-29',
        color: const Color(0xff112233),
        cardStyle: const NoteCardStyle(fontSize: AppFontSize.large));
    notes.values['target'] = NoteDto.fromNote(saved);
    final result = await apply(appendRequest());
    expect(result!.description, 'Heading\nBody\n\nAdded');
    expect(result.folderId, 'new-folder');
    expect(result.isPinned, isTrue);
    expect(result.sortOrder, 123);
    expect(result.tags, ['fresh']);
    expect(result.linkedNoteIds, ['other-note']);
    expect(result.dailyNoteDateKey, '2026-10-29');
    expect(result.color, saved.color);
    expect(result.cardStyle, saved.cardStyle);
  });

  test('newer checklist edits force review instead of stale draft overwrite',
      () async {
    notes.values['target'] = NoteDto.fromNote(notes.values['target']!
        .toDomain()
        .copyWith(todo: [Todo(id: 'task', title: 'Keep completion')]));
    notes.failSave = true;
    await expectLater(
        apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
    notes.failSave = false;
    notes.values['target'] = NoteDto.fromNote(notes.values['target']!
        .toDomain()
        .copyWith(todo: [
      Todo(id: 'task', title: 'Keep completion', completed: true)
    ]));
    await expectLater(
        apply(appendRequest()),
        throwsA(isA<ShortcutAppendException>().having((error) => error.failure,
            'reason', ShortcutAppendFailure.conflict)));
    expect(notes.values['target']!.toDomain().todo.single.completed, isTrue);
    expect(notes.values['target']!.description, 'Heading\nBody');
    expect(notes.writes, 0);
    expect(service.retainedRequests, hasLength(1));
  });

  test('unacknowledged discard tombstone survives bounded receipt eviction',
      () async {
    final request = appendRequest(noteId: 'missing');
    await service.discard(request.id, acknowledge: (_) async {});
    // A second request is discarded while native acknowledgement fails.
    final retained = appendRequest(sequence: 2, noteId: 'missing');
    await expectLater(
        service.discard(retained.id, acknowledge: (_) async {
          throw StateError('Native ack unavailable');
        }),
        throwsStateError);
    journal.values
        .remove('${ShortcutsAppendService.receiptPrefix}${retained.id}');
    notes.values['missing'] =
        NoteDto.fromNote(Note(id: 'missing', title: 'Available later'));
    service = ShortcutsAppendService(
        repository: notes,
        journal: journal,
        store: store,
        readDraft: (id) => store.drafts[id]);
    expect(await apply(retained), isNull);
    expect(notes.values['missing']!.description, isNull);
    expect(notes.writes, 0);
  });

  test(
      'discard cleanup failure retains tombstone and cannot resurrect new Inbox draft',
      () async {
    final request = appendRequest(destination: ShortcutAppendDestination.inbox);
    notes.failSave = true;
    await expectLater(apply(request), throwsStateError);
    expect(store.drafts['inbox-note']!.description, 'Added');
    notes.failSave = false;
    store.failRemove = true;
    await expectLater(service.discard(request.id, acknowledge: (_) async {}),
        throwsStateError);
    journal.values
        .remove('${ShortcutsAppendService.receiptPrefix}${request.id}');
    store.failRemove = false;
    service = ShortcutsAppendService(
        repository: notes,
        journal: journal,
        store: store,
        readDraft: (id) => store.drafts[id]);
    expect(await apply(request), isNull);
    expect(notes.values.containsKey('inbox-note'), isFalse);
    expect(store.drafts, isEmpty);
    expect(service.retainedRequests, isEmpty);
  });
  test(
      'old before-body draft cannot bypass fresh content validation after failed draft write',
      () async {
    final original = notes.values['target']!
        .toDomain()
        .copyWith(todo: [Todo(id: 'task', title: 'Keep the new completion')]);
    notes.values['target'] = NoteDto.fromNote(original);
    store.drafts['target'] = original;
    store.failDraftWrite = true;
    await expectLater(
        apply(appendRequest()), throwsA(isA<ShortcutAppendException>()));
    expect(store.drafts['target']!.description, 'Heading\nBody');
    store.failDraftWrite = false;
    notes.values['target'] = NoteDto.fromNote(original.copyWith(todo: [
      Todo(id: 'task', title: 'Keep the new completion', completed: true)
    ]));
    await expectLater(
        apply(appendRequest()),
        throwsA(isA<ShortcutAppendException>().having((error) => error.failure,
            'reason', ShortcutAppendFailure.conflict)));
    expect(notes.values['target']!.toDomain().todo.single.completed, isTrue);
    expect(notes.values['target']!.description, 'Heading\nBody');
    expect(notes.writes, 0);
    expect(service.retainedRequests, hasLength(1));
  });
}
