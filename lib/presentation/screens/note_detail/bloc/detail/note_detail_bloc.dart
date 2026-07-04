import 'package:bloc/bloc.dart';
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
  NoteDetailBloc(this._usecase, this._updateUsecase) : super(const NoteDetailState.initial()) {
    //* show note detail
    on<_ShowNote>((event, emit) async {
      emit(const NoteDetailState.loading());

      final failureOrSuccess = await _usecase(event.noteId);

      failureOrSuccess.fold(
        (error) => emit(NoteDetailState.error(message: error.message)),
        (note) => emit(NoteDetailState.success(note)),
      );
    });

    //* toggle Todo Checkbox
    on<_ToggleTodoCheckbox>((event, emit) async {
      if (state is _Loaded) {
        final state = this.state as _Loaded;

        final toggledTodo = state.note.todo.map((todo) {
          if (todo.id == event.todoId) {
            return todo.copyWith(completed: !todo.completed);
          }
          return todo;
        }).toList();

        // Move checked items to the bottom, keeping the relative order
        // within the unchecked and checked groups.
        final sortedTodo = [
          ...toggledTodo.where((todo) => !todo.completed),
          ...toggledTodo.where((todo) => todo.completed),
        ];

        final updatedNote = state.note.copyWith(todo: sortedTodo);

        final failureOrSuccess = await _updateUsecase(updatedNote);
        failureOrSuccess.fold(
          (error) {
            getIt<AppRouter>().context.showToast('${error.message}', isError: true);
          },
          (_) => emit(state.copyWith(note: updatedNote)),
        );
      }
    });
  }

  final GetNoteUsecase _usecase;
  final UpdateNoteUsecase _updateUsecase;
}
