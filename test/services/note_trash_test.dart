import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/note_trash.dart';
import 'package:onlynote/services/daily_note.dart';

class TrashRepository implements NoteRepository {
  final notes = <String, NoteDto>{};
  String? failNextId;
  @override
  Future addUpdateNote(NoteDto note) async {
    if (note.id == failNextId) {
      failNextId = null;
      throw StateError('Disk full');
    }
    notes[note.id!] = note;
  }

  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future deleteNote(String id) async => notes.remove(id);
  @override
  Future deleteMultiNotes(List<String> ids) async => ids.forEach(notes.remove);
}

void main() {
  late TrashRepository repository;
  late NoteTrash service;
  late List<Reminder> reminders;
  late Set<int> scheduled;
  setUp(() {
    repository = TrashRepository();
    repository.notes['a'] = NoteDto(
        id: 'a',
        title: 'Keep my metadata',
        folderId: 'folder',
        isPinned: true,
        sortOrder: 7,
        imagePaths: ['photo.png'],
        todoList: [TodoDto(title: 'Done', completed: true)]);
    repository.notes['b'] = NoteDto(id: 'b', title: 'Second note');
    reminders = [
      Reminder(
          noteId: 'a',
          reminderId: 42,
          reminderDate: DateTime.now().add(const Duration(days: 2)))
    ];
    scheduled = {42};
    service = NoteTrash(repository,
        reminders: () => reminders,
        cancel: (r) async {
          scheduled.remove(r.reminderId);
        },
        schedule: (_, r) async {
          scheduled.add(r.reminderId);
          return true;
        });
  });
  test(
      'delete and undo preserve content, folder, pin, ordering, photos and reminder',
      () async {
    final original = repository.notes['a'];
    await service.setDeleted(['a'], deleted: true);
    expect(repository.notes['a']!.isDeleted, isTrue);
    expect(scheduled, isEmpty);
    expect(reminders, hasLength(1));
    await service.setDeleted(['a'], deleted: false);
    final restored = repository.notes['a']!;
    expect(restored.isDeleted, isFalse);
    expect(restored.toDomain(), original!.toDomain());
    expect(scheduled, {42});
  });
  test('a failed bulk delete rolls back earlier notes and notifications',
      () async {
    repository.failNextId = 'b';
    await expectLater(
        service.setDeleted(['a', 'b'], deleted: true), throwsStateError);
    expect(repository.notes.values.every((n) => !n.isDeleted), isTrue);
    expect(scheduled, {42});
  });
  test('restoring a past reminder keeps its date but does not notify now',
      () async {
    reminders = [
      Reminder(noteId: 'a', reminderId: 42, reminderDate: DateTime(2020))
    ];
    await service.setDeleted(['a'], deleted: true);
    await service.setDeleted(['a'], deleted: false);
    expect(scheduled, isEmpty);
    expect(reminders.single.reminderDate, DateTime(2020));
  });
  test('notification failure still restores the note and reports a warning',
      () async {
    await service.setDeleted(['a'], deleted: true);
    service = NoteTrash(repository,
        reminders: () => reminders,
        cancel: (_) async {},
        schedule: (_, __) async => false);
    expect(await service.setDeleted(['a'], deleted: false), isFalse);
    expect(repository.notes['a']!.isDeleted, isFalse);
    expect(reminders.single.reminderId, 42);
  });

  for (final archived in [false, true]) {
    test(
        'restoring an old daily note keeps the ${archived ? 'archived' : 'active'} replacement as today\'s note',
        () async {
      repository.notes['a'] = repository.notes['a']!.copyWith(
          dailyNoteDateKey: '2026-10-06',
          dateTime: DateTime(2026, 10, 6, 9).toIso8601String());
      final original = repository.notes['a']!;
      await service.setDeleted(['a'], deleted: true);
      final replacement = repository.notes['b']!.copyWith(
          title: 'My replacement thoughts',
          dailyNoteDateKey: '2026-10-06',
          dateTime: DateTime(2026, 10, 6, 12).toIso8601String(),
          isArchived: archived);
      repository.notes['b'] = replacement;
      await service.setDeleted(['a'], deleted: false);
      final restored = repository.notes['a']!;
      expect(restored.isDeleted, isFalse);
      expect(restored.dailyNoteDateKey, isNull);
      expect(restored.title, original.title);
      expect(restored.folderId, original.folderId);
      expect(restored.imagePaths, original.imagePaths);
      expect(restored.todoList, original.todoList);
      expect(restored.dateTime, original.dateTime);
      expect(repository.notes['b'], same(replacement));
      final today = await DailyNoteService(repository,
              now: () => DateTime(2026, 10, 6, 18))
          .openToday(titleForDay: (_) => 'Should not create');
      expect(today.id, 'b');
      expect(today.isArchived, archived);
    });
  }

  test('restoring a daily note with no live owner retains its association',
      () async {
    repository.notes['a'] =
        repository.notes['a']!.copyWith(dailyNoteDateKey: '2026-10-06');
    await service.setDeleted(['a'], deleted: true);
    await service.setDeleted(['a'], deleted: false);
    expect(repository.notes['a']!.dailyNoteDateKey, '2026-10-06');
  });

  test('failed bulk restore rolls back cleared daily identity and trash state',
      () async {
    repository.notes['a'] =
        repository.notes['a']!.copyWith(dailyNoteDateKey: '2026-10-06');
    await service.setDeleted(['a', 'b'], deleted: true);
    final trashed = repository.notes['a']!;
    repository.notes['owner'] =
        NoteDto(id: 'owner', title: 'Today', dailyNoteDateKey: '2026-10-06');
    final owner = repository.notes['owner'];
    repository.failNextId = 'b';
    await expectLater(
        service.setDeleted(['a', 'b'], deleted: false), throwsStateError);
    expect(repository.notes['a'], same(trashed));
    expect(repository.notes['a']!.dailyNoteDateKey, '2026-10-06');
    expect(repository.notes['a']!.isDeleted, isTrue);
    expect(repository.notes['b']!.isDeleted, isTrue);
    expect(repository.notes['owner'], same(owner));
    expect(scheduled, isEmpty);
  });

  for (final repeat in [ReminderRepeat.daily, ReminderRepeat.weekly]) {
    test('undo reschedules a ${repeat.name} reminder with a past anchor',
        () async {
      final anchor = DateTime(2020, 1, 6, 9, 30);
      reminders = [
        Reminder(
            noteId: 'a', reminderId: 42, reminderDate: anchor, repeat: repeat)
      ];
      await service.setDeleted(['a'], deleted: true);
      expect(scheduled, isEmpty);
      expect(await service.setDeleted(['a'], deleted: false), isTrue);
      expect(scheduled, {42});
      expect(reminders.single.reminderDate, anchor);
      expect(reminders.single.repeat, repeat);
    });

    test('failed delete reschedules a past ${repeat.name} reminder', () async {
      reminders = [
        Reminder(
            noteId: 'a',
            reminderId: 42,
            reminderDate: DateTime(2020),
            repeat: repeat)
      ];
      repository.failNextId = 'b';
      await expectLater(
          service.setDeleted(['a', 'b'], deleted: true), throwsStateError);
      expect(repository.notes.values.every((n) => !n.isDeleted), isTrue);
      expect(scheduled, {42});
      expect(reminders.single.repeat, repeat);
    });
  }

  test('repeating a delete or undo does not mutate other notes', () async {
    await service.setDeleted(['a', 'a'], deleted: true);
    final deletedAt = repository.notes['a']!.deletedAt;
    await service.setDeleted(['a'], deleted: true);
    expect(repository.notes['a']!.deletedAt, deletedAt);
    expect(repository.notes['b']!.isDeleted, isFalse);
    await service.setDeleted(['a'], deleted: false);
    await service.setDeleted(['a'], deleted: false);
    expect(scheduled, {42});
  });
}
