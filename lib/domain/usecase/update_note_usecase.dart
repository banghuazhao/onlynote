import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/Tools/note_cleanup.dart';
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

      // Images the user dropped from the note are only deleted once the
      // edit is committed — and only if no other note still points at them.
      final previousPaths = await _previousImagePaths(noteDto.id);
      final dropped = previousPaths
          .where((path) => !(noteDto.imagePaths ?? const []).contains(path))
          .toList();

      await _repository.addUpdateNote(noteDto);

      if (dropped.isNotEmpty) {
        await NoteCleanup.deleteUnreferencedImages(
          dropped,
          repository: _repository,
          ignoreNoteIds: {if (noteDto.id != null) noteDto.id!},
        );
      }
      return right(unit);
    } catch (e) {
      return left(
        NoteError(
          message: '${_i10n.Failed_to_Update_note_please_try_again}\nError: $e',
        ),
      );
    }
  }

  Future<List<String>> _previousImagePaths(String? id) async {
    if (id == null) return const [];
    try {
      final previous = await _repository.getNote(id);
      return previous.imagePaths ?? const [];
    } catch (_) {
      return const [];
    }
  }
}
