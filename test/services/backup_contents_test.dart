import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/note_search.dart';
import 'package:onlynote/services/saved_note_views.dart';

void main() {
  test('portable saved views preserve recording scan and existing filters', () {
    const filters = {
      NoteSearchFilter.checklists,
      NoteSearchFilter.photos,
      NoteSearchFilter.reminders,
      NoteSearchFilter.pinned,
      NoteSearchFilter.unfinished,
      NoteSearchFilter.recordings,
      NoteSearchFilter.scans,
    };
    final contents = BackupContents(
      createdAt: DateTime(2026, 10, 12),
      notes: [],
      folders: [FolderDto(id: 'folder', name: 'Research')],
      photos: {},
      reminders: [],
      savedViews: [
        SavedNoteView(
          id: 'view',
          name: 'Research media',
          query: 'meeting',
          filters: filters,
          tags: ['Work'],
          folderId: 'folder',
          archiveScope: NoteArchiveScope.all,
        ),
      ],
    );

    final bytes = encodeBackup(contents);
    final serialized = jsonDecode(utf8.decode(bytes)) as Map;
    expect(serialized['version'], 8);
    expect((serialized['savedViews'] as List).single['filters'], [
      'checklists',
      'photos',
      'reminders',
      'pinned',
      'unfinished',
      'recordings',
      'scans',
    ]);
    final restored = decodeBackup(bytes).savedViews.single;
    expect(restored.id, 'view');
    expect(restored.name, 'Research media');
    expect(restored.query, 'meeting');
    expect(restored.filters, filters);
    expect(restored.tags, ['Work']);
    expect(restored.folderId, 'folder');
    expect(restored.archiveScope, NoteArchiveScope.all);
  });

  test('v4 through v8 legacy saved-view filter names remain portable', () {
    const legacyNames = [
      'checklists',
      'photos',
      'reminders',
      'pinned',
      'unfinished',
    ];
    const legacyFilters = {
      NoteSearchFilter.checklists,
      NoteSearchFilter.photos,
      NoteSearchFilter.reminders,
      NoteSearchFilter.pinned,
      NoteSearchFilter.unfinished,
    };
    for (var version = 4; version <= 8; version++) {
      final legacy = BackupContents.fromJson(
        _savedViewBackupJson(legacyNames, version: version),
      );
      expect(legacy.savedViews.single.filters, legacyFilters,
          reason: 'Backup version $version');
      final portable = decodeBackup(encodeBackup(legacy));
      expect(portable.savedViews.single.filters, legacyFilters);
      expect(portable.savedViews.single.toJson()['filters'], legacyNames);
    }
  });

  test('unknown saved-view filters reject the entire portable backup', () {
    expect(
      BackupContents.fromJson(_savedViewBackupJson(['recordings', 'scans']))
          .savedViews
          .single
          .filters,
      {NoteSearchFilter.recordings, NoteSearchFilter.scans},
    );
    for (final invalid in ['future_filter', 'Recordings', 1, null]) {
      final json = _savedViewBackupJson(['recordings', 'scans', invalid]);
      final invalidFilter = throwsA(isA<FormatException>()
          .having((error) => error.message, 'message', 'Invalid saved view'));
      expect(() => BackupContents.fromJson(json), invalidFilter);
      expect(
        () => decodeBackup(Uint8List.fromList(utf8.encode(jsonEncode(json)))),
        throwsFormatException,
      );
    }
  });
}

Map<String, dynamic> _savedViewBackupJson(List<Object?> filters,
        {int version = 8}) =>
    {
      'format': 'onlynote-backup',
      'version': version,
      'createdAt': '2026-10-12T09:00:00.000',
      'folders': [],
      'notes': [],
      'photos': <String, dynamic>{},
      'audio': <String, dynamic>{},
      'reminders': [],
      'templates': [],
      'histories': <String, dynamic>{},
      'savedViews': [
        {
          'id': 'legacy-view',
          'name': 'Legacy view',
          'query': '',
          'filters': filters,
          'tags': [],
          'folderId': null,
          'archiveScope': 'active',
        },
      ],
    };
