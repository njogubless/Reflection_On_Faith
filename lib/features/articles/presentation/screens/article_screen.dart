import 'package:devotion/features/articles/data/models/article_model.dart';
import 'package:devotion/features/articles/presentation/providers/article_provider.dart';
import 'package:devotion/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:devotion/widget/bookmark_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            return const Center(child: Text('No articles available.'));
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ListTile(
                title: Text(article.title),
                subtitle: Text(
                  'Published on: ${article.createdAt.toLocal().toString().split(' ')[0]}',
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
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
      return const Center(child: Text('No results found.'));
    }
    return _buildList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Start typing to search articles.'));
    }
    final suggestions = _results;
    if (suggestions.isEmpty) {
      return const Center(child: Text('No articles match your search.'));
    }
    return _buildList(context, suggestions);
  }

  Widget _buildList(BuildContext context, List<ArticleModel> articles) {
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return ListTile(
          title: Text(article.title),
          subtitle: Text(
            article.createdAt.toLocal().toString().split(' ')[0],
          ),
          onTap: () {
            close(context, article);
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
        );
      },
    );
  }
}
