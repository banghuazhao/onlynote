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
class ShowAllNotesUsecase {
  const ShowAllNotesUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, List<Note>>> call() async {
    try {
      final notesDto = _repository.getAllNotes();
      final notes = (notesDto..sort()).map((note) => note.toDomain()).toList();

      return right(notes);
    } catch (e) {
      if (e is NoRecordsException) {
        return left(
          NoteError(message: _i10n.No_notes_found),
        );
      }
      return left(
        NoteError(message: _i10n.Failed_to_load_notes_please_try_again),
      );
    }
  }
}
