import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_find.dart';

void main() {
  test('literal search retains original UTF16 offsets and folds case', () {
    final fields = [const NoteSearchField('body', 'Tea .* TEA 茶 tea')];
    expect(findNoteMatches(fields, ' tea '), [
      const NoteSearchMatch('body', 0, 3),
      const NoteSearchMatch('body', 7, 10),
      const NoteSearchMatch('body', 13, 16),
    ]);
    expect(
        findNoteMatches(fields, '.*'), [const NoteSearchMatch('body', 4, 6)]);
    expect(findNoteMatches(fields, ''), isEmpty);
    expect(findNoteMatches(fields, 'missing'), isEmpty);
  });

  test(
      'Unicode matches expand whole accents and joined emoji without duplicates',
      () {
    const body = 'e\u0301 👩‍👩‍👧‍👧 茶';
    expect(findNoteMatches([const NoteSearchField('body', body)], 'e'),
        [const NoteSearchMatch('body', 0, 2)]);
    final family = findNoteMatches([const NoteSearchField('body', body)], '👩');
    expect(family, [const NoteSearchMatch('body', 3, 14)]);
    expect(
        body.substring(family.single.start, family.single.end), '👩‍👩‍👧‍👧');
    expect(findNoteMatches([const NoteSearchField('body', '𠮷茶𠮷')], '茶'),
        [const NoteSearchMatch('body', 2, 3)]);
  });

  test('fields follow reader order and include completed tasks and transcripts',
      () {
    final note = Note(
      title: 'tea title',
      description: 'tea body',
      todo: [
        Todo(id: 'done', title: 'tea done', completed: true),
        Todo(id: 'active', title: 'tea active'),
      ],
      voiceMemos: [
        VoiceMemo(
            id: 'memo',
            path: 'note_audio/memo.m4a',
            durationMs: 10,
            createdAt: DateTime(2026),
            transcript: 'tea voice')
      ],
    );
    expect(
        findNoteMatches(noteSearchFields(note), 'tea')
            .map((match) => match.fieldId),
        ['title', 'todo:active', 'todo:done', 'body', 'voice:memo']);
  });

  testWidgets(
      'navigation wraps, retains the current match on refresh, and ignores stale targets',
      (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final controller = NoteSearchController();
    addTearDown(controller.dispose);
    controller.setFields([const NoteSearchField('body', 'tea tea')]);
    final revealed = <NoteSearchMatch>[];
    final unregister = controller.registerTarget(
        owner: Object(), fieldId: 'body', reveal: revealed.add);
    controller.setQuery('tea');
    await tester.pump();
    expect(revealed.last, const NoteSearchMatch('body', 0, 3));
    controller.previous();
    await tester.pump();
    expect(controller.currentIndex, 1);
    expect(revealed.last, const NoteSearchMatch('body', 4, 7));
    controller.setFields([const NoteSearchField('body', 'tea tea tea')]);
    expect(controller.currentIndex, 1);
    controller.next();
    controller.next();
    await tester.pump();
    expect(controller.currentIndex, 0);
    unregister();
    final count = revealed.length;
    controller.next();
    await tester.pump();
    expect(revealed.length, count);
    controller.setQuery('none');
    expect(controller.currentMatch, isNull);
    controller.previous();
    expect(controller.currentIndex, -1);
  });
}
