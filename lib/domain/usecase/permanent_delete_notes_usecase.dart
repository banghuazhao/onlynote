import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/Tools/note_cleanup.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

/// Permanently deletes notes and cleans up images + reminders.
@injectable
class PermanentDeleteNotesUsecase {
  const PermanentDeleteNotesUsecase(this._repository);
  final NoteRepository _repository;

  Future<Either<NoteError, Unit>> call(List<String> ids) async {
    try {
      final notes = <NoteDto>[];
      for (final id in ids) {
        notes.add(await _repository.getNote(id));
      }
      await NoteCleanup.cleanupNotes(notes);
      await _repository.deleteMultiNotes(ids);
      return right(unit);
    } catch (_) {
      return left(NoteError(message: _i10n.Failed_to_delete_notes));
    }
  }
}
