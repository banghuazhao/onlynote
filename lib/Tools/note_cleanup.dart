import 'package:onlynote/Tools/image_storage.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/data/dto/note_dto.dart';

/// Best-effort cleanup of side effects owned by a note (images + reminders).
class NoteCleanup {
  NoteCleanup._();

  static Future<void> cleanupNotes(Iterable<NoteDto> notes) async {
    for (final note in notes) {
      await cleanupNote(note);
    }
  }

  static Future<void> cleanupNote(NoteDto note) async {
    final paths = note.imagePaths ?? const <String>[];
    if (paths.isNotEmpty) {
      await ImageStorage.deleteImages(paths);
    }

    final noteId = note.id;
    if (noteId == null) return;

    final reminders = ReminderData.shared.reminders
        .where((reminder) => reminder.noteId == noteId)
        .toList();
    final notificationService = NotificationService();
    for (final reminder in reminders) {
      await notificationService.removeNotification(reminder);
      await ReminderData.shared.deleteReminder(reminder);
    }
  }
}
