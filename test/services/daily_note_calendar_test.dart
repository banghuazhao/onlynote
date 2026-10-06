import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/daily_note.dart';
import 'package:onlynote/services/daily_note_calendar.dart';

class _Notes extends Fake implements NoteRepository {
  final notes = <String, NoteDto>{};
  int writes = 0;
  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    notes[note.id!] = note;
  }
}

void main() {
  test('association stays on its day after renaming and editing on another day',
      () {
    final note = Note(
        id: 'daily',
        title: 'A renamed note',
        description: 'Keep every thought',
        dailyNoteDateKey: '2026-10-06',
        dateTime: DateTime(2026, 12, 2, 18));
    final ordinary = Note(
        id: 'ordinary',
        title: 'October 7, 2026',
        dateTime: DateTime(2026, 10, 7));
    final index = DailyNoteCalendarIndex.fromNotes([note, ordinary]);
    expect(index.noteForDay(DateTime(2026, 10, 6, 23, 59)), same(note));
    expect(index.noteForDay(DateTime(2026, 12, 2)), isNull);
    expect(index.noteForDay(DateTime(2026, 10, 7)), isNull);
    expect(index.notesByDay.keys, ['2026-10-06']);
  });

  test('archived notes appear while trash and unusable IDs remain absent', () {
    final archive = Note(
        id: 'archive',
        title: 'Saved history',
        isArchived: true,
        dailyNoteDateKey: '2026-10-06');
    final index = DailyNoteCalendarIndex.fromNotes([
      archive,
      Note(
          id: 'trash',
          dailyNoteDateKey: '2026-10-07',
          deletedAt: DateTime(2026, 10, 8)),
      Note(dailyNoteDateKey: '2026-10-08'),
      Note(id: '', dailyNoteDateKey: '2026-10-09'),
      Note(id: '   ', dailyNoteDateKey: '2026-10-10'),
    ]);
    expect(index.noteForDay(DateTime(2026, 10, 6)), same(archive));
    expect(index.notesByDay.keys, ['2026-10-06']);
    expect(archive.isArchived, isTrue);
  });

  test('valid leap dates and year rollover sort correctly; invalid keys vanish',
      () {
    final index = DailyNoteCalendarIndex.fromNotes([
      Note(id: 'new-year', dailyNoteDateKey: '2027-01-01'),
      Note(id: 'leap', dailyNoteDateKey: '2024-02-29'),
      Note(id: 'old-year', dailyNoteDateKey: '2026-12-31'),
      for (final key in [
        '2026-02-29',
        '2024-02-30',
        '2026-2-01',
        '0000-01-01',
        '2026-01-01T00:00:00',
        'tomorrow'
      ])
        Note(id: key, dailyNoteDateKey: key),
    ]);
    expect(index.notesByDay.keys, ['2024-02-29', '2026-12-31', '2027-01-01']);
    expect(index.firstDay, DateTime(2024, 2, 29));
    expect(index.lastDay, DateTime(2027, 1, 1));
    expect(index.noteForDay(DateTime(2024, 2, 29))!.id, 'leap');
    expect(index.noteForDay(DateTime(2026, 12, 31))!.id, 'old-year');
    expect(index.noteForDay(DateTime(2027, 1, 1))!.id, 'new-year');
  });

  test(
      'calendar duplicate selection agrees with Today across active/archive ties',
      () {
    final notes = [
      Note(
          id: 'archive',
          isArchived: true,
          dailyNoteDateKey: '2026-10-06',
          dateTime: DateTime(2026, 10, 6, 7)),
      Note(
          id: 'later',
          dailyNoteDateKey: '2026-10-06',
          dateTime: DateTime(2026, 10, 6, 18)),
      Note(
          id: 'b-earlier',
          dailyNoteDateKey: '2026-10-06',
          dateTime: DateTime(2026, 10, 6, 9)),
      Note(
          id: 'a-earlier',
          dailyNoteDateKey: '2026-10-06',
          dateTime: DateTime(2026, 10, 6, 9)),
      Note(id: 'unknown-date', dailyNoteDateKey: '2026-10-06'),
    ];
    for (final input in [notes, notes.reversed.toList()]) {
      final expected =
          dailyNoteForDay(input.map(NoteDto.fromNote), '2026-10-06')!;
      final index = DailyNoteCalendarIndex.fromNotes(input);
      expect(index.notesByDay['2026-10-06']!.id, expected.id);
      expect(index.notesByDay['2026-10-06'], same(notes[3]));
    }
  });

  test('snapshot is immutable and UTC queries resolve the same local instant',
      () {
    final note = Note(id: 'one', dailyNoteDateKey: '2026-10-06');
    final source = [note];
    final index = DailyNoteCalendarIndex.fromNotes(source);
    source.clear();
    expect(index.notesByDay.values, [note]);
    expect(() => index.notesByDay.clear(), throwsUnsupportedError);
    final local = DateTime(2026, 10, 6, 0, 30);
    expect(index.noteForDay(local.toUtc()), same(index.noteForDay(local)));
    final empty = DailyNoteCalendarIndex.fromNotes([]);
    expect(empty.notesByDay, isEmpty);
    expect(empty.firstDay, isNull);
    expect(empty.lastDay, isNull);
  });

  test('existingForDay reads latest edits/deletion/archive and never creates',
      () {
    final repository = _Notes();
    final service = DailyNoteService(repository,
        createId: () => throw StateError('Read must never generate an ID'));
    final day = DateTime(2026, 10, 6);
    expect(service.existingForDay(day), isNull);
    repository.notes['one'] =
        NoteDto(id: 'one', title: 'Original', dailyNoteDateKey: '2026-10-06');
    expect(service.existingForDay(day)!.id, 'one');
    repository.notes['one'] = repository.notes['one']!.copyWith(
        title: 'Renamed',
        description: 'Latest thoughts',
        isArchived: true,
        dateTime: DateTime(2026, 11, 1).toIso8601String());
    final latest = service.existingForDay(day)!;
    expect(latest.title, 'Renamed');
    expect(latest.description, 'Latest thoughts');
    expect(latest.isArchived, isTrue);
    expect(service.existingForDay(DateTime(2026, 11, 1)), isNull);
    repository.notes['one'] = repository.notes['one']!
        .copyWith(deletedAt: DateTime(2026, 11, 2).toIso8601String());
    expect(service.existingForDay(day), isNull);
    repository.notes.remove('one');
    expect(service.existingForDay(day), isNull);
    expect(repository.writes, 0);
  });
}
