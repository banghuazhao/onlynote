import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/domain/usecase/usecase.dart';
import 'package:onlynote/presentation/components/toast.dart';

part 'multiple_delete_bloc.freezed.dart';
part 'multiple_delete_event.dart';
part 'multiple_delete_state.dart';

@injectable
class MultipleDeleteBloc
    extends Bloc<MultipleDeleteEvent, MultipleDeleteState> {
  MultipleDeleteBloc(this._usecase)
      : super(const MultipleDeleteState.initial()) {
    on<_ToggleSelect>((event, emit) {
      if (state is _Selected) {
        final state = this.state as _Selected;
        final selectedIds = List<String>.from(state.selectedIds);

        if (selectedIds.contains(event.id)) {
          selectedIds.remove(event.id);
          if (selectedIds.isEmpty) {
            add(const _ClearAll());
          }
        } else {
          selectedIds.add(event.id);
        }
        emit(state.copyWith(selectedIds: selectedIds));
      } else {
        emit(MultipleDeleteState.selected([event.id]));
      }
    });

    on<_ClearAll>((event, emit) => emit(const MultipleDeleteState.initial()));

    on<_Delete>((event, emit) async {
      if (state is _Selected) {
        final selectedIds = (state as _Selected).selectedIds;

        emit(const MultipleDeleteState.deleting());

        final failureOrSuccess = await _usecase(selectedIds);

        failureOrSuccess.fold(
          (error) {
            emit(MultipleDeleteState.selected(selectedIds));
            getIt<AppRouter>()
                .context
                .showToast('${error.message}', isError: true);
          },
          (_) {
            emit(MultipleDeleteState.success(List.unmodifiable(selectedIds)));
          },
        );
      }
    });
  }

  bool isSelected(String? id) =>
      (id != null) &&
      (state is _Selected) &&
      (state as _Selected).selectedIds.contains(id);

  final DeleteMultipleNotesUsecase _usecase;
}
