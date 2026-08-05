import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:devotion/core/constants/firebase_constants.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  final String title;
  final String content;
  final bool isPublished;

  /// Only the admin article-management screen should pass `true`. It's what
  /// shows the publish/draft chip and lets the viewer delete other people's
  /// comments — this used to default to `true`, which meant every regular
  /// reader saw and could use admin-only comment moderation controls.
  final bool isAdminView;

  const ArticleDetailScreen({
    super.key,
    required this.articleId,
    required this.title,
    required this.content,
    required this.isPublished,
    this.isAdminView = false,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (comment.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection(FirebaseConstants.commentsCollection).add({
        'articleId': widget.articleId,
        'comment': comment,
        'userId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Comment added successfully')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Could not add your comment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.isAdminView) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(widget.isPublished ? 'Published' : 'Draft'),
                      backgroundColor: widget.isPublished
                          ? Colors.green.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: widget.isPublished
                            ? Colors.green.shade700
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(widget.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
              const Divider(height: 32),
              Text("Comments", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(FirebaseConstants.commentsCollection)
                    .where('articleId', isEqualTo: widget.articleId)
                    .orderBy('timestamp', descending: true)
                    .limit(200)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Could not load comments.',
                      style: TextStyle(color: theme.colorScheme.error),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "No comments yet — be the first to comment.",
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment =
                          comments[index].data() as Map<String, dynamic>;
                      final timestamp = comment['timestamp'] as Timestamp?;
                      final currentUid =
                          FirebaseAuth.instance.currentUser?.uid;
                      final canDelete = widget.isAdminView ||
                          (currentUid != null &&
                              comment['userId'] == currentUid);
                      final authorName = comment['authorName'] as String? ?? 'Anonymous';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(authorName,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(comment['comment'], style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      timestamp != null
                                          ? _formatTimestamp(timestamp)
                                          : 'Just now',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (canDelete)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              _deleteComment(comments[index].id),
                                          style: TextButton.styleFrom(
                                            foregroundColor: theme.colorScheme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Add a comment...',
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.commentsCollection)
          .doc(commentId)
          .delete();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Comment deleted')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Could not delete the comment. Please try again.')),
      );
    }
  }
}

class EditArticleScreen extends StatefulWidget {
  final String articleId;
  final String title;
  final String content;

  const EditArticleScreen({
    super.key,
    required this.articleId,
    required this.title,
    required this.content,
  });

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateArticle() async {
    final ctx = context;
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.articleCollection)
          .doc(widget.articleId)
          .update({
        'title': title,
        'content': content,
        'updatedAt': DateTime.now().toLocal().toString(),
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Article updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (!ctx.mounted) return;
      Navigator.pop(ctx);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Could not update the article. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Article')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Article Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Article Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateArticle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Update Article'),
            ),
          ],
        ),
      ),
    );
  }
}
