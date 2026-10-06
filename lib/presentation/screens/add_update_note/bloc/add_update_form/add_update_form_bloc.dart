import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/common/extension/string.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/services/note_document.dart';
import 'package:onlynote/presentation/screens/add_update_note/bloc/add_update_bloc.dart'
    show AddUpdateBloc, AddUpdateEvent;

part 'add_update_form_bloc.freezed.dart';
part 'add_update_form_event.dart';
part 'add_update_form_state.dart';

@injectable
class AddUpdateFormBloc extends Bloc<AddUpdateFormEvent, AddUpdateFormState> {
  AddUpdateFormBloc(AddUpdateBloc bloc)
      : this.withState(bloc, AddUpdateFormState());

  AddUpdateFormBloc.withState(
      this._addUpdateBloc, AddUpdateFormState initialState)
      : super(initialState) {
    //* initialize form with initial data
    on<_Initialize>((event, emit) {
      emit(
        AddUpdateFormState(
          title: event.title,
          description: event.description,
          textStyles: event.textStyles ?? [],
          selectedColor: event.color,
          todos: event.todos ?? [],
          imagePaths: event.imagePaths ?? [],
          imageLayouts: event.imageLayouts ?? [],
          voiceMemos: event.voiceMemos ?? [],
          tags: event.tags ?? [],
          linkedNoteIds: event.linkedNoteIds ?? [],
          dailyNoteDateKey: event.dailyNoteDateKey,
        ),
      );
    });

    //* Update field with current data
    on<AddUpdateFormEvent>((event, emit) {
      if (event is _TitleChanged) {
        emit(state.copyWith(title: event.value));
      }

      if (event is _BodyChanged) {
        emit(state.copyWith(
            description: event.text,
            textStyles: event.styles,
            imageLayouts: event.layouts));
      }
      if (event is _ImageLayoutsChanged) {
        emit(state.copyWith(imageLayouts: event.value));
      }
      if (event is _DescriptionChanged) {
        emit(state.copyWith(description: event.value));
      }

      if (event is _ColorChanged) {
        emit(state.copyWith(selectedColor: event.value));
      }
      if (event is _TagsChanged) {
        emit(state.copyWith(tags: event.value));
      }
      if (event is _LinksChanged) {
        emit(state.copyWith(linkedNoteIds: event.value));
      }
      if (event is _VoiceMemosChanged) {
        emit(state.copyWith(voiceMemos: event.value));
      }
    });

    //* add or update note to local database.
    on<_AddOrUpdateNote>((event, emit) {
      if (event.id == null) {
        final note = Note(
          color: state.selectedColor,
          title: state.title,
          description: state.description,
          textStyles: state.textStyles,
          dateTime: DateTime.now(),
          todo: state.todos,
          imagePaths: state.imagePaths,
          imageLayouts: state.imageLayouts,
          voiceMemos: state.voiceMemos,
          tags: state.tags,
          linkedNoteIds: state.linkedNoteIds,
          dailyNoteDateKey: state.dailyNoteDateKey,
          isArchived: event.isArchived,
          folderId: event.folderId,
          isPinned: event.isPinned,
          sortOrder: event.sortOrder,
        );
        _addUpdateBloc.add(AddUpdateEvent.addNote(note));
      } else {
        final note = Note(
          id: event.id,
          color: state.selectedColor,
          title: state.title,
          description: state.description,
          textStyles: state.textStyles,
          dateTime: DateTime.now(),
          todo: state.todos,
          imagePaths: state.imagePaths,
          imageLayouts: state.imageLayouts,
          voiceMemos: state.voiceMemos,
          tags: state.tags,
          linkedNoteIds: state.linkedNoteIds,
          dailyNoteDateKey: state.dailyNoteDateKey,
          isArchived: event.isArchived,
          folderId: event.folderId,
          isPinned: event.isPinned,
          sortOrder: event.sortOrder,
          deletedAt: event.deletedAt,
        );
        _addUpdateBloc.add(AddUpdateEvent.updateNote(note, event.id!));
      }
    });

    //* TODO's events
    //* add empty todo
    on<_AddEmptyTodo>((event, emit) {
      final todos = List<Todo>.from(state.todos);
      final afterIndex = todos.indexWhere((todo) => todo.id == event.afterId);
      todos.insert(
          afterIndex < 0 ? todos.length : afterIndex + 1, Todo.empty());

      emit(state.copyWith(todos: todos));
    });

    //* Delete todo item
    on<_DeleteTodo>((event, emit) {
      final todos = List<Todo>.from(state.todos);
      todos.removeWhere((todo) => todo.id == event.id);

      emit(state.copyWith(todos: todos));
    });

    //* Update todo item
    on<_TodoValueChanged>((event, emit) {
      final todos = List<Todo>.from(state.todos);

      final updatedTodoList = todos.map((todo) {
        if (todo.id == event.id) {
          return todo.copyWith(
            title: event.value,
          );
        }
        return todo;
      }).toList();

      emit(state.copyWith(todos: updatedTodoList));
    });

    on<_ToggleTodoCheckbox>((event, emit) {
      // Preserve the user's order while they type or drag items in the editor.
      emit(state.copyWith(todos: [
        for (final todo in state.todos)
          if (todo.id == event.id)
            todo.copyWith(completed: !todo.completed)
          else
            todo,
      ]));
    });

    // Native widget commands carry an explicit state so crash recovery cannot
    // toggle the same item twice. Merge only the matching row into the draft.
    on<_SetTodoCompleted>((event, emit) {
      emit(state.copyWith(todos: [
        for (final todo in state.todos)
          if (todo.id == event.id)
            todo.copyWith(completed: event.completed)
          else
            todo,
      ]));
    });

    on<_ReplaceTodoLines>((event, emit) {
      final index = state.todos.indexWhere((todo) => todo.id == event.id);
      if (index < 0 || event.lines.isEmpty) return;
      final todos = List<Todo>.from(state.todos);
      todos[index] = todos[index].copyWith(title: event.lines.first);
      todos.insertAll(index + 1, [
        for (final line in event.lines.skip(1))
          Todo.empty().copyWith(title: line),
      ]);
      emit(state.copyWith(todos: todos));
    });

    //* Reorder todo item
    on<_ReorderTodo>((event, emit) {
      final todos = List<Todo>.from(state.todos);
      // ReorderableListView.onReorderItem already accounts for the item being
      // removed from oldIndex, so newIndex needs no further adjustment.
      final todo = todos.removeAt(event.oldIndex);
      todos.insert(event.newIndex, todo);

      emit(state.copyWith(todos: todos));
    });

    //* Images
    on<_AddImage>((event, emit) {
      final imagePaths = List<String>.from(state.imagePaths)..add(event.path);
      emit(state.copyWith(
          imagePaths: imagePaths,
          imageLayouts: normalizeNoteImageLayouts([
            ...state.imageLayouts,
            NoteImageLayout(
                path: event.path,
                textOffset:
                    event.textOffset ?? (state.description ?? '').length)
          ], imagePaths, state.description ?? '')));
    });

    //* Only drops the path from the draft. The file itself is deleted when
    //* the note is saved (see UpdateNoteUsecase) — deleting it here would
    //* break the saved note if the user backs out without saving.
    on<_RemoveImage>((event, emit) {
      final imagePaths = List<String>.from(state.imagePaths)
        ..remove(event.path);
      emit(state.copyWith(
          imagePaths: imagePaths,
          imageLayouts: normalizeNoteImageLayouts(
              state.imageLayouts, imagePaths, state.description ?? '')));
    });

    on<_ReplaceImage>((event, emit) {
      if (!state.imagePaths.contains(event.oldPath)) return;
      final paths = [
        for (final path in state.imagePaths)
          path == event.oldPath ? event.newPath : path,
      ];
      final layouts = [
        for (final layout in state.imageLayouts)
          layout.path == event.oldPath
              ? layout.copyWith(
                  path: event.newPath, aspectRatio: event.aspectRatio)
              : layout,
      ];
      emit(state.copyWith(
        imagePaths: paths,
        imageLayouts:
            normalizeNoteImageLayouts(layouts, paths, state.description ?? ''),
      ));
    });
  }

  final AddUpdateBloc _addUpdateBloc;
}
