import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/daily_note.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/services/premium_access.dart';

import '../support/premium_test_fakes.dart';

class _Notes extends Fake implements NoteRepository {
  final values = <String, NoteDto>{};
  Completer<void>? nextWrite;

  @override
  List<NoteDto> getAllNotes() => values.values.toList();

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    await nextWrite?.future;
    values[note.id!] = note;
  }
}

void main() {
  late PremiumTestFixture fixture;
  late _Notes notes;

  setUp(() async {
    fixture = PremiumTestFixture();
    await fixture.init();
    notes = _Notes();
  });

  tearDown(() => fixture.dispose());

  Future<void> create(String id) =>
      NoteCreationLimit.save(notes, NoteDto(id: id, title: 'Note $id'),
          access: fixture.access);

  test('free users create ten notes; archived notes count, Trash does not',
      () async {
    notes.values['archived'] =
        NoteDto(id: 'archived', title: 'Archived', isArchived: true);
    notes.values['trash'] = NoteDto(
        id: 'trash',
        title: 'Trash',
        deletedAt: DateTime.now().toIso8601String());
    for (var i = 0; i < 9; i++) {
      await create('$i');
    }
    expect(NoteCreationLimit.count(notes), 10);
    await expectLater(create('blocked'), throwsA(isA<PremiumRequired>()));
    expect(notes.values.containsKey('blocked'), isFalse);
    notes.values['0'] = notes.values['0']!
        .copyWith(deletedAt: DateTime.now().toIso8601String());
    await create('slot-after-trash');
    expect(NoteCreationLimit.count(notes), 10);
  });

  test('concurrent tenth and eleventh saves cannot exceed the free cap',
      () async {
    for (var i = 0; i < 9; i++) {
      await create('$i');
    }
    notes.nextWrite = Completer<void>();
    final tenth = create('tenth');
    final eleventh = create('eleventh');
    final blocked = expectLater(eleventh, throwsA(isA<PremiumRequired>()));
    notes.nextWrite!.complete();
    await tenth;
    await blocked;
    expect(NoteCreationLimit.count(notes), 10);
    expect(notes.values.containsKey('eleventh'), isFalse);
  });

  test('existing libraries over the cap can edit without losing any note',
      () async {
    for (var i = 0; i < 15; i++) {
      notes.values['$i'] = NoteDto(id: '$i', title: 'Existing $i');
    }
    await NoteCreationLimit.save(
        notes, notes.values['0']!.copyWith(description: 'Edited content'),
        access: fixture.access);
    expect(notes.values['0']!.description, 'Edited content');
    expect(NoteCreationLimit.count(notes), 15);
    await expectLater(create('new'), throwsA(isA<PremiumRequired>()));
  });

  test('Premium unlocks creation immediately using the same access instance',
      () async {
    for (var i = 0; i < 10; i++) {
      await create('$i');
    }
    fixture.store.grant();
    await pumpEventQueue();
    await create('premium-eleven');
    expect(NoteCreationLimit.count(notes), 11);
  });

  test('daily note reuse stays free and new daily notes obey the cap',
      () async {
    for (var i = 0; i < 10; i++) {
      await create('$i');
    }
    notes.values['0'] =
        notes.values['0']!.copyWith(dailyNoteDateKey: '2026-10-07');
    final existing = await DailyNoteService(notes,
            now: () => DateTime(2026, 10, 7), premiumAccess: fixture.access)
        .openToday(titleForDay: (_) => 'Today');
    expect(existing.id, '0');
    await expectLater(
        DailyNoteService(notes,
                now: () => DateTime(2026, 10, 8), premiumAccess: fixture.access)
            .openToday(titleForDay: (_) => 'Tomorrow'),
        throwsA(isA<PremiumRequired>()));
    expect(NoteCreationLimit.count(notes), 10);
  });

  test('autosave preserves interrupted drafts for recovery above the limit',
      () async {
    final directory = await Directory.systemTemp.createTemp('note-cap-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(NoteDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TodoDtoAdapter());
    final drafts = await Hive.openBox('premium-note-drafts');
    try {
      for (var i = 0; i < 10; i++) {
        await create('$i');
      }
      final store =
          HiveNoteAutosaveStore(notes, drafts, premiumAccess: fixture.access);
      final draft = Note(id: 'interrupted', title: 'Keep this content');
      await store.writeDraft(draft);
      await expectLater(store.saveNote(draft), throwsA(isA<PremiumRequired>()));
      expect(drafts.get('interrupted'), isA<NoteDto>());
      expect(notes.values.containsKey('interrupted'), isFalse);
      await store.recover();
      expect(notes.values['interrupted']!.title, 'Keep this content');
      expect(drafts.get('interrupted'), isNull);
    } finally {
      await drafts.close();
      await directory.delete(recursive: true);
    }
  });
}
