import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/exception.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';

@LazySingleton(as: FolderRepository)
class FolderRepositoryImplementation implements FolderRepository {
  Box get _box => Hive.box(folderDatabaseBox);

  @override
  List<FolderDto> getAllFolders() {
    try {
      final data = _box.toMap().values;
      if (data.isEmpty) return [];
      return data.toList().cast<FolderDto>();
    } on NoteAppException {
      return [];
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future addUpdateFolder(FolderDto folder) async {
    await _box.put(folder.id!, folder);
  }

  @override
  Future deleteFolder(String id) async {
    await _box.delete(id);
  }
}
