import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/services/voice_memo_service.dart';

class FakeVoicePlatform implements VoiceMemoPlatform {
  final events = StreamController<Object?>.broadcast();
  final calls = <String>[];
  Future<Object?> Function(String, Map<String, Object?>?)? action;
  @override
  Stream<Object?> get states => events.stream;
  @override
  Future<Object?> invoke(String method,
      [Map<String, Object?>? arguments]) async {
    calls.add(method);
    if (action != null) return await action!(method, arguments);
    return {'phase': 'idle', 'durationMs': 1000};
  }
}

void main() {
  late FakeVoicePlatform platform;
  late VoiceMemoService service;
  setUp(() {
    platform = FakeVoicePlatform();
    service = VoiceMemoService(platform: platform);
  });
  tearDown(() async {
    await service.dispose();
    await platform.events.close();
  });
  const path = '/app/note_audio/memo.m4a';

  test('permission-sensitive operations occur only after explicit actions',
      () async {
    await service.init();
    expect(platform.calls, ['state']);
    await service.startRecording(path);
    await service.stopRecording();
    expect(platform.calls, ['state', 'startRecording', 'stopRecording']);
  });
  test('rejects unowned, traversal and unsupported recording paths', () {
    for (final invalid in [
      '/app/memo.m4a',
      '/app/note_audio/../memo.m4a',
      'note_audio/memo.m4a',
      '/app/note_audio/memo.mp3',
      '/app/template_audio/memo.m4a'
    ]) {
      expect(() => service.startRecording(invalid), throwsFormatException);
    }
    expect(platform.calls, isEmpty);
  });
  test('serializes start and stop without losing the native state', () async {
    final started = Completer<Object?>();
    platform.action = (method, _) async {
      if (method == 'startRecording') return await started.future;
      return {'phase': 'idle', 'durationMs': 2400, 'path': path};
    };
    final start = service.startRecording(path);
    final stop = service.stopRecording();
    await Future<void>.delayed(Duration.zero);
    expect(platform.calls, ['startRecording']);
    started.complete({'phase': 'recording', 'path': path});
    await start;
    expect(await stop, 2400);
    expect(platform.calls, ['startRecording', 'stopRecording']);
  });
  test('native automatic stop and interruption update all listeners', () async {
    platform.events.add({
      'phase': 'idle',
      'path': path,
      'durationMs': 300000,
      'interrupted': true
    });
    await Future<void>.delayed(Duration.zero);
    expect(service.state.value.recording, false);
    expect(service.state.value.durationMs, 300000);
    expect(service.state.value.interrupted, true);
  });
  test('transcription failure preserves audio state and remains retryable',
      () async {
    var failures = 1;
    platform.action = (method, args) async {
      if (method == 'transcribe') {
        expect(args!['path'], path);
        expect(args['locale'], 'zh-CN');
        if (failures-- > 0) {
          throw PlatformException(code: 'transcription_unavailable');
        }
        return '  Buy milk  ';
      }
      return {'phase': 'idle', 'path': path, 'durationMs': 2300};
    };
    await expectLater(service.transcribe(path, locale: 'zh-CN'),
        throwsA(isA<PlatformException>()));
    await Future<void>.delayed(Duration.zero);
    expect(await service.transcribe(path, locale: 'zh-CN'), 'Buy milk');
    expect(platform.calls.where((m) => m == 'cancelRecording'), isEmpty);
  });
  test('cancellation is not blocked behind the transcription response',
      () async {
    final result = Completer<Object?>();
    platform.action = (method, _) async {
      if (method == 'transcribe') return await result.future;
      if (method == 'cancelTranscription') {
        result.completeError(PlatformException(code: 'cancelled'));
      }
      return {'phase': 'idle'};
    };
    final transcription = service.transcribe(path);
    final checked =
        expectLater(transcription, throwsA(isA<PlatformException>()));
    await Future<void>.delayed(Duration.zero);
    await service.cancelTranscription();
    await checked;
    expect(platform.calls, contains('cancelTranscription'));
  });
  test(
      'duration probe rejects invalid media and permits owned template playback',
      () async {
    platform.action = (_, __) async => 0;
    await expectLater(
        service.duration(path), throwsA(isA<PlatformException>()));
    platform.action = (_, __) async => 1200;
    expect(await service.duration(path), 1200);
    await service.play('/app/template_audio/template.m4a');
    expect(platform.calls.last, 'play');
  });
  test('a failed operation does not poison later controls', () async {
    platform.action = (method, _) async {
      if (method == 'play') throw PlatformException(code: 'play_failed');
      return {'phase': 'idle'};
    };
    await expectLater(service.play(path), throwsA(isA<PlatformException>()));
    await service.stopPlayback();
    expect(platform.calls.last, 'stopPlayback');
  });
  test('cancel before a queued transcription starts never invokes recognition',
      () async {
    final prepared = Completer<Object?>();
    platform.action = (method, _) async {
      if (method == 'stopPlayback') return await prepared.future;
      return {'phase': 'idle'};
    };
    final recognition = service.transcribe(path);
    final checked = expectLater(
        recognition,
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'cancelled')));
    await Future<void>.delayed(Duration.zero);
    await service.cancelTranscription();
    prepared.complete({'phase': 'idle'});
    await checked;
    expect(platform.calls, isNot(contains('transcribe')));
  });
  test('another file cannot consume the current recording transcript',
      () async {
    final result = Completer<Object?>();
    platform.action = (method, _) async {
      if (method == 'transcribe') return await result.future;
      return {'phase': 'idle'};
    };
    final first = service.transcribe(path);
    expect(identical(first, service.transcribe(path)), isTrue);
    await expectLater(
        service.transcribe('/app/note_audio/another.m4a'), throwsStateError);
    result.complete('First recording only');
    expect(await first, 'First recording only');
    expect(platform.calls.where((method) => method == 'transcribe').length, 1);
  });
  test('backgrounding cancels a transcription waiting behind playback cleanup',
      () async {
    final prepared = Completer<Object?>();
    platform.action = (method, _) async {
      if (method == 'stopPlayback') return await prepared.future;
      return {'phase': 'idle'};
    };
    final recognition = service.transcribe(path);
    final checked = expectLater(
        recognition,
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'cancelled')));
    await Future<void>.delayed(Duration.zero);
    await service.onBackground();
    prepared.complete({'phase': 'idle'});
    await checked;
    expect(platform.calls, contains('background'));
    expect(platform.calls, isNot(contains('transcribe')));
  });
}
