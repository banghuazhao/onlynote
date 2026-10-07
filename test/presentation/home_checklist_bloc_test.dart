import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/screens/home/bloc/home_bloc.dart';
import 'package:onlynote/services/note_search.dart';

class _Notes implements NoteRepository {
  final notes = <String, NoteDto>{};
  Completer<void>? writeGate;
  bool failWrites = false;
  int writes = 0;
  @override
  Future<void> addUpdateNote(NoteDto note) async {
    writes++;
    await writeGate?.future;
    if (failWrites) throw StateError('disk full');
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

class _Folders implements FolderRepository {
  @override
  List<FolderDto> getAllFolders() => [];
  @override
  Future<void> addUpdateFolder(FolderDto folder) async {}
  @override
  Future<void> deleteFolder(String id) async {}
}

List<Note> _visible(HomeBloc bloc) => bloc.state.maybeMap(
    loaded: (state) => state.notes,
    orElse: () => throw StateError('not loaded'));
Future<void> _turn() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(() {
    if (!locator.isRegistered<S>()) locator.registerSingleton(S());
  });
  late _Notes repository;
  late HomeBloc bloc;

  setUp(() async {
    repository = _Notes();
    final folders = _Folders();
    repository.notes['note'] =
        NoteDto.fromNote(Note(id: 'note', title: 'Shopping', todo: [
      Todo(id: 'a', title: 'Milk'),
      Todo(id: 'b', title: 'Eggs'),
    ]));
    bloc = HomeBloc(
      ShowAllNotesUsecase(repository, folders),
      AddNoteUsecase(repository),
      ReorderNotesUsecase(repository),
      TogglePinUsecase(repository),
      RestoreNotesUsecase(repository),
      PermanentDeleteNotesUsecase(repository),
      CreateFolderUsecase(folders),
      RenameFolderUsecase(folders),
      DeleteFolderUsecase(folders, repository),
      MoveNoteToFolderUsecase(repository),
      GetNoteUsecase(repository),
      UpdateNoteUsecase(repository),
    );
    bloc.add(const HomeEvent.getAllNotes());
    await _turn();
  });
  tearDown(() => bloc.close());

  test(
      'rapid Home taps persist every item and return accurate completion milestones',
      () async {
    repository.writeGate = Completer<void>();
    final first = bloc.toggleTodo(noteId: 'note', todoId: 'a');
    final second = bloc.toggleTodo(noteId: 'note', todoId: 'b');
    await _turn();
    expect(repository.writes, 1);
    expect(_visible(bloc).single.todo.every((todo) => !todo.completed), isTrue);
    repository.writeGate!.complete();
    final firstResult = await first;
    final secondResult = await second;
    expect(firstResult.change!.newlyCompleted, isTrue);
    expect(firstResult.change!.checklistNowComplete, isFalse);
    expect(secondResult.change!.checklistNowComplete, isTrue);
    expect(
        repository.notes['note']!
            .toDomain()
            .todo
            .every((todo) => todo.completed),
        isTrue);
    expect(_visible(bloc).single.todo.map((todo) => todo.id), ['a', 'b']);
  });

  test(
      'Home checkbox writes use latest saved title, folder and other item edits',
      () async {
    repository.notes['note'] = NoteDto.fromNote(Note(
        id: 'note',
        title: 'Edited elsewhere',
        folderId: 'ideas',
        isPinned: true,
        todo: [
          Todo(id: 'a', title: 'Oat milk'),
          Todo(id: 'b', title: 'Fresh eggs', completed: true)
        ]));
    final result = await bloc.toggleTodo(noteId: 'note', todoId: 'a');
    expect(result.error, isNull);
    final saved = repository.notes['note']!.toDomain();
    expect(saved.title, 'Edited elsewhere');
    expect(saved.folderId, 'ideas');
    expect(saved.isPinned, isTrue);
    expect(saved.todo.map((todo) => todo.title), ['Oat milk', 'Fresh eggs']);
    expect(saved.todo.every((todo) => todo.completed), isTrue);
  });

  test('Undo explicitly restores its item and preserves unrelated changes',
      () async {
    final change = (await bloc.toggleTodo(noteId: 'note', todoId: 'a')).change!;
    repository.notes['note'] = NoteDto.fromNote(repository.notes['note']!
        .toDomain()
        .copyWith(title: 'New title', todo: [
      Todo(id: 'a', title: 'Milk', completed: true),
      Todo(id: 'b', title: 'Eggs', completed: true),
      Todo(id: 'c', title: 'Bread')
    ]));
    final undone = await bloc.setTodoCompleted(
        noteId: change.noteId,
        todoId: change.todoId,
        completed: change.previousCompleted);
    expect(undone.change!.newlyCompleted, isFalse);
    final saved = repository.notes['note']!.toDomain();
    expect(saved.title, 'New title');
    expect(saved.todo.map((todo) => todo.completed), [false, true, false]);
    final writes = repository.writes;
    expect(
        (await bloc.setTodoCompleted(
                noteId: 'note', todoId: 'a', completed: false))
            .change,
        isNull);
    expect(repository.writes, writes);
  });

  test(
      'a failed save returns an error without an Undo snapshot or visible success',
      () async {
    repository.failWrites = true;
    final result = await bloc.toggleTodo(noteId: 'note', todoId: 'a');
    expect(result.error, isNotNull);
    expect(result.change, isNull);
    expect(_visible(bloc).single.todo.first.completed, isFalse);
    expect(repository.notes['note']!.toDomain().todo.first.completed, isFalse);
  });

  test('deleted notes and missing items reject Home edits', () async {
    repository.notes['note'] = NoteDto.fromNote(repository.notes['note']!
        .toDomain()
        .copyWith(deletedAt: DateTime.now()));
    expect(
        (await bloc.toggleTodo(noteId: 'note', todoId: 'a')).error, isNotNull);
    repository.notes['note'] =
        NoteDto.fromNote(Note(id: 'note', title: 'No checklist'));
    expect(
        (await bloc.setTodoCompleted(
                noteId: 'note', todoId: 'a', completed: false))
            .error,
        isNotNull);
    expect(repository.writes, 0);
  });

  test(
      'Unfinished updates after completion and explicit Undo restores the filtered card',
      () async {
    repository.notes['note'] = NoteDto.fromNote(Note(
        id: 'note', title: 'One item', todo: [Todo(id: 'a', title: 'Milk')]));
    bloc.add(const HomeEvent.getAllNotes());
    bloc.add(const HomeEvent.filtersChanged({NoteSearchFilter.unfinished}));
    await _turn();
    await _turn();
    expect(_visible(bloc).length, 1);
    await bloc.toggleTodo(noteId: 'note', todoId: 'a');
    expect(_visible(bloc), isEmpty);
    await bloc.setTodoCompleted(noteId: 'note', todoId: 'a', completed: false);
    expect(_visible(bloc).single.id, 'note');
  });

  test('a queued reorder snapshot preserves the newly saved checkbox value',
      () async {
    final oldSnapshot = _visible(bloc);
    repository.writeGate = Completer<void>();
    final toggled = bloc.toggleTodo(noteId: 'note', todoId: 'a');
    bloc.add(HomeEvent.reorderNotes(oldSnapshot));
    await _turn();
    repository.writeGate!.complete();
    await toggled;
    await _turn();
    await _turn();
    expect(repository.notes['note']!.toDomain().todo.first.completed, isTrue);
  });

  test(
      'card style waits for checklist and pin writes and preserves current content',
      () async {
    repository.notes['note'] = NoteDto.fromNote(repository.notes['note']!
        .toDomain()
        .copyWith(title: 'Updated shopping', folderId: 'groceries'));
    repository.writeGate = Completer<void>();
    final checklist = bloc.toggleTodo(noteId: 'note', todoId: 'a');
    bloc.add(const HomeEvent.togglePin('note'));
    const style = NoteCardStyle(
        cardSize: NoteCardSize.large, fontSize: AppFontSize.large);
    final appearance = bloc.setCardStyle('note', style);
    await _turn();
    expect(repository.writes, 1);
    repository.writeGate!.complete();
    expect((await checklist).error, isNull);
    expect(await appearance, isNull);
    final saved = repository.notes['note']!.toDomain();
    expect(saved.cardStyle, style);
    expect(saved.todo.map((item) => item.completed), [true, false]);
    expect(saved.isPinned, isTrue);
    expect(saved.title, 'Updated shopping');
    expect(saved.folderId, 'groceries');
    expect(_visible(bloc).single.cardStyle, style);
    expect(repository.writes, 3);
  });

  test('card style rejects deleted and missing notes and reports failed saves',
      () async {
    const style = NoteCardStyle(cardSize: NoteCardSize.large);
    repository.notes['note'] = NoteDto.fromNote(repository.notes['note']!
        .toDomain()
        .copyWith(deletedAt: DateTime(2026, 10, 7)));
    expect(await bloc.setCardStyle('note', style), isNotNull);
    expect(await bloc.setCardStyle('missing', style), isNotNull);
    expect(repository.writes, 0);
    repository.notes['note'] =
        NoteDto.fromNote(Note(id: 'note', title: 'Shopping'));
    repository.failWrites = true;
    expect(await bloc.setCardStyle('note', style), isNotNull);
    expect(repository.notes['note']!.toDomain().cardStyle.isDefault, isTrue);
    expect(_visible(bloc).single.cardStyle.isDefault, isTrue);
  });
}
