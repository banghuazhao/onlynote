import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class MoveNoteToFolderUsecase {
  const MoveNoteToFolderUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, Unit>> call({
    required String noteId,
    String? folderId,
  }) async {
    try {
      final note = await _repository.getNote(noteId);
      await _repository.addUpdateNote(
        note.copyWith(
          folderId: folderId,
          clearFolderId: folderId == null,
        ),
      );
      return right(unit);
    } catch (_) {
      return left(
        NoteError(message: _i10n.Failed_to_Update_note_please_try_again),
      );
    }
  }
}
