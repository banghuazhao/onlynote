import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/domain/repository/folder_repository.dart';
import 'package:onlynote/services/note_folder_info.dart';

class _Folders implements FolderRepository {
  final values = <FolderDto>[];
  int reads = 0;
  int writes = 0;
  bool fail = false;

  @override
  List<FolderDto> getAllFolders() {
    reads++;
    if (fail) throw StateError('Folder storage unavailable');
    return values;
  }

  @override
  Future<void> addUpdateFolder(FolderDto folder) async {
    writes++;
  }

  @override
  Future<void> deleteFolder(String id) async {
    writes++;
  }
}

void main() {
  test('resolves only the matching current name without writing metadata', () {
    final folders = _Folders()
      ..values.addAll([
        FolderDto(id: 'other', name: 'Other folder'),
        FolderDto(id: 'folder', name: '  Travel plans  '),
      ]);
    expect(noteFolderInfoName('folder', repository: folders), 'Travel plans');
    expect(folders.writes, 0);
    expect(folders.values.last.name, '  Travel plans  ');
  });

  test('unfiled notes do not read folder storage', () {
    final folders = _Folders()..fail = true;
    for (final folderId in [null, '', ' \t\n ']) {
      expect(noteFolderInfoName(folderId, repository: folders), isNull);
    }
    expect(folders.reads, 0);
    expect(folders.writes, 0);
  });

  test('missing folders and blank legacy names stay absent', () {
    final folders = _Folders()
      ..values.addAll([
        FolderDto(id: 'unnamed'),
        FolderDto(id: 'blank', name: ' \t\n '),
      ]);
    for (final folderId in ['missing', 'unnamed', 'blank']) {
      expect(noteFolderInfoName(folderId, repository: folders), isNull);
    }
    expect(folders.writes, 0);
  });

  test('renaming or deleting a folder is reflected on the next read', () {
    final folders = _Folders()
      ..values.add(FolderDto(id: 'folder', name: 'Before rename'));
    expect(noteFolderInfoName('folder', repository: folders), 'Before rename');
    folders.values[0] = FolderDto(id: 'folder', name: 'After rename');
    expect(noteFolderInfoName('folder', repository: folders), 'After rename');
    folders.values.clear();
    expect(noteFolderInfoName('folder', repository: folders), isNull);
    expect(folders.writes, 0);
  });

  test('unavailable repository or failed storage omits optional metadata', () {
    expect(noteFolderInfoName('folder'), isNull);
    final folders = _Folders()..fail = true;
    expect(noteFolderInfoName('folder', repository: folders), isNull);
    expect(folders.writes, 0);
  });
}
