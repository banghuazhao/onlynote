import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/note_search.dart';

void main() {
  test('photo text matches literal queries and composes with existing filters',
      () {
    final photo = Note(id: 'receipt', imagePaths: ['note_images/receipt.jpg']);
    for (final query in ['market', '茶', '12.50', '[paid]']) {
      expect(
          matchesNoteSearch(photo, query, {NoteSearchFilter.photos},
              hasReminder: false, photoText: ['MARKET 茶\nTotal 12.50 [paid]']),
          isTrue);
    }
    expect(
        matchesNoteSearch(photo, 'market', {NoteSearchFilter.pinned},
            hasReminder: false, photoText: ['MARKET']),
        isFalse);
    expect(
        matchesNoteSearch(photo, '.*', {},
            hasReminder: false, photoText: ['MARKET']),
        isFalse);
    expect(matchesNoteSearch(photo, 'market', {}, hasReminder: false), isFalse);
  });
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
  test('blank editor placeholders do not appear as checklist notes', () {
    for (final todos in [
      [Todo.empty()],
      [Todo(title: ' \n\t '), Todo(title: null, completed: true)],
    ]) {
      final plain = Note(title: 'An ordinary note', todo: todos);
      expect(
          matchesNoteSearch(plain, '', {NoteSearchFilter.checklists},
              hasReminder: false),
          isFalse);
      expect(
          matchesNoteSearch(plain, 'ordinary', {}, hasReminder: false), isTrue);
    }
    expect(
        matchesNoteSearch(
            Note(todo: [Todo(title: 'Finished', completed: true)]),
            '',
            {NoteSearchFilter.checklists},
            hasReminder: false),
        isTrue);
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
  test('Unfinished search excludes matches only in completed task labels', () {
    final checklist = Note(title: 'Shopping', todo: [
      Todo(title: 'Tea', completed: true),
      Todo(title: 'Milk'),
    ]);
    expect(matchesNoteSearch(checklist, 'tea', {}, hasReminder: false), isTrue);
    expect(
        matchesNoteSearch(checklist, 'tea', {NoteSearchFilter.unfinished},
            hasReminder: false),
        isFalse);
    expect(
        matchesNoteSearch(checklist, 'milk', {NoteSearchFilter.unfinished},
            hasReminder: false),
        isTrue);
    for (final current in [
      checklist.copyWith(title: 'Tea shopping'),
      checklist.copyWith(description: 'Tea party'),
      checklist.copyWith(tags: ['Tea']),
    ]) {
      expect(
          matchesNoteSearch(current, 'tea', {NoteSearchFilter.unfinished},
              hasReminder: false),
          isTrue);
    }
    expect(
        matchesNoteSearch(checklist, 'tea', {NoteSearchFilter.unfinished},
            hasReminder: false, photoText: ['Tea receipt']),
        isTrue);
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
  test('excerpt clips combining and joined emoji at complete graphemes', () {
    for (final grapheme in ['e\u0301', '👩🏽‍💻', '🇳🇿', '♥️']) {
      final tail = 'A' * (31 - grapheme.length);
      final text = '${'B' * 50}$grapheme${tail}Needle';
      // The preferred clip lies one UTF-16 unit into the grapheme.
      expect(searchExcerpt(text, 'needle'), '…${tail}Needle');
    }
  });
  test('excerpt retains a whole long grapheme containing the query start', () {
    final grapheme = 'e${'\u0301' * 40}';
    final text = '${'B' * 50}${grapheme}Needle';
    expect(searchExcerpt(text, '\u0301Needle'), '…${grapheme}Needle');
  });
  test('immediate excerpts preserve the whole grapheme containing a match', () {
    for (final (grapheme, query) in [
      ('e\u0301', '\u0301'),
      ('👩🏽‍💻', '💻'),
      ('🇳🇿', '🇿'),
      ('♥️', '\uFE0F'),
    ]) {
      expect(searchExcerpt('Intro $grapheme detail', query, leadingContext: 0),
          '…$grapheme detail');
      expect(searchExcerpt('$grapheme detail', query, leadingContext: 0),
          '$grapheme detail');
    }
    expect(searchExcerpt('Short Needle detail', 'needle', leadingContext: 0),
        '…Needle detail');
    expect(searchExcerpt('No match', 'needle', leadingContext: 0), 'No match');
  });
}
