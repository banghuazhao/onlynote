import 'package:flutter/foundation.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/reminder_agenda.dart';

enum ReminderAgendaActionResult { saved, failed, unavailable, changed, busy }

/// Injectable agenda state. Loading does not mutate reminders or reactivate
/// notifications intentionally omitted when restoring a backup.
class ReminderAgendaController extends ChangeNotifier {
  ReminderAgendaController({
    required this.readReminders,
    required this.readNotes,
    required this.readNote,
    required this.readPendingSnoozes,
    required this.snoozeReminder,
    required this.rescheduleReminder,
    this.reminderChanges,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    referenceTime = this.now();
    reminderChanges?.addListener(_remindersChanged);
  }

  final List<Reminder> Function() readReminders;
  final Future<List<Note>> Function() readNotes;
  final Future<Note?> Function(String id) readNote;
  final Future<Map<int, DateTime>> Function(List<Reminder>) readPendingSnoozes;
  final Future<bool> Function(ReminderAgendaEntry, Duration) snoozeReminder;
  final Future<bool> Function(ReminderAgendaEntry, DateTime, ReminderRepeat)
      rescheduleReminder;
  final Listenable? reminderChanges;
  final DateTime Function() now;

  List<ReminderAgendaEntry> entries = const [];
  late DateTime referenceTime;
  bool loading = false;
  bool loadFailed = false;
  int? busyReminderId;
  int _loadRevision = 0;
  bool _disposed = false;

  void _remindersChanged() => refresh();

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_loadRevision;
    loading = true;
    _notify();
    try {
      final reminders = List<Reminder>.of(readReminders());
      final notes = await readNotes();
      final snoozes = await readPendingSnoozes(reminders);
      if (_disposed || revision != _loadRevision) return;
      referenceTime = now();
      entries = buildReminderAgenda(
        reminders: reminders,
        notes: notes,
        now: referenceTime,
        pendingSnoozes: snoozes,
      );
      loadFailed = false;
    } catch (_) {
      if (!_disposed && revision == _loadRevision) loadFailed = true;
    } finally {
      if (!_disposed && revision == _loadRevision) {
        loading = false;
        _notify();
      }
    }
  }

  Future<Note?> resolveNote(ReminderAgendaEntry entry) async {
    final note = await readNote(entry.reminder.noteId);
    return note == null || note.isDeleted ? null : note;
  }

  Future<ReminderAgendaActionResult> snooze(
          ReminderAgendaEntry entry, Duration delay) =>
      _perform(entry, (latest) => snoozeReminder(latest, delay));

  Future<ReminderAgendaActionResult> reschedule(
          ReminderAgendaEntry entry, DateTime date, ReminderRepeat repeat) =>
      _perform(entry, (latest) => rescheduleReminder(latest, date, repeat));

  Future<ReminderAgendaActionResult> _perform(ReminderAgendaEntry entry,
      Future<bool> Function(ReminderAgendaEntry) operation) async {
    if (_disposed || busyReminderId != null) {
      return ReminderAgendaActionResult.busy;
    }
    busyReminderId = entry.reminder.reminderId;
    _notify();
    try {
      final note = await resolveNote(entry);
      // Reading a note may yield to another window or reminder update. Check
      // the live schedule after that wait, immediately before the mutation.
      final matches = readReminders()
          .where((r) => r.reminderId == entry.reminder.reminderId);
      if (matches.isEmpty) return ReminderAgendaActionResult.unavailable;
      final current = matches.first;
      if (note == null || current.noteId != entry.reminder.noteId) {
        return ReminderAgendaActionResult.unavailable;
      }
      if (current.reminderDate != entry.reminder.reminderDate ||
          current.repeat != entry.reminder.repeat) {
        // A reminder edited while its action sheet was open must be reviewed
        // before a stale choice can replace its new schedule.
        await refresh();
        return ReminderAgendaActionResult.changed;
      }
      final saved = await operation(ReminderAgendaEntry(
        reminder: current,
        note: note,
        dueDate: entry.dueDate,
        snoozed: entry.snoozed,
      ));
      if (!saved) return ReminderAgendaActionResult.failed;
      await refresh();
      return ReminderAgendaActionResult.saved;
    } catch (_) {
      return ReminderAgendaActionResult.failed;
    } finally {
      busyReminderId = null;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    reminderChanges?.removeListener(_remindersChanged);
    super.dispose();
  }
}
