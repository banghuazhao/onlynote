import 'dart:convert';
import 'dart:typed_data';

import 'package:onlynote/Tools/reminder.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/note_image_layout.dart';
import 'package:onlynote/domain/model/note_card_style.dart';
import 'package:onlynote/domain/model/daily_note_date.dart';
import 'package:onlynote/domain/model/note_text_style.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/note_tags.dart';
import 'package:onlynote/services/note_links.dart';
import 'package:onlynote/services/note_section_links.dart';
import 'package:onlynote/services/saved_note_views.dart';
import 'package:onlynote/services/note_text_format.dart';
import 'package:onlynote/services/note_document.dart';

const maxBackupBytes = 256 * 1024 * 1024;
const maxBackupAudioBytes = 32 * 1024 * 1024;
const maxBackupRecords = 10000;
const maxBackupMemosPerNote = 100;

class BackupPhoto {
  BackupPhoto(this.extension, this.bytes);
  final String extension;
  final Uint8List bytes;
}

class BackupAudio {
  BackupAudio(this.bytes);
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
  BackupContents({
    required this.createdAt,
    required this.notes,
    required this.folders,
    required this.photos,
    required this.reminders,
    this.templates = const [],
    this.audio = const {},
    this.histories = const {},
    this.savedViews = const [],
  });
  final DateTime createdAt;
  final List<NoteDto> notes;
  final List<FolderDto> folders;
  final Map<String, BackupPhoto> photos;
  final List<BackupReminder> reminders;
  final List<CustomNoteTemplate> templates;
  final Map<String, BackupAudio> audio;
  final Map<String, List<NoteHistoryVersion>> histories;
  final List<SavedNoteView> savedViews;

