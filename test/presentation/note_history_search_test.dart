import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/presentation/components/note_history_search.dart';

void main() {
  test('history filter preserves original identities and ordering', () {
    final first = Object();
    final second = Object();
    final third = Object();
    final versions = [first, second, third];
    final text = {
      first: ['A Review'],
      second: ['Another topic'],
      third: ['Review tasks'],
    };
    final result = filterNoteHistoryVersions(versions, ' review ',
        searchableText: (version) => text[version]!);
    expect(result, [same(first), same(third)]);
    expect(versions, [same(first), same(second), same(third)]);
  });

  test('blank history query returns all without reading snapshot content', () {
    final versions = [Object(), Object()];
    final result = filterNoteHistoryVersions(versions, ' \n\t ',
        searchableText: (_) => throw StateError('Blank query needs no text'));
    expect(result, [same(versions.first), same(versions.last)]);
    expect(result, isNot(same(versions)));
  });

  test('history search treats regex symbols and Unicode as literal text', () {
    final versions = [
      ['A [draft].*', 'Other text'],
      ['茶室😀 café'],
      ['AdraftXYZ'],
    ];
    expect(
        filterNoteHistoryVersions(versions, '[DRAFT].*',
            searchableText: (value) => value),
        [same(versions[0])]);
    expect(
        filterNoteHistoryVersions(versions, '茶室😀 CAFÉ',
            searchableText: (value) => value),
        [same(versions[1])]);
    expect(
        filterNoteHistoryVersions(versions, r'[]()\^$+?',
            searchableText: (value) => value),
        isEmpty);
  });
}
