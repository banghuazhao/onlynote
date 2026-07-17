import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class TogglePinUsecase {
  const TogglePinUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, Unit>> call(String id) async {
    try {
      final note = await _repository.getNote(id);
      await _repository.addUpdateNote(
        note.copyWith(isPinned: !(note.isPinned ?? false)),
      );
      return right(unit);
    } catch (_) {
      return left(
        NoteError(message: _i10n.Failed_to_Update_note_please_try_again),
      );
    }
  }
}