  Map<String, dynamic> toJson() => {
        'format': 'onlynote-backup',
        'version': 9,
        'createdAt': createdAt.toIso8601String(),
        'folders': [
          for (final folder in folders)
            {
              'id': folder.id,
              'name': folder.name,
              'sortOrder': folder.sortOrder
            }
        ],
        'notes': [for (final note in notes) _noteJson(note)],
        'photos': {
          for (final entry in photos.entries)
            entry.key: {
              'extension': entry.value.extension,
              'data': base64Encode(entry.value.bytes),
            }
        },
        'audio': {
          for (final entry in audio.entries)
            entry.key: {
              'extension': 'm4a',
              'data': base64Encode(entry.value.bytes)
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
        'savedViews': [for (final view in savedViews) view.toJson()],
        'histories': {
          for (final entry in histories.entries)
            entry.key: [
              for (final version in entry.value)
                {
                  'id': version.id,
                  'savedAt': version.savedAt.toIso8601String(),
                  'note': _noteJson(version.note),
                }
            ]
        },
      };

  static Map<String, dynamic> _noteJson(NoteDto note) => {
        'id': note.id,
        'title': note.title,
        'description': note.description,
        'color': note.colorValue,
        'dateTime': note.dateTime,
        'sortOrder': note.sortOrder,
        'isPinned': note.isPinned ?? false,
        'deletedAt': note.deletedAt,
        'folderId': note.folderId,
        'isArchived': note.isArchived,
        'tags': note.tags ?? [],
        'linkedNoteIds': note.linkedNoteIds ?? [],
        'sectionLinks': note.sectionLinks ?? [],
        'textStyles': note.textStyles ?? [],
        'imageLayouts': note.imageLayouts ?? [],
        'dailyNoteDateKey': note.dailyNoteDateKey,
        'cardStyle': note.cardStyle,
        'photos': note.imagePaths ?? [],
        'voiceMemos': note.voiceMemos ?? [],
        'todos': [
          for (final todo in note.todoList ?? <TodoDto>[])
            {
              'id': todo.id,
              'title': todo.title,
              'completed': todo.completed ?? false,
            }
        ],
      };

  factory BackupContents.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (json['format'] != 'onlynote-backup' ||
        (version != 1 &&
            version != 2 &&
            version != 3 &&
            version != 4 &&
            version != 5 &&
            version != 6 &&
            version != 7 &&
            version != 8 &&
            version != 9)) {
      throw const FormatException('Unsupported backup');
    }
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final folders = <FolderDto>[];
    final folderIds = <String>{};
    for (final raw in _list(json['folders'])) {
      final map = raw as Map<String, dynamic>;
      final id = _id(map['id']);
      if (!folderIds.add(id)) throw const FormatException('Duplicate folder');
      final name = _text(map['name'])!;
      if (name.trim().isEmpty) throw const FormatException('Empty folder');
      folders.add(
          FolderDto(id: id, name: name, sortOrder: map['sortOrder'] as int?));
    }
    final photos = <String, BackupPhoto>{};
    final audio = <String, BackupAudio>{};
    var total = 0;
    Uint8List mediaBytes(Map<String, dynamic> map, {bool recording = false}) {
      final encoded = map['data'];
      if (encoded is! String || encoded.length > maxBackupBytes) {
        throw const FormatException('Invalid media data');
      }
      final bytes = base64Decode(encoded);
      total += bytes.length;
      if (total > maxBackupBytes ||
          bytes.isEmpty ||
          (recording && bytes.length > maxBackupAudioBytes)) {
        throw const FormatException('Invalid media size');
      }
      return bytes;
    }

    for (final entry in _map(json['photos']).entries) {
      final map = entry.value as Map<String, dynamic>;
      final extension = map['extension'] as String;
      if (!RegExp(r'^[a-zA-Z0-9]{1,10}$').hasMatch(extension)) {
        throw const FormatException('Invalid photo type');
      }
      photos[_archiveKey(entry.key)] = BackupPhoto(extension, mediaBytes(map));
    }
    if (version >= 3) {
      for (final entry in _map(json['audio']).entries) {
        final map = entry.value as Map<String, dynamic>;
        if (map['extension'] != 'm4a') {
          throw const FormatException('Invalid recording type');
        }
        audio[_archiveKey(entry.key)] =
            BackupAudio(mediaBytes(map, recording: true));
      }
    }
    if (photos.length + audio.length > maxBackupRecords) {
      throw const FormatException('Too many media files');
    }
    final notes = <NoteDto>[];
    final noteIds = <String>{};
    NoteDto noteFromJson(Map<String, dynamic> map) {
      final id = _id(map['id']);
      final folder = map['folderId'] as String?;
      if (folder != null && !folderIds.contains(folder)) {
        throw const FormatException('Missing folder');
      }
      final paths = _photoRefs(map['photos'], photos);
      final memos =
          version >= 3 ? _memoRefs(map['voiceMemos'], audio) : <VoiceMemo>[];
      final color = map['color'] as int?;
      if (color != null && (color < 0 || color > 0xffffffff)) {
        throw const FormatException('Invalid color');
      }
      final todos = <TodoDto>[];
      final todoIds = <String>{};
      for (final raw in _list(map['todos'])) {
        final todo = raw as Map<String, dynamic>;
        final todoId = todo['id'] == null ? null : _id(todo['id']);
        if (todoId != null && !todoIds.add(todoId)) {
          throw const FormatException('Duplicate task');
        }
        todos.add(TodoDto(
            id: todoId,
            title: _text(todo['title'], nullable: true),
            completed: todo['completed'] as bool));
      }
      final description = _text(map['description'], nullable: true);
      final textStyles = version >= 5
          ? _textStyles(map['textStyles'] ?? const [], description ?? '')
          : const <NoteTextStyleRange>[];
      final imageLayouts = version >= 6
          ? _imageLayouts(
              map['imageLayouts'] ?? const [], paths, description ?? '')
          : normalizeNoteImageLayouts(const [], paths, description ?? '');
      final dailyKey = version >= 7 ? map['dailyNoteDateKey'] : null;
      if (dailyKey != null && !isValidDailyNoteDateKey(dailyKey)) {
        throw const FormatException('Invalid daily note date');
      }
      return NoteDto(
        id: id,
        title: _text(map['title'], nullable: true),
        description: description,
        textStyles: [for (final style in textStyles) style.toMap()],
        imageLayouts: [for (final layout in imageLayouts) layout.toMap()],
        dailyNoteDateKey: dailyKey as String?,
        cardStyle: version >= 8
            ? NoteCardStyle.fromMap(map['cardStyle']).toMap()
            : null,
        colorValue: color,
        dateTime: _date(map['dateTime']),
        sortOrder: map['sortOrder'] as int?,
        isPinned: map['isPinned'] as bool,
        deletedAt: _date(map['deletedAt']),
        folderId: folder,
        isArchived: version >= 4 ? map['isArchived'] as bool : false,
        tags: version >= 4
            ? normalizeNoteTags(
                _list(map['tags'], max: maxNoteTags).cast<String>())
            : const [],
        linkedNoteIds: version >= 4
            ? normalizeLinkedNoteIds(
                _list(map['linkedNoteIds'], max: maxLinkedNotes).cast<String>(),
                noteId: id)
            : const [],
        sectionLinks: version >= 9
            ? [
                for (final link
                    in parseNoteSectionLinks(map['sectionLinks'] ?? const []))
                  link.toMap(),
              ]
            : const [],
        imagePaths: paths,
        voiceMemos: [for (final memo in memos) memo.toMap()],
        todoList: todos,
      );
    }

    for (final raw in _list(json['notes'])) {
      final note = noteFromJson(raw as Map<String, dynamic>);
      if (!noteIds.add(note.id!)) throw const FormatException('Duplicate note');
      notes.add(note);
    }
    final reminders = <BackupReminder>[];
    final reminderNotes = <String>{};
    for (final raw in _list(json['reminders'])) {
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
    if (version != 1 && json['templates'] is! List) {
      throw const FormatException('Missing templates');
    }
    for (final raw in _list(json['templates'] ?? const [])) {
      final map = raw as Map<String, dynamic>;
      final paths = _photoRefs(map['imagePaths'], photos);
      final memos =
          version >= 3 ? _memoRefs(map['voiceMemos'], audio) : <VoiceMemo>[];
      // Archive references are not device paths; validate metadata separately.
      final template = CustomNoteTemplate.fromJson({
        ...map,
        'imagePaths': paths,
        'voiceMemos': [],
        if (version < 5) 'textStyles': [],
        if (version < 6) 'imageLayouts': [],
        if (version < 8) 'cardStyle': null,
        if (version < 9) 'sectionLinks': [],
        if (version < 9) 'sourceNoteId': null,
      }).copyWith(voiceMemos: memos);
      _id(template.id);
      if (!templateIds.add(template.id)) {
        throw const FormatException('Duplicate template');
      }
      templates.add(template);
    }
    final histories = <String, List<NoteHistoryVersion>>{};
    var historyCount = 0;
    if (version >= 3) {
      for (final entry in _map(json['histories']).entries) {
        final noteId = _id(entry.key);
        if (!noteIds.contains(noteId)) {
          throw const FormatException('Missing history note');
        }
        final versions = <NoteHistoryVersion>[];
        final versionIds = <String>{};
        for (final raw in _list(entry.value, max: 100)) {
          if (++historyCount > maxBackupRecords) {
            throw const FormatException('Too much history');
          }
          final map = raw as Map<String, dynamic>;
          final id = _id(map['id'], max: 128);
          final note = noteFromJson(map['note'] as Map<String, dynamic>);
          if (note.id != noteId || !versionIds.add(id)) {
            throw const FormatException('Invalid history version');
          }
          versions.add(NoteHistoryVersion(
              id: id,
              savedAt: DateTime.parse(map['savedAt'] as String),
              note: note));
        }
        histories[noteId] = versions;
      }
    }
    final savedViews = <SavedNoteView>[];
    final viewIds = <String>{};
    if (version >= 4) {
      for (final raw
          in _list(json['savedViews'], max: SavedNoteViewStore.maxViews)) {
        if (raw is! Map) throw const FormatException('Invalid saved view');
        final view = SavedNoteView.fromJson(raw);
        if (!viewIds.add(view.id)) {
          throw const FormatException('Duplicate saved view');
        }
        savedViews.add(view.withAvailableFolders(folderIds));
      }
    }
    return BackupContents(
        savedViews: savedViews,
        createdAt: createdAt,
        notes: notes,
        folders: folders,
        photos: photos,
        reminders: reminders,
        templates: templates,
        audio: audio,
        histories: histories);
  }

  static List<VoiceMemo> _memoRefs(
      dynamic value, Map<String, BackupAudio> audio) {
    final memos = <VoiceMemo>[];
    final ids = <String>{};
    for (final raw in _list(value, max: maxBackupMemosPerNote)) {
      final map = raw as Map<String, dynamic>;
      final path = _archiveKey(map['path']);
      if (!audio.containsKey(path)) {
        throw const FormatException('Missing recording');
      }
      final memo =
          VoiceMemo.tryFromMap({...map, 'path': 'note_audio/validation.m4a'});
      if (memo == null ||
          memo.durationMs <= 0 ||
          memo.durationMs > const Duration(hours: 24).inMilliseconds ||
          (memo.transcript?.length ?? 0) > 1024 * 1024 ||
          !ids.add(memo.id)) {
        throw const FormatException('Invalid recording metadata');
      }
      memos.add(memo.copyWith(path: path));
    }
    return memos;
  }

  static List<NoteTextStyleRange> _textStyles(dynamic value, String text) {
    final styles = <NoteTextStyleRange>[];
    for (final raw in _list(value, max: maxBackupRecords)) {
      final style = NoteTextStyleRange.tryFromMap(raw);
      if (style == null) {
        throw const FormatException('Invalid text formatting');
      }
      styles.add(style);
    }
    if (!areValidNoteTextStyles(styles, text)) {
      throw const FormatException('Invalid text formatting');
    }
    return normalizeNoteTextStyles(styles, text);
  }

  static List<NoteImageLayout> _imageLayouts(
      dynamic value, List<String> imagePaths, String text) {
    final layouts = <NoteImageLayout>[];
    for (final raw in _list(value, max: maxBackupRecords)) {
      final layout = NoteImageLayout.tryFromMap(raw);
      if (layout == null) {
        throw const FormatException('Invalid image layout');
      }
      layouts.add(layout);
    }
    if (!areValidNoteImageLayouts(layouts, imagePaths, text)) {
      throw const FormatException('Invalid image layout');
    }
    return normalizeNoteImageLayouts(layouts, imagePaths, text);
  }

  static List<String> _photoRefs(
      dynamic value, Map<String, BackupPhoto> photos) {
    final paths = _list(value).map(_archiveKey).toList();
    if (paths.any((p) => !photos.containsKey(p))) {
      throw const FormatException('Missing photo');
    }
    return paths;
  }

  static List _list(dynamic value, {int max = maxBackupRecords}) {
    if (value is! List || value.length > max) {
      throw const FormatException('Invalid list');
    }
    return value;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is! Map<String, dynamic> || value.length > maxBackupRecords) {
      throw const FormatException('Invalid map');
    }
    return value;
  }

  static String? _text(dynamic value, {bool nullable = false}) {
    if (value == null && nullable) return null;
    if (value is! String || value.length > 1024 * 1024) {
      throw const FormatException('Invalid text');
    }
    return value;
  }

  static String _id(dynamic value, {int max = 512}) {
    if (value is! String || value.isEmpty || value.length > max) {
      throw const FormatException('Invalid ID');
    }
    return value;
  }

  static String _archiveKey(dynamic value) {
    if (value is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)) {
      throw const FormatException('Invalid media reference');
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
