part of 'home_bloc.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded({
    required List<Note> notes,
    required List<Folder> folders,
    @Default('') String searchQuery,
    String? selectedFolderId,
    @Default(false) bool showTrash,
    @Default(0) int trashCount,
  }) = _Loaded;
  const factory HomeState.error(String? message) = _Error;
}
