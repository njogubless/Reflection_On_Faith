// Regression tests for the 25-minute sermon recording cap.
//
// Before this session, nothing in the app enforced the "sermons should only
// span 25 minutes" rule — AudioRecorderNotifier just counted elapsed time
// forever. These tests cover the pure state/duration logic that the cap is
// built on (AudioRecorderNotifier itself talks to the platform `record`
// plugin, which needs a device/platform channel and isn't unit-testable
// here — see audio_recorder_provider.dart for the auto-stop wiring these
// values feed into).

import 'package:devotion/features/audio/presentation/screens/audio_recoding_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioRecordingState.maxDuration', () {
    test('is exactly 25 minutes', () {
      expect(AudioRecordingState.maxDuration, const Duration(minutes: 25));
    });
  });

  group('AudioRecordingState.remainingDuration', () {
    test('counts down from the 25-minute cap', () {
      final state =
          AudioRecordingState(recordingDuration: const Duration(minutes: 10));
      expect(state.remainingDuration, const Duration(minutes: 15));
    });

    test('never goes negative once recording exceeds the cap', () {
      // Defensive: the notifier should never let this happen (it auto-stops
      // exactly at the cap), but the getter must not report a negative
      // "remaining" if it ever did.
      final state =
          AudioRecordingState(recordingDuration: const Duration(minutes: 30));
      expect(state.remainingDuration, Duration.zero);
    });

    test('is zero exactly at the cap', () {
      final state = AudioRecordingState(recordingDuration: AudioRecordingState.maxDuration);
      expect(state.remainingDuration, Duration.zero);
    });
  });

  group('AudioRecordingState.isNearDurationLimit', () {
    test('false with more than a minute remaining', () {
      final state =
          AudioRecordingState(recordingDuration: const Duration(minutes: 23, seconds: 59));
      expect(state.isNearDurationLimit, isFalse);
    });

    test('true with exactly a minute remaining', () {
      final state = AudioRecordingState(recordingDuration: const Duration(minutes: 24));
      expect(state.isNearDurationLimit, isTrue);
    });

    test('true with less than a minute remaining', () {
      final state =
          AudioRecordingState(recordingDuration: const Duration(minutes: 24, seconds: 30));
      expect(state.isNearDurationLimit, isTrue);
    });
  });

  group('AudioRecordingState.copyWith', () {
    test('preserves fields that are not overridden', () {
      final state = AudioRecordingState(
        isRecording: true,
        recordingDuration: const Duration(seconds: 5),
        waveformData: const [0.1, 0.2],
      );
      final copy = state.copyWith(isPaused: true);

      expect(copy.isRecording, isTrue);
      expect(copy.isPaused, isTrue);
      expect(copy.recordingDuration, const Duration(seconds: 5));
      expect(copy.waveformData, const [0.1, 0.2]);
    });

    test('can explicitly clear recordedFilePath back to null', () {
      final state = AudioRecordingState(recordedFilePath: '/tmp/rec.m4a');
      final copy = state.copyWith(recordedFilePath: null);

      expect(copy.recordedFilePath, isNull);
    });

    test('leaves recordedFilePath untouched when not passed at all', () {
      final state = AudioRecordingState(recordedFilePath: '/tmp/rec.m4a');
      final copy = state.copyWith(isRecording: false);

      expect(copy.recordedFilePath, '/tmp/rec.m4a');
    });

    test('carries didHitDurationLimit through when set', () {
      final state = AudioRecordingState().copyWith(didHitDurationLimit: true);
      expect(state.didHitDurationLimit, isTrue);

      final copy = state.copyWith(isPaused: true);
      expect(copy.didHitDurationLimit, isTrue,
          reason: 'unrelated copyWith calls should not silently reset the flag');
    });
  });
}
