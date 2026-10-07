import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/reorder_notes_usecase.dart';
import 'package:onlynote/generated/l10n.dart';

class _Notes implements NoteRepository {
  final values = <String, NoteDto>{};
  final failAtWrites = <int>{};
  int writes = 0;
  void Function()? onFailedWrite;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    if (failAtWrites.contains(writes)) {
      onFailedWrite?.call();
      throw StateError('Storage failed');
    }
    values[note.id!] = note;
  }

  @override
  List<NoteDto> getAllNotes() => values.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => values[id]!;
  @override
  Future<void> deleteNote(String id) async => values.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {}
}

void main() {
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  late _Notes notes;
  setUp(() {
    notes = _Notes();
    for (var i = 0; i < 3; i++) {
      notes.values['$i'] = NoteDto.fromNote(Note(
          id: '$i',
          title: 'Note $i',
          sortOrder: i == 0 ? null : i,
          todo: [Todo(id: 'todo-$i', title: 'Task $i')]));
    }
  });

  test('reordering changes only ordering in the freshest persisted notes',
      () async {
    final snapshots =
        notes.values.values.map((note) => note.toDomain()).toList();
    notes.values['1'] = NoteDto.fromNote(notes.values['1']!
        .toDomain()
        .copyWith(title: 'Edited title', isPinned: true, todo: [
      Todo(id: 'todo-1', title: 'Edited task', completed: true),
    ]));
    expect(
        (await ReorderNotesUsecase(notes)(snapshots.reversed.toList()))
            .isRight(),
        isTrue);
    expect(
        notes.values['2']!.sortOrder, lessThan(notes.values['1']!.sortOrder!));
    expect(
        notes.values['1']!.sortOrder, lessThan(notes.values['0']!.sortOrder!));
    final edited = notes.values['1']!.toDomain();
    expect(edited.title, 'Edited title');
    expect(edited.isPinned, isTrue);
    expect(edited.todo.single.title, 'Edited task');
    expect(edited.todo.single.completed, isTrue);
  });

  test(
      'a failed second write rolls back prior order while retaining new content',
      () async {
    final snapshots =
        notes.values.values.map((note) => note.toDomain()).toList();
    notes.failAtWrites.add(2);
    notes.onFailedWrite = () {
      notes.values['0'] = NoteDto.fromNote(notes.values['0']!
          .toDomain()
          .copyWith(title: 'Edited during save', isPinned: true));
    };
    expect((await ReorderNotesUsecase(notes)(snapshots)).isLeft(), isTrue);
    expect(notes.values['0']!.sortOrder, isNull);
    expect(notes.values['1']!.sortOrder, 1);
    expect(notes.values['2']!.sortOrder, 2);
    expect(notes.values['0']!.title, 'Edited during save');
    expect(notes.values['0']!.isPinned, isTrue);
    expect(notes.writes, 3);
  });

  test('rollback leaves a newer independent sort order intact', () async {
    final snapshots =
        notes.values.values.map((note) => note.toDomain()).toList();
    notes.failAtWrites.add(2);
    notes.onFailedWrite = () {
      notes.values['0'] = notes.values['0']!.copyWith(sortOrder: -42);
    };
    expect((await ReorderNotesUsecase(notes)(snapshots)).isLeft(), isTrue);
    expect(notes.values['0']!.sortOrder, -42);
    expect(notes.writes, 2);
  });
}
