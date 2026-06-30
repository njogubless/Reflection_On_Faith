import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';

enum DownloadStatus { initial, downloading, success, failure }

class DownloadState {
  final DownloadStatus status;
  final String? error;

  const DownloadState({required this.status, this.error});

  factory DownloadState.initial() =>
      const DownloadState(status: DownloadStatus.initial);
  factory DownloadState.downloading() =>
      const DownloadState(status: DownloadStatus.downloading);
  factory DownloadState.success() =>
      const DownloadState(status: DownloadStatus.success);
  factory DownloadState.failure(String error) =>
      DownloadState(status: DownloadStatus.failure, error: error);
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  final String audioId;
  final Dio _dio = Dio();

  DownloadNotifier(this.audioId) : super(DownloadState.initial());

  Future<void> download(List<AudioFile> audioList) async {
    final AudioFile? audio = audioList.firstWhereOrNull((a) => a.id == audioId);

    if (audio == null) {
      state = DownloadState.failure('Audio file not found.');
      return;
    }

    if (audio.url.isEmpty) {
      state = DownloadState.failure('Audio URL is not available yet.');
      return;
    }

    state = DownloadState.downloading();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${_sanitiseFileName(audio.title)}.mp3';
      final response = await _dio.download(audio.url, filePath);

      state = response.statusCode == 200
          ? DownloadState.success()
          : DownloadState.failure(
              'Download failed with status: ${response.statusCode}');
    } catch (e) {
      state = DownloadState.failure(e.toString());
    }
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}

final downloadProvider = StateNotifierProvider.autoDispose
    .family<DownloadNotifier, DownloadState, String>((ref, audioId) {
  return DownloadNotifier(audioId);
});

extension _ListX<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

String _sanitiseFileName(String name) =>
    name.replaceAll(RegExp(r'[^\w\s\-.]'), '_').trim();
