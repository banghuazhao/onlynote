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
    final written = <String, ({int? before, int after})>{};
    try {
      final base = -DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < notes.length; i++) {
        final id = notes[i].id;
        if (id == null || written.containsKey(id)) continue;
        final current = await _repository.getNote(id);
        if (current.isDeleted || current.isArchived) continue;
        final noteDto =
            NoteDto.fromNote(current.toDomain().copyWith(sortOrder: base + i));
        written[id] = (before: current.sortOrder, after: base + i);
        await _repository.addUpdateNote(noteDto);
      }
      return right(unit);
    } catch (_) {
      // Roll back only ordering. A note edited while storage was failing must
      // retain its latest content, and a newer independent reorder must win.
      for (final entry in written.entries.toList().reversed) {
        try {
          final current = await _repository.getNote(entry.key);
          if (current.sortOrder != entry.value.after) continue;
          await _repository.addUpdateNote(NoteDto.fromNote(
              current.toDomain().copyWith(sortOrder: entry.value.before)));
        } catch (_) {
          // Persistent storage failure is reported to the caller below.
        }
      }
      return left(NoteError(message: _i10n.Reorder_Save_Failed));
    }
  }
}
