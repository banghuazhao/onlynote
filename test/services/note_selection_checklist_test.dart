import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_selection.dart';
import 'package:onlynote/services/note_selection_checklist.dart';

void main() {
  test('selected lines strip list and checkbox markers while retaining order',
      () {
    final parsed = parseNoteSelectionChecklist(
      '  • Bread\r\n- [ ] Coffee\n12. Tea\n3) Milk\n(4) Fruit\n'
      '☑ Rice\n* [x] Apples\n[ X ] Pears\n\n•\n- [ ]\nCoffee',
    );
    expect(parsed.status, NoteSelectionChecklistStatus.ready);
    expect(parsed.titles, [
      'Bread',
      'Coffee',
      'Tea',
      'Milk',
      'Fruit',
      'Rice',
      'Apples',
      'Pears',
      'Coffee'
    ]);
    expect(() => parsed.titles.clear(), throwsUnsupportedError);
  });

  test('Unicode lines and ordinary punctuation remain complete', () {
    final parsed = parseNoteSelectionChecklist(
      '• 👩🏽‍💻 Prepare cafe\u0301\u2028'
      '1. 買牛奶\u2029'
      '☑️ Finished item\n✅ Another item\n'
      '-5°C is cold\n3.14 is pi\n*italic*\n[example] stays literal',
    );
    expect(parsed.titles, [
      '👩🏽‍💻 Prepare cafe\u0301',
      '買牛奶',
      'Finished item',
      'Another item',
      '-5°C is cold',
      '3.14 is pi',
      '*italic*',
      '[example] stays literal',
    ]);
  });

  test('empty and marker-only lines do not create tasks', () {
    for (final text in ['', ' \n\t', '•\n- [ ]\n1.\n[x]\n☐']) {
      final parsed = parseNoteSelectionChecklist(text);
      expect(parsed.status, NoteSelectionChecklistStatus.empty);
      expect(parsed.isEmpty, isTrue);
      expect(parsed.canApply, isFalse);
    }
  });

  test('storage limit uses UTF16 and rejects the entire oversized transaction',
      () {
    expect(parseNoteSelectionChecklist('a' * 100).canApply, isTrue);
    expect(parseNoteSelectionChecklist('😀' * 50).canApply, isTrue);
    final longLine = '😀' * 51;
    final selected = NoteTextSelection(text: 'Keep this too\n$longLine');
    final parsed = parseNoteSelectionChecklist(selected.text);
    expect(parsed.status, NoteSelectionChecklistStatus.tooLong);
    expect(parsed.titles, ['Keep this too', longLine]);
    final note =
        Note(description: 'Original', todo: [Todo(id: 'old', title: 'Old')]);
    final result = appendSelectionToChecklist(note, selected);
    expect(result.status, NoteSelectionChecklistStatus.tooLong);
    expect(result.note, isNull);
    expect(result.addedTodoIds, isEmpty);
    expect(note.description, 'Original');
    expect(note.todo, hasLength(1));
  });

  test('append preserves prose, formatting, existing todos, and all metadata',
      () {
    final note = Note(
      id: 'source',
      title: 'Keep title',
      description: '• Coffee\n1. Tea',
      color: Colors.amber,
      dateTime: DateTime(2026, 10, 7),
      todo: [Todo(id: 'old', title: 'Existing', completed: true)],
      imagePaths: ['photo.jpg'],
      imageLayouts: const [NoteImageLayout(path: 'photo.jpg', textOffset: 0)],
      voiceMemos: [
        VoiceMemo(
          id: 'audio',
          path: 'note_audio/audio.m4a',
          durationMs: 500,
          createdAt: DateTime(2026, 10, 7),
        ),
      ],
      sortOrder: 4,
      isPinned: true,
      folderId: 'folder',
      isArchived: true,
      tags: ['home'],
      linkedNoteIds: ['related'],
      dailyNoteDateKey: '2026-10-07',
      textStyles: const [
        NoteTextStyleRange(start: 2, end: 8, kind: NoteTextStyleKind.bold),
      ],
    );
    final result = appendSelectionToChecklist(
        note, NoteTextSelection(text: '• Coffee\n1. Tea\nCoffee'));
    expect(result.status, NoteSelectionChecklistStatus.ready);
    final after = result.note!;
    expect(after.todo.first, same(note.todo.first));
    expect(after.todo.skip(1).map((todo) => todo.title),
        ['Coffee', 'Tea', 'Coffee']);
    expect(after.todo.skip(1).every((todo) => !todo.completed), isTrue);
    expect(result.addedTodoIds, hasLength(3));
    expect(result.addedTodoIds.toSet(), hasLength(3));
    expect(result.addedTodoIds.every((id) => id.isNotEmpty && id != 'old'),
        isTrue);
    expect(after.copyWith(todo: note.todo), note);
    expect(() => result.addedTodoIds.clear(), throwsUnsupportedError);
  });

  test('reader Undo removes only created IDs from the latest note', () {
    final original = Note(
        id: 'source',
        description: 'Selected prose',
        todo: [Todo(id: 'old', title: 'Old')]);
    final appended = appendSelectionToChecklist(
        original, NoteTextSelection(text: 'Coffee\nTea'));
    final after = appended.note!;
    final latest = after.copyWith(
      description: 'Newer prose',
      tags: ['newer tag'],
      todo: [
        after.todo.first.copyWith(completed: true, title: 'Updated old task'),
        after.todo[1].copyWith(completed: true, title: 'Edited added row'),
        Todo(id: 'unrelated', title: 'Later task'),
        after.todo[2],
      ],
    );
    final restored = undoSelectionChecklist(latest, appended.addedTodoIds);
    expect(restored.description, 'Newer prose');
    expect(restored.tags, ['newer tag']);
    expect(restored.todo.map((todo) => todo.id), ['old', 'unrelated']);
    expect(restored.todo.first.completed, isTrue);
    expect(restored.todo.first.title, 'Updated old task');
    expect(restored.copyWith(todo: latest.todo), latest);
    expect(undoSelectionChecklist(restored, appended.addedTodoIds),
        same(restored));
  });
}
