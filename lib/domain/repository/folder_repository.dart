import 'package:onlynote/data/dto/folder_dto.dart';

abstract class FolderRepository {
  List<FolderDto> getAllFolders();
  Future addUpdateFolder(FolderDto folder);
  Future deleteFolder(String id);
}
