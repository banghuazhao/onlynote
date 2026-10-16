import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_sort.dart';

Note note(
  String id, {
  String? title,
  String? description,
  DateTime? dateTime,
  int? sortOrder,
  bool isPinned = false,
  List<Todo> todo = const [],
  List<VoiceMemo> voiceMemos = const [],
}) =>
    Note(
      id: id,
      title: title,
      description: description,
      dateTime: dateTime,
      sortOrder: sortOrder,
      isPinned: isPinned,
      todo: todo,
      voiceMemos: voiceMemos,
    );

List<String> ids(Iterable<Note> notes, NoteSortOrder order) =>
    (List<Note>.of(notes)..sort((a, b) => compareLibraryNotes(a, b, order)))
        .map((note) => note.id!)
        .toList();

void main() {
  test('manual order keeps dragged positions, then most recent change', () {
    final dragged = [
      note('second', sortOrder: 2, dateTime: DateTime(2026, 1, 1)),
      note('first', sortOrder: 1, dateTime: DateTime(2020, 1, 1)),
    ];
    expect(ids(dragged, NoteSortOrder.manual), ['first', 'second']);

    // Notes saved before sortOrder existed still fall back to newest first,
    // exactly as every release before sorting did.
    final legacy = [
      note('old', dateTime: DateTime(2020, 5, 1)),
      note('new', dateTime: DateTime(2026, 5, 1)),
    ];
    expect(ids(legacy, NoteSortOrder.manual), ['new', 'old']);
  });

  test('pinned notes stay above unpinned ones in every order', () {
    final notes = [
      note('loose-a', title: 'Aaa', dateTime: DateTime(2026, 6, 1)),
      note('pinned-z',
          title: 'Zzz', dateTime: DateTime(2020, 1, 1), isPinned: true),
      note('loose-b', title: 'Bbb', dateTime: DateTime(2026, 7, 1)),
    ];
    for (final order in NoteSortOrder.values) {
      expect(ids(notes, order).first, 'pinned-z', reason: order.name);
    }
  });

  test('modified orders run newest and oldest first', () {
    final notes = [
      note('middle', dateTime: DateTime(2023, 1, 1)),
      note('newest', dateTime: DateTime(2026, 1, 1)),
      note('oldest', dateTime: DateTime(2020, 1, 1)),
    ];
    expect(ids(notes, NoteSortOrder.modifiedNewest),
        ['newest', 'middle', 'oldest']);
    expect(ids(notes, NoteSortOrder.modifiedOldest),
        ['oldest', 'middle', 'newest']);
  });

  test('a missing timestamp sorts as the oldest note rather than throwing', () {
    final notes = [
      note('dated', dateTime: DateTime(2026, 1, 1)),
      note('undated'),
    ];
    expect(ids(notes, NoteSortOrder.modifiedNewest), ['dated', 'undated']);
    expect(ids(notes, NoteSortOrder.modifiedOldest), ['undated', 'dated']);
  });

  test('title order ignores case and surrounding space', () {
    final notes = [
      note('b', title: 'banana'),
      note('a', title: '  Apple '),
      note('c', title: 'CHERRY'),
    ];
    expect(ids(notes, NoteSortOrder.titleAsc), ['a', 'b', 'c']);
    expect(ids(notes, NoteSortOrder.titleDesc), ['c', 'b', 'a']);
  });

  test('untitled notes sort by the headline their card shows', () {
    final notes = [
      note('titled', title: 'Melon'),
      note('body', description: '\n\n  Apple crumble\nmore text'),
      note('task',
          todo: [Todo(id: 't', title: ''), Todo(id: 'u', title: 'Zu')]),
      note('memo', voiceMemos: [
        VoiceMemo(
            id: 'm',
            path: 'note_audio/m.m4a',
            durationMs: 0,
            createdAt: DateTime(2026, 1, 1),
            transcript: 'Grocery run'),
      ]),
    ];
    expect(
        ids(notes, NoteSortOrder.titleAsc), ['body', 'memo', 'titled', 'task']);
  });

  test('a note with no text at all sorts without a crash', () {
    final notes = [note('empty'), note('titled', title: 'Apple')];
    expect(ids(notes, NoteSortOrder.titleAsc), ['empty', 'titled']);
    expect(ids(notes, NoteSortOrder.titleDesc), ['titled', 'empty']);
  });

  test('equal notes resolve by id so repeated sorts never reshuffle', () {
    final same = DateTime(2026, 2, 2);
    final notes = [
      note('c', title: 'Same', dateTime: same),
      note('a', title: 'same', dateTime: same),
      note('b', title: 'SAME', dateTime: same),
    ];
    for (final order in NoteSortOrder.values) {
      expect(ids(notes, order), ['a', 'b', 'c'], reason: order.name);
      expect(
          ids(
              ids(notes, order)
                  .map((id) => notes.firstWhere((n) => n.id == id)),
              order),
          ['a', 'b', 'c'],
          reason: order.name);
    }
  });
}
