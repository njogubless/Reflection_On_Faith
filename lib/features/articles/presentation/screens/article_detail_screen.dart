import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:devotion/core/constants/firebase_constants.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  final String title;
  final String content;
  final bool isPublished;
  final bool isAdminView;

  const ArticleDetailScreen({
    super.key,
    required this.articleId,
    required this.title,
    required this.content,
    required this.isPublished,
    this.isAdminView = true,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('comments').add({
        'articleId': widget.articleId,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Comment added successfully')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.isAdminView)
                    Chip(
                      label: Text(
                        widget.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          color:
                              widget.isPublished ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: widget.isPublished
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(widget.content, style: const TextStyle(fontSize: 16)),
              const Divider(height: 32),
              const Text("Comments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comments')
                    .where('articleId', isEqualTo: widget.articleId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error loading comments: ${snapshot.error}');
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text("No comments yet."),
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

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['comment'],
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timestamp != null
                                    ? _formatTimestamp(timestamp)
                                    : 'Just now',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (widget.isAdminView)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _deleteComment(comments[index].id),
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
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
          .collection('comments')
          .doc(commentId)
          .delete();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Comment deleted')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting comment: $e')),
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
        SnackBar(content: Text('Error updating article: $e')),
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
