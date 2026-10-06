import 'dart:ui' show Color;

import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:uuid/uuid.dart';

const maxTemplateNameLength = 80;

/// Reusable content owns separate media files and never stores task identities.
class CustomNoteTemplate {
  CustomNoteTemplate({
    required this.id,
    required this.name,
    this.title = '',
    this.body = '',
    List<String> items = const [],
    this.color,
    List<String> imagePaths = const [],
    List<VoiceMemo> voiceMemos = const [],
    required this.createdAt,
  })  : items = List.unmodifiable(items),
        imagePaths = List.unmodifiable(imagePaths),
        voiceMemos = List.unmodifiable(voiceMemos);

  final String id;
  final String name;
  final String title;
  final String body;
  final List<String> items;
  final int? color;
  final List<String> imagePaths;
  final List<VoiceMemo> voiceMemos;
  final DateTime createdAt;

  factory CustomNoteTemplate.fromNote(Note note,
          {required String name,
          required List<String> imageCopies,
          List<VoiceMemo> voiceCopies = const []}) =>
      CustomNoteTemplate(
        id: const Uuid().v4(),
        name: validatedTemplateName(name),
        title: note.title ?? '',
        body: note.description ?? '',
        items: note.todo.map((item) => item.title ?? '').toList(),
        color: note.color?.toARGB32(),
        imagePaths: imageCopies,
        voiceMemos: voiceCopies,
        createdAt: DateTime.now(),
      );

  Note createNote({
    required List<String> imageCopies,
    List<VoiceMemo> voiceCopies = const [],
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
      voiceMemos: voiceCopies,
      folderId: folderId,
      dateTime: created,
      sortOrder: -created.millisecondsSinceEpoch,
    );
  }

  CustomNoteTemplate copyWith({
    String? id,
    String? name,
    List<String>? imagePaths,
    List<VoiceMemo>? voiceMemos,
  }) =>
      CustomNoteTemplate(
        id: id ?? this.id,
        name: name == null ? this.name : validatedTemplateName(name),
        title: title,
        body: body,
        items: items,
        color: color,
        imagePaths: imagePaths ?? this.imagePaths,
        voiceMemos: voiceMemos ?? this.voiceMemos,
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
        'voiceMemos': [for (final memo in voiceMemos) memo.toMap()],
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
    final rawMemos =
        json.containsKey('voiceMemos') ? json['voiceMemos'] : const [];
    if (rawMemos is! List || rawMemos.length > 100) {
      throw const FormatException('Invalid template recordings');
    }
    final memos = <VoiceMemo>[];
    final memoIds = <String>{};
    for (final raw in rawMemos) {
      final memo = VoiceMemo.tryFromMap(raw);
      if (memo == null || memo.durationMs <= 0 || !memoIds.add(memo.id)) {
        throw const FormatException('Invalid template recording');
      }
      memos.add(memo);
    }
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
      voiceMemos: memos,
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
