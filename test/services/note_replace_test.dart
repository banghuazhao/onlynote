import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_find.dart';
import 'package:onlynote/services/note_replace.dart';

NoteTextStyleRange _style(int start, int end, NoteTextStyleKind kind) =>
    NoteTextStyleRange(start: start, end: end, kind: kind);

void main() {
  test('all editable fields change atomically while metadata stays intact', () {
    final note = Note(
      id: 'note',
      title: 'Tea title',
      description: 'tea body',
      color: Colors.amber,
      dateTime: DateTime(2026, 10, 7),
      isPinned: true,
      sortOrder: 4,
      folderId: 'folder',
      tags: ['tea'],
      linkedNoteIds: ['other-note'],
      dailyNoteDateKey: '2026-10-07',
      todo: [
        Todo(id: 'done', title: 'tea done', completed: true),
        Todo(id: 'active', title: 'tea active'),
      ],
      imagePaths: ['tea-photo.jpg'],
      imageLayouts: const [
        NoteImageLayout(path: 'tea-photo.jpg', textOffset: 8)
      ],
      voiceMemos: [
        VoiceMemo(
            id: 'memo',
            path: 'note_audio/tea.m4a',
            durationMs: 4000,
            createdAt: DateTime(2026),
            transcript: 'tea transcript')
      ],
    );
    final result = replaceNoteText(note, query: 'tea', replacement: 'coffee');
    expect(result.replacedCount, 5);
    expect(result.failure, isNull);
    expect(
        result.note,
        note.copyWith(
          title: 'coffee title',
          description: 'coffee body',
          todo: [
            note.todo[0].copyWith(title: 'coffee done'),
            note.todo[1].copyWith(title: 'coffee active'),
          ],
          imageLayouts: [note.imageLayouts.single.copyWith(textOffset: 11)],
          voiceMemos: [
            note.voiceMemos.single.copyWith(transcript: 'coffee transcript')
          ],
        ));
    expect(note.description, 'tea body');
  });

  test('one selected completed checklist match changes without reordering', () {
    final note = Note(description: 'tea', todo: [
      Todo(id: 'done', title: 'tea tea', completed: true),
      Todo(id: 'active', title: 'tea'),
    ]);
    final result = replaceNoteText(note,
        query: 'tea',
        replacement: 'coffee',
        match: const NoteSearchMatch('todo:done', 4, 7));
    expect(result.replacedCount, 1);
    expect(result.note.todo.first.title, 'tea coffee');
    expect(result.note.todo.first.completed, isTrue);
    expect(result.note.todo.map((todo) => todo.id), ['done', 'active']);
    expect(result.note.description, 'tea');
    expect(result.note.todo.last, note.todo.last);
  });

  test('Unicode replacement uses whole accents and unique joined graphemes',
      () {
    final note = Note(description: 'e\u0301 👩‍👩‍👧‍👧 𠮷茶𠮷');
    final accent = replaceNoteText(note, query: 'e', replacement: 'é');
    expect(accent.note.description, 'é 👩‍👩‍👧‍👧 𠮷茶𠮷');
    final family = replaceNoteText(note, query: '👩', replacement: '😀');
    expect(family.replacedCount, 1);
    expect(family.note.description, 'e\u0301 😀 𠮷茶𠮷');
    final chinese = replaceNoteText(note, query: '茶', replacement: '咖啡');
    expect(chinese.note.description, 'e\u0301 👩‍👩‍👧‍👧 𠮷咖啡𠮷');
    final invalid = replaceNoteText(note,
        query: '👩',
        replacement: 'x',
        match: const NoteSearchMatch('body', 3, 5));
    expect(invalid.failure, NoteReplaceFailure.staleMatch);
    expect(invalid.note, same(note));
  });

  test('replacement inherits covered styles and preserves untouched runs', () {
    final note = Note(description: 'tea and tea\nkeep', textStyles: [
      _style(0, 3, NoteTextStyleKind.bold),
      _style(8, 11, NoteTextStyleKind.bold),
      _style(0, 11, NoteTextStyleKind.highlight),
      _style(12, 16, NoteTextStyleKind.heading),
    ]);
    final result = replaceNoteText(note, query: 'tea', replacement: 'coffee');
    expect(result.note.description, 'coffee and coffee\nkeep');
    expect(result.note.textStyles, [
      _style(0, 6, NoteTextStyleKind.bold),
      _style(0, 17, NoteTextStyleKind.highlight),
      _style(11, 17, NoteTextStyleKind.bold),
      _style(18, 22, NoteTextStyleKind.heading),
    ]);
    final partial = replaceNoteText(
        Note(description: 'tea tail', textStyles: [
          _style(0, 1, NoteTextStyleKind.bold),
          _style(4, 8, NoteTextStyleKind.highlight),
        ]),
        query: 'tea',
        replacement: 'coffee');
    expect(
        partial.note.textStyles, [_style(7, 11, NoteTextStyleKind.highlight)]);
    final neighbor = replaceNoteText(
        Note(description: 'tea next', textStyles: [
          _style(0, 3, NoteTextStyleKind.bold),
        ]),
        query: 'next',
        replacement: 'last');
    expect(neighbor.note.textStyles, [_style(0, 3, NoteTextStyleKind.bold)]);
  });

  test('a newline replacement retains styles on untouched trailing text', () {
    final note = Note(description: 'tea after', textStyles: [
      _style(0, 9, NoteTextStyleKind.bold),
      _style(0, 9, NoteTextStyleKind.heading),
    ]);
    final result = replaceNoteText(note, query: 'tea', replacement: '\n');
    expect(result.note.description, '\n after');
    expect(result.note.textStyles, [
      _style(1, 7, NoteTextStyleKind.bold),
      _style(1, 7, NoteTextStyleKind.heading),
    ]);
  });

  test('repeated paragraph replacements preserve photo order and geometry', () {
    final note = Note(
      description: 'tea\ntea\ntea',
      imagePaths: ['first', 'middle', 'end'],
      imageLayouts: const [
        NoteImageLayout(
            path: 'first', textOffset: 4, widthFactor: .4, xFactor: 0),
        NoteImageLayout(
            path: 'middle', textOffset: 8, widthFactor: .6, xFactor: 1),
        NoteImageLayout(path: 'end', textOffset: 11, aspectRatio: 2),
      ],
    );
    final result = replaceNoteText(note, query: 'tea', replacement: 'coffee');
    expect(result.note.description, 'coffee\ncoffee\ncoffee');
    expect(result.note.imageLayouts, [
      note.imageLayouts[0].copyWith(textOffset: 7),
      note.imageLayouts[1].copyWith(textOffset: 14),
      note.imageLayouts[2].copyWith(textOffset: 20),
    ]);
    expect(result.note.imagePaths, note.imagePaths);
  });

  test('empty replacement deletes matches and shifts untouched styles/photos',
      () {
    final note = Note(
        description: 'tea\nkeep',
        textStyles: [_style(4, 8, NoteTextStyleKind.bold)],
        imagePaths: ['photo'],
        imageLayouts: const [NoteImageLayout(path: 'photo', textOffset: 4)]);
    final result = replaceNoteText(note, query: 'tea', replacement: '');
    expect(result.note.description, '\nkeep');
    expect(result.note.textStyles, [_style(1, 5, NoteTextStyleKind.bold)]);
    expect(result.note.imageLayouts.single.textOffset, 1);
  });

  test('invalid matches and stale snapshots leave the original note untouched',
      () {
    final note = Note(description: 'tea again');
    for (final match in const [
      NoteSearchMatch('body', -1, 3),
      NoteSearchMatch('body', 0, 99),
      NoteSearchMatch('body', 1, 3),
      NoteSearchMatch('photo:ocr', 0, 3),
    ]) {
      final result = replaceNoteText(note,
          query: 'tea', replacement: 'coffee', match: match);
      expect(result.failure, NoteReplaceFailure.staleMatch);
      expect(result.changed, isFalse);
      expect(result.note, same(note));
    }
    final stale = replaceNoteText(note,
        query: 'tea',
        replacement: 'coffee',
        expectedFields: noteSearchFields(Note(description: 'tea before')));
    expect(stale.failure, NoteReplaceFailure.staleMatch);
    expect(stale.note, same(note));
  });

  test('title and checklist limits reject every field of a replace all', () {
    for (final note in [
      Note(
          title: '${List.filled(137, 'x').join()}tea', description: 'tea body'),
      Note(
          description: 'tea body',
          todo: [Todo(id: 'task', title: '${List.filled(97, 'x').join()}tea')]),
    ]) {
      final result = replaceNoteText(note, query: 'tea', replacement: 'coffee');
      expect(result.failure, NoteReplaceFailure.lengthLimit);
      expect(result.replacedCount, 0);
      expect(result.note, same(note));
      expect(result.note.description, 'tea body');
    }
  });

  test('unchanged replacements are no-ops; case and literal symbols still work',
      () {
    final note = Note(description: 'tea tea');
    final sameText = replaceNoteText(note, query: 'tea', replacement: 'tea');
    expect(sameText.changed, isFalse);
    expect(sameText.note, same(note));
    final absent = replaceNoteText(note, query: 'missing', replacement: 'x');
    expect(absent.note, same(note));
    final caseChange = replaceNoteText(Note(description: 'Tea tea'),
        query: 'tea', replacement: 'tea');
    expect(caseChange.replacedCount, 1);
    expect(caseChange.note.description, 'tea tea');
    final literal = replaceNoteText(Note(description: '.* tea .*'),
        query: '.*', replacement: r'$1');
    expect(literal.note.description, r'$1 tea $1');
  });
}
