import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/common/exception.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/model/folder.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';

final S _i10n = locator<S>();

class NotesBundle {
  const NotesBundle({
    required this.activeNotes,
    required this.trashedNotes,
    required this.folders,
  });

  final List<Note> activeNotes;
  final List<Note> trashedNotes;
  final List<Folder> folders;
}

@injectable
class ShowAllNotesUsecase {
  const ShowAllNotesUsecase(this._noteRepository, this._folderRepository);
  final NoteRepository _noteRepository;
  final FolderRepository _folderRepository;

  Future<Either<NoteError, NotesBundle>> call() async {
    try {
      final notesDto = _noteRepository.getAllNotes()..sort();
      final foldersDto = _folderRepository.getAllFolders()..sort();

      final active = <Note>[];
      final trashed = <Note>[];
      for (final dto in notesDto) {
        final note = dto.toDomain();
        if (note.isDeleted) {
          trashed.add(note);
        } else {
          active.add(note);
        }
      }

      // Within active notes, pinned already sorted via NoteDto.compareTo.
      // Trash: most recently deleted first.
      trashed.sort((a, b) {
        final aDeleted = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDeleted = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDeleted.compareTo(aDeleted);
      });

      return right(
        NotesBundle(
          activeNotes: active,
          trashedNotes: trashed,
          folders: foldersDto.map((f) => f.toDomain()).toList(),
        ),
      );
    } catch (e) {
      if (e is NoRecordsException) {
        return right(
          const NotesBundle(
            activeNotes: [],
            trashedNotes: [],
            folders: [],
          ),
        );
      }
      return left(
        NoteError(message: _i10n.Failed_to_load_notes_please_try_again),
      );
    }
  }
}
