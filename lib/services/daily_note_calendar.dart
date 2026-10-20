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

  /// Counts saved calendar days in [month], including archived notes.
  /// The index already resolves duplicates and excludes trash/invalid dates.
  int savedDayCountForMonth(DateTime month) {
    final monthPrefix = '${dailyNoteDateKey(month).substring(0, 7)}-';
    return notesByDay.keys.where((key) => key.startsWith(monthPrefix)).length;
  }

  /// The nearest saved day strictly before [day], skipping empty dates.
  DateTime? previousSavedDay(DateTime day) {
    final target = dailyNoteDateKey(day);
    String? previous;
    for (final key in notesByDay.keys) {
      if (key.compareTo(target) >= 0) break;
      previous = key;
    }
    return previous == null ? null : DateTime.parse(previous);
  }

  /// The nearest saved day strictly after [day], skipping empty dates.
  DateTime? nextSavedDay(DateTime day) {
    final target = dailyNoteDateKey(day);
    for (final key in notesByDay.keys) {
      if (key.compareTo(target) > 0) return DateTime.parse(key);
    }
    return null;
  }
}
