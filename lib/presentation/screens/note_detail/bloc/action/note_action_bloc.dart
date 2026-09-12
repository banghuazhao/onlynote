import 'package:flutter/material.dart';
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
      if (_deleting) return;
      _deleting = true;
      final failureOrSuccess = await _usecase(event.noteId);
      _deleting = false;

      failureOrSuccess.fold(
        (failure) {
          emit(NoteActionState.deleteFailure(message: failure.message));
          getIt<AppRouter>()
              .context
              .showToast('${failure.message}', isError: true);
        },
        (success) {
          emit(const NoteActionState.deleteSuccess());
          final router = getIt<AppRouter>();
          router.popUntilRoot();
          showTransientSnackBar(
              router.context,
              SnackBar(
                content: Text(_i10n.Notes_Moved_To_Trash),
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                    label: _i10n.Undo,
                    onPressed: () async {
                      final restored =
                          await getIt<RestoreNotesUsecase>()([event.noteId]);
                      restored.fold(
                          (error) => router.context
                              .showToast('${error.message}', isError: true),
                          (remindersRestored) {
                        if (!remindersRestored) {
                          router.context
                              .showToast(_i10n.Restore_Reminder_Warning);
                        }
                      });
                    }),
              ));
        },
      );
    });
  }

  bool _deleting = false;
  final DeleteNoteUsecase _usecase;
}
