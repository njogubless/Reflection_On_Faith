import 'package:devotion/core/common/widgets/state_views.dart';
import 'package:devotion/features/articles/presentation/providers/article_provider.dart';
import 'package:devotion/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:devotion/services/bookmark_provider.dart';
import 'package:devotion/widget/bookmark_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedIds = ref.watch(bookmarkedArticlesProvider);
    final articlesAsync = ref.watch(articleStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: articlesAsync.when(
        data: (articles) {
          final bookmarkedArticles =
              articles.where((article) => bookmarkedIds.contains(article.id)).toList();

          if (bookmarkedArticles.isEmpty) {
            return const EmptyView(
              icon: Icons.bookmark_border,
              title: 'No bookmarks yet',
              subtitle: 'Tap the bookmark icon on an article to save it here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarkedArticles.length,
            itemBuilder: (context, index) {
              final article = bookmarkedArticles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.article, color: theme.colorScheme.primary),
                  ),
                  title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy').format(article.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: BookmarkButton(articleId: article.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          articleId: article.id,
                          title: article.title,
                          content: article.content,
                          isPublished: article.isPublished,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(
          message: 'Could not load bookmarks.\n$error',
          onRetry: () => ref.invalidate(articleStreamProvider),
        ),
      ),
    );
  }
}
