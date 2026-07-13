import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/toast.dart';

part 'add_update_bloc.freezed.dart';
part 'add_update_event.dart';
part 'add_update_state.dart';

final S _i10n = locator<S>();

@injectable
class AddUpdateBloc extends Bloc<AddUpdateEvent, AddUpdateState> {
  AddUpdateBloc(
    this._addUsecase,
    this._updateUsecase,
  ) : super(const AddUpdateState.initial()) {
    on<_AddNote>((event, emit) async {
      emit(const AddUpdateState.saving());

      final failureOrSuccess = await _addUsecase(event.note);

      await Future.delayed(animationDuration);

      failureOrSuccess.fold((failure) {
        emit(AddUpdateState.failed(message: failure.message));
        getIt<AppRouter>()
            .context
            .showToast('${failure.message}', isError: true);
      }, (_) {
        emit(const AddUpdateState.saved());
        getIt<AppRouter>().navigate(const HomeRoute());
        getIt<AppRouter>().context.showToast(_i10n.Note_Added_Successfully);
      });
    });

    on<_UpdateNote>((event, emit) async {
      emit(const AddUpdateState.saving());

      final failureOrSuccess = await _updateUsecase(event.note);

      await Future.delayed(animationDuration);

      failureOrSuccess.fold((failure) {
        emit(AddUpdateState.failed(message: failure.message));
        getIt<AppRouter>()
            .context
            .showToast('${failure.message}', isError: true);
      }, (_) {
        emit(const AddUpdateState.saved());
        getIt<AppRouter>().maybePop();
        getIt<AppRouter>().context.showToast(_i10n.Note_Updated_Successfully);
      });
    });
  }

  final AddNoteUsecase _addUsecase;
  final UpdateNoteUsecase _updateUsecase;
}
