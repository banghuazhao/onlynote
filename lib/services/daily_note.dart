import 'dart:async';
import 'dart:ui' show Color;

import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:uuid/uuid.dart';

/// Resolves one durable note per local calendar day, even across title edits.
class DailyNoteService {
  DailyNoteService(this.repository,
      {DateTime Function()? now, String Function()? createId})
      : _now = now ?? DateTime.now,
        _createId = createId ?? const Uuid().v4;

  final NoteRepository repository;
  final DateTime Function() _now;
  final String Function() _createId;

  // Separate home instances can briefly coexist while routes transition.
  // Sharing the in-flight write prevents both from creating today's note.
  static final _pending = Expando<Map<String, Future<Note>>>();

  /// Reads the current saved note for a day without creating missing entries.
  Note? existingForDay(DateTime day) =>
      dailyNoteForDay(repository.getAllNotes(), dailyNoteDateKey(day))
          ?.toDomain();

  Future<Note> openToday({required String Function(DateTime) titleForDay}) {
    final now = _now().toLocal();
    final dayKey = dailyNoteDateKey(now);
    final requests = _pending[repository] ??= {};
    if (requests[dayKey] case final existing?) return existing;
    final operation = _getOrCreate(now, dayKey, titleForDay);
    requests[dayKey] = operation;
    unawaited(operation.then<void>((_) {
      if (identical(requests[dayKey], operation)) requests.remove(dayKey);
    }, onError: (Object _, StackTrace __) {
      if (identical(requests[dayKey], operation)) requests.remove(dayKey);
    }));
    return operation;
  }

  Future<Note> _getOrCreate(DateTime now, String dayKey,
      String Function(DateTime) titleForDay) async {
    final notes = repository.getAllNotes();
    final existing = dailyNoteForDay(notes, dayKey);
    if (existing != null) return existing.toDomain();
    final usedIds = notes.map((note) => note.id).toSet();
    var id = _createId();
    while (usedIds.contains(id)) {
      id = _createId();
    }
    final note = Note(
      id: id,
      title: titleForDay(DateTime(now.year, now.month, now.day)),
      description: '',
      color: const Color(0xFFFFF9F0),
      dateTime: now,
      sortOrder: -now.millisecondsSinceEpoch,
      dailyNoteDateKey: dayKey,
    );
    await repository.addUpdateNote(NoteDto.fromNote(note));
    return note;
  }
}

/// Active notes win over archived ones; older saved notes win a restore tie.
/// Deleted notes are intentionally excluded so the shortcut never revives one.
NoteDto? dailyNoteForDay(Iterable<NoteDto> notes, String dayKey) {
  final matching = notes
      .where((note) =>
          note.id?.trim().isNotEmpty == true &&
          !note.isDeleted &&
          note.dailyNoteDateKey == dayKey)
      .toList()
    ..sort((a, b) {
      if (a.isArchived != b.isArchived) return a.isArchived ? 1 : -1;
      final aDate = DateTime.tryParse(a.dateTime ?? '');
      final bDate = DateTime.tryParse(b.dateTime ?? '');
      if (aDate != null && bDate != null) {
        final byDate = aDate.compareTo(bDate);
        if (byDate != 0) return byDate;
      } else if ((aDate == null) != (bDate == null)) {
        return aDate == null ? 1 : -1;
      }
      return a.id!.compareTo(b.id!);
    });
  return matching.firstOrNull;
}
