import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/extension/string.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/services/note_creation_limit.dart';
import 'package:onlynote/services/premium_access.dart';
import 'package:uuid/uuid.dart';

final S _i10n = locator<S>();

@injectable
class AddNoteUsecase {
  AddNoteUsecase(this._repository, {@ignoreParam this.premiumAccess});
  final NoteRepository _repository;
  final PremiumAccess? premiumAccess;
  final _uuid = const Uuid();

  Future<Either<NoteError, Unit>> call(Note note) async {
    try {
      final todo = List<Todo>.from(note.todo)
        ..removeWhere((todo) => todo.title.isEmptyString);
      // New notes sort to the top: more negative than any existing sortOrder
      // and than any note added later (since -now() keeps decreasing).
      final newId = _uuid.v4();
      final noteDto = NoteDto.fromNote(
        note.copyWith(
          id: newId,
          todo: todo,
          sortOrder: -DateTime.now().millisecondsSinceEpoch,
          sectionLinks: [
            for (final link in note.sectionLinks)
              link.noteId == note.id ? link.copyWith(noteId: newId) : link,
          ],
        ),
      );

      if (!noteDto.validNote) {
        return left(
          NoteError(message: _i10n.Failed_to_add_note_Title_should_not_empty),
        );
      }

      await NoteCreationLimit.save(_repository, noteDto, access: premiumAccess);
      return right(unit);
    } on PremiumRequired {
      return left(NoteError(
          message: _i10n.Premium_Note_Limit(PremiumAccess.freeNoteLimit)));
    } catch (_) {
      return left(
          NoteError(message: _i10n.Failed_to_add_note_please_try_again));
    }
  }
}
