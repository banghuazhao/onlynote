import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_tags.dart';

void main() {
  test('trims and collapses whitespace while preserving first spelling', () {
    expect(
      normalizeNoteTags([
        '  Work\t Projects\n ',
        'work projects',
        ' 個人\u00a0\u0085計劃 ',
        '個人 計劃',
        '',
        '  ',
      ]),
      ['Work Projects', '個人 計劃'],
    );
  });

  test('comparison keys normalize spacing and case', () {
    expect(tagKey('  HOME\n Ideas  '), 'home ideas');
    expect(tagKey('   '), '');
    expect(tagKey('ÄPFEL'), tagKey('äpfel'));
  });

  test('result cannot be mutated and is independent of its source', () {
    final source = ['Work'];
    final tags = normalizeNoteTags(source);
    source[0] = 'Changed';
    expect(tags, ['Work']);
    expect(() => tags.add('Other'), throwsUnsupportedError);
    expect(() => tags[0] = 'Other', throwsUnsupportedError);
  });

  test('twenty unique tags are allowed and duplicates do not consume slots',
      () {
    final tags = List.generate(20, (index) => 'Tag $index');
    expect(normalizeNoteTags([...tags, ' TAG   0 ']), tags);
    expect(
        () => normalizeNoteTags([...tags, 'New tag']), throwsFormatException);
  });

  test('limits use complete emoji and combining sequences', () {
    final emojis = List.filled(40, '👩🏽‍💻').join();
    final accents = List.filled(40, 'e\u0301').join();
    expect(normalizeNoteTags([emojis, accents]), [emojis, accents]);
    expect(() => normalizeNoteTags(['$emojis👩🏽‍💻']), throwsFormatException);
    expect(
        () => normalizeNoteTags(['${accents}e\u0301']), throwsFormatException);
  });

  test('length is checked after whitespace normalization', () {
    expect(normalizeNoteTags(['${' ' * 60}Ideas${' ' * 60}']), ['Ideas']);
    expect(() => normalizeNoteTags(['a' * 41]), throwsFormatException);
    expect(normalizeNoteTags(['', '\n\t']), isEmpty);
  });
}
