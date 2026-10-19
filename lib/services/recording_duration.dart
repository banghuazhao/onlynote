import 'package:onlynote/domain/model/voice_memo.dart';

/// Sums stored metadata only; unavailable recordings still contribute.
/// Invalid negative values never subtract time from the other recordings.
int totalRecordingDurationMs(Iterable<VoiceMemo> recordings) =>
    recordings.fold<int>(
      0,
      (total, memo) => total + (memo.durationMs < 0 ? 0 : memo.durationMs),
    );

/// Matches the player's minutes:seconds display without capping combined time.
String formatRecordingDuration(int milliseconds) {
  final seconds = (milliseconds < 0 ? 0 : milliseconds) ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
