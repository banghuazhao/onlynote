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
        {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: BackupRestorePreview(metadata: metadata),
        ),
      ),
    );

BackupRestoreMetadata _metadata({bool empty = false}) => BackupRestoreMetadata(
      createdAt: DateTime.utc(2026, 10, 7, 14, 30),
      noteCount: empty ? 0 : 1200,
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
    expect(metadata.folderCount, 1);
    expect(metadata.photoCount, 2);
    expect(metadata.templateCount, 1);
    expect(metadata.recordingFileCount, 2);
    expect(metadata.savedViewCount, 2);
    expect(metadata.historyVersionCount, 3);
    expect(jsonEncode(contents.toJson()), before);
  });

  test(
      'legacy metadata keeps original totals and shows absent additions as zero',
      () {
    final date = DateTime.utc(2020, 3, 4, 5, 6);
    final legacy = BackupContents(
      createdAt: date,
      notes: [NoteDto(id: 'old-one'), NoteDto(id: 'old-two')],
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
    final validated =
        decodeBackup(Uint8List.fromList(utf8.encode(jsonEncode(legacy))));
    final metadata = backupRestoreMetadata(validated);

    expect(metadata.createdAt, date);
    expect(metadata.noteCount, 2);
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
    expect(find.text('0'), findsNWidgets(4));
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
    expect(tester.takeException(), isNull);
  });

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
