import 'dart:io';

import 'package:characters/characters.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:path_provider/path_provider.dart';

/// A native inbox entry owns its attachment files until [acknowledge] succeeds.
/// Both native platforms publish an entry only after every attachment is copied.
class SharedNotePayload {
  const SharedNotePayload({
    required this.id,
    this.title = '',
    this.text = '',
    this.images = const [],
  });

  final String id;
  final String title;
  final String text;
  final List<String> images;

  static final _idPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  static SharedNotePayload? parse(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    final id = value['id'];
    final title = value['title'];
    final text = value['text'];
    final images = value['images'];
    if (id is! String ||
        !_idPattern.hasMatch(id) ||
        title is! String ||
        title.length > 1000 ||
        text is! String ||
        text.length > 100000 ||
        images is! List ||
        images.length > 10 ||
        images.any((path) => path is! String || !_validSource(path)) ||
        (title.trim().isEmpty && text.trim().isEmpty && images.isEmpty)) {
      return null;
    }
    return SharedNotePayload(
      id: id.toLowerCase(),
      title: title.trim(),
      text: text.trim(),
      images: images.cast<String>(),
    );
  }

  Map<String, Object> toMap() => {
        'version': 1,
        'id': id,
        'title': title,
        'text': text,
        'images': images,
      };

  static bool _validSource(String path) =>
      path.startsWith('/') &&
      path.length <= 4096 &&
      !path.contains('\u0000') &&
      !path.split('/').contains('..');
}

/// Imports with a stable note ID and durable copy journal. Retrying after an
/// interrupted repository write or native acknowledgement cannot create a
/// second note or take ownership of another editor's active draft.
class SharedNoteImport {
  SharedNoteImport({
    required this.journal,
    required this.notes,
    Future<String> Function(File source, String id, int index)? copyImage,
    DateTime Function()? now,
  })  : _copyImage = copyImage ?? _copyManagedImage,
        _now = now ?? DateTime.now;

  static const journalPrefix = '_shared_note_import_v1.';
  final Box journal;
  final NoteRepository notes;
  final Future<String> Function(File source, String id, int index) _copyImage;
  final DateTime Function() _now;
  Future<void> _queue = Future.value();

  bool get hasPendingImports => journal.keys
      .whereType<String>()
      .any((key) => key.startsWith(journalPrefix));

  Future<Note?> import(SharedNotePayload payload,
      {required Future<void> Function(String id) acknowledge}) async {
    Note? imported;
    final operation = _queue.then((_) async {
      imported = await _import(payload, acknowledge);
    });
    _queue = operation.catchError((Object _) {});
    await operation;
    return imported;
  }

