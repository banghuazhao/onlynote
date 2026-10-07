import 'dart:ui' show Color;

import 'package:characters/characters.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:uuid/uuid.dart';
import 'package:onlynote/services/note_tags.dart';
import 'package:onlynote/services/note_links.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:onlynote/services/note_document.dart';

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
    List<String> tags = const [],
    List<String> linkedNoteIds = const [],
    List<NoteTextStyleRange> textStyles = const [],
    List<NoteImageLayout> imageLayouts = const [],
    this.cardStyle = const NoteCardStyle(),
    required this.createdAt,
  })  : items = List.unmodifiable(items),
        imagePaths = List.unmodifiable(imagePaths),
        voiceMemos = List.unmodifiable(voiceMemos),
        tags = normalizeNoteTags(tags),
        linkedNoteIds = normalizeLinkedNoteIds(linkedNoteIds),
        textStyles = normalizeNoteTextStyles(textStyles, body),
        imageLayouts =
            normalizeNoteImageLayouts(imageLayouts, imagePaths, body);

  final String id;
  final String name;
  final String title;
  final String body;
  final List<String> items;
  final int? color;
  final List<String> imagePaths;
  final List<VoiceMemo> voiceMemos;
  final DateTime createdAt;
  final List<String> tags;
  final List<String> linkedNoteIds;
  final List<NoteTextStyleRange> textStyles;
  final List<NoteImageLayout> imageLayouts;
  final NoteCardStyle cardStyle;

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
        cardStyle: note.cardStyle,
        imagePaths: imageCopies,
        voiceMemos: voiceCopies,
        tags: note.tags,
        linkedNoteIds: note.linkedNoteIds,
        textStyles: note.textStyles,
        imageLayouts: _remapImages(note.imageLayouts, note.imagePaths,
            imageCopies, note.description ?? ''),
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
      cardStyle: cardStyle,
      imagePaths: imageCopies,
      voiceMemos: voiceCopies,
      tags: tags,
      linkedNoteIds: linkedNoteIds,
      textStyles: textStyles,
      imageLayouts: _remapImages(imageLayouts, imagePaths, imageCopies, body),
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
    List<String>? tags,
    List<String>? linkedNoteIds,
    List<NoteTextStyleRange>? textStyles,
    List<NoteImageLayout>? imageLayouts,
    NoteCardStyle? cardStyle,
  }) =>
      CustomNoteTemplate(
        id: id ?? this.id,
        name: name == null ? this.name : validatedTemplateName(name),
        title: title,
        body: body,
        items: items,
        color: color,
        cardStyle: cardStyle ?? this.cardStyle,
        imagePaths: imagePaths ?? this.imagePaths,
        voiceMemos: voiceMemos ?? this.voiceMemos,
        tags: tags ?? this.tags,
        linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
        textStyles: textStyles ?? this.textStyles,
        imageLayouts: imageLayouts ??
            (imagePaths == null
                ? this.imageLayouts
                : _remapImages(
                    this.imageLayouts, this.imagePaths, imagePaths, body)),
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
        'tags': tags,
        'linkedNoteIds': linkedNoteIds,
        'textStyles': [for (final style in textStyles) style.toMap()],
        'imageLayouts': [for (final layout in imageLayouts) layout.toMap()],
        if (!cardStyle.isDefault) 'cardStyle': cardStyle.toMap(),
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

    List<String> metadataList(String key) {
      if (!json.containsKey(key)) return const [];
      return list(key);
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
    final body = text('body');
    final rawStyles = json['textStyles'] ?? const [];
    if (rawStyles is! List || rawStyles.length > 10000) {
      throw const FormatException('Invalid template formatting');
    }
    final textStyles = <NoteTextStyleRange>[];
    for (final raw in rawStyles) {
      final style = NoteTextStyleRange.tryFromMap(raw);
      if (style == null) {
        throw const FormatException('Invalid template formatting');
      }
      textStyles.add(style);
    }
    if (!areValidNoteTextStyles(textStyles, body)) {
      throw const FormatException('Invalid template formatting');
    }
    final imagePaths = list('imagePaths');
    final rawLayouts = json['imageLayouts'] ?? const [];
    if (rawLayouts is! List || rawLayouts.length > 10000) {
      throw const FormatException('Invalid template image layout');
    }
    final imageLayouts = <NoteImageLayout>[];
    for (final raw in rawLayouts) {
      final layout = NoteImageLayout.tryFromMap(raw);
      if (layout == null) {
        throw const FormatException('Invalid template image layout');
      }
      imageLayouts.add(layout);
    }
    if (!areValidNoteImageLayouts(imageLayouts, imagePaths, body)) {
      throw const FormatException('Invalid template image layout');
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
      body: body,
      textStyles: textStyles,
      imageLayouts: imageLayouts,
      cardStyle: NoteCardStyle.fromMap(json['cardStyle']),
      items: list('items'),
      color: color as int?,
      imagePaths: imagePaths,
      voiceMemos: memos,
      tags: metadataList('tags'),
      linkedNoteIds: metadataList('linkedNoteIds'),
      createdAt: createdAt,
    );
  }
}

List<NoteImageLayout> _remapImages(Iterable<NoteImageLayout> layouts,
    List<String> oldPaths, List<String> newPaths, String body) {
  if (oldPaths.length != newPaths.length) {
    throw const FormatException('Image copies do not match template photos');
  }
  final paths = {
    for (var index = 0; index < oldPaths.length; index++)
      oldPaths[index]: newPaths[index],
  };
  return [
    for (final layout in normalizeNoteImageLayouts(layouts, oldPaths, body))
      layout.copyWith(path: paths[layout.path]!),
  ];
}

String validatedTemplateName(String name) {
  final value = name.trim();
  if (value.isEmpty || value.characters.length > maxTemplateNameLength) {
    throw const FormatException('Invalid template name');
  }
  return value;
}
