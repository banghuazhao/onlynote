import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/get_note_usecase.dart';
import 'package:onlynote/domain/usecase/update_note_usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/note_detail/bloc/detail/note_detail_bloc.dart';

class _Notes implements NoteRepository {
  final notes = <String, NoteDto>{};
  Completer<void>? writeGate;
  bool failWrites = false;
  int writes = 0;

  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    await writeGate?.future;
    if (failWrites) throw StateError('disk unavailable');
    notes[note.id!] = note;
  }

  @override
  Future<void> deleteNote(String id) async => notes.remove(id);
  @override
  Future<void> deleteMultiNotes(List<String> ids) async {
    for (final id in ids) {
      notes.remove(id);
    }
  }

  @override
  List<NoteDto> getAllNotes() => notes.values.toList();
  @override
  Future<NoteDto> getNote(String id) async => notes[id]!;
}

Note _loaded(NoteDetailBloc bloc) => bloc.state.maybeWhen(
    success: (note) => note, orElse: () => throw StateError('not loaded'));

Future<void> _turn() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });

  late _Notes repository;
  late NoteDetailBloc bloc;

  setUp(() async {
    repository = _Notes();
    repository.notes['note'] = NoteDto.fromNote(Note(
      id: 'note',
      title: 'Shopping',
      todo: [
        Todo(id: 'a', title: 'Milk'),
        Todo(id: 'b', title: 'Eggs', completed: true),
        Todo(id: 'c', title: 'Bread'),
      ],
    ));
    bloc = NoteDetailBloc(
        GetNoteUsecase(repository), UpdateNoteUsecase(repository));
    bloc.add(const NoteDetailEvent.showNote('note'));
    await _turn();
  });

  tearDown(() => bloc.close());

  test('rapid checklist taps persist every change without changing item order',
      () async {
    repository.writeGate = Completer<void>();
    bloc.add(const NoteDetailEvent.toggleTodoCheckbox('a'));
    bloc.add(const NoteDetailEvent.toggleTodoCheckbox('c'));
    await _turn();
    expect(repository.writes, 1);
    repository.writeGate!.complete();
    await _turn();
    await _turn();

    expect(_loaded(bloc).todo.map((todo) => todo.id), ['a', 'b', 'c']);
    expect(_loaded(bloc).todo.every((todo) => todo.completed), isTrue);
    expect(bloc.lastSaveWasTodoToggle, isTrue);
    expect(
        repository.notes['note']!
            .toDomain()
            .todo
            .every((todo) => todo.completed),
        isTrue);
  });

  test('reset and Undo preserve unrelated checklist changes', () async {
    final completedIds = await bloc.resetChecklist('note');
    expect(bloc.lastSaveWasTodoToggle, isFalse);
    expect(completedIds, ['b']);
    expect(_loaded(bloc).todo.every((todo) => !todo.completed), isTrue);
    bloc.add(const NoteDetailEvent.toggleTodoCheckbox('a'));
    bloc.add(NoteDetailEvent.restoreCompletedTodos(
        noteId: 'note', todoIds: completedIds!));
    await _turn();
    await _turn();

    expect(
        _loaded(bloc).todo.map((todo) => todo.completed), [true, true, false]);
    expect(bloc.lastSaveWasTodoToggle, isFalse);
    expect(
        repository.notes['note']!.toDomain().todo.map((todo) => todo.completed),
        [true, true, false]);
  });

  test('failed reset returns no Undo snapshot and retains saved completion',
      () async {
    repository.failWrites = true;
    expect(await bloc.resetChecklist('note'), isNull);
    expect(_loaded(bloc).todo[1].completed, isTrue);
    expect(repository.notes['note']!.toDomain().todo[1].completed, isTrue);
  });

  test('queued note switches cannot be overwritten by an old checklist save',
      () async {
    repository.notes['other'] =
        NoteDto.fromNote(Note(id: 'other', title: 'Other'));
    repository.writeGate = Completer<void>();
    bloc.add(const NoteDetailEvent.toggleTodoCheckbox('a'));
    bloc.add(const NoteDetailEvent.showNote('other'));
    await _turn();
    repository.writeGate!.complete();
    await _turn();
    await _turn();

    expect(_loaded(bloc).id, 'other');
    bloc.add(const NoteDetailEvent.restoreCompletedTodos(
        noteId: 'note', todoIds: ['a']));
    await _turn();
    expect(_loaded(bloc).id, 'other');
    expect(repository.writes, 1);
  });

  test('trashed checklists stay read-only for every mutation', () async {
    repository.notes['note'] =
        NoteDto.fromNote(_loaded(bloc).copyWith(deletedAt: DateTime.now()));
    bloc.add(const NoteDetailEvent.showNote('note'));
    await _turn();
    bloc.add(const NoteDetailEvent.toggleTodoCheckbox('a'));
    expect(await bloc.resetChecklist('note'), isNull);
    bloc.add(const NoteDetailEvent.restoreCompletedTodos(
        noteId: 'note', todoIds: ['a']));
    await _turn();
    expect(repository.writes, 0);
  });
}
