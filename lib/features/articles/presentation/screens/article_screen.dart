import 'package:devotion/core/common/widgets/state_views.dart';
import 'package:devotion/features/articles/data/models/article_model.dart';
import 'package:devotion/features/articles/presentation/providers/article_provider.dart';
import 'package:devotion/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:devotion/widget/bookmark_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ArticlePage extends ConsumerWidget {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleList = ref.watch(articleStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final articles =
                  ref.read(articleStreamProvider).asData?.value ?? [];
              showSearch(
                context: context,
                delegate: ArticleSearchDelegate(articles),
              );
            },
          ),
        ],
      ),
      body: articleList.when(
        data: (articles) {
          if (articles.isEmpty) {
            return const EmptyView(
              icon: Icons.article_outlined,
              title: 'No articles yet',
              subtitle: 'Check back soon for new articles.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            itemBuilder: (context, index) => _ArticleCard(article: articles[index]),
          );
        },
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(
          message: 'Could not load articles.\n$error',
          onRetry: () => ref.invalidate(articleStreamProvider),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleModel article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          'Published ${DateFormat('MMM d, yyyy').format(article.createdAt)}',
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
                isPublished: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ArticleSearchDelegate extends SearchDelegate<ArticleModel?> {
  final List<ArticleModel> allArticles;

  ArticleSearchDelegate(this.allArticles);

  List<ArticleModel> get _results => allArticles
      .where((a) => a.title.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _results;
    if (results.isEmpty) {
      return const EmptyView(icon: Icons.search_off, title: 'No results found');
    }
    return _buildList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const EmptyView(
        icon: Icons.search,
        title: 'Search articles',
        subtitle: 'Start typing to search by title.',
      );
    }
    final suggestions = _results;
    if (suggestions.isEmpty) {
      return const EmptyView(icon: Icons.search_off, title: 'No articles match your search');
    }
    return _buildList(context, suggestions);
  }

  Widget _buildList(BuildContext context, List<ArticleModel> articles) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return _ArticleCard(article: article);
      },
    );
  }
}
