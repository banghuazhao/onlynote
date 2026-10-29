import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/notification_service.dart';
import 'package:onlynote/Tools/reminder_data.dart';
import 'package:onlynote/Tools/widget_commands.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/today_agenda.dart';

TodayAgendaController createLiveTodayAgendaController() {
  final repository = getIt<NoteRepository>();
  final reminders = ReminderData.shared;
  final notifications = NotificationService();
  return TodayAgendaController(
    readNotes: () async =>
        repository.getAllNotes().map((note) => note.toDomain()).toList(),
    readNote: (id) async {
      if (!repository.getAllNotes().any((note) => note.id == id)) return null;
      return (await repository.getNote(id)).toDomain();
    },
    readReminders: () => reminders.reminders,
    readPendingSnoozes: notifications.readPendingSnoozeDates,
    saveNote: (note) async => repository.addUpdateNote(NoteDto.fromNote(note)),
    beforeTaskWrite: () async =>
        WidgetCommands.initializedInstance?.importPending(),
    reminderChanges: reminders,
    noteChanges:
        Hive.isBoxOpen(databaseBox) ? Hive.box(databaseBox).watch() : null,
  );
}
