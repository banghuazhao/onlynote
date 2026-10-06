import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/note_cleanup.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/custom_note_template.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/custom_template_images.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_history.dart';
import 'package:onlynote/services/note_photo_recovery.dart';
import 'package:onlynote/services/shared_note_import.dart';
import 'package:onlynote/services/voice_memo_drafts.dart';
import 'package:onlynote/services/document_scan_capture.dart';

import '../support/memory_preferences.dart';

class _Notes extends Fake implements NoteRepository {
  final saved = <String, NoteDto>{};
  bool unavailable = false;

  @override
  List<NoteDto> getAllNotes() {
    if (unavailable) throw StateError('Ownership unavailable');
    return saved.values.toList();
  }
}

class _TemplateImages extends Fake implements CustomTemplateImages {
  @override
  Future<void> pruneTemplates(Set<String> keep) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box drafts;
  late _Notes notes;
  late NoteHistory history;
  late AudioStorage audio;
  late CustomNoteTemplateStore templates;

  VoiceMemo memo(String name, {String folder = 'note_audio'}) => VoiceMemo(
        id: name,
        path: '$folder/$name.m4a',
        durationMs: 1000,
        createdAt: DateTime.utc(2026),
      );

  NoteDto note(String name) => NoteDto(
        id: name,
        title: name,
        imagePaths: ['note_images/$name.jpg'],
        voiceMemos: [memo(name).toMap()],
      );

  Future<File> file(String path) async {
    final value = File('${directory.path}/$path');
    await value.parent.create(recursive: true);
    await value.writeAsBytes([1, 2, 3], flush: true);
    return value;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-cleanup-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TodoDtoAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteDtoAdapter());
    drafts = await Hive.openBox(draftDatabaseBox);
    notes = _Notes();
    audio = AudioStorage(documentsPath: directory.path);
    history = NoteHistory(
        box: await Hive.openBox('cleanup_history'), repository: notes);
    NoteHistory.configure(history);
    final preferences = MemoryPreferences();
    final template = CustomNoteTemplate(
      id: 'template',
      name: 'Template',
      imagePaths: ['template_images/template.jpg'],
      voiceMemos: [memo('template', folder: 'template_audio')],
      createdAt: DateTime.utc(2026),
    );
    await preferences.setString(
        CustomNoteTemplateStore.storageKey,
        jsonEncode({
          'version': 1,
          'templates': [template.toJson()],
        }));
    templates = CustomNoteTemplateStore(
        preferences: preferences, images: _TemplateImages(), audio: audio);
  });

  tearDown(() async {
    NoteHistory.initializedInstance = null;
    VoiceMemoDrafts.initializedInstance = null;
    history.dispose();
    templates.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('all saved, draft, history, template and pending media retain ownership',
      () async {
    notes.saved['current'] = note('current');
    final previous = note('historical');
    await history.recordBeforeSave(previous,
        previous.copyWith(title: 'Changed', imagePaths: [], voiceMemos: []));
    await drafts.put('draft', note('draft'));
    await drafts.put(NotePhotoRecovery.recordKey, {
      'note': note('camera-seed'),
      'saved': ['note_images/camera-copied.jpg'],
    });
    await drafts.put('${SharedNoteImport.journalPrefix}share', {
      'note': note('share-seed'),
      'saved': ['note_images/share-copied.jpg'],
    });
    await drafts.put('${VoiceMemoDrafts.prefix}pending', {
      'seed': note('voice-seed'),
      'memo': memo('pending').toMap(),
    });
    await drafts.put('${DocumentScanCapture.journalPrefix}scan', {
      'note': note('scan-seed'),
      'saved': ['note_images/scan-copied.jpg'],
    });

    expect(
        await NoteCleanup.referencedImages(notes, templateStore: templates), {
      'note_images/current.jpg',
      'note_images/historical.jpg',
      'template_images/template.jpg',
      'note_images/draft.jpg',
      'note_images/camera-seed.jpg',
      'note_images/camera-copied.jpg',
      'note_images/share-seed.jpg',
      'note_images/share-copied.jpg',
      'note_images/voice-seed.jpg',
      'note_images/scan-seed.jpg',
      'note_images/scan-copied.jpg',
    });
    expect(await NoteCleanup.referencedAudio(notes, templateStore: templates), {
      'note_audio/current.m4a',
      'note_audio/historical.m4a',
      'template_audio/template.m4a',
      'note_audio/draft.m4a',
      'note_audio/camera-seed.m4a',
      'note_audio/share-seed.m4a',
      'note_audio/voice-seed.m4a',
      'note_audio/pending.m4a',
      'note_audio/scan-seed.m4a',
    });
  });

  test('dropping a recording keeps its history and deletes only unowned files',
      () async {
    final previous = note('historical');
    await history.recordBeforeSave(previous.copyWith(voiceMemos: []), previous);
    await history.recordBeforeSave(
        previous, previous.copyWith(title: 'Changed', voiceMemos: []));
    final retained = await file(memo('historical').path);
    final orphan = await file(memo('orphan').path);

    await NoteCleanup.deleteUnreferencedAudio(
      [memo('historical').path, memo('orphan').path],
      repository: notes,
      ignoreNoteIds: {'historical'},
      templateStore: templates,
      audio: audio,
    );

    expect(await retained.exists(), isTrue);
    expect(await orphan.exists(), isFalse);
  });

  test('unresolved recovery prevents pruning until its journal is cleared',
      () async {
    notes.saved['current'] = note('current');
    final retained = await file(memo('current').path);
    final template =
        await file(memo('template', folder: 'template_audio').path);
    final orphan = await file(memo('orphan').path);
    final key = '${VoiceMemoDrafts.prefix}interrupted';
    await drafts.put(key, {'version': 1});

    await NoteCleanup.pruneOrphanAudio(notes,
        templateStore: templates, audio: audio);
    expect(await orphan.exists(), isTrue);

    await drafts.delete(key);
    await NoteCleanup.pruneOrphanAudio(notes,
        templateStore: templates, audio: audio);
    expect(await orphan.exists(), isFalse);
    expect(await retained.exists(), isTrue);
    expect(await template.exists(), isTrue);
  });

  test('unreadable ownership preserves audio during removal and pruning',
      () async {
    final retained = await file(memo('unknown').path);
    notes.unavailable = true;
    await NoteCleanup.deleteUnreferencedAudio([memo('unknown').path],
        repository: notes, templateStore: templates, audio: audio);
    await NoteCleanup.pruneOrphanAudio(notes,
        templateStore: templates, audio: audio);
    expect(await retained.exists(), isTrue);
  });

  test('unresolved document scan prevents media pruning without a global owner',
      () async {
    final orphan = await file(memo('orphan').path);
    final key = '${DocumentScanCapture.journalPrefix}interrupted';
    await drafts.put(key, {'version': 1});
    expect(DocumentScanCapture.initializedInstance, isNull);
    expect(NoteCleanup.hasPendingMediaRecovery, isTrue);
    await NoteCleanup.pruneOrphanAudio(notes,
        templateStore: templates, audio: audio);
    expect(await orphan.exists(), isTrue);

    await drafts.delete(key);
    expect(NoteCleanup.hasPendingMediaRecovery, isFalse);
    await NoteCleanup.pruneOrphanAudio(notes,
        templateStore: templates, audio: audio);
    expect(await orphan.exists(), isFalse);
  });
}
