import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/add_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_form/add_update_form_bloc.dart';

class _FakeNoteRepository implements NoteRepository {
  final Map<String, NoteDto> notes = {};

  @override
  Future addUpdateNote(NoteDto note) async => notes[note.id!] = note;

  @override
  Future deleteNote(String id) async => notes.remove(id);

  @override
  Future deleteMultiNotes(List<String> ids) async => ids.forEach(notes.remove);

  @override
  List<NoteDto> getAllNotes() => notes.values.toList();

  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
}

void main() {
  late AddUpdateFormBloc bloc;

  setUp(() {
    final repository = _FakeNoteRepository();
    bloc = AddUpdateFormBloc(
      AddUpdateBloc(AddNoteUsecase(repository), UpdateNoteUsecase(repository)),
    );
  });

  tearDown(() => bloc.close());

  void seedTodos(List<String> titles) {
    bloc.add(
      AddUpdateFormEvent.initialize(
        todos: [
          for (final title in titles) Todo(id: title, title: title),
        ],
      ),
    );
  }

  List<String?> titles() => bloc.state.todos.map((todo) => todo.title).toList();

  test('dragging a todo to the end lands it last', () async {
    seedTodos(['a', 'b', 'c']);
    await Future<void>.delayed(Duration.zero);

    // ReorderableListView.onReorderItem has already accounted for the item
    // leaving oldIndex, so (0, 2) means "a goes after c".
    bloc.add(const AddUpdateFormEvent.reorderTodo(oldIndex: 0, newIndex: 2));
    await Future<void>.delayed(Duration.zero);

    expect(titles(), ['b', 'c', 'a']);
  });

  test('dragging a todo down one position swaps it with its neighbour',
      () async {
    seedTodos(['a', 'b', 'c']);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const AddUpdateFormEvent.reorderTodo(oldIndex: 0, newIndex: 1));
    await Future<void>.delayed(Duration.zero);

    expect(titles(), ['b', 'a', 'c']);
  });

  test('dragging a todo up keeps working', () async {
    seedTodos(['a', 'b', 'c']);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const AddUpdateFormEvent.reorderTodo(oldIndex: 2, newIndex: 0));
    await Future<void>.delayed(Duration.zero);

    expect(titles(), ['c', 'a', 'b']);
  });

  test('removing an image only drops it from the draft', () async {
    bloc.add(
      const AddUpdateFormEvent.initialize(
        imagePaths: ['note_images/one.jpg', 'note_images/two.jpg'],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    bloc.add(const AddUpdateFormEvent.removeImage('note_images/one.jpg'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.imagePaths, ['note_images/two.jpg']);
  });
}
