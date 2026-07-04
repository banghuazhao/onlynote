import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/toast.dart';

part 'home_bloc.freezed.dart';
part 'home_event.dart';
part 'home_state.dart';

final S _i10n = locator<S>();

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// Get all notes
  HomeBloc(this._usecase, this._addNoteUsecase, this._reorderNotesUsecase)
      : super(const HomeState.initial()) {
    on<_GetAllNotes>(
      (event, emit) async {
        emit(const HomeState.loading());

        final failureOrSuccess = await _usecase();

        failureOrSuccess.fold((error) {
          emit(HomeState.error(error.message));
        }, (notes) {
          emit(HomeState.loaded(notes));
        });
      },
    );

    on<_DuplicateNote>((event, emit) async {
      // AddNoteUsecase always assigns a fresh id, so the original note's id is discarded.
      final duplicated = event.note.copyWith(
        title: '${event.note.title ?? ''} ${_i10n.Copy_Suffix}',
        dateTime: DateTime.now(),
        todo: event.note.todo.map((todo) => todo.copyWith()).toList(),
      );

      final failureOrSuccess = await _addNoteUsecase(duplicated);

      failureOrSuccess.fold(
        (error) => getIt<AppRouter>().context.showToast('${error.message}', isError: true),
        (_) => getIt<AppRouter>().context.showToast(_i10n.Note_Duplicated_Successfully),
      );
    });

    on<_ReorderNotes>((event, emit) async {
      // Optimistic update — Hive's box listener will re-fetch and confirm
      // this same order once the write below completes.
      emit(HomeState.loaded(event.notes));

      final failureOrSuccess = await _reorderNotesUsecase(event.notes);

      failureOrSuccess.fold(
        (error) => getIt<AppRouter>().context.showToast('${error.message}', isError: true),
        (_) => null,
      );
    });
  }

  final ShowAllNotesUsecase _usecase;
  final AddNoteUsecase _addNoteUsecase;
  final ReorderNotesUsecase _reorderNotesUsecase;
}
