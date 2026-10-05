import 'dart:ui' show Color;

import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:uuid/uuid.dart';

const maxTemplateNameLength = 80;

/// Reusable content owns separate photo files and never stores task identities.
class CustomNoteTemplate {
  CustomNoteTemplate({
    required this.id,
    required this.name,
    this.title = '',
    this.body = '',
    List<String> items = const [],
    this.color,
    List<String> imagePaths = const [],
    required this.createdAt,
  })  : items = List.unmodifiable(items),
        imagePaths = List.unmodifiable(imagePaths);

  final String id;
  final String name;
  final String title;
  final String body;
  final List<String> items;
  final int? color;
  final List<String> imagePaths;
  final DateTime createdAt;

  factory CustomNoteTemplate.fromNote(Note note,
          {required String name, required List<String> imageCopies}) =>
      CustomNoteTemplate(
        id: const Uuid().v4(),
        name: validatedTemplateName(name),
        title: note.title ?? '',
        body: note.description ?? '',
        items: note.todo.map((item) => item.title ?? '').toList(),
        color: note.color?.toARGB32(),
        imagePaths: imageCopies,
        createdAt: DateTime.now(),
      );

  Note createNote({
    required List<String> imageCopies,
    String? folderId,
    DateTime? now,
  }) {
    final created = now ?? DateTime.now();
    const uuid = Uuid();
    return Note(
      id: uuid.v4(),
      title: title,
      description: body,
      todo: [for (final item in items) Todo(id: uuid.v4(), title: item)],
      color: color == null ? null : Color(color!),
      imagePaths: imageCopies,
      folderId: folderId,
      dateTime: created,
      sortOrder: -created.millisecondsSinceEpoch,
    );
  }

  CustomNoteTemplate copyWith({
    String? id,
    String? name,
    List<String>? imagePaths,
  }) =>
      CustomNoteTemplate(
        id: id ?? this.id,
        name: name == null ? this.name : validatedTemplateName(name),
        title: title,
        body: body,
        items: items,
        color: color,
        imagePaths: imagePaths ?? this.imagePaths,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'body': body,
        'items': items,
        'color': color,
        'imagePaths': imagePaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomNoteTemplate.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String) throw FormatException('Invalid template $key');
      return value;
    }

    List<String> list(String key) {
      final value = json[key];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('Invalid template $key');
      }
      return value.cast<String>();
    }

    final id = text('id');
    final name = validatedTemplateName(text('name'));
    final createdAt = DateTime.tryParse(text('createdAt'));
    final color = json['color'];
    if (id.isEmpty ||
        createdAt == null ||
        (color != null && (color is! int || color < 0 || color > 0xffffffff))) {
      throw const FormatException('Invalid template metadata');
    }
    return CustomNoteTemplate(
      id: id,
      name: name,
      title: text('title'),
      body: text('body'),
      items: list('items'),
      color: color as int?,
      imagePaths: list('imagePaths'),
      createdAt: createdAt,
    );
  }
}

String validatedTemplateName(String name) {
  final value = name.trim();
  if (value.isEmpty || value.characters.length > maxTemplateNameLength) {
    throw const FormatException('Invalid template name');
  }
  return value;
}
