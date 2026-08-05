
import 'package:devotion/features/audio/presentation/screens/audio_recoding_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';



class AudioRecorderNotifier extends Notifier<AudioRecordingState> {
  late final AudioRecorder _audioRecorder;
  Timer? _timer;
  Timer? _amplitudeTimer;

  @override
  AudioRecordingState build() {

    _audioRecorder = AudioRecorder();

    ref.onDispose(() {
      _timer?.cancel();
      _amplitudeTimer?.cancel();
      _audioRecorder.dispose();
    });

    return AudioRecordingState();
  }

  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return;
      }

      final path = await _getRecordingPath();

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _startTimer();
      _startAmplitudeListener();
      state = state.copyWith(isRecording: true, isPaused: false);
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = state.recordingDuration + const Duration(seconds: 1);

      if (elapsed >= AudioRecordingState.maxDuration) {
        // Hard cap: sermons must not exceed 25 minutes. Stop the recorder
        // itself (not just the timer) so the saved file is never longer
        // than the limit, regardless of what the submit screen does next.
        state = state.copyWith(
          recordingDuration: AudioRecordingState.maxDuration,
        );
        stopRecording(didHitDurationLimit: true);
        return;
      }

      state = state.copyWith(recordingDuration: elapsed);
    });
  }

  void _startAmplitudeListener() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      try {
        final amplitude = await _audioRecorder.getAmplitude();
        final normalized = ((amplitude.current + 160) / 160).clamp(0.0, 1.0);

        final updated = [...state.waveformData, normalized];
        const maxSamples = 300;
        state = state.copyWith(
          waveformData: updated.length > maxSamples
              ? updated.sublist(updated.length - maxSamples)
              : updated,
        );
      } catch (e) {
        debugPrint('Error getting amplitude: $e');
      }
    });
  }

  Future<void> pauseRecording() async {
    await _audioRecorder.pause();
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  Future<void> resumeRecording() async {
    await _audioRecorder.resume();
    _startTimer();
    _startAmplitudeListener();
    state = state.copyWith(isPaused: false);
  }

  Future<void> stopRecording({bool didHitDurationLimit = false}) async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    if (path != null) {
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        recordedFilePath: path,
        didHitDurationLimit: didHitDurationLimit,
      );
    }
  }

  Future<void> reset() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    state = AudioRecordingState();
  }
}


final audioRecorderProvider =
    NotifierProvider<AudioRecorderNotifier, AudioRecordingState>(
  AudioRecorderNotifier.new,
);