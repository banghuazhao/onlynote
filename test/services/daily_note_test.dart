import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/daily_note.dart';

class _Notes extends Fake implements NoteRepository {
  final saved = <String, NoteDto>{};
  int writes = 0;
  bool fail = false;
  Completer<void>? writeGate;

  @override
  List<NoteDto> getAllNotes() => saved.values.toList();

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    await writeGate?.future;
    if (fail) throw StateError('Storage unavailable');
    saved[note.id!] = note;
  }
}

String _title(DateTime day) => dailyNoteDateKey(day);

void main() {
  test('creates once and reuses edited content after service recreation',
      () async {
    final notes = _Notes();
    final day = DateTime(2026, 10, 6, 23, 58);
    final service =
        DailyNoteService(notes, now: () => day, createId: () => 'new');
    final first = await service.openToday(titleForDay: _title);
    expect(first.dailyNoteDateKey, '2026-10-06');
    expect(first.title, '2026-10-06');
    expect(first.description, '');
    expect(first.dateTime, day);
    notes.saved['new'] = notes.saved['new']!.copyWith(
        title: 'A title I changed', description: 'Keep these thoughts');
    final later = await DailyNoteService(notes, now: () => day)
        .openToday(titleForDay: (_) => 'Another title');
    expect(later.id, first.id);
    expect(later.title, 'A title I changed');
    expect(later.description, 'Keep these thoughts');
    expect(notes.writes, 1);
  });

  test('rapid requests from separate service instances share the durable write',
      () async {
    final notes = _Notes()..writeGate = Completer<void>();
    final day = DateTime(2026, 10, 6);
    final first = DailyNoteService(notes, now: () => day, createId: () => 'one')
        .openToday(titleForDay: _title);
    final second =
        DailyNoteService(notes, now: () => day, createId: () => 'two')
            .openToday(titleForDay: _title);
    expect(identical(first, second), isTrue);
    expect(notes.writes, 1);
    notes.writeGate!.complete();
    expect((await first).id, (await second).id);
    expect(notes.saved.keys, ['one']);
  });

  test('failed save can be retried without keeping a stale in-flight note',
      () async {
    final notes = _Notes()..fail = true;
    final service = DailyNoteService(notes,
        now: () => DateTime(2026, 10, 6), createId: () => 'one');
    await expectLater(service.openToday(titleForDay: _title), throwsStateError);
    expect(notes.saved, isEmpty);
    notes.fail = false;
    expect((await service.openToday(titleForDay: _title)).id, 'one');
    expect(notes.writes, 2);
  });

  test('local midnight uses a new day without relying on 24-hour intervals',
      () async {
    final notes = _Notes();
    var now = DateTime(2026, 9, 27, 23, 59);
    var id = 0;
    final service =
        DailyNoteService(notes, now: () => now, createId: () => 'note-${++id}');
    final before = await service.openToday(titleForDay: _title);
    now = DateTime(2026, 9, 28);
    final after = await service.openToday(titleForDay: _title);
    expect(before.dailyNoteDateKey, '2026-09-27');
    expect(after.dailyNoteDateKey, '2026-09-28');
    expect(after.id, isNot(before.id));
    now = DateTime(2026, 9, 28, 22);
    expect((await service.openToday(titleForDay: _title)).id, after.id);
    expect(notes.writes, 2);
  });

  test('archived daily note opens without unarchiving or replacing it',
      () async {
    final notes = _Notes()
      ..saved['archived'] = NoteDto(
          id: 'archived',
          title: 'Archived thoughts',
          isArchived: true,
          folderId: 'folder',
          dailyNoteDateKey: '2026-10-06');
    final note = await DailyNoteService(notes, now: () => DateTime(2026, 10, 6))
        .openToday(titleForDay: _title);
    expect(note.id, 'archived');
    expect(note.isArchived, isTrue);
    expect(note.folderId, 'folder');
    expect(notes.writes, 0);
  });

  test('trashed daily note remains untouched and date-like titles are ignored',
      () async {
    final notes = _Notes()
      ..saved['trash'] = NoteDto(
          id: 'trash',
          title: 'Deleted thoughts',
          deletedAt: DateTime(2026, 10, 6, 9).toIso8601String(),
          dailyNoteDateKey: '2026-10-06')
      ..saved['ordinary'] = NoteDto(id: 'ordinary', title: '2026-10-06');
    final note = await DailyNoteService(notes,
        now: () => DateTime(2026, 10, 6),
        createId: () => 'replacement').openToday(titleForDay: _title);
    expect(note.id, 'replacement');
    expect(notes.saved['trash']!.isDeleted, isTrue);
    expect(notes.saved['ordinary']!.dailyNoteDateKey, isNull);
    expect(notes.writes, 1);
  });

  test('restore collisions choose active then oldest association consistently',
      () {
    final notes = [
      NoteDto(id: 'archive', isArchived: true, dailyNoteDateKey: '2026-10-06'),
      NoteDto(
          id: 'later',
          dateTime: DateTime(2026, 10, 6, 18).toIso8601String(),
          dailyNoteDateKey: '2026-10-06'),
      NoteDto(
          id: 'earlier',
          dateTime: DateTime(2026, 10, 6, 9).toIso8601String(),
          dailyNoteDateKey: '2026-10-06'),
    ];
    expect(dailyNoteForDay(notes, '2026-10-06')!.id, 'earlier');
    expect(dailyNoteForDay(notes.reversed, '2026-10-06')!.id, 'earlier');
  });

  test(
      'day keys reject invalid dates and DTO copies preserve or clear identity',
      () {
    for (final invalid in [
      null,
      '2026-2-03',
      '2026-02-30',
      '0000-01-01',
      123
    ]) {
      expect(isValidDailyNoteDateKey(invalid), isFalse);
    }
    expect(isValidDailyNoteDateKey('2028-02-29'), isTrue);
    final dto = NoteDto(id: 'note', dailyNoteDateKey: '2026-10-06');
    expect(dto.copyWith(title: 'Renamed').dailyNoteDateKey, '2026-10-06');
    expect(dto.copyWith(clearDailyNoteDateKey: true).dailyNoteDateKey, isNull);
    expect(NoteDto.fromNote(dto.toDomain()).dailyNoteDateKey, '2026-10-06');
    expect(NoteDto(id: 'old').toDomain().dailyNoteDateKey, isNull);
    expect(
        NoteDto(id: 'bad', dailyNoteDateKey: '2026-02-30')
            .toDomain()
            .dailyNoteDateKey,
        isNull);
  });

  test('templates made from a daily note create ordinary independent notes',
      () {
    final template = CustomNoteTemplate.fromNote(
      Note(
          id: 'daily',
          title: 'Daily outline',
          description: 'Keep the outline',
          dailyNoteDateKey: '2026-10-06'),
      name: 'My outline',
      imageCopies: [],
    );
    final created = template.createNote(imageCopies: []);
    expect(created.dailyNoteDateKey, isNull);
    expect(created.title, 'Daily outline');
    expect(created.description, 'Keep the outline');
    expect(created.id, isNot('daily'));
  });
}
