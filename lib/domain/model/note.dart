import 'dart:ui' show Color;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part 'note.freezed.dart';

@freezed
class Note with _$Note {
  Note._();

  factory Note({
    String? id,
    String? title,
    String? description,
    Color? color,
    DateTime? dateTime,
    @Default([]) List<Todo> todo,
    @Default([]) List<String> imagePaths,
    int? sortOrder,
    @Default(false) bool isPinned,
    DateTime? deletedAt,
    String? folderId,
  }) = _Note;

  final DateFormat _formatter = DateFormat('MMMM dd, yyyy');
  String get date => dateTime != null ? _formatter.format(dateTime!) : '';

  final DateFormat _formatter1 = DateFormat('MMMM dd, yyyy  h:m a');
  String get dateWithTime =>
      dateTime != null ? _formatter1.format(dateTime!) : '';

  bool get hasTodo => todo.isNotEmpty;

  bool get hasImages => imagePaths.isNotEmpty;

  bool get isDeleted => deletedAt != null;
}

@freezed
class Todo with _$Todo {
  Todo._();

  factory Todo({
    @Default(false) bool completed,
    String? title,
    String? id,
  }) = _Todo;

  factory Todo.empty() {
    const uuid = Uuid();

    return Todo(
      id: uuid.v4(),
      title: '',
      completed: false,
    );
  }
}
