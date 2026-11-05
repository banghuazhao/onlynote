import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/note_tag_management.dart';
import 'package:onlynote/services/note_tags.dart';

void main() {
  group('tagNameProblem', () {
    test('rejects names no note could store', () {
      expect(tagNameProblem(''), TagNameProblem.empty);
      expect(tagNameProblem('   '), TagNameProblem.empty);
      expect(tagNameProblem('\t\n '), TagNameProblem.empty);
      expect(tagNameProblem('a' * 41), TagNameProblem.tooLong);
      expect(tagNameProblem('a' * 40), isNull);
      expect(tagNameProblem('  Work notes  '), isNull);
    });

    test('counts visible characters, so emoji are never split', () {
      // A family emoji is one grapheme cluster made of many code units.
      expect(tagNameProblem('👨‍👩‍👧‍👦' * 40), isNull);
      expect(tagNameProblem('👨‍👩‍👧‍👦' * 41), TagNameProblem.tooLong);
    });
  });

  group('renameTagIn', () {
    test('keeps the renamed tag in place', () {
      expect(
          renameTagIn(['Alpha', 'Beta', 'Gamma'], from: 'beta', to: 'Delta'),
          ['Alpha', 'Delta', 'Gamma']);
    });

    test('changes only spelling when both names share a key', () {
      expect(renameTagIn(['work'], from: 'WORK', to: 'Work'), ['Work']);
    });

    test('merges onto an existing tag at the earlier position', () {
      expect(renameTagIn(['Beta', 'Alpha', 'Gamma'], from: 'Alpha', to: 'beta'),
          ['beta', 'Gamma']);
      expect(renameTagIn(['Alpha', 'Beta', 'Gamma'], from: 'Alpha', to: 'beta'),
          ['beta', 'Gamma']);
    });

    test('leaves lists without the old tag untouched, spelling included', () {
      final tags = ['Beta', 'Gamma'];
      expect(renameTagIn(tags, from: 'Alpha', to: 'beta'), same(tags));
    });

    test('folds legacy duplicate spellings on the lists it rewrites', () {
      expect(
          renameTagIn(['Work', ' WORK ', 'Work\tMeetings', 'work   meetings'],
              from: 'Work', to: 'Job'),
          ['Job', 'Work Meetings']);
    });

    test('never grows a list, so the tag limit cannot be passed', () {
      final tags = [for (var i = 0; i < maxNoteTags; i++) 'tag$i'];
      final renamed = renameTagIn(tags, from: 'tag0', to: 'tag1');
      expect(renamed.length, maxNoteTags - 1);
      expect(renameTagIn(tags, from: 'tag0', to: 'fresh').length, maxNoteTags);
    });

    test('ignores a blank replacement rather than dropping the tag', () {
      final tags = ['Alpha', 'Beta'];
      expect(renameTagIn(tags, from: 'Alpha', to: '   '), same(tags));
    });

    test('result is unmodifiable', () {
      final renamed = renameTagIn(['Alpha'], from: 'Alpha', to: 'Beta');
      expect(() => renamed.add('Gamma'), throwsUnsupportedError);
    });
  });

  group('removeTagIn', () {
    test('removes every spelling of the tag', () {
      expect(removeTagIn(['Work', ' WORK ', 'Research'], 'work'), ['Research']);
    });

    test('leaves lists without the tag untouched', () {
      final tags = ['Research'];
      expect(removeTagIn(tags, 'work'), same(tags));
    });

    test('can empty a list', () {
      expect(removeTagIn(['Work'], 'WORK'), isEmpty);
    });
  });

  group('sameNoteTags', () {
    test('compares spellings in order', () {
      expect(sameNoteTags(['a', 'b'], ['a', 'b']), isTrue);
      expect(sameNoteTags(['a', 'b'], ['b', 'a']), isFalse);
      expect(sameNoteTags(['a'], ['A']), isFalse);
      expect(sameNoteTags(['a'], ['a', 'b']), isFalse);
      expect(sameNoteTags(const [], const []), isTrue);
    });
  });
}
