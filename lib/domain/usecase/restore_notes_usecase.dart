import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class RestoreNotesUsecase {
  const RestoreNotesUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, Unit>> call(List<String> ids) async {
    try {
      for (final id in ids) {
        final note = await _repository.getNote(id);
        await _repository.addUpdateNote(note.copyWith(clearDeletedAt: true));
      }
      return right(unit);
    } catch (_) {
      return left(
        NoteError(message: _i10n.Failed_to_restore_notes),
      );
    }
  }
}
