import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_export.dart';
import 'package:onlynote/services/note_search.dart';

VoiceMemo _memo(String id, {String? transcript}) => VoiceMemo(
    id: id,
    path: 'note_audio/$id.m4a',
    durationMs: 42000,
    createdAt: DateTime(2026, 10, 6),
    transcript: transcript);

void main() {
  test(
      'audio-only transcript search is literal, case insensitive and bilingual',
      () {
    final note = Note(voiceMemos: [
      _memo('private-recording-id', transcript: 'Meeting [Tea] tomorrow 会议買茶'),
      _memo('second', transcript: 'Later recording'),
      _memo('without-transcript'),
    ]);
    for (final query in ['meeting', '  [tea] ', '会议', '買茶', 'later', '']) {
      expect(matchesNoteSearch(note, query, {}, hasReminder: false), isTrue);
    }
    for (final query in [
      '.*',
      'private-recording-id',
      'note_audio',
      'missing'
    ]) {
      expect(matchesNoteSearch(note, query, {}, hasReminder: false), isFalse);
    }
    expect(
        matchesNoteSearch(note, 'meeting', {NoteSearchFilter.photos},
            hasReminder: false),
        isFalse);
    expect(
        matchesNoteSearch(note, 'meeting', {NoteSearchFilter.reminders},
            hasReminder: true),
        isTrue);
  });

  test('plain text exports full ordered transcripts without audio paths', () {
    final first = 'Meeting notes\n会议记录';
    final second = '${'Keep the full transcript. ' * 80}FINAL WORDS';
    final note = Note(
        title: 'Minutes',
        description: 'Written introduction',
        voiceMemos: [
          _memo('first', transcript: first),
          _memo('untranscribed'),
          _memo('empty', transcript: ''),
          _memo('second', transcript: second),
        ],
        todo: [
          Todo(title: 'Send minutes', completed: true)
        ]);
    final exported = NoteExport.plainText(note, reminder: 'Tomorrow at 9');
    expect(exported,
        'Minutes\n\nWritten introduction\n\n$first\n\n$second\n\n[x] Send minutes\n\nTomorrow at 9');
    expect(exported, isNot(contains('note_audio/')));
    expect(exported, isNot(contains('first.m4a')));
    expect(
        NoteExport.plainText(
            Note(voiceMemos: [_memo('only', transcript: first)])),
        first);
  });

  test('Markdown escapes transcripts and retains Chinese and line breaks', () {
    final note = Note(voiceMemos: [
      _memo('first', transcript: '# [Meeting] *action* <todo> 会议\nSecond line'),
      _memo('silent'),
      _memo('second', transcript: '香港買茶'),
    ]);
    final exported = NoteExport.markdown(note);
    expect(exported,
        '${r'\# \[Meeting\] \*action\* \<todo\> 会议'}\nSecond line\n\n香港買茶');
    expect(exported, isNot(contains('note_audio/')));
    expect(exported, isNot(contains('.m4a')));
  });
}
