import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_search.dart';

void main() {
  final note = Note(
      id: 'a',
      title: 'Trip [ideas]',
      description: 'Visit Hong Kong',
      isPinned: true,
      imagePaths: ['photo.png'],
      todo: [Todo(title: 'Buy 茶')]);
  test('search matches title, body, and checklist, treating symbols literally',
      () {
    for (final query in ['TRIP', '[ideas]', '  hong kong ', '茶', '']) {
      expect(matchesNoteSearch(note, query, {}, hasReminder: false), isTrue);
    }
    expect(matchesNoteSearch(note, '.*', {}, hasReminder: false), isFalse);
    expect(matchesNoteSearch(note, 'missing', {}, hasReminder: false), isFalse);
  });
  test('filters combine with AND and work with an empty query', () {
    expect(
        matchesNoteSearch(note, '', NoteSearchFilter.values.toSet(),
            hasReminder: true),
        isTrue);
    expect(
        matchesNoteSearch(note, '', NoteSearchFilter.values.toSet(),
            hasReminder: false),
        isFalse);
    expect(
        matchesNoteSearch(
            note.copyWith(isPinned: false), 'Trip', {NoteSearchFilter.pinned},
            hasReminder: true),
        isFalse);
    expect(
        matchesNoteSearch(
            note.copyWith(imagePaths: []), '', {NoteSearchFilter.photos},
            hasReminder: true),
        isFalse);
    expect(
        matchesNoteSearch(
            note.copyWith(todo: []), '', {NoteSearchFilter.checklists},
            hasReminder: true),
        isFalse);
  });
  test('Unfinished requires a nonempty unchecked item and composes with search',
      () {
    expect(
        matchesNoteSearch(note, '茶', {NoteSearchFilter.unfinished},
            hasReminder: false),
        isTrue);
    expect(
        matchesNoteSearch(
            note.copyWith(todo: [Todo(title: 'Buy 茶', completed: true)]),
            '',
            {NoteSearchFilter.unfinished},
            hasReminder: false),
        isFalse);
    expect(
        matchesNoteSearch(note.copyWith(todo: [Todo(title: '  ')]), '',
            {NoteSearchFilter.unfinished},
            hasReminder: false),
        isFalse);
    expect(
        matchesNoteSearch(
            note.copyWith(todo: []), '', {NoteSearchFilter.unfinished},
            hasReminder: false),
        isFalse);
    expect(
        matchesNoteSearch(note, 'missing', {NoteSearchFilter.unfinished},
            hasReminder: false),
        isFalse);
  });
  test(
      'excerpt reveals a match deep in a note without breaking surrogate pairs',
      () {
    final text = '${'A long introduction. ' * 40}Tea at noon';
    final excerpt = searchExcerpt(text, 'tea');
    expect(excerpt, startsWith('…'));
    expect(excerpt, contains('Tea at noon'));
    expect(excerpt.length, lessThan(60));
    expect(searchExcerpt('Short note', 'note'), 'Short note');
  });
}
