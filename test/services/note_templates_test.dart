import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());

  test('templates create independent editable notes in the selected folder',
      () async {
    final strings = await S.load(const Locale('en'));
    final now = DateTime(2026, 10, 5, 9, 30);
    final noteIds = <String>{};
    final itemIds = <String>{};
    for (final template in NoteTemplate.values) {
      final first = template.createNote(strings, folderId: 'travel', now: now);
      final second = template.createNote(strings, folderId: 'travel', now: now);
      for (final note in [first, second]) {
        expect(noteIds.add(note.id!), isTrue);
        expect(note.folderId, 'travel');
        expect(note.dateTime, now);
        expect(note.sortOrder, -now.millisecondsSinceEpoch);
        expect(note.color, isNotNull);
        expect(note.isPinned, isFalse);
        expect(note.isDeleted, isFalse);
        expect(note.title, isNotEmpty);
        expect(note.title!.length, lessThanOrEqualTo(maxTitleCharCount));
        expect(note.imagePaths, isEmpty);
        expect(note.todo, isNotEmpty);
        for (final item in note.todo) {
          expect(itemIds.add(item.id!), isTrue);
          expect(item.completed, isFalse);
          expect(item.title, isNotEmpty);
          expect(item.title!.length, lessThanOrEqualTo(todoMaxCharCount));
        }
      }
      final edited = first.copyWith(
        title: 'My version',
        todo: [first.todo.first.copyWith(completed: true)],
      );
      expect(edited.todo.first.completed, isTrue);
      expect(second.todo.first.completed, isFalse);
      expect(second.title, isNot('My version'));
    }
  });

  test('checklists have useful items and writing templates have outlines',
      () async {
    final strings = await S.load(const Locale('en'));
    expect(NoteTemplate.shopping.content(strings).items,
        contains('Fruit & vegetables'));
    expect(NoteTemplate.packing.content(strings).items,
        contains('Travel documents'));
    expect(NoteTemplate.dailyPlan.content(strings).body,
        contains("Today's focus"));
    expect(NoteTemplate.meeting.content(strings).body, contains('Decisions'));
    expect(NoteTemplate.meeting.createNote(strings).folderId, isNull);
  });

  test('titles, outlines, and checklist items use the selected language',
      () async {
    final simplified = await S.load(const Locale('zh'));
    expect(NoteTemplate.shopping.createNote(simplified).title, '购物清单');
    expect(
        NoteTemplate.shopping.createNote(simplified).todo.first.title, '水果和蔬菜');
    expect(NoteTemplate.meeting.content(simplified).body, contains('参会人员'));

    final traditional = await S.load(const Locale('zh', 'HK'));
    expect(NoteTemplate.shopping.createNote(traditional).title, '購物清單');
    expect(NoteTemplate.packing.createNote(traditional).todo.last.title, '藥品');
    expect(NoteTemplate.meeting.content(traditional).body, contains('與會人員'));
  });
}
