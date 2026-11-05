import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

@injectable
class TogglePinUsecase {
  const TogglePinUsecase(this._repository);
  final NoteRepository _repository;

  /// Flips the note's pin, or sets it to [pinned] when a caller needs a
  /// definite state — a bulk action must not flip a mixed selection apart.
  Future<Either<NoteError, Unit>> call(String id, {bool? pinned}) async {
    try {
      final note = await _repository.getNote(id);
      final current = note.isPinned ?? false;
      final next = pinned ?? !current;
      if (next == current) return right(unit);
      await _repository.addUpdateNote(note.copyWith(isPinned: next));
      return right(unit);
    } catch (_) {
      return left(
        NoteError(message: _i10n.Failed_to_Update_note_please_try_again),
      );
    }
  }
}
