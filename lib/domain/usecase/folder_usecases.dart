import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/Tools/locator.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/domain/model/error.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:uuid/uuid.dart';

final S _i10n = locator<S>();

@injectable
class CreateFolderUsecase {
  CreateFolderUsecase(this._folderRepository);
  final FolderRepository _folderRepository;
  final _uuid = const Uuid();

  Future<Either<NoteError, String>> call(String name) async {
    try {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        return left(NoteError(message: _i10n.Folder_Name_Required));
      }
      final id = _uuid.v4();
      await _folderRepository.addUpdateFolder(
        FolderDto(
          id: id,
          name: trimmed,
          sortOrder: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return right(id);
    } catch (_) {
      return left(NoteError(message: _i10n.Failed_to_save_folder));
    }
  }
}

@injectable
class RenameFolderUsecase {
  const RenameFolderUsecase(this._folderRepository);
  final FolderRepository _folderRepository;

  Future<Either<NoteError, Unit>> call({
    required String id,
    required String name,
  }) async {
    try {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        return left(NoteError(message: _i10n.Folder_Name_Required));
      }
      final folders = _folderRepository.getAllFolders();
      final folder = folders.firstWhere((f) => f.id == id);
      await _folderRepository.addUpdateFolder(folder.copyWith(name: trimmed));
      return right(unit);
    } catch (_) {
      return left(NoteError(message: _i10n.Failed_to_save_folder));
    }
  }
}

@injectable
class DeleteFolderUsecase {
  const DeleteFolderUsecase(this._folderRepository, this._noteRepository);
  final FolderRepository _folderRepository;
  final NoteRepository _noteRepository;

  Future<Either<NoteError, Unit>> call(String id) async {
    try {
      final notes = _noteRepository.getAllNotes();
      for (final note in notes) {
        if (note.folderId == id) {
          await _noteRepository.addUpdateNote(note.copyWith(clearFolderId: true));
        }
      }
      await _folderRepository.deleteFolder(id);
      return right(unit);
    } catch (_) {
      return left(NoteError(message: _i10n.Failed_to_delete_folder));
    }
  }
}
