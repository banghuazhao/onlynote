import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onlynote/Tools/note_cleanup.dart';
import 'package:onlynote/data/dto/note_dto.dart';
import 'package:onlynote/domain/model/note.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/domain/repository/note_repository.dart';
import 'package:onlynote/services/audio_storage.dart';
import 'package:onlynote/services/custom_note_template_store.dart';
import 'package:onlynote/services/custom_template_images.dart';
import 'package:onlynote/services/document_scan_capture.dart';
import 'package:onlynote/services/note_autosave.dart';
import 'package:onlynote/services/note_edit_history.dart';

import '../support/memory_preferences.dart';

class _Notes extends Fake implements NoteRepository {
  @override
  List<NoteDto> getAllNotes() => [];
}

class _TemplateImages extends Fake implements CustomTemplateImages {
  @override
  Future<void> pruneTemplates(Set<String> keep) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box drafts;
  late _Notes repository;
  late AudioStorage audio;
  late CustomNoteTemplateStore templates;
  final histories = <NoteEditHistory>[];

  NoteEditHistory history(Note note) {
    final instance = NoteEditHistory(initial: NoteEditSnapshot(note: note));
    histories.add(instance);
    return instance;
  }

  Future<File> file(String path) async {
    final result = File('${directory.path}/$path');
    await result.parent.create(recursive: true);
    await result.writeAsBytes([1, 2, 3]);
    return result;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-undo-media-');
    Hive.init(directory.path);
    drafts = await Hive.openBox(draftDatabaseBox);
    repository = _Notes();
    audio = AudioStorage(documentsPath: directory.path);
    templates = CustomNoteTemplateStore(
        preferences: MemoryPreferences(),
        images: _TemplateImages(),
        audio: audio);
  });
  tearDown(() async {
    for (final instance in histories) {
      instance.dispose();
    }
    histories.clear();
    templates.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('removed and cropped photos survive cleanup until undo is released',
      () async {
    final originalFile = await file('note_images/original.jpg');
    final croppedFile = await file('note_images/cropped.jpg');
    final original = Note(id: 'note', imagePaths: [originalFile.path]);
    final edits = history(original);
    edits.record(NoteEditSnapshot(
        note: original.copyWith(imagePaths: [croppedFile.path])));
    edits.record(NoteEditSnapshot(note: original.copyWith(imagePaths: [])));

    await NoteCleanup.deleteUnreferencedImages(
      [originalFile.path, croppedFile.path],
      repository: repository,
      ignoreNoteIds: {'note'},
      templateStore: templates,
    );
    expect(await originalFile.exists(), isTrue);
    expect(await croppedFile.exists(), isTrue);
    expect(edits.undo()!.note.imagePaths, [croppedFile.path]);
    expect(edits.undo()!.note.imagePaths, [originalFile.path]);

    edits.dispose();
    await NoteCleanup.deleteUnreferencedImages(
      [originalFile.path, croppedFile.path],
      repository: repository,
      templateStore: templates,
    );
    expect(await originalFile.exists(), isFalse);
    expect(await croppedFile.exists(), isFalse);
  });

  test('other open editors independently retain a shared photo', () async {
    final photo = await file('note_images/shared.jpg');
    final first = history(Note(id: 'first', imagePaths: [photo.path]));
    final second = history(Note(id: 'second', imagePaths: [photo.path]));
    first.record(NoteEditSnapshot(note: Note(id: 'first')));
    first.dispose();
    await NoteCleanup.deleteUnreferencedImages([photo.path],
        repository: repository, templateStore: templates);
    expect(await photo.exists(), isTrue);

    second.dispose();
    await NoteCleanup.deleteUnreferencedImages([photo.path],
        repository: repository, templateStore: templates);
    expect(await photo.exists(), isFalse);
  });

  test('redo owns audio until a new edit discards the redo branch', () async {
    const path = 'note_audio/recording.m4a';
    final recording = await file(path);
    final original = Note(id: 'note');
    final edits = history(original);
    edits.record(NoteEditSnapshot(
        note: original.copyWith(voiceMemos: [
      VoiceMemo(
          id: 'recording',
          path: path,
          durationMs: 1000,
          createdAt: DateTime.utc(2026)),
    ])));
    edits.undo();
    await NoteCleanup.deleteUnreferencedAudio([path],
        repository: repository, templateStore: templates, audio: audio);
    expect(await recording.exists(), isTrue);

    edits.record(
        NoteEditSnapshot(note: original.copyWith(description: 'Other')));
    await NoteCleanup.deleteUnreferencedAudio([path],
        repository: repository, templateStore: templates, audio: audio);
    expect(await recording.exists(), isFalse);
  });

  test('releasing undo never bypasses pending scanner pruning protection',
      () async {
    const path = 'note_audio/recording.m4a';
    final recording = await file(path);
    final edits = history(Note(id: 'note', voiceMemos: [
      VoiceMemo(
          id: 'recording',
          path: path,
          durationMs: 1000,
          createdAt: DateTime.utc(2026)),
    ]));
    edits.dispose();
    final key = '${DocumentScanCapture.journalPrefix}pending';
    await drafts.put(key, {'version': 1});
    await NoteCleanup.pruneOrphanAudio(repository,
        templateStore: templates, audio: audio);
    expect(await recording.exists(), isTrue);
    await drafts.delete(key);
    await NoteCleanup.pruneOrphanAudio(repository,
        templateStore: templates, audio: audio);
    expect(await recording.exists(), isFalse);
  });
}
