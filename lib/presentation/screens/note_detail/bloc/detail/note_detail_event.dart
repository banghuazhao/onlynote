part of 'note_detail_bloc.dart';

@freezed
class NoteDetailEvent with _$NoteDetailEvent {
  const factory NoteDetailEvent.showNote(String noteId) = _ShowNote;
  const factory NoteDetailEvent.toggleTodoCheckbox(String todoId) =
      _ToggleTodoCheckbox;
  const factory NoteDetailEvent.resetChecklist({
    required String noteId,
    Completer<List<String>?>? completion,
  }) = _ResetChecklist;
  const factory NoteDetailEvent.restoreCompletedTodos({
    required String noteId,
    required List<String> todoIds,
  }) = _RestoreCompletedTodos;
}
