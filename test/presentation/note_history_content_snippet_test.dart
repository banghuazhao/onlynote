import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/presentation/components/note_history_content_snippet.dart';

void main() {
  test(
      'blank query preserves full text, whitespace and original field priority',
      () {
    final body = 'Body first line\n${'Long original context ' * 30}';
    final note = NoteDto(
      description: ' \n$body\t ',
      todoList: [TodoDto(title: ' First task '), TodoDto(title: 'Second task')],
      voiceMemos: const [
        {'transcript': ' Recorded thought\nSecond line '},
      ],
    );
    for (final query in ['', ' \n\t ']) {
      expect(noteHistoryContentSnippet(note, query: query), body.trim());
      expect(
          noteHistoryContentSnippet(note.copyWith(description: ' \n '),
              query: query),
          ' First task , Second task');
      expect(
          noteHistoryContentSnippet(
              note.copyWith(description: ' ', todoList: []),
              query: query),
          'Recorded thought\nSecond line');
    }
  });

  test('late body match appears immediately in a bounded single line excerpt',
      () {
    final original = '${'Unrelated earlier context\n' * 50}'
        'Needle first detail\n${'Remaining detail ' * 50}';
    final note = NoteDto(description: original);
    final snippet = noteHistoryContentSnippet(note, query: ' NEEDLE ');
    expect(snippet, startsWith('…Needle first detail Remaining detail'));
    expect(snippet, endsWith('…'));
    expect(snippet.characters.length, lessThanOrEqualTo(160));
    expect(snippet, isNot(contains('\n')));
    expect(note.description, original);
  });

  test('matching checklist and transcript replace unrelated body context', () {
    final note = NoteDto(
      description: 'Ordinary saved body',
      todoList: [TodoDto(title: ' Earlier task '), TodoDto(title: 'Buy [tea]')],
      voiceMemos: const [
        {'transcript': 'Voice CABIN reservation'},
      ],
    );
    expect(noteHistoryContentSnippet(note, query: '[TEA]'), '…[tea]');
    expect(
        noteHistoryContentSnippet(note, query: 'cabin'), '…CABIN reservation');
    expect(noteHistoryContentSnippet(note, query: 'ORDINARY'),
        'Ordinary saved body');
    expect(noteHistoryContentSnippet(note, query: 'unmatched title'),
        'Ordinary saved body');
  });

  test('literal punctuation, CJK and emoji share the normal search behavior',
      () {
    final note = NoteDto(
      description: 'Earlier context ${'padding ' * 20}'
          '茶室😀 [draft].* final notes',
    );
    expect(noteHistoryContentSnippet(note, query: '茶室😀'),
        '…茶室😀 [draft].* final notes');
    expect(noteHistoryContentSnippet(note, query: '[DRAFT].*'),
        '…[draft].* final notes');
    expect(noteHistoryContentSnippet(note, query: r'[]()\^$+?'),
        startsWith('Earlier context'));
  });

  test('query and clipping boundaries retain complete complex graphemes', () {
    const family = '👨‍👩‍👧‍👦';
    const accented = 'e\u0301';
    final note = NoteDto(description: 'Introduction $family$accented match');
    expect(noteHistoryContentSnippet(note, query: '👩'),
        '…$family$accented match');
    expect(noteHistoryContentSnippet(note, query: '\u0301 match'),
        '…$accented match');
    final long = NoteDto(description: '${'茶' * 158}$family$accented尾');
    final snippet = noteHistoryContentSnippet(long, query: '茶');
    expect(snippet, '${'茶' * 158}$family…');
    expect(snippet.characters.length, 160);
  });

  test('blank and malformed stored transcripts are skipped without coercion',
      () {
    final memos = <Map<dynamic, dynamic>>[
      {},
      {'transcript': null},
      {'transcript': 42},
      {'transcript': false},
      {
        'transcript': <String>['not readable text']
      },
      {'transcript': ' \n '},
      {'transcript': 'Saved CAFÉ thought'},
    ];
    final note = NoteDto(
        description: null,
        todoList: [TodoDto(title: null), TodoDto(title: '\t ')],
        voiceMemos: memos);
    expect(noteHistoryContentSnippet(note), 'Saved CAFÉ thought');
    expect(noteHistoryContentSnippet(note, query: 'café'), '…CAFÉ thought');
    expect(noteHistoryContentSnippet(note, query: 'not readable'),
        'Saved CAFÉ thought');
    expect(note.voiceMemos, same(memos));
    expect(
        noteHistoryContentSnippet(NoteDto(voiceMemos: memos.take(6).toList()),
            query: 'missing'),
        isEmpty);
  });
}
