import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/extension/string.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class UpdateNoteUsecase {
  const UpdateNoteUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, Unit>> call(Note note) async {
    try {
      final todo = List<Todo>.from(note.todo)
        ..removeWhere((todo) => todo.title.isEmptyString);
      final noteDto = NoteDto.fromNote(note.copyWith(todo: todo));

      if (!noteDto.validNote) {
        return left(
          NoteError(
              message: _i10n.Failed_to_update_note_Title_should_not_empty),
        );
      }

      await _repository.addUpdateNote(noteDto);
      return right(unit);
    } catch (e) {
      return left(
        NoteError(
          message: '${_i10n.Failed_to_Update_note_please_try_again}\nError: $e',
        ),
      );
    }
  }
}
