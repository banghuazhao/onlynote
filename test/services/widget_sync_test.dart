import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/widget_sync.dart';
import 'package:onlynote/data/dto/note_dto.dart';

void main() {
  test('configuration includes every active note beyond the overview rows', () {
    final notes = List.generate(
        12,
        (index) =>
            NoteDto(id: 'note-$index', title: 'Note $index', sortOrder: index));
    notes.add(NoteDto(id: 'trash', deletedAt: '2026-10-06'));
    final payload = WidgetSync.buildPayload(notes);
    expect(payload['total'], 12);
    expect(payload['notes'], hasLength(8));
    final all = payload['allNotes'] as List<Map<String, dynamic>>;
    expect(all, hasLength(12));
    expect(all.last['id'], 'note-11');
    expect(all.any((note) => note['id'] == 'trash'), false);
    expect(notes, hasLength(13));
  });

  test('snapshot carries stable item IDs and leaves legacy items read only',
      () {
    final payload = WidgetSync.buildPayload([
      NoteDto(id: 'one', title: 'Packing\n list', todoList: [
        TodoDto(id: 'passport', title: 'Passport', completed: true),
        TodoDto(title: 'Old item'),
      ]),
    ]);
    final note = (payload['allNotes'] as List<Map<String, dynamic>>).single;
    final todos = note['todos'] as List<Map<String, dynamic>>;
    expect(note['title'], 'Packing list');
    expect(note['todoTotal'], 2);
    expect(note['todoDone'], 1);
    expect(todos.first, {'id': 'passport', 't': 'Passport', 'c': true});
    expect(todos.last.containsKey('id'), false);
    expect(todos.last['c'], false);
  });
}
