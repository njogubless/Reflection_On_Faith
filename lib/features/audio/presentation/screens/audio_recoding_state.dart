// Removed: AudioPlayerState enum does not belong here — it conflicts with
// AudioPlayerState class defined in audio_player_provider.dart.
// If you need a simple playback enum elsewhere, define it in its own file.

import 'package:devotion/core/constants/firebase_constants.dart';

class AudioRecordingState {
  final bool isRecording;
  final bool isPaused;
  final String? recordedFilePath;
  final Duration recordingDuration;
  final List<double> waveformData;

  /// Set once when the recorder auto-stops after hitting the 25-minute cap,
  /// so the UI can show a one-time explanation instead of a silent stop.
  final bool didHitDurationLimit;

  AudioRecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.recordedFilePath,
    this.recordingDuration = Duration.zero,
    this.waveformData = const [],
    this.didHitDurationLimit = false,
  });

  static const maxDuration =
      Duration(seconds: FirebaseConstants.maxSermonDurationSeconds);

  Duration get remainingDuration {
    final remaining = maxDuration - recordingDuration;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// True in the last minute of allowed recording time — used to switch the
  /// timer/progress UI to a warning color before the hard auto-stop.
  bool get isNearDurationLimit =>
      remainingDuration <= const Duration(seconds: 60);

  AudioRecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    // FIX: Use Object? sentinel to allow explicitly clearing the path back to
    // null (e.g. after a reset), which plain `String?` copyWith cannot do.
    Object? recordedFilePath = _sentinel,
    Duration? recordingDuration,
    List<double>? waveformData,
    bool? didHitDurationLimit,
  }) {
    return AudioRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      recordedFilePath: recordedFilePath == _sentinel
          ? this.recordedFilePath
          : recordedFilePath as String?,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      waveformData: waveformData ?? this.waveformData,
      didHitDurationLimit: didHitDurationLimit ?? this.didHitDurationLimit,
    );
  }
}

// Private sentinel used by copyWith to distinguish "not provided" from null.
const Object _sentinel = Object();