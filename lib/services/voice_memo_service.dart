import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/services/premium_access.dart';

enum VoiceMemoPhase { idle, recording, playing, paused, transcribing }

class VoiceMemoState {
  const VoiceMemoState(
      {this.phase = VoiceMemoPhase.idle,
      this.path,
      this.durationMs = 0,
      this.positionMs = 0,
      this.interrupted = false,
      this.transcriptionSupported = false});
  final VoiceMemoPhase phase;
  final String? path;
  final int durationMs;
  final int positionMs;
  final bool interrupted;
  final bool transcriptionSupported;
  bool get recording => phase == VoiceMemoPhase.recording;
  bool get playing => phase == VoiceMemoPhase.playing;
  bool get transcribing => phase == VoiceMemoPhase.transcribing;
  factory VoiceMemoState.decode(Object? value) {
    final map = value is Map ? value : const {};
    int number(String key) =>
        (map[key] is num ? (map[key] as num).toInt() : 0).clamp(0, 86400000);
    return VoiceMemoState(
      phase: VoiceMemoPhase.values.firstWhere((p) => p.name == map['phase'],
          orElse: () => VoiceMemoPhase.idle),
      path: map['path'] is String ? map['path'] as String : null,
      durationMs: number('durationMs'),
      positionMs: number('positionMs'),
      interrupted: map['interrupted'] == true,
      transcriptionSupported: map['transcriptionSupported'] == true,
    );
  }
}

abstract interface class VoiceMemoPlatform {
  Stream<Object?> get states;
  Future<Object?> invoke(String method, [Map<String, Object?>? arguments]);
}

class MethodChannelVoiceMemoPlatform implements VoiceMemoPlatform {
  MethodChannelVoiceMemoPlatform() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'stateChanged') _states.add(call.arguments);
    });
  }
  static const channel = MethodChannel('com.appsbay.onlynote/voice_memos');
  final _states = StreamController<Object?>.broadcast();
  @override
  Stream<Object?> get states => _states.stream;
  @override
  Future<Object?> invoke(String method, [Map<String, Object?>? arguments]) =>
      channel.invokeMethod<Object?>(method, arguments);
}

/// One media session for the app. Native code also stops when interrupted or
/// backgrounded; events update any composer/player sharing this service.
class VoiceMemoService {
  VoiceMemoService(
      {required VoiceMemoPlatform platform, PremiumAccess? premiumAccess})
      : _platform = platform,
        _premiumAccess = premiumAccess ?? PremiumAccess.instance {
    _subscription = platform.states.listen((value) {
      if (!_disposed) state.value = VoiceMemoState.decode(value);
    });
  }
  static VoiceMemoService? _instance;
  static VoiceMemoService get instance => _instance ??=
      VoiceMemoService(platform: MethodChannelVoiceMemoPlatform());
  final VoiceMemoPlatform _platform;
  final PremiumAccess _premiumAccess;
  final state = ValueNotifier(const VoiceMemoState());
  late final StreamSubscription<Object?> _subscription;
  Future<void> _operations = Future.value();
  Future<String>? _transcription;
  String? _transcriptionPath;
  int _transcriptionGeneration = 0;
  bool _disposed = false;

  Future<void> init() => refresh();
  Future<void> refresh() async {
    try {
      _accept(await _platform.invoke('state'));
    } on MissingPluginException {
      _accept(null);
    }
  }

  void _accept(Object? value) {
    if (!_disposed && value is Map) state.value = VoiceMemoState.decode(value);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _operations.then((_) => operation());
    _operations =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static void validatePath(String path, {bool recording = false}) {
    if (!path.startsWith('/') ||
        path.contains('\u0000') ||
        path.split('/').contains('..') ||
        !path.endsWith('.m4a') ||
        !(path.contains('/note_audio/') ||
            (!recording && path.contains('/template_audio/')))) {
      throw const FormatException('Recording must use an owned m4a path');
    }
  }

  Future<void> startRecording(String absolutePath) {
    validatePath(absolutePath, recording: true);
    return _serialize(() async {
      _premiumAccess.require(PremiumFeature.voiceMemos);
      if (_transcription != null) throw StateError('Transcription is active');
      _accept(await _platform.invoke(
          'startRecording', {'path': absolutePath, 'maxDurationMs': 300000}));
    });
  }

  Future<int> stopRecording() => _serialize(() async {
        final value = await _platform.invoke('stopRecording');
        _accept(value);
        return state.value.durationMs;
      });
  Future<int> duration(String absolutePath) async {
    validatePath(absolutePath);
    final value = await _platform.invoke('duration', {'path': absolutePath});
    if (value is! num || value <= 0 || value > 300500) {
      throw PlatformException(code: 'invalid_audio');
    }
    return value.toInt();
  }

  Future<void> cancelRecording() => _serialize(() async {
        _accept(await _platform.invoke('cancelRecording'));
      });
  Future<void> play(String absolutePath) {
    validatePath(absolutePath);
    return _serialize(() async {
      if (_transcription != null) throw StateError('Transcription is active');
      _accept(await _platform.invoke('play', {'path': absolutePath}));
    });
  }

  Future<void> pause() => _serialize(() async {
        _accept(await _platform.invoke('pause'));
      });
  Future<void> stopPlayback() => _serialize(() async {
        _accept(await _platform.invoke('stopPlayback'));
      });
  Future<String> transcribe(String absolutePath, {String? locale}) {
    validatePath(absolutePath);
    if (_transcription != null) {
      if (_transcriptionPath == absolutePath) return _transcription!;
      return Future.error(StateError('Another recording is being transcribed'));
    }
    final generation = ++_transcriptionGeneration;
    _transcriptionPath = absolutePath;
    final completion = Completer<String>();
    _transcription = completion.future;
    unawaited(() async {
      try {
        await _serialize(() async {
          if (state.value.recording) {
            throw StateError('Stop recording before transcribing');
          }
          _accept(await _platform.invoke('stopPlayback'));
        });
        if (generation != _transcriptionGeneration) {
          throw PlatformException(code: 'cancelled');
        }
        final result = await _platform.invoke('transcribe',
            {'path': absolutePath, if (locale != null) 'locale': locale});
        if (generation != _transcriptionGeneration) {
          throw PlatformException(code: 'cancelled');
        }
        if (result is! String || result.trim().isEmpty) {
          throw PlatformException(
              code: 'no_speech', message: 'No speech found');
        }
        completion.complete(result.trim());
      } catch (error, stack) {
        completion.completeError(error, stack);
      } finally {
        _transcription = null;
        _transcriptionPath = null;
        try {
          await refresh();
        } catch (_) {/* Next resume retries state query. */}
      }
    }());
    return completion.future;
  }

  Future<void> cancelTranscription() async {
    _transcriptionGeneration++;
    _accept(await _platform.invoke('cancelTranscription'));
  }

  bool isTranscribingPath(String absolutePath) =>
      _transcription != null && _transcriptionPath == absolutePath;

  Future<void> cancelTranscriptionFor(String absolutePath) async {
    if (isTranscribingPath(absolutePath)) await cancelTranscription();
  }

  Future<void> onBackground() async {
    _transcriptionGeneration++;
    try {
      _accept(await _platform.invoke('background'));
    } on MissingPluginException {/* unsupported host */}
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription.cancel();
    state.dispose();
  }
}

String formatVoiceMemoDuration(int milliseconds) {
  final seconds = (milliseconds / 1000).floor().clamp(0, 86400);
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
