part of 'home_bloc.dart';

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.getAllNotes() = _GetAllNotes;
  const factory HomeEvent.duplicateNote(Note note) = _DuplicateNote;
  const factory HomeEvent.reorderNotes(List<Note> notes) = _ReorderNotes;
}
