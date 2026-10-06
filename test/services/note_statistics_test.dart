import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_statistics.dart';

VoiceMemo _memo(String id, {String? transcript}) => VoiceMemo(
      id: id,
      path: 'note_audio/$id.m4a',
      durationMs: 42000,
      createdAt: DateTime(2026, 10, 7),
      transcript: transcript,
    );

void main() {
  test('empty and entirely blank content has no statistics', () {
    for (final note in [
      Note(),
      Note(
        title: ' \t ',
        description: '\n\r\n\u00a0',
        todo: [Todo(), Todo(title: '  '), Todo(title: '\n', completed: true)],
        voiceMemos: [_memo('blank', transcript: '\t\n')],
      ),
    ]) {
      final stats = NoteStatistics.fromNote(note);
      expect(stats.wordCount, 0);
      expect(stats.characterCount, 0);
      expect(stats.estimatedReadingSeconds, 0);
      expect(stats.estimatedReadingMinutes, 0);
    }
  });

  test('attachment filenames, tags and linked IDs do not count as text', () {
    final stats = NoteStatistics.fromNote(Note(
      id: 'private title',
      folderId: 'folder name',
      imagePaths: ['holiday photo 香港.jpg'],
      voiceMemos: [_memo('a-very-long-file-name')],
      tags: ['business', '重要'],
      linkedNoteIds: ['https://example.com/saved-note'],
    ));
    expect(stats.wordCount, 0);
    expect(stats.characterCount, 0);
    expect(stats.estimatedReadingSeconds, 0);
  });

  test('includes title, body, all nonempty tasks and transcripts once', () {
    final stats = NoteStatistics.fromNote(Note(
      title: 'Walk',
      description: 'Fresh air.',
      todo: [
        Todo(title: 'Bring tea'),
        Todo(title: 'Call home', completed: true),
        Todo(title: '  '),
        Todo(),
      ],
      voiceMemos: [
        _memo('first', transcript: 'Meet at noon.'),
        _memo('silent'),
        _memo('blank', transcript: ' '),
      ],
    ));
    expect(stats.wordCount, 10);
    expect(stats.characterCount, 45);
    expect(stats.estimatedReadingSeconds, 3);
  });

  test('Chinese characters and mixed English count without requiring spaces',
      () {
    final stats = NoteStatistics.fromNote(Note(
      title: '香港',
      description: '今天喝 tea，明天買 coffee。',
    ));
    expect(stats.wordCount, 10);
    expect(stats.characterCount, 21);
    expect(stats.estimatedReadingSeconds, 3);
    final rareHan = NoteStatistics.fromNote(Note(description: '𠀀'));
    expect(rareHan.wordCount, 1);
    expect(rareHan.characterCount, 1);
  });

  test('Japanese and Korean graphemes use the same CJK counting convention',
      () {
    final stats = NoteStatistics.fromNote(Note(description: 'かな カナ 한글 한'));
    expect(stats.wordCount, 7);
    expect(stats.characterCount, 10);
    expect(stats.estimatedReadingSeconds, 2);
  });

  test(
      'joined emoji, modifiers, flags, keycaps and combining accents stay whole',
      () {
    final stats = NoteStatistics.fromNote(
      Note(description: '👨‍👩‍👧‍👦 👍🏽 🇳🇿 1️⃣ e\u0301'),
    );
    expect(stats.characterCount, 9);
    expect(stats.wordCount, 1);
    expect(stats.estimatedReadingSeconds, 1);
    final emojiOnly = NoteStatistics.fromNote(Note(description: '👨‍👩‍👧‍👦'));
    expect(emojiOnly.characterCount, 1);
    expect(emojiOnly.wordCount, 0);
    expect(emojiOnly.estimatedReadingSeconds, 1);
  });

  test('Unicode words and internal apostrophes or hyphens stay together', () {
    final stats = NoteStatistics.fromNote(
      Note(description: "don't well-being foo--bar l’été naïve 3"),
    );
    expect(stats.wordCount, 7);
    final languages = NoteStatistics.fromNote(
      Note(description: 'naïve cafe\u0301 Ελληνικά Москва العربية'),
    );
    expect(languages.wordCount, 5);
  });

  test('multiline mixed formatted body uses the original text only', () {
    const body = 'Heading\nCafé with tea.\n下一步：買麵包 🥖';
    final stats = NoteStatistics.fromNote(Note(
      description: body,
      textStyles: const [
        NoteTextStyleRange(start: 0, end: 7, kind: NoteTextStyleKind.heading),
        NoteTextStyleRange(start: 8, end: 12, kind: NoteTextStyleKind.bold),
        NoteTextStyleRange(
            start: 23, end: 30, kind: NoteTextStyleKind.highlight),
      ],
    ));
    expect(stats.wordCount, 10);
    expect(stats.characterCount, 32);
    expect(stats.estimatedReadingSeconds, 3);
  });

  test('includes original whitespace but inserts no extra field separators',
      () {
    final separate =
        NoteStatistics.fromNote(Note(title: 'A', description: 'B'));
    expect(separate.wordCount, 2);
    expect(separate.characterCount, 2);
    final spaced = NoteStatistics.fromNote(Note(description: '  a\nb  '));
    expect(spaced.wordCount, 2);
    expect(spaced.characterCount, 7);
    final crlf = NoteStatistics.fromNote(Note(description: 'a\r\nb'));
    expect(crlf.characterCount, 3);
  });

  test(
      'reading estimate combines scripts and rounds up exact minute boundaries',
      () {
    final english = NoteStatistics.fromNote(Note(description: 'word ' * 200));
    expect(english.estimatedReadingSeconds, 60);
    expect(english.estimatedReadingMinutes, 1);
    final chinese = NoteStatistics.fromNote(Note(description: '讀' * 300));
    expect(chinese.wordCount, 300);
    expect(chinese.estimatedReadingSeconds, 60);
    expect(chinese.estimatedReadingMinutes, 1);
    final mixed = NoteStatistics.fromNote(
      Note(description: '${'word ' * 100}${'讀' * 150}'),
    );
    expect(mixed.estimatedReadingSeconds, 60);
    expect(mixed.estimatedReadingMinutes, 1);
    final longer = NoteStatistics.fromNote(
      Note(description: '${'word ' * 101}${'讀' * 150}'),
    );
    expect(longer.estimatedReadingSeconds, 61);
    expect(longer.estimatedReadingMinutes, 2);
  });
}
