import 'dart:convert';
import 'dart:typed_data';

import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';

const maxBackupBytes = 256 * 1024 * 1024;

class BackupPhoto {
  BackupPhoto(this.extension, this.bytes);
  final String extension;
  final Uint8List bytes;
}

class BackupReminder {
  BackupReminder(this.noteId, this.date, {this.repeat = ReminderRepeat.none});
  final String noteId;
  final DateTime date;
  final ReminderRepeat repeat;

  bool isSchedulable(DateTime now) =>
      repeat != ReminderRepeat.none || date.isAfter(now);
}

class BackupContents {
  BackupContents(
      {required this.createdAt,
      required this.notes,
      required this.folders,
      required this.photos,
      required this.reminders,
      this.templates = const []});
  final DateTime createdAt;
  final List<NoteDto> notes;
  final List<FolderDto> folders;
  final Map<String, BackupPhoto> photos;
  final List<BackupReminder> reminders;
  final List<CustomNoteTemplate> templates;

  Map<String, dynamic> toJson() => {
        'format': 'onlynote-backup',
        'version': 2,
        'createdAt': createdAt.toIso8601String(),
        'folders': [
          for (final folder in folders)
            {
              'id': folder.id,
              'name': folder.name,
              'sortOrder': folder.sortOrder,
            }
        ],
        'notes': [
          for (final note in notes)
            {
              'id': note.id,
              'title': note.title,
              'description': note.description,
              'color': note.colorValue,
              'dateTime': note.dateTime,
              'sortOrder': note.sortOrder,
              'isPinned': note.isPinned ?? false,
              'deletedAt': note.deletedAt,
              'folderId': note.folderId,
              'photos': note.imagePaths ?? [],
              'todos': [
                for (final todo in note.todoList ?? <TodoDto>[])
                  {
                    'id': todo.id,
                    'title': todo.title,
                    'completed': todo.completed ?? false,
                  }
              ],
            }
        ],
        'photos': {
          for (final entry in photos.entries)
            entry.key: {
              'extension': entry.value.extension,
              'data': base64Encode(entry.value.bytes),
            }
        },
        'reminders': [
          for (final reminder in reminders)
            {
              'noteId': reminder.noteId,
              'date': reminder.date.toIso8601String(),
              'repeat': reminder.repeat.name,
            }
        ],
        'templates': [for (final template in templates) template.toJson()],
      };

  factory BackupContents.fromJson(Map<String, dynamic> json) {
    if (json['format'] != 'onlynote-backup' ||
        (json['version'] != 1 && json['version'] != 2)) {
      throw const FormatException('Unsupported backup');
    }
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final folders = <FolderDto>[];
    final folderIds = <String>{};
    for (final raw in json['folders'] as List) {
      final map = raw as Map<String, dynamic>;
      final id = _id(map['id']);
      if (!folderIds.add(id)) throw const FormatException('Duplicate folder');
      final name = map['name'] as String;
      if (name.trim().isEmpty) throw const FormatException('Empty folder');
      folders.add(
          FolderDto(id: id, name: name, sortOrder: map['sortOrder'] as int?));
    }
    final photos = <String, BackupPhoto>{};
    var total = 0;
    for (final entry in (json['photos'] as Map<String, dynamic>).entries) {
      final map = entry.value as Map<String, dynamic>;
      final extension = map['extension'] as String;
      if (!RegExp(r'^[a-zA-Z0-9]{1,10}$').hasMatch(extension)) {
        throw const FormatException('Invalid photo type');
      }
      final bytes = base64Decode(map['data'] as String);
      total += bytes.length;
      if (total > maxBackupBytes || bytes.isEmpty) {
        throw const FormatException('Invalid photo size');
      }
      photos[_id(entry.key)] = BackupPhoto(extension, bytes);
    }
    final notes = <NoteDto>[];
    final noteIds = <String>{};
    for (final raw in json['notes'] as List) {
      final map = raw as Map<String, dynamic>;
      final id = _id(map['id']);
      if (!noteIds.add(id)) throw const FormatException('Duplicate note');
      final folder = map['folderId'] as String?;
      if (folder != null && !folderIds.contains(folder)) {
        throw const FormatException('Missing folder');
      }
      final paths = (map['photos'] as List).cast<String>();
      if (paths.any((p) => !photos.containsKey(p))) {
        throw const FormatException('Missing photo');
      }
      final color = map['color'] as int?;
      if (color != null && (color < 0 || color > 0xffffffff)) {
        throw const FormatException('Invalid color');
      }
      notes.add(NoteDto(
        id: id,
        title: map['title'] as String?,
        description: map['description'] as String?,
        colorValue: color,
        dateTime: _date(map['dateTime']),
        sortOrder: map['sortOrder'] as int?,
        isPinned: map['isPinned'] as bool,
        deletedAt: _date(map['deletedAt']),
        folderId: folder,
        imagePaths: paths,
        todoList: [
          for (final todo in map['todos'] as List)
            TodoDto(
              id: (todo as Map<String, dynamic>)['id'] as String?,
              title: todo['title'] as String?,
              completed: todo['completed'] as bool,
            )
        ],
      ));
    }
    final reminders = <BackupReminder>[];
    final reminderNotes = <String>{};
    for (final raw in json['reminders'] as List) {
      final map = raw as Map<String, dynamic>;
      final id = _id(map['noteId']);
      if (!noteIds.contains(id) || !reminderNotes.add(id)) {
        throw const FormatException('Invalid reminder');
      }
      final repeat = map.containsKey('repeat')
          ? ReminderRepeat.values.where((r) => r.name == map['repeat'])
          : [ReminderRepeat.none];
      if (repeat.length != 1) {
        throw const FormatException('Invalid reminder repeat');
      }
      reminders.add(BackupReminder(id, DateTime.parse(map['date'] as String),
          repeat: repeat.single));
    }
    final templates = <CustomNoteTemplate>[];
    final templateIds = <String>{};
    if (json['version'] == 2 && json['templates'] is! List) {
      throw const FormatException('Missing templates');
    }
    for (final raw in (json['templates'] as List? ?? const [])) {
      final map = raw as Map<String, dynamic>;
      final paths = (map['imagePaths'] as List).cast<String>();
      if (paths.any((path) => !photos.containsKey(path))) {
        throw const FormatException('Missing template photo');
      }
      // Photo references in a backup are archive keys, not device paths.
      final template = CustomNoteTemplate.fromJson({...map, 'imagePaths': []})
          .copyWith(imagePaths: paths);
      if (!templateIds.add(template.id)) {
        throw const FormatException('Duplicate template');
      }
      templates.add(template);
    }
    return BackupContents(
        createdAt: createdAt,
        notes: notes,
        folders: folders,
        photos: photos,
        reminders: reminders,
        templates: templates);
  }

  static String _id(dynamic value) {
    if (value is! String || value.isEmpty || value.length > 512) {
      throw const FormatException('Invalid ID');
    }
    return value;
  }

  static String? _date(dynamic value) =>
      value == null ? null : DateTime.parse(value as String).toIso8601String();
}

Uint8List encodeBackup(BackupContents contents) {
  final bytes = Uint8List.fromList(utf8.encode(jsonEncode(contents.toJson())));
  if (bytes.length > maxBackupBytes) {
    throw const FormatException('Backup exceeds size limit');
  }
  return bytes;
}

BackupContents decodeBackup(Uint8List bytes) {
  if (bytes.length > maxBackupBytes) {
    throw const FormatException('Backup exceeds size limit');
  }
  try {
    return BackupContents.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
  } catch (_) {
    throw const FormatException('Invalid or unsupported Onlynote backup');
  }
}
