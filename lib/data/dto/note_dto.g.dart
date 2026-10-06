// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoDtoAdapter extends TypeAdapter<TodoDto> {
  @override
  final int typeId = 0;

  @override
  TodoDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoDto(
      id: fields[0] as String?,
      title: fields[1] as String?,
      completed: fields[2] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, TodoDto obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteDtoAdapter extends TypeAdapter<NoteDto> {
  @override
  final int typeId = 1;

  @override
  NoteDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteDto(
      id: fields[0] as String?,
      title: fields[1] as String?,
      description: fields[2] as String?,
      colorValue: fields[3] as int?,
      dateTime: fields[4] as String?,
      todoList: (fields[5] as List?)?.cast<TodoDto>(),
      imagePaths: (fields[6] as List?)?.cast<String>(),
      sortOrder: fields[7] as int?,
      isPinned: fields[8] as bool?,
      deletedAt: fields[9] as String?,
      folderId: fields[10] as String?,
      voiceMemos: (fields[11] as List?)
          ?.map((dynamic e) => (e as Map).cast<dynamic, dynamic>())
          ?.toList(),
      isArchived: fields[12] == null ? false : fields[12] as bool,
      tags: (fields[13] as List?)?.cast<String>(),
      linkedNoteIds: (fields[14] as List?)?.cast<String>(),
      textStyles: (fields[15] as List?)
          ?.map((dynamic e) => (e as Map).cast<dynamic, dynamic>())
          ?.toList(),
      imageLayouts: (fields[16] as List?)
          ?.map((dynamic e) => (e as Map).cast<dynamic, dynamic>())
          ?.toList(),
    );
  }

  @override
  void write(BinaryWriter writer, NoteDto obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.dateTime)
      ..writeByte(5)
      ..write(obj.todoList)
      ..writeByte(6)
      ..write(obj.imagePaths)
      ..writeByte(7)
      ..write(obj.sortOrder)
      ..writeByte(8)
      ..write(obj.isPinned)
      ..writeByte(9)
      ..write(obj.deletedAt)
      ..writeByte(10)
      ..write(obj.folderId)
      ..writeByte(11)
      ..write(obj.voiceMemos)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.linkedNoteIds)
      ..writeByte(15)
      ..write(obj.textStyles)
      ..writeByte(16)
      ..write(obj.imageLayouts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
