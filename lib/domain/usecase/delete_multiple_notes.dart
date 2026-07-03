import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class DeleteMultipleNotesUsecase {
  DeleteMultipleNotesUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, Unit>> call(List<String> selectedIds) async {
    try {
      await _repository.deleteMultiNotes(selectedIds);
      return right(unit);
    } catch (_) {
      return left(NoteError(message: _i10n.Failed_to_delete_notes));
    }
  }
}
