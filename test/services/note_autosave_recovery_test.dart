import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/shortcuts_append.dart';

class _RecoveryNotes implements NoteRepository {
  _RecoveryNotes(this.box);
  final Box box;
  bool failSave = false;
  int writes = 0;

  @override
  List<NoteDto> getAllNotes() => box.values.cast<NoteDto>().toList();
  @override
  Future<NoteDto> getNote(String id) async => box.get(id) as NoteDto;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    if (failSave) throw StateError('Storage unavailable');
    writes++;
    await box.put(note.id!, note);
    await box.flush();
  }

  @override
  Future<void> deleteNote(String id) => box.delete(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) => box.deleteAll(ids);
}

void main() {
  late Directory directory;
  late Box notes;
  late Box drafts;
  late _RecoveryNotes repository;

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('onlynote-autosave-recovery-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    notes = await Hive.openBox('autosave_recovery_notes');
    drafts = await Hive.openBox('autosave_recovery_drafts');
    repository = _RecoveryNotes(notes);
  });
  tearDown(() async {
    await drafts.close();
    await notes.close();
    await directory.delete(recursive: true);
  });

  Future<void> stage(Note draft) async {
    await drafts.put(draft.id!, NoteDto.fromNote(draft));
    await drafts.flush();
    // Exercise recovery from the serialized disk record rather than an object
    // still retained by the box's in-memory cache.
    await drafts.close();
    drafts = await Hive.openBox('autosave_recovery_drafts');
  }

  Future<void> recover() => HiveNoteAutosaveStore(repository, drafts).recover();

  const shortcutRequest = ShortcutAppendRequest(
      id: '12345678-1234-1234-1234-000000000001',
      text: 'Captured text',
      destination: ShortcutAppendDestination.note,
      createdAt: 0,
      noteId: 'shortcut-target');

  ShortcutsAppendService shortcuts() => ShortcutsAppendService(
      repository: repository,
      journal: HiveShortcutAppendJournal(drafts),
      store: HiveNoteAutosaveStore(repository, drafts),
      readDraft: (id) => (drafts.get(id) as NoteDto?)?.toDomain());

  Future<Note?> append(ShortcutsAppendService service) =>
      service.apply(shortcutRequest,
          acknowledge: (_) async {},
          titleForDay: (_) => 'Today',
          inboxTitle: 'Inbox');

  Future<Note> failShortcut() async {
    final original = Note(
        id: 'shortcut-target',
        title: 'Shopping',
        description: 'Before',
        todo: [Todo(id: 'task', title: 'Keep completion')]);
    await notes.put(original.id, NoteDto.fromNote(original));
    repository.failSave = true;
    await expectLater(
        append(shortcuts()), throwsA(isA<ShortcutAppendException>()));
    repository.failSave = false;
    expect((drafts.get(original.id) as NoteDto).description,
        'Before\n\nCaptured text');
    return original;
  }

  test('restart defers failed shortcut draft before newer checklist state',
      () async {
    final original = await failShortcut();
    final newer = original.copyWith(
        todo: [Todo(id: 'task', title: 'Keep completion', completed: true)]);
    await notes.put(newer.id, NoteDto.fromNote(newer));
    await stage(Note(id: 'unrelated', description: 'Normal typing recovery'));

    await recover();

    expect((notes.get(newer.id) as NoteDto).toDomain(), newer);
    expect((notes.get('unrelated') as NoteDto).description,
        'Normal typing recovery');
    expect(drafts.get(newer.id), isA<NoteDto>());
    expect(shortcuts().retainedRequests.single.text, 'Captured text');
    await expectLater(
        append(shortcuts()),
        throwsA(isA<ShortcutAppendException>().having((error) => error.failure,
            'reason', ShortcutAppendFailure.conflict)));
    expect((notes.get(newer.id) as NoteDto).toDomain(), newer);
  });

  test('discarded failed existing-note append cannot replay on restart',
      () async {
    final original = await failShortcut();
    await shortcuts().discard(shortcutRequest.id, acknowledge: (_) async {});
    await drafts.close();
    drafts = await Hive.openBox('autosave_recovery_drafts');

    await recover();

    expect((notes.get(original.id) as NoteDto).toDomain(), original);
    expect(drafts.get(original.id), isNull);
    expect(shortcuts().retainedRequests, isEmpty);
  });

  for (final linksOnly in [false, true]) {
    test(
        'discard preserves a newer ${linksOnly ? 'links-only' : 'typing'} draft for recovery',
        () async {
      final original = await failShortcut();
      final edited = linksOnly
          ? (drafts.get(original.id) as NoteDto)
              .toDomain()
              .copyWith(linkedNoteIds: ['new-independent-link'])
          : original.copyWith(
              title: 'My newer title',
              description: 'Keep these independent edits');
      await stage(edited);
      await shortcuts().discard(shortcutRequest.id, acknowledge: (_) async {});
      expect((drafts.get(original.id) as NoteDto).toDomain(), edited);
      await recover();
      expect((notes.get(original.id) as NoteDto).toDomain(), edited);
      expect(drafts.get(original.id), isNull);
    });
  }

  test('unacknowledged discard protects its owned draft across restart',
      () async {
    final original = await failShortcut();
    await expectLater(
        shortcuts().discard(shortcutRequest.id, acknowledge: (_) async {
          throw StateError('Native acknowledgement failed');
        }),
        throwsStateError);
    await drafts.close();
    drafts = await Hive.openBox('autosave_recovery_drafts');
    await recover();
    expect((notes.get(original.id) as NoteDto).toDomain(), original);
    expect(drafts.get(original.id), isA<NoteDto>());
    await shortcuts().discard(shortcutRequest.id, acknowledge: (_) async {});
    await recover();
    expect((notes.get(original.id) as NoteDto).toDomain(), original);
    expect(drafts.get(original.id), isNull);
  });

  test('an older active draft cannot restore a note now in Trash', () async {
    final draft = Note(
        id: 'trashed',
        title: 'Draft before trash',
        description: 'Unsaved content',
        linkedNoteIds: const ['reference']);
    final trashed = NoteDto.fromNote(draft.copyWith(
        title: 'Stored trash title',
        deletedAt: DateTime.utc(2026, 10, 6),
        isArchived: true,
        tags: const ['Stored']));
    await notes.put(trashed.id, trashed);
    await stage(draft);

    await recover();

    final retained = notes.get('trashed') as NoteDto;
    expect(repository.writes, 0);
    expect(retained.isDeleted, isTrue);
    expect(retained.deletedAt, trashed.deletedAt);
    expect(retained.title, 'Stored trash title');
    expect(retained.isArchived, isTrue);
    expect(retained.tags, ['Stored']);
    expect(drafts.isEmpty, isTrue);
    await drafts.close();
    drafts = await Hive.openBox('autosave_recovery_drafts');
    await recover();
    expect(repository.writes, 0);
    expect((notes.get('trashed') as NoteDto).isDeleted, isTrue);
  });

  for (final archived in [false, true]) {
    test('draft content preserves the current archived=$archived state',
        () async {
      final stored = Note(
          id: 'existing',
          title: 'Stored title',
          description: 'Stored body',
          isArchived: archived,
          folderId: 'latest-folder',
          isPinned: true,
          sortOrder: -42,
          tags: const ['Stored'],
          linkedNoteIds: const ['stored-link']);
      await notes.put(stored.id, NoteDto.fromNote(stored));
      final draft = stored.copyWith(
          title: 'Explicit draft title',
          description: 'Explicit draft body',
          isArchived: !archived,
          folderId: 'old-folder',
          isPinned: false,
          sortOrder: -1,
          tags: const ['Draft'],
          linkedNoteIds: const ['draft-link'],
          todo: [Todo(id: 'task', title: 'Draft task', completed: true)]);
      await stage(draft);

      await recover();

      final recovered = (notes.get('existing') as NoteDto).toDomain();
      expect(recovered.isArchived, archived);
      expect(recovered.folderId, 'latest-folder');
      expect(recovered.isPinned, isTrue);
      expect(recovered.sortOrder, -42);
      expect(recovered.title, draft.title);
      expect(recovered.description, draft.description);
      expect(recovered.tags, ['Draft']);
      expect(recovered.linkedNoteIds, ['draft-link']);
      expect(recovered.todo, draft.todo);
      expect(recovered.isDeleted, isFalse);
      expect(repository.writes, 1);
      expect(drafts.isEmpty, isTrue);
      await recover();
      expect(repository.writes, 1);
    });
  }

  test('normal active recovery retains all explicit draft content', () async {
    final stored = Note(
        id: 'active',
        title: 'Stored',
        folderId: 'folder',
        isPinned: true,
        sortOrder: -42);
    await notes.put(stored.id, NoteDto.fromNote(stored));
    final draft = stored.copyWith(
        title: 'Recovered',
        description: 'Latest body',
        folderId: 'folder',
        isPinned: true,
        sortOrder: -42,
        tags: const [
          'Work'
        ],
        linkedNoteIds: const [
          'reference'
        ],
        imagePaths: const [
          'note_images/retained.jpg'
        ],
        imageLayouts: const [
          NoteImageLayout(
              path: 'note_images/retained.jpg',
              textOffset: 11,
              widthFactor: .6,
              xFactor: .2,
              aspectRatio: 2),
        ],
        textStyles: const [
          NoteTextStyleRange(start: 0, end: 6, kind: NoteTextStyleKind.bold),
        ]);
    await stage(draft);

    await recover();

    expect((notes.get('active') as NoteDto).toDomain(), draft);
    expect(repository.writes, 1);
    expect(drafts.isEmpty, isTrue);
  });

  for (final currentDay in [null, '2026-10-05']) {
    test('stale draft respects the current daily association $currentDay',
        () async {
      final stored = Note(
          id: 'restored',
          title: 'Restored old thoughts',
          dailyNoteDateKey: currentDay);
      final owner = Note(
          id: 'today',
          title: 'Today\'s replacement',
          dailyNoteDateKey: '2026-10-06');
      await notes.put(stored.id, NoteDto.fromNote(stored));
      await notes.put(owner.id, NoteDto.fromNote(owner));
      await stage(stored.copyWith(
          title: 'Keep draft edits',
          description: 'Recover my unsaved thoughts',
          dailyNoteDateKey: '2026-10-06'));

      await recover();

      final recovered = (notes.get('restored') as NoteDto).toDomain();
      expect(recovered.dailyNoteDateKey, currentDay);
      expect(recovered.title, 'Keep draft edits');
      expect(recovered.description, 'Recover my unsaved thoughts');
      expect((notes.get('today') as NoteDto).toDomain(), owner);
      expect(repository.writes, 1);
      expect(drafts.isEmpty, isTrue);
    });
  }

  test('legacy photo drafts recover with placement after the existing body',
      () async {
    await drafts.put(
        'legacy',
        NoteDto(
          id: 'legacy',
          description: 'Original body',
          imagePaths: const ['note_images/legacy.jpg'],
          imageLayouts: null,
        ));
    await drafts.flush();
    await drafts.close();
    drafts = await Hive.openBox('autosave_recovery_drafts');

    await recover();

    final recovered = (notes.get('legacy') as NoteDto).toDomain();
    expect(recovered.description, 'Original body');
    expect(recovered.imagePaths, ['note_images/legacy.jpg']);
    expect(recovered.imageLayouts, const [
      NoteImageLayout(path: 'note_images/legacy.jpg', textOffset: 13),
    ]);
    expect(repository.writes, 1);
    expect(drafts.isEmpty, isTrue);
  });

  test('new meaningful drafts recover and empty new drafts remain unsaved',
      () async {
    final newNote = Note(
        id: 'new',
        description: 'Recover this new note',
        tags: const ['Work'],
        linkedNoteIds: const ['reference']);
    await stage(newNote);
    await stage(Note(id: 'empty'));

    await recover();

    expect((notes.get('new') as NoteDto).toDomain(), newNote);
    expect(notes.containsKey('empty'), isFalse);
    expect(repository.writes, 1);
    expect(drafts.isEmpty, isTrue);
  });

  test('failed replay retains its journal and rereads archive state on retry',
      () async {
    final stored = Note(id: 'retry', title: 'Stored');
    await notes.put(stored.id, NoteDto.fromNote(stored));
    await stage(stored.copyWith(description: 'Recover after storage returns'));
    repository.failSave = true;

    await recover();

    expect((notes.get('retry') as NoteDto).description, isNull);
    expect(drafts.get('retry'), isA<NoteDto>());
    await notes.put(
        stored.id, NoteDto.fromNote(stored.copyWith(isArchived: true)));
    repository.failSave = false;
    await recover();
    final recovered = notes.get('retry') as NoteDto;
    expect(recovered.isArchived, isTrue);
    expect(recovered.description, 'Recover after storage returns');
    expect(drafts.isEmpty, isTrue);
    expect(repository.writes, 1);
  });
}
