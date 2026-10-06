import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';

/// Counts only content a reader sees: title, body, nonempty checklist items,
/// and voice transcripts. Formatting, tags, attachment paths, IDs, and other
/// metadata never contribute to these totals.
class NoteStatistics {
  const NoteStatistics._({
    required this.wordCount,
    required this.characterCount,
    required this.estimatedReadingSeconds,
  });

  factory NoteStatistics.fromNote(Note note) {
    var separatedWords = 0;
    var cjkCharacters = 0;
    var characterCount = 0;
    final fields = <String?>[
      note.title,
      note.description,
      ...note.todo.map((item) => item.title),
      ...note.voiceMemos.map((memo) => memo.transcript),
    ];
    for (final field in fields) {
      if (field == null || field.trim().isEmpty) continue;
      var inWord = false;
      var pendingConnector = false;
      for (final character in field.characters) {
        characterCount++;
        if (_isCjk(character)) {
          cjkCharacters++;
          inWord = false;
          pendingConnector = false;
        } else if (_isWordCharacter(character)) {
          if (!inWord) separatedWords++;
          inWord = true;
          pendingConnector = false;
        } else if (inWord &&
            !pendingConnector &&
            _connectors.contains(character)) {
          // Internal apostrophes and hyphens keep "don't" and "well-being"
          // together. Two connectors, punctuation, and emoji end a word.
          pendingConnector = true;
        } else {
          inWord = false;
          pendingConnector = false;
        }
      }
    }

    // Approximate reading pace: 200 separated words or 300 CJK characters
    // per minute. Integer arithmetic keeps exact minute boundaries stable.
    final seconds = (separatedWords * 3 + cjkCharacters * 2 + 9) ~/ 10;
    return NoteStatistics._(
      wordCount: separatedWords + cjkCharacters,
      characterCount: characterCount,
      estimatedReadingSeconds: seconds == 0 && characterCount > 0 ? 1 : seconds,
    );
  }

  /// Unicode letter/number runs count as words. Each Han, kana, or Hangul
  /// grapheme counts individually because those scripts need no spaces.
  /// This is a counting convention, not dictionary-based word segmentation.
  final int wordCount;

  /// Extended grapheme clusters, including spaces and line breaks in each
  /// nonempty field. Joined emoji and a letter with combining accents each
  /// count once. No artificial separators are inserted between fields, and
  /// entirely blank fields contribute zero characters.
  final int characterCount;

  final int estimatedReadingSeconds;

  /// Rounded up for the displayed estimate; zero means there is no content.
  int get estimatedReadingMinutes => (estimatedReadingSeconds + 59) ~/ 60;
}

final _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);
const _connectors = {"'", '’', '-', '‐', '‑'};

bool _isWordCharacter(String character) =>
    // Keycap emoji contain a digit but are symbols rather than words.
    !character.contains('\u20e3') && _wordCharacter.hasMatch(character);

bool _isCjk(String character) {
  final rune = character.runes.first;
  return (rune >= 0x3400 && rune <= 0x4dbf) || // Han Extension A.
      (rune >= 0x4e00 && rune <= 0x9fff) || // Unified Han.
      (rune >= 0xf900 && rune <= 0xfaff) || // Compatibility Han.
      (rune >= 0x20000 && rune <= 0x323af) || // Supplementary Han.
      (rune >= 0x3041 && rune <= 0x3096) || // Hiragana.
      (rune >= 0x30a1 && rune <= 0x30fa) || // Katakana.
      (rune >= 0x31f0 && rune <= 0x31ff) || // Katakana extensions.
      (rune >= 0xff66 && rune <= 0xff9d) || // Halfwidth katakana.
      (rune >= 0x1100 && rune <= 0x11ff) || // Hangul jamo.
      (rune >= 0x3131 && rune <= 0x318e) || // Compatibility jamo.
      (rune >= 0xa960 && rune <= 0xa97f) || // Hangul Extended-A.
      (rune >= 0xac00 && rune <= 0xd7af) || // Hangul syllables.
      (rune >= 0xd7b0 && rune <= 0xd7ff); // Hangul Extended-B.
}
