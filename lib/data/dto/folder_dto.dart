import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/domain/model/folder.dart';

part 'folder_dto.g.dart';

@HiveType(typeId: 2)
class FolderDto implements Comparable {
  FolderDto({
    this.id,
    this.name,
    this.sortOrder,
  });

  factory FolderDto.fromDomain(Folder folder) {
    return FolderDto(
      id: folder.id,
      name: folder.name,
      sortOrder: folder.sortOrder,
    );
  }

  Folder toDomain() {
    return Folder(
      id: id!,
      name: name ?? '',
      sortOrder: sortOrder,
    );
  }

  FolderDto copyWith({
    String? id,
    String? name,
    int? sortOrder,
  }) {
    return FolderDto(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String? name;
  @HiveField(2)
  final int? sortOrder;

  @override
  int compareTo(other) {
    final FolderDto otherFolder = other as FolderDto;
    if (sortOrder != null && otherFolder.sortOrder != null) {
      return sortOrder!.compareTo(otherFolder.sortOrder!);
    }
    return (name ?? '').toLowerCase().compareTo((otherFolder.name ?? '').toLowerCase());
  }
}
