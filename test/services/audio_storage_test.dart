import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/audio_storage.dart';

void main() {
  late Directory directory;
  late AudioStorage storage;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('onlynote-audio-files-');
    storage = AudioStorage(documentsPath: directory.path);
  });
  tearDown(() async => directory.delete(recursive: true));

  Future<VoiceMemo> recording() async {
    final memo = (await storage.createMemo())
        .copyWith(durationMs: 2500, transcript: 'Keep the reviewed transcript');
    await File(await storage.resolvePath(memo.path))
        .writeAsBytes([1, 2, 3, 4], flush: true);
    return memo;
  }

  test('recording preparation owns a fresh safe path without a fake audio file',
      () async {
    final first = await storage.createMemo();
    final second = await storage.createMemo();
    expect(first.id, isNot(second.id));
    expect(VoiceMemo.isManagedPath(first.path), isTrue);
    expect(await File(await storage.resolvePath(first.path)).exists(), isFalse);
    for (final invalid in [
      '../private.m4a',
      '/note_audio/absolute.m4a',
      'note_audio/../private.m4a',
      'note_audio/audio.mp3'
    ]) {
      await expectLater(storage.resolvePath(invalid), throwsFormatException);
    }
  });

  test('note and template copies own immutable files and preserve metadata',
      () async {
    final original = await recording();
    final template = (await storage.copyToTemplate([original])).single;
    final duplicate = (await storage.copyToNote([template])).single;
    expect(template.path, startsWith('template_audio/'));
    expect(duplicate.path, startsWith('note_audio/'));
    expect({original.id, template.id, duplicate.id}.length, 3);
    expect(duplicate.transcript, original.transcript);
    expect(duplicate.createdAt, original.createdAt);
    expect(duplicate.durationMs, original.durationMs);
    await storage.deletePaths([original.path, template.path]);
    expect(await File(await storage.resolvePath(duplicate.path)).readAsBytes(),
        [1, 2, 3, 4]);
  });

  test('failed batch copy removes every partial destination', () async {
    final original = await recording();
    final missing =
        original.copyWith(id: 'missing', path: 'note_audio/missing.m4a');
    await expectLater(storage.copyToTemplate([original, missing]),
        throwsA(isA<FileSystemException>()));
    final contents =
        await Directory('${directory.path}/template_audio').list().toList();
    expect(contents, isEmpty);
    expect(
        await File(await storage.resolvePath(original.path)).exists(), isTrue);
  });

  test('prune respects retained paths and ignores unrelated files', () async {
    final keep = await recording();
    final orphan = await recording();
    final unrelated = File('${directory.path}/note_audio/unrelated.txt');
    await unrelated.writeAsString('Do not delete');
    await storage.prune({keep.path});
    expect(await File(await storage.resolvePath(keep.path)).exists(), isTrue);
    expect(
        await File(await storage.resolvePath(orphan.path)).exists(), isFalse);
    expect(await unrelated.readAsString(), 'Do not delete');
  });
}
