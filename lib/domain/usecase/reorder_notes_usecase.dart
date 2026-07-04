import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class ReorderNotesUsecase {
  const ReorderNotesUsecase(this._repository);
  final NoteRepository _repository;

  /// Persists [notes] in the given order by assigning each a fresh,
  /// strictly increasing sortOrder relative to "now" so future new notes
  /// (which sort by an even more negative timestamp) still land above them.
  Future<Either<NoteError, Unit>> call(List<Note> notes) async {
    try {
      final base = -DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < notes.length; i++) {
        final note = notes[i];
        final noteDto = NoteDto.fromNote(note.copyWith(sortOrder: base + i));
        await _repository.addUpdateNote(noteDto);
      }
      return right(unit);
    } catch (_) {
      return left(NoteError(message: _i10n.Failed_to_load_notes_please_try_again));
    }
  }
}
