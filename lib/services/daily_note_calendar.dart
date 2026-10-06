import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/daily_note.dart';

/// A read-only snapshot of saved daily notes, grouped by their associated day.
/// Ordinary dates and titles never give a note a calendar association.
class DailyNoteCalendarIndex {
  DailyNoteCalendarIndex._(Map<String, Note> notes)
      : notesByDay = Map.unmodifiable(notes),
        firstDay = notes.isEmpty ? null : DateTime.parse(notes.keys.first),
        lastDay = notes.isEmpty ? null : DateTime.parse(notes.keys.last);

  factory DailyNoteCalendarIndex.fromNotes(Iterable<Note> notes) {
    final groups = <String, Map<NoteDto, Note>>{};
    for (final note in notes) {
      final key = note.dailyNoteDateKey;
      if (note.isDeleted ||
          note.id?.trim().isNotEmpty != true ||
          !isValidDailyNoteDateKey(key)) {
        continue;
      }
      // Supply only selection metadata to the same resolver as Today's note.
      // Return the original domain object, preserving all text and attachments.
      final candidate = NoteDto(
        id: note.id,
        dateTime: note.dateTime?.toIso8601String(),
        isArchived: note.isArchived,
        dailyNoteDateKey: key,
      );
      (groups[key!] ??= Map<NoteDto, Note>.identity())[candidate] = note;
    }
    final days = groups.keys.toList()..sort();
    return DailyNoteCalendarIndex._({
      for (final day in days)
        day: groups[day]![dailyNoteForDay(groups[day]!.keys, day)!]!,
    });
  }

  /// Keys are yyyy-MM-dd and iterate from the earliest day to the latest.
  final Map<String, Note> notesByDay;
  final DateTime? firstDay;
  final DateTime? lastDay;

  Note? noteForDay(DateTime day) => notesByDay[dailyNoteDateKey(day)];
}