  Future<Note?> _import(SharedNotePayload payload,
      Future<void> Function(String id) acknowledge) async {
    // Validate also for callers constructing a payload directly.
    if (SharedNotePayload.parse(payload.toMap()) == null) {
      throw const FormatException('Invalid shared content');
    }
    final key = '$journalPrefix${payload.id}';
    final noteId = 'share-${payload.id}';
    final existing = notes.getAllNotes().where((note) => note.id == noteId);
    if (existing.isNotEmpty) {
      // An unacknowledged retry must preserve subsequent edits and trash state.
      await acknowledge(payload.id);
      await journal.delete(key);
      return existing.first.isDeleted ? null : existing.first.toDomain();
    }

    final previous = journal.get(key);
    final record = previous is Map ? previous : const {};
    if (record['committed'] == true) {
      // The user may have permanently removed an imported note while native
      // acknowledgement was unavailable. A retry must not resurrect it.
      await acknowledge(payload.id);
      await journal.delete(key);
      return null;
    }
    final persistedPayload = SharedNotePayload.parse(record['payload']);
    final source = persistedPayload == null
        ? payload
        : SharedNotePayload(
            id: persistedPayload.id,
            title: persistedPayload.title,
            text: persistedPayload.text,
            // App group container paths can change after an iOS restore.
            // Native delivery rebuilds paths from its current container.
            images: payload.images.length == persistedPayload.images.length
                ? payload.images
                : persistedPayload.images,
          );
    final rawSaved = record['saved'];
    final saved = rawSaved is List && rawSaved.every(_validManagedPath)
        ? rawSaved.cast<String>().toList()
        : <String>[];
    if (saved.length > source.images.length) {
      throw const FormatException('Invalid shared photo journal');
    }

    Future<void> retain({NoteDto? note, bool committed = false}) async {
      await journal.put(key, {
        'payload': source.toMap(),
        'saved': saved.toList(),
        if (note != null) 'note': note,
        if (committed) 'committed': true,
      });
      await journal.flush();
    }

    await retain();
    while (saved.length < source.images.length) {
      final index = saved.length;
      final path =
          await _copyImage(File(source.images[index]), source.id, index);
      if (!_validManagedPath(path)) {
        throw const FormatException('Invalid imported image path');
      }
      saved.add(path);
      // Keep source and destination ownership before releasing the native inbox.
      await retain();
    }

    final title = _titleWithinLimit(source.title);
    final description = title == source.title
        ? source.text
        : [source.title, if (source.text.isNotEmpty) source.text].join('\n\n');
    final note = Note(
      id: noteId,
      title: title,
      description: description,
      imagePaths: saved,
      dateTime: _now(),
      sortOrder: -_now().millisecondsSinceEpoch,
    );
    final dto = NoteDto.fromNote(note);
    await retain(note: dto);
    await notes.addUpdateNote(dto);
    await retain(note: dto, committed: true);
    await acknowledge(source.id);
    await journal.delete(key);
    return dto.toDomain();
  }

  /// Journals may outlive a native host's initial notification. Replaying them
  /// uses the same IDs and attachment copies as ordinary inbox delivery.
  Future<List<Note>> recover(
      {required Future<void> Function(String id) acknowledge,
      void Function(Object error)? onFailure}) async {
    final recovered = <Note>[];
    for (final key in journal.keys.whereType<String>().toList()) {
      if (!key.startsWith(journalPrefix)) continue;
      final record = journal.get(key);
      final payload =
          SharedNotePayload.parse(record is Map ? record['payload'] : null);
      if (payload == null) continue;
      try {
        final note = await import(payload, acknowledge: acknowledge);
        if (note != null) recovered.add(note);
      } catch (error) {
        if (onFailure == null) rethrow;
        onFailure(error);
      }
    }
    return recovered;
  }

  static bool _validManagedPath(Object? path) =>
      path is String &&
      RegExp(r'^note_images/[^/\\]+\.[a-zA-Z0-9]+$').hasMatch(path) &&
      !path.contains('..') &&
      path.length <= 512;

  static String _titleWithinLimit(String value) {
    if (value.length <= maxTitleCharCount) return value;
    final title = StringBuffer();
    var length = 0;
    for (final cluster in value.characters) {
      if (length + cluster.length > maxTitleCharCount) break;
      title.write(cluster);
      length += cluster.length;
    }
    return title.toString();
  }

  static Future<String> _copyManagedImage(
      File source, String id, int index) async {
    final length = await source.length();
    if (length <= 0 || length > 25 * 1024 * 1024) {
      throw const FormatException('Shared photo exceeds the size limit');
    }
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/note_images');
    await directory.create(recursive: true);
    final rawExtension = source.path.split('.').last.toLowerCase();
    final extension = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(rawExtension)
        ? rawExtension
        : 'jpg';
    final relative = 'note_images/share-$id-$index.$extension';
    final destination = File('${documents.path}/$relative');
    final temporary = File('${destination.path}.pending');
    await source.copy(temporary.path);
    final handle = await temporary.open(mode: FileMode.append);
    try {
      await handle.flush();
    } finally {
      await handle.close();
    }
    await temporary.rename(destination.path);
    return relative;
  }
}
