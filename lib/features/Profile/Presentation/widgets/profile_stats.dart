import 'package:devotion/features/audio/presentation/providers/audio_provider.dart';
import 'package:devotion/services/bookmark_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// This used to show "Playlists / Followers / Following" — three numbers
/// pulled from Firestore fields (`playlistCount`, `followersCount`,
/// `followingCount`) that nothing in the app ever writes to, since there's
/// no playlist or social/follow feature here at all (this looks like
/// leftover boilerplate from a different kind of app). Replaced with two
/// numbers this app actually has: bookmarked articles and sermons the user
/// has recorded.
class ProfileStats extends ConsumerWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkCount = ref.watch(bookmarkedArticlesProvider).length;
    final recordingsAsync = ref.watch(myRecordingsProvider);
    final recordingCount = recordingsAsync.asData?.value.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(context, '$bookmarkCount', 'Bookmarks'),
          _buildStatItem(
              context, recordingCount?.toString() ?? '–', 'Sermons Recorded'),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
