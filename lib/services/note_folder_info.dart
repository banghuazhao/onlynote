import 'package:onlynote/di/di.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';

/// Reads current folder metadata without changing the note or caching a name.
///
/// Older notes can refer to a removed folder, and folder storage may be
/// unavailable while the note itself remains readable. In either case, omit
/// the optional information instead of blocking the note info sheet.
String? noteFolderInfoName(String? folderId, {FolderRepository? repository}) {
  if (folderId == null || folderId.trim().isEmpty) return null;
  try {
    final folders = (repository ?? getIt<FolderRepository>()).getAllFolders();
    for (final folder in folders) {
      if (folder.id != folderId) continue;
      final name = folder.name?.trim();
      return name == null || name.isEmpty ? null : name;
    }
  } catch (_) {
    // Folder metadata is optional; storage failure must not hide note details.
  }
  return null;
}
