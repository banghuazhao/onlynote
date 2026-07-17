import 'dart:ui' show Color;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/extension/string.dart';
import 'package:onlynote/domain/model/note.dart';

part 'note_dto.g.dart';

@HiveType(typeId: 0)
class TodoDto {
  TodoDto({
    this.id,
    this.title,
    this.completed,
  });

  factory TodoDto.fromDomain(Todo todo) {
    return TodoDto(
      completed: todo.completed,
      id: todo.id,
      title: todo.title.clipToMaxLength(todoMaxCharCount),
    );
  }

  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String? title;
  @HiveField(2)
  final bool? completed;

  Todo toDomain() {
    return Todo(
      id: id,
      title: title,
      completed: completed ?? false,
    );
  }
}

@HiveType(typeId: 1)
class NoteDto implements Comparable {
  NoteDto({
    this.id,
    this.title,
    this.description,
    this.colorValue,
    this.dateTime,
    this.todoList = const [],
    this.imagePaths = const [],
    this.sortOrder,
    this.isPinned = false,
    this.deletedAt,
    this.folderId,
  });

  factory NoteDto.fromNote(Note note) {
    return NoteDto(
      id: note.id,
      title: note.title.clipToMaxLength(maxTitleCharCount),
      description: note.description,
      dateTime: note.dateTime?.toIso8601String(),
      colorValue: note.color?.toARGB32(),
      todoList: note.todo.map((todo) => TodoDto.fromDomain(todo)).toList(),
      imagePaths: note.imagePaths,
      sortOrder: note.sortOrder,
      isPinned: note.isPinned,
      deletedAt: note.deletedAt?.toIso8601String(),
      folderId: note.folderId,
    );
  }

  Note toDomain() {
    return Note(
      id: id,
      title: title,
      description: description,
      dateTime: dateTime != null ? DateTime.tryParse(dateTime!) : null,
      color: colorValue != null ? Color(colorValue!) : null,
      todo: todoList?.map((todo) => todo.toDomain()).toList() ?? [],
      imagePaths: imagePaths ?? [],
      sortOrder: sortOrder,
      isPinned: isPinned ?? false,
      deletedAt: deletedAt != null ? DateTime.tryParse(deletedAt!) : null,
      folderId: folderId,
    );
  }

  // Title is optional — a note only needs *some* content to be worth saving.
  bool get validNote =>
      (title?.isNotEmpty ?? false) ||
      (description?.isNotEmpty ?? false) ||
      (todoList?.isNotEmpty ?? false) ||
      (imagePaths?.isNotEmpty ?? false);

  bool get isDeleted => deletedAt != null && deletedAt!.isNotEmpty;

  NoteDto copyWith({
    String? id,
    String? title,
    String? description,
    int? colorValue,
    String? dateTime,
    List<TodoDto>? todoList,
    List<String>? imagePaths,
    int? sortOrder,
    bool? isPinned,
    String? deletedAt,
    String? folderId,
    bool clearDeletedAt = false,
    bool clearFolderId = false,
  }) {
    return NoteDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      dateTime: dateTime ?? this.dateTime,
      todoList: todoList ?? this.todoList,
      imagePaths: imagePaths ?? this.imagePaths,
      sortOrder: sortOrder ?? this.sortOrder,
      isPinned: isPinned ?? this.isPinned,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
    );
  }

  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String? title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final int? colorValue;
  @HiveField(4)
  final String? dateTime;
  @HiveField(5)
  final List<TodoDto>? todoList;
  @HiveField(6)
  final List<String>? imagePaths;
  @HiveField(7)
  final int? sortOrder;
  @HiveField(8)
  final bool? isPinned;
  @HiveField(9)
  final String? deletedAt;
  @HiveField(10)
  final String? folderId;

  @override
  int compareTo(other) {
    final NoteDto otherNote = other as NoteDto;

    // Pinned notes float to the top (among non-trashed notes).
    final pinned = isPinned ?? false;
    final otherPinned = otherNote.isPinned ?? false;
    if (pinned != otherPinned) {
      return pinned ? -1 : 1;
    }

    // Notes with an explicit sortOrder (user-dragged, or newly created) sort
    // by that; older notes created before this field existed fall back to
    // date-based ordering.
    if (sortOrder != null && otherNote.sortOrder != null) {
      return sortOrder!.compareTo(otherNote.sortOrder!);
    }
    try {
      final isAfter = DateTime.parse(otherNote.dateTime!).isAfter(
        DateTime.parse(dateTime!),
      );
      return isAfter ? 1 : -1;
    } catch (_) {
      return 1;
    }
  }
}
