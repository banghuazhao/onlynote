import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/services/unfinished_checklist.dart';

void main() {
  test('keeps unfinished titles in saved order and does not mutate the items',
      () {
    final todos = [
      Todo(id: 'c', title: '  Bread  '),
      Todo(id: 'a', title: 'Milk', completed: true),
      Todo(id: 'b', title: ' Eggs '),
      Todo(id: 'duplicate', title: 'Bread'),
    ];
    final snapshot = List<Todo>.of(todos);

    final titles = unfinishedChecklistTitles(todos);

    expect(titles, ['Bread', 'Eggs', 'Bread']);
    expect(todos, snapshot);
    expect(todos.map((todo) => todo.id), ['c', 'a', 'b', 'duplicate']);
    expect(todos.map((todo) => todo.completed), [false, true, false, false]);
    expect(todos.first.title, '  Bread  ');
    expect(() => titles.add('Changed'), throwsUnsupportedError);
  });

  test('ignores null, blank and completed placeholders', () {
    expect(
      unfinishedChecklistTitles([
        Todo(),
        Todo(title: ''),
        Todo(title: ' \t\n '),
        Todo(title: 'Done', completed: true),
      ]),
      isEmpty,
    );
    expect(unfinishedChecklistTitles(const []), isEmpty);
  });

  test('preserves internal newlines, spacing and Unicode text', () {
    expect(
      unfinishedChecklistTitles([
        Todo(title: ' \nTea  bags\nfor  dinner\t '),
        Todo(title: '買麵包 🥖'),
        Todo(title: ' e\u0301 '),
      ]).join('\n'),
      'Tea  bags\nfor  dinner\n買麵包 🥖\ne\u0301',
    );
  });
}
