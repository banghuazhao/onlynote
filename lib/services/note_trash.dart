import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

/// Keeps reminder metadata intact for Undo, while silencing notes in Trash.
class NoteTrash {
  NoteTrash(this.repository,
      {required this.reminders, required this.cancel, required this.schedule});

  factory NoteTrash.device(NoteRepository repository) => NoteTrash(
        repository,
        reminders: () => ReminderData.shared.reminders,
        cancel: (r) => NotificationService().removeNotification(r),
        schedule: (note, r) => NotificationService().scheduleNotifications(
          id: r.reminderId,
          title: S.current.Onlynote,
          body: '${S.current.Reminder}: ${note.title ?? ''}',
          time: r.reminderDate,
          noteId: r.noteId,
          repeat: r.repeat,
        ),
      );

  final NoteRepository repository;
  final List<Reminder> Function() reminders;
  final Future<void> Function(Reminder) cancel;
  final Future<bool> Function(NoteDto, Reminder) schedule;

  Future<bool> setDeleted(List<String> ids, {required bool deleted}) async {
    final originals = <NoteDto>[];
    for (final id in ids.toSet()) {
      final note = await repository.getNote(id);
      if ((note.deletedAt != null) != deleted) originals.add(note);
    }
    if (!deleted) return _restore(originals);
    final changed = <NoteDto>[];
    final touched = <(NoteDto, Reminder)>[];
    final now = DateTime.now();
    try {
      for (final note in originals) {
        for (final r in reminders().where((r) => r.noteId == note.id)) {
          touched.add((note, r));
          await cancel(r);
        }
        changed.add(note);
        await repository
            .addUpdateNote(note.copyWith(deletedAt: now.toIso8601String()));
      }
    } catch (_) {
      for (final note in changed.reversed) {
        await repository.addUpdateNote(note);
      }
      for (final (note, r) in touched) {
        if (r.isSchedulable(DateTime.now())) {
          await schedule(note, r);
        }
      }
      rethrow;
    }
    return true;
  }

  Future<bool> _restore(List<NoteDto> originals) async {
    final changed = <NoteDto>[];
    try {
      for (final note in originals) {
        changed.add(note);
        await repository.addUpdateNote(note.copyWith(clearDeletedAt: true));
      }
    } catch (_) {
      for (final note in changed.reversed) {
        await repository.addUpdateNote(note);
      }
      rethrow;
    }
    // Recover the user's content even if notification permissions or the
    // scheduler have changed. The UI explains when reminders need attention.
    var allRemindersScheduled = true;
    for (final note in originals) {
      for (final reminder in reminders().where(
          (r) => r.noteId == note.id && r.isSchedulable(DateTime.now()))) {
        try {
          if (!await schedule(note, reminder)) {
            allRemindersScheduled = false;
          }
        } catch (_) {
          allRemindersScheduled = false;
        }
      }
    }
    return allRemindersScheduled;
  }
}
