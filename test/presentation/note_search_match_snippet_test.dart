import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/presentation/components/note_search_match_snippet.dart';

VoiceMemo _memo(String? transcript) => VoiceMemo(
      id: 'private-memo-id',
      path: 'note_audio/private-recording.m4a',
      durationMs: 1000,
      createdAt: DateTime(2026, 10, 20),
      transcript: transcript,
    );

void main() {
  test(
      'only matching stored content explains body, checklist, transcript or tag',
      () {
    final note = Note(
      title: 'Meeting title',
      description: '  Ordinary\n body   text ',
      todo: [Todo(title: 'Bring [tea]', completed: true)],
      voiceMemos: [_memo('Confirm the CABIN reservation')],
      tags: ['Travel C++'],
    );
    expect(noteSearchMatchSnippet(note, ' BODY '), '…body text');
    expect(noteSearchMatchSnippet(note, '[TEA]'), '…[tea]');
    expect(noteSearchMatchSnippet(note, 'cabin'), '…CABIN reservation');
    expect(noteSearchMatchSnippet(note, ' C++ '), '…C++');
    expect(noteSearchMatchSnippet(note, 'meeting'), isEmpty);
    expect(noteSearchMatchSnippet(note, 'missing'), isEmpty);
    expect(note.description, '  Ordinary\n body   text ');
    expect(note.todo.single.completed, isTrue);
    expect(note.voiceMemos.single.transcript, 'Confirm the CABIN reservation');
    expect(note.tags, ['Travel C++']);
  });

  test('blank/title-only/media-only and technical matches have no excerpt', () {
    final note = Note(
      id: 'private-note-id',
      title: 'Only heading',
      description: ' \n\t',
      todo: [Todo(title: null), Todo(id: 'private-task-id', title: ' ')],
      voiceMemos: [_memo(null), _memo(''), _memo('\t ')],
      imagePaths: ['private-photo.jpg'],
      folderId: 'private-folder-id',
      linkedNoteIds: ['private-linked-id'],
    );
    for (final query in [
      '',
      ' \t\n\u3000 ',
      'Only heading',
      'private-note-id',
      'private-task-id',
      'private-memo-id',
      'private-recording',
      'note_audio',
      '.m4a',
      'private-photo',
      'private-folder-id',
      'private-linked-id',
    ]) {
      expect(noteSearchMatchSnippet(note, query), isEmpty, reason: query);
    }
  });

  test('queries match literally and within individual fields', () {
    final note = Note(
      description: 'C++ [2026] .* ? \\',
      todo: [Todo(title: '閱讀茶😀')],
      tags: ['Ångström', 'Alpha', 'Beta'],
      voiceMemos: [_memo('Family 👨‍👩‍👧‍👦')],
    );
    for (final (query, expected) in [
      ('c++', 'C++ [2026] .* ? \\'),
      ('[2026]', '…[2026] .* ? \\'),
      ('[', '…[2026] .* ? \\'),
      ('.*', '….* ? \\'),
      ('?', '…? \\'),
      ('\\', '…\\'),
    ]) {
      expect(noteSearchMatchSnippet(note, query), expected);
    }
    expect(noteSearchMatchSnippet(note, ' 茶😀 '), '…茶😀');
    expect(noteSearchMatchSnippet(note, ' ÅNGSTRÖM '), 'Ångström');
    expect(noteSearchMatchSnippet(note, '👨‍👩‍👧‍👦'), '…👨‍👩‍👧‍👦');
    expect(noteSearchMatchSnippet(note, 'Alpha Beta'), isEmpty);
  });

  test('long matching text starts at the match and stays bounded in graphemes',
      () {
    const family = '👨‍👩‍👧‍👦';
    const accented = 'e\u0301';
    final prefix = List.filled(100, 'Earlier text. ').join();
    final tail = List.filled(200, '茶').join();
    final note = Note(description: '$prefix$family$accented Match $tail');
    final snippet = noteSearchMatchSnippet(note, '$family$accented Match');
    expect(snippet, startsWith('…$family$accented Match'));
    expect(snippet, contains('$family$accented Match'));
    expect(snippet, endsWith('…'));
    expect(snippet.characters.length, lessThanOrEqualTo(161));
    expect(note.description, '$prefix$family$accented Match $tail');
  });

  test('first matching content field wins without mixing unrelated text', () {
    final note = Note(
      description: 'First needle body',
      todo: [
        Todo(title: 'Second needle task'),
        Todo(title: 'Third needle task')
      ],
      voiceMemos: [_memo('Fourth needle recording')],
      tags: ['Fifth needle tag'],
    );
    expect(noteSearchMatchSnippet(note, 'needle'), '…needle body');
    expect(
        noteSearchMatchSnippet(
            note.copyWith(description: 'Unrelated'), 'needle'),
        '…needle task');
    expect(
        noteSearchMatchSnippet(
            note.copyWith(description: '', todo: []), 'needle'),
        '…needle recording');
    expect(
        noteSearchMatchSnippet(
            note.copyWith(description: '', todo: [], voiceMemos: []), 'needle'),
        '…needle tag');
  });

  test(
      'matches inside combined graphemes retain the full grapheme at the start',
      () {
    const family = '👨‍👩‍👧‍👦';
    const accented = 'e\u0301';
    final note = Note(description: 'Before $family$accented after');
    expect(noteSearchMatchSnippet(note, '👩'), '…$family$accented after');
    expect(noteSearchMatchSnippet(note, '\u0301'), '…$accented after');
  });
}
