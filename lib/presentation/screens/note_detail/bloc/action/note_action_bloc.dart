import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/toast.dart';

part 'note_action_bloc.freezed.dart';
part 'note_action_event.dart';
part 'note_action_state.dart';

final S _i10n = locator<S>();

@injectable
class NoteActionBloc extends Bloc<NoteActionEvent, NoteActionState> {
  NoteActionBloc(
    this._usecase,
  ) : super(const NoteActionState.initial()) {
    on<_DeleteNote>((event, emit) async {
      final failureOrSuccess = await _usecase(event.noteId);

      failureOrSuccess.fold(
        (failure) {
          emit(NoteActionState.deleteFailure(message: failure.message));
          getIt<AppRouter>()
              .context
              .showToast('${failure.message}', isError: true);
        },
        (success) {
          emit(const NoteActionState.deleteSuccess());
          getIt<AppRouter>().navigate(const HomeRoute());
          getIt<AppRouter>().context.showToast(_i10n.Notes_Moved_To_Trash);
        },
      );
    });
  }

  final DeleteNoteUsecase _usecase;
}
