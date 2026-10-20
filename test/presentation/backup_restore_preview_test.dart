import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onlynote/data/dto/folder_dto.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/generated/l10n.dart';
import 'package:onlynote/presentation/components/backup_restore_preview.dart';
import 'package:onlynote/presentation/components/backup_restore_previews.dart';
import 'package:onlynote/presentation/screens/settings/backup_screen.dart';
import 'package:onlynote/services/backup/backup_contents.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/saved_note_views.dart';

Widget _host(BackupRestoreMetadata metadata,
        {Locale locale = const Locale('en'),
        double textScale = 1,
        ValueChanged<bool?>? onDialogResult}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: onDialogResult == null
            ? SingleChildScrollView(
                child: BackupRestorePreview(metadata: metadata),
              )
            : Builder(
                builder: (context) => TextButton(
                  child: const Text('Open restore preview'),
                  onPressed: () async => onDialogResult(
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        scrollable: true,
                        title: Text(S.of(context).Backup_Restore),
                        content: BackupRestorePreview(metadata: metadata),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(S.of(context).Cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(S.of(context).Restore),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );

BackupRestoreMetadata _metadata({bool empty = false}) => BackupRestoreMetadata(
      createdAt: DateTime.utc(2026, 10, 7, 14, 30),
      noteCount: empty ? 0 : 1200,
      activeNoteCount: empty ? 0 : 1000,
      archivedNoteCount: empty ? 0 : 150,
      trashedNoteCount: empty ? 0 : 50,
      folderCount: empty ? 0 : 3,
      photoCount: empty ? 0 : 16,
      templateCount: empty ? 0 : 2,
      recordingFileCount: empty ? 0 : 5,
      savedViewCount: empty ? 0 : 4,
      historyVersionCount: empty ? 0 : 1038,
    );

Map<String, dynamic> _memo(String id) => {
      'id': id,
      'path': 'audio_one',
      'durationMs': 1000,
      'createdAt': '2026-10-07T14:30:00.000Z',
    };

void main() {
  test('validated metadata counts unique media files and all history versions',
      () {
    final date = DateTime.utc(2026, 10, 7, 14, 30);
    final first = NoteDto(
      id: 'first',
      imagePaths: ['photo_one'],
      voiceMemos: [_memo('one'), _memo('two')],
    );
    final second = NoteDto(
      id: 'second',
      imagePaths: ['photo_one'],
      voiceMemos: [_memo('three')],
    );
    final contents = decodeBackup(encodeBackup(BackupContents(
      createdAt: date,
      notes: [first, second],
      folders: [FolderDto(id: 'folder', name: 'Work')],
      photos: {
        'photo_one': BackupPhoto('jpg', Uint8List.fromList([1])),
        'photo_two': BackupPhoto('png', Uint8List.fromList([2])),
      },
      audio: {
        'audio_one': BackupAudio(Uint8List.fromList([3])),
        'audio_two': BackupAudio(Uint8List.fromList([4])),
      },
      reminders: [],
      templates: [
        CustomNoteTemplate(id: 'template', name: 'Plan', createdAt: date)
      ],
      savedViews: [
        SavedNoteView(id: 'view-one', name: 'Work'),
        SavedNoteView(id: 'view-two', name: 'Home'),
      ],
      histories: {
        'first': [
          NoteHistoryVersion(id: 'first-old', savedAt: date, note: first),
          NoteHistoryVersion(id: 'first-older', savedAt: date, note: first),
        ],
        'second': [
          NoteHistoryVersion(id: 'second-old', savedAt: date, note: second)
        ],
      },
    )));
    final before = jsonEncode(contents.toJson());
    final metadata = backupRestoreMetadata(contents);

    expect(metadata.createdAt, date);
    expect(metadata.noteCount, 2);
    expect(metadata.activeNoteCount, 2);
    expect(metadata.archivedNoteCount, 0);
    expect(metadata.trashedNoteCount, 0);
    expect(metadata.folderCount, 1);
    expect(metadata.photoCount, 2);
    expect(metadata.templateCount, 1);
    expect(metadata.recordingFileCount, 2);
    expect(metadata.savedViewCount, 2);
    expect(metadata.historyVersionCount, 3);
    expect(jsonEncode(contents.toJson()), before);
  });

  test(
      'scope totals partition validated notes with deleted precedence over archive',
      () {
    final date = DateTime.utc(2026, 10, 7, 14, 30);
    final active = NoteDto(id: 'active');
    final contents = decodeBackup(encodeBackup(BackupContents(
      createdAt: date,
      notes: [
        active,
        NoteDto(id: 'archived', isArchived: true),
        NoteDto(id: 'deleted', deletedAt: date.toIso8601String()),
        NoteDto(
            id: 'deleted-archive',
            isArchived: true,
            deletedAt: date.toIso8601String()),
      ],
      folders: [],
      photos: {},
      reminders: [],
      histories: {
        'active': [
          NoteHistoryVersion(
              id: 'older',
              savedAt: date,
              note: active.copyWith(isArchived: true)),
        ],
      },
    )));
    final before = jsonEncode(contents.toJson());
    final metadata = backupRestoreMetadata(contents);
    expect(metadata.noteCount, 4);
    expect(metadata.activeNoteCount, 1);
    expect(metadata.archivedNoteCount, 1);
    expect(metadata.trashedNoteCount, 2);
    expect(
        metadata.activeNoteCount +
            metadata.archivedNoteCount +
            metadata.trashedNoteCount,
        metadata.noteCount);
    expect(metadata.historyVersionCount, 1);
    expect(jsonEncode(contents.toJson()), before);
  });

  test('empty validated backup has zero notes in every scope', () {
    final contents = decodeBackup(encodeBackup(BackupContents(
      createdAt: DateTime.utc(2026, 10, 7),
      notes: [],
      folders: [],
      photos: {},
      reminders: [],
    )));
    final metadata = backupRestoreMetadata(contents);
    expect(metadata.noteCount, 0);
    expect(metadata.activeNoteCount, 0);
    expect(metadata.archivedNoteCount, 0);
    expect(metadata.trashedNoteCount, 0);
  });

  test(
      'legacy metadata keeps original totals and shows absent additions as zero',
      () {
    final date = DateTime.utc(2020, 3, 4, 5, 6);
    final legacy = BackupContents(
      createdAt: date,
      notes: [
        NoteDto(id: 'old-one'),
        NoteDto(id: 'old-two', deletedAt: date.toIso8601String()),
      ],
      folders: [FolderDto(id: 'old-folder', name: 'Old')],
      photos: {
        'old-photo': BackupPhoto('jpg', Uint8List.fromList([1]))
      },
      reminders: [],
    ).toJson()
      ..['version'] = 1
      ..remove('templates')
      ..remove('audio')
      ..remove('histories')
      ..remove('savedViews');
    for (final note in legacy['notes'] as List) {
      (note as Map).remove('isArchived');
    }
    final validated =
        decodeBackup(Uint8List.fromList(utf8.encode(jsonEncode(legacy))));
    final metadata = backupRestoreMetadata(validated);

    expect(metadata.createdAt, date);
    expect(metadata.noteCount, 2);
    expect(metadata.activeNoteCount, 1);
    expect(metadata.archivedNoteCount, 0);
    expect(metadata.trashedNoteCount, 1);
    expect(metadata.folderCount, 1);
    expect(metadata.photoCount, 1);
    expect(metadata.templateCount, 0);
    expect(metadata.recordingFileCount, 0);
    expect(metadata.savedViewCount, 0);
    expect(metadata.historyVersionCount, 0);
  });

  testWidgets(
      'restore details use localized dates, counts and descriptive semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final metadata = _metadata();
      await tester.pumpWidget(_host(metadata));
      await tester.pumpAndSettle();
      final date =
          DateFormat.yMMMd('en').add_jm().format(metadata.createdAt.toLocal());
      expect(find.text('1,200 notes · 3 folders · 16 photos'), findsOneWidget);
      expect(find.bySemanticsLabel('${S.current.Backup_Created}: $date'),
          findsOneWidget);
      for (final (id, label, value) in [
        ('active-notes', S.current.Backup_Active_Notes, '1,000'),
        ('archived-notes', S.current.Backup_Archived_Notes, '150'),
        ('trashed-notes', S.current.Backup_Trashed_Notes, '50'),
        ('templates', S.current.My_Templates, '2'),
        ('recording-files', S.current.Backup_Recording_Files, '5'),
        ('saved-views', S.current.Backup_Saved_Views, '4'),
        ('history-versions', S.current.Backup_History_Versions, '1,038'),
      ]) {
        final finder = find.byKey(ValueKey('backup-preview-$id-value'));
        expect(tester.widget<Text>(finder).data, value);
        expect(find.bySemanticsLabel('$label: $value'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('empty backup explicitly shows zero for every count',
      (tester) async {
    await tester.pumpWidget(_host(_metadata(empty: true)));
    await tester.pumpAndSettle();
    expect(find.text('0 notes · 0 folders · 0 photos'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(7));
    expect(find.text(S.current.Backup_Recording_Files), findsOneWidget);
    expect(find.text(S.current.Backup_Saved_Views), findsOneWidget);
    expect(find.text(S.current.Backup_History_Versions), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date follows the selected Chinese locale', (tester) async {
    final metadata = _metadata();
    await tester.pumpWidget(_host(metadata, locale: const Locale('zh', 'HK')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
              find.byKey(const ValueKey('backup-preview-created-value')))
          .data,
      DateFormat.yMMMd('zh_HK').add_jm().format(metadata.createdAt.toLocal()),
    );
    expect(find.text(S.current.Backup_Created), findsOneWidget);
    for (final (id, label, value) in [
      ('active-notes', S.current.Backup_Active_Notes, metadata.activeNoteCount),
      (
        'archived-notes',
        S.current.Backup_Archived_Notes,
        metadata.archivedNoteCount
      ),
      (
        'trashed-notes',
        S.current.Backup_Trashed_Notes,
        metadata.trashedNoteCount
      ),
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.byKey(ValueKey('backup-preview-$id-value')))
              .data,
          NumberFormat.decimalPattern('zh_HK').format(value));
    }
    expect(tester.takeException(), isNull);
  });

  for (final confirmed in [false, true]) {
    testWidgets(
        'scope review still allows ${confirmed ? 'confirmation' : 'cancellation'}',
        (tester) async {
      tester.view.physicalSize = const Size(280, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final results = <bool?>[];
      await tester.pumpWidget(
          _host(_metadata(), textScale: 2, onDialogResult: results.add));
      await tester.tap(find.text('Open restore preview'));
      await tester.pumpAndSettle();
      final trashCount =
          find.byKey(const ValueKey('backup-preview-trashed-notes-value'));
      await tester.ensureVisible(trashCount);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(trashCount).data, '50');
      expect(results, isEmpty);
      final action = confirmed
          ? find.widgetWithText(FilledButton, S.current.Restore)
          : find.widgetWithText(TextButton, S.current.Cancel);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(results, [confirmed]);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'isolated restore dialogs fit light, dark and Chinese 2x narrow layouts',
      (tester) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 1;
    for (final (preview, size) in [
      (backupRestoreLightPreview, const Size(390, 700)),
      (backupRestoreDarkPreview, const Size(390, 700)),
      (backupRestoreChinesePreview, const Size(280, 700)),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      for (final (id, value) in [
        ('active-notes', '17'),
        ('archived-notes', '5'),
        ('trashed-notes', '2'),
      ]) {
        final count = find.byKey(ValueKey('backup-preview-$id-value'));
        await tester.ensureVisible(count);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(count).data, value);
        final bounds = tester.getRect(count);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
      }
      await tester.ensureVisible(
          find.byKey(const ValueKey('backup-preview-history-versions-value')));
      await tester.pumpAndSettle();
      expect(find.text('38'), findsOneWidget);
      expect(find.text(S.current.Cancel), findsOneWidget);
      expect(find.text(S.current.Restore), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
