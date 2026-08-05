import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:devotion/features/audio/presentation/providers/audio_player_provider.dart';
import 'package:devotion/features/audio/presentation/providers/audio_provider.dart';
import 'package:devotion/features/audio/presentation/providers/download_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AudioTile extends ConsumerWidget {
  final AudioFile audioFile;

  const AudioTile({super.key, required this.audioFile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPlayer = ref.watch(audioPlayerProvider);
    final isCurrentlyPlaying =
        audioPlayer.currentAudioId == audioFile.id && audioPlayer.isPlaying;
    final downloadState = ref.watch(downloadProvider(audioFile.id));

    final formattedDate =
        DateFormat('MMM d, yyyy').format(audioFile.uploadDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: audioFile.coverUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          audioFile.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, _) => Icon(
                            Icons.audiotrack,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.audiotrack,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
              ),
              title: Text(
                audioFile.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audioFile.minister.isNotEmpty
                        ? '${audioFile.minister} · $formattedDate'
                        : 'Uploaded on $formattedDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (audioFile.scripture.isNotEmpty)
                    Text(
                      audioFile.scripture,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      if (audioFile.url.isNotEmpty) {
                        if (isCurrentlyPlaying) {
                          ref.read(audioPlayerProvider.notifier).pauseAudio();
                        } else {
                          ref.read(audioPlayerProvider.notifier).playAudio(
                                audioFile.id,
                                audioFile.url,
                                audioFile.title,
                              );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Audio URL is unavailable'),
                          ),
                        );
                      }
                    },
                  ),
                  _buildDownloadButton(context, ref, downloadState),
                ],
              ),
            ),
            if (isCurrentlyPlaying)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Consumer(
                  builder: (context, ref, _) {
                    final position = ref.watch(audioPlayerProvider).position;
                    final duration = ref.watch(audioPlayerProvider).duration;

                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: duration.inSeconds > 0
                              ? position.inSeconds / duration.inSeconds
                              : 0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
      BuildContext context, WidgetRef ref, DownloadState downloadState) {
    switch (downloadState.status) {
      case DownloadStatus.initial:
        return IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {
            final audioList = ref.read(audioProvider).asData?.value ?? [];
            ref
                .read(downloadProvider(audioFile.id).notifier)
                .download(audioList);
          },
        );
      case DownloadStatus.downloading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        );
      case DownloadStatus.success:
        return const Icon(Icons.check, color: Colors.green);
      case DownloadStatus.failure:
        return IconButton(
          icon: const Icon(Icons.error, color: Colors.red),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Download failed: ${downloadState.error}')),
            );
          },
        );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
