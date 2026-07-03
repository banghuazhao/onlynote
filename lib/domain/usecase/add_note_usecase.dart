import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/extension/string.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:uuid/uuid.dart';

final S _i10n = locator<S>();

@injectable
class AddNoteUsecase {
  AddNoteUsecase(this._repository);
  final NoteRepository _repository;
  final _uuid = const Uuid();

  Future<Either<NoteError, Unit>> call(Note note) async {
    try {
      final todo = List<Todo>.from(note.todo)
        ..removeWhere((todo) => todo.title.isEmptyString);
      final noteDto = NoteDto.fromNote(note.copyWith(todo: todo));

      if (!noteDto.validNote) {
        return left(
          NoteError(message: _i10n.Failed_to_add_note_Title_should_not_empty),
        );
      }

      await _repository.addUpdateNote(noteDto.copyWith(id: _uuid.v4()));
      return right(unit);
    } catch (_) {
      return left(NoteError(message: _i10n.Failed_to_add_note_please_try_again));
    }
  }
}
