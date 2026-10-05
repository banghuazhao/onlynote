import 'dart:async';
import 'package:onlynote/Tools/widget_commands.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/presentation/components/toast.dart';

part 'note_detail_bloc.freezed.dart';
part 'note_detail_event.dart';
part 'note_detail_state.dart';

@injectable
class NoteDetailBloc extends Bloc<NoteDetailEvent, NoteDetailState> {
  NoteDetailBloc(this._usecase, this._updateUsecase)
      : super(const NoteDetailState.initial()) {
    // A second tap must read the result of the first save. Serializing across
    // all detail events also prevents an old save from replacing another note.
    on<NoteDetailEvent>(_handleEvent,
        transformer: (events, mapper) => events.asyncExpand(mapper));
  }

  final GetNoteUsecase _usecase;
  final UpdateNoteUsecase _updateUsecase;
  bool _lastSaveWasTodoToggle = false;
  bool get lastSaveWasTodoToggle => _lastSaveWasTodoToggle;

  /// Returns an undo snapshot only after the reset has been persisted.
  Future<List<String>?> resetChecklist(String noteId) {
    if (isClosed) return Future.value(null);
    final completion = Completer<List<String>?>();
    add(NoteDetailEvent.resetChecklist(noteId: noteId, completion: completion));
    return completion.future;
  }

  Future<void> _handleEvent(
      NoteDetailEvent event, Emitter<NoteDetailState> emit) async {
    if (event is _ShowNote) {
      _lastSaveWasTodoToggle = false;
      final current = state;
      // Keep the note visible when returning from the editor.
      final isRefresh = current is _Loaded && current.note.id == event.noteId;
      if (!isRefresh) emit(const NoteDetailState.loading());
      final result = await _usecase(event.noteId);
      if (emit.isDone) return;
      result.fold(
        (error) => emit(NoteDetailState.error(message: error.message)),
        (note) => emit(NoteDetailState.success(note)),
      );
      return;
    }

    final current = state;
    if (current is! _Loaded || current.note.isDeleted) {
      if (event is _ResetChecklist) event.completion?.complete(null);
      return;
    }
    await WidgetCommands.initializedInstance?.importPending();
    final fetched = await _usecase(current.note.id!);
    final note = fetched.fold<Note?>((_) => null, (note) => note);
    if (note == null || note.isDeleted) {
      if (event is _ResetChecklist) event.completion?.complete(null);
      return;
    }
    if (event is _ToggleTodoCheckbox) {
      if (!note.todo.any((todo) => todo.id == event.todoId)) return;
      final todos = [
        for (final todo in note.todo)
          if (todo.id == event.todoId)
            todo.copyWith(completed: !todo.completed)
          else
            todo,
      ];
      await _persist(note.copyWith(todo: todos), emit, isTodoToggle: true);
    } else if (event is _ResetChecklist) {
      if (note.id != event.noteId) {
        event.completion?.complete(null);
        return;
      }
      final completedIds = [
        for (final todo in note.todo)
          if (todo.completed && todo.id != null) todo.id!,
      ];
      if (completedIds.isEmpty) {
        event.completion?.complete(null);
        return;
      }
      final saved = await _persist(
          note.copyWith(todo: [
            for (final todo in note.todo) todo.copyWith(completed: false),
          ]),
          emit);
      event.completion?.complete(saved ? completedIds : null);
    } else if (event is _RestoreCompletedTodos) {
      if (note.id != event.noteId) return;
      // Restore completion on the items reset, retaining additions, edits and
      // other changes the user made since the reset.
      final ids = event.todoIds.toSet();
      if (!note.todo.any((todo) => ids.contains(todo.id) && !todo.completed)) {
        return;
      }
      final todos = [
        for (final todo in note.todo)
          if (ids.contains(todo.id)) todo.copyWith(completed: true) else todo,
      ];
      await _persist(note.copyWith(todo: todos), emit);
    }
  }

  Future<bool> _persist(Note note, Emitter<NoteDetailState> emit,
      {bool isTodoToggle = false}) async {
    final result = await _updateUsecase(note);
    if (emit.isDone) return false;
    return result.fold(
      (error) {
        // A failed write keeps the previous checklist visible and unchanged.
        if (getIt.isRegistered<AppRouter>() &&
            getIt<AppRouter>().navigatorKey.currentContext != null) {
          getIt<AppRouter>()
              .context
              .showToast('${error.message}', isError: true);
        }
        return false;
      },
      (_) {
        _lastSaveWasTodoToggle = isTodoToggle;
        emit(NoteDetailState.success(note));
        return true;
      },
    );
  }
}
