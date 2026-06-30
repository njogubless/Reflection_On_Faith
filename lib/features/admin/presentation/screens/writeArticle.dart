import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/core/constants/firebase_constants.dart';
import 'package:flutter/material.dart';

class WriteArticleScreen extends StatefulWidget {
  const WriteArticleScreen({super.key});

  @override
  State<WriteArticleScreen> createState() => _WriteArticleScreenState();
}

class _WriteArticleScreenState extends State<WriteArticleScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _publishImmediately = false;

  Future<int> _getArticleCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.articleCollection)
        .get();
    return snapshot.docs.length;
  }

  Future<void> _submitArticle() async {
    final ctx = context;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);

    if (title.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (content.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter content')),
      );
      return;
    }

    try {
      final articleCount = await _getArticleCount();
      final today = DateTime.now().toLocal();
      final formattedDate = '${today.day}/${today.month}/${today.year}';

      await FirebaseFirestore.instance
          .collection(FirebaseConstants.articleCollection)
          .add({
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isPublished': _publishImmediately,
        'createdAt': formattedDate,
        'articleNumber': articleCount + 1,
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_publishImmediately
              ? 'Article published successfully!'
              : 'Article saved as draft!'),
          backgroundColor: _publishImmediately ? Colors.green : Colors.orange,
        ),
      );

      if (!ctx.mounted) return;
      Navigator.pop(ctx);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error submitting article: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write New Article')),
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
            Row(
              children: [
                Checkbox(
                  value: _publishImmediately,
                  onChanged: (value) {
                    setState(() {
                      _publishImmediately = value ?? false;
                    });
                  },
                ),
                const Text('Publish immediately'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitArticle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                  _publishImmediately ? 'Publish Article' : 'Save as Draft'),
            ),
          ],
        ),
      ),
    );
  }
}
