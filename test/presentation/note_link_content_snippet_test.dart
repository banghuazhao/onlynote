import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/presentation/components/note_link_content_snippet.dart';

VoiceMemo _memo(String? transcript) => VoiceMemo(
      id: 'memo',
      path: 'missing-recording.m4a',
      durationMs: 0,
      createdAt: DateTime(2026),
      transcript: transcript,
    );

void main() {
  test('stored body, checklist and transcript provide distinct content context',
      () {
    final note = Note(
      title: 'Same title',
      description: '  Visit\n the   coast  ',
      todo: [Todo(title: '  Buy 茶  ')],
      voiceMemos: [_memo('Book the cabin')],
    );
    expect(noteLinkContentSnippet(note), 'Visit the coast');
    expect(noteLinkContentSnippet(note.copyWith(description: null)), 'Buy 茶');
    expect(noteLinkContentSnippet(note.copyWith(description: ' ', todo: [])),
        'Book the cabin');
  });

  test('blank placeholders and media without text omit the excerpt', () {
    final note = Note(
      title: 'Title alone is not repeated',
      description: '\n \t',
      todo: [Todo(title: null), Todo(title: '  ')],
      voiceMemos: [_memo(null), _memo('  ')],
      imagePaths: ['missing-photo.jpg'],
    );
    expect(noteLinkContentSnippet(note), isEmpty);
    expect(noteLinkContentSnippet(note, query: 'title'), isEmpty);
    expect(noteLinkContentSnippet(note, photoText: ['Cached receipt text']),
        isEmpty);
  });

  test('search prefers matching literal body, checklist and transcript text',
      () {
    final note = Note(
      description: 'Ordinary body without this match',
      todo: [Todo(title: 'Buy [tea]')],
      voiceMemos: [_memo('CABIN reservation')],
    );
    expect(noteLinkContentSnippet(note, query: ' ORDINARY '),
        'Ordinary body without this match');
    expect(noteLinkContentSnippet(note, query: '[TEA]'), 'Buy [tea]');
    expect(noteLinkContentSnippet(note, query: 'cabin'), 'CABIN reservation');
    expect(noteLinkContentSnippet(note, query: '.*'),
        'Ordinary body without this match');
    expect(noteLinkContentSnippet(note, query: 'unmatched'),
        'Ordinary body without this match');
  });

  test('long matching content is revealed near the query', () {
    final prefix = List.filled(100, 'Earlier text ').join();
    final note = Note(
      description: '${prefix}Unique destination after the long prefix',
      voiceMemos: [_memo('${prefix}Mountain cabin for the weekend')],
    );
    final body = noteLinkContentSnippet(note, query: 'unique destination');
    expect(body, startsWith('…'));
    expect(body, contains('Unique destination'));
    expect(body.characters.length, lessThanOrEqualTo(161));
    final transcript = noteLinkContentSnippet(note, query: 'mountain cabin');
    expect(transcript, startsWith('…'));
    expect(transcript, contains('Mountain cabin'));
  });

  test('cached OCR can explain a match without affecting ordinary previews',
      () {
    final note = Note(description: 'Keep this receipt');
    final cachedText = ['MARKET 茶\nTotal: 12.50 [paid]'];
    expect(noteLinkContentSnippet(note, query: '[PAID]', photoText: cachedText),
        'MARKET 茶 Total: 12.50 [paid]');
    expect(noteLinkContentSnippet(note, photoText: cachedText),
        'Keep this receipt');
    expect(noteLinkContentSnippet(note, query: '.*', photoText: cachedText),
        'Keep this receipt');
  });

  test('prefixes preserve CJK, emoji and combining mark graphemes', () {
    const family = '👨‍👩‍👧‍👦';
    const accented = 'e\u0301';
    final long = '${List.filled(158, '茶').join()}$family$accented尾';
    final snippet = noteLinkContentSnippet(Note(description: long));
    expect(snippet, '${List.filled(158, '茶').join()}$family$accented…');
    expect(snippet.characters.length, 161);
    expect(noteLinkContentSnippet(Note(description: '茶 $family $accented')),
        '茶 $family $accented');
    expect(noteLinkContentSnippet(Note(description: long), query: family),
        contains(family));
  });
}
