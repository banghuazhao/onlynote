import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/exception.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class GetNoteUsecase {
  const GetNoteUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, Note>> call(String id) async {
    try {
      final noteDto = await _repository.getNote(id);
      final note = noteDto.toDomain();

      return right(note);
    } catch (e) {
      if (e is NoRecordsException) {
        return left(NoteError(message: 'No matched note found.'));
      }
      return left(
        NoteError(message: _i10n.Failed_to_load_note_please_try_again),
      );
    }
  }
}
