import 'package:flutter_test/flutter_test.dart';
import 'package:onlynote/domain/model/voice_memo.dart';
import 'package:onlynote/services/recording_duration.dart';

VoiceMemo _memo(String id, int durationMs) => VoiceMemo(
      id: id,
      path: 'note_audio/$id.m4a',
      durationMs: durationMs,
      createdAt: DateTime(2026, 10, 20),
    );

void main() {
  test('stored durations sum before rounding and invalid time adds zero', () {
    final recordings = [
      _memo('missing-first', 600),
      _memo('invalid', -42000),
      _memo('missing-second', 600),
    ];
    expect(totalRecordingDurationMs(recordings), 1200);
    expect(
        formatRecordingDuration(totalRecordingDurationMs(recordings)), '0:01');
    expect(recordings[1].durationMs, -42000);
    expect(totalRecordingDurationMs(const []), 0);
  });

  test('format is zero-safe and stable at second and minute boundaries', () {
    for (final (milliseconds, expected) in [
      (-42000, '0:00'),
      (0, '0:00'),
      (999, '0:00'),
      (1000, '0:01'),
      (59999, '0:59'),
      (60000, '1:00'),
      (3600000, '60:00'),
    ]) {
      expect(formatRecordingDuration(milliseconds), expected);
    }
  });

  test('combined durations remain uncapped beyond one day', () {
    final milliseconds = totalRecordingDurationMs([
      _memo('first-day', const Duration(hours: 24).inMilliseconds),
      _memo('extra-hour', const Duration(hours: 1, seconds: 5).inMilliseconds),
    ]);
    expect(formatRecordingDuration(milliseconds), '1500:05');
  });
}
