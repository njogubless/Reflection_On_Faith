import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/core/constants/firebase_constants.dart';
import 'package:devotion/features/admin/presentation/screens/write_article.dart';
import 'package:devotion/features/articles/presentation/providers/article_provider.dart';
import 'package:devotion/features/articles/presentation/screens/article_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArticleManagementScreen extends ConsumerWidget {
  const ArticleManagementScreen({super.key});

  Future<void> _togglePublishStatus(
      BuildContext context, String docId, bool newStatus) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.articleCollection)
          .doc(docId)
          .update({'isPublished': newStatus});

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'Article published successfully'
              : 'Article unpublished'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Could not update publish status. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text(
            'Are you sure you want to delete this article? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteArticle(context, docId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArticle(BuildContext context, String docId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.articleCollection)
          .doc(docId)
          .delete();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Article deleted successfully')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Could not delete the article. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(allArticlesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WriteArticleScreen()),
              );
            },
          ),
        ],
      ),
      body: articlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load articles: $error')),
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text('No articles found'));
          }

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(article.title),
                  subtitle: Text(
                    article.content.length > 50
                        ? '${article.content.substring(0, 50)}...'
                        : article.content,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          article.isPublished
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color:
                              article.isPublished ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _togglePublishStatus(
                            context, article.id, !article.isPublished),
                        tooltip: article.isPublished ? 'Unpublish' : 'Publish',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditArticleScreen(
                                articleId: article.id,
                                title: article.title,
                                content: article.content,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmation(context, article.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          articleId: article.id,
                          title: article.title,
                          content: article.content,
                          isPublished: article.isPublished,
                          isAdminView: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
