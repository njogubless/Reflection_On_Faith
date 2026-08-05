import 'package:devotion/core/common/widgets/state_views.dart';
import 'package:devotion/features/articles/presentation/providers/article_provider.dart';
import 'package:devotion/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:devotion/features/audio/presentation/providers/audio_provider.dart';
import 'package:devotion/features/audio/presentation/screens/audio_player_page.dart';
import 'package:devotion/services/bookmark_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// This used to be three tabs of entirely hardcoded fake data ("My Playlist
/// 1", "Recently Played Track 1" by "Artist 1", ...) with `onTap: () {}` —
/// nothing here was ever real. Replaced with two tabs backed by data this
/// app actually has: the sermons the user has recorded themselves
/// (including pending/rejected ones, so they can see their review status),
/// and their bookmarked articles.
class ProfileTabs extends StatefulWidget {
  const ProfileTabs({super.key});

  @override
  State<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends State<ProfileTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'My Sermons'),
            Tab(text: 'Bookmarks'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _MySermonsTab(),
              _BookmarksTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MySermonsTab extends ConsumerWidget {
  const _MySermonsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(myRecordingsProvider);

    return recordingsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Could not load your sermons.\n$e',
        onRetry: () => ref.invalidate(myRecordingsProvider),
      ),
      data: (recordings) {
        if (recordings.isEmpty) {
          return const EmptyView(
            icon: Icons.mic_none,
            title: 'No sermons recorded yet',
            subtitle: 'Sermons you record from the Sermons tab will show up here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recordings.length,
          itemBuilder: (context, index) =>
              _RecordingTile(recording: recordings[index]),
        );
      },
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final AudioFile recording;

  const _RecordingTile({required this.recording});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (recording.approvalStatus) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.mic, color: theme.colorScheme.primary),
        ),
        title: Text(recording.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(DateFormat('MMM d, yyyy').format(recording.uploadDate)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            recording.approvalStatus.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        onTap: recording.approvalStatus == 'approved'
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AudioPlayerPage(audioFile: recording),
                  ),
                )
            : null,
      ),
    );
  }
}

class _BookmarksTab extends ConsumerWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarkedArticlesProvider);
    final articlesAsync = ref.watch(articleStreamProvider);

    return articlesAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'Could not load bookmarks.\n$e',
        onRetry: () => ref.invalidate(articleStreamProvider),
      ),
      data: (articles) {
        final bookmarked =
            articles.where((a) => bookmarkedIds.contains(a.id)).toList();
        if (bookmarked.isEmpty) {
          return const EmptyView(
            icon: Icons.bookmark_border,
            title: 'No bookmarks yet',
            subtitle: 'Tap the bookmark icon on an article to save it here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarked.length,
          itemBuilder: (context, index) {
            final article = bookmarked[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.article, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(article.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(DateFormat('MMM d, yyyy').format(article.createdAt)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(
                      articleId: article.id,
                      title: article.title,
                      content: article.content,
                      isPublished: article.isPublished,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
