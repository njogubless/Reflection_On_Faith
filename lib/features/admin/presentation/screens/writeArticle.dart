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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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

    setState(() => _isSubmitting = true);
    try {
      final today = DateTime.now().toLocal();
      final formattedDate = '${today.day}/${today.month}/${today.year}';

      // NOTE: this used to also read the entire article collection just to
      // compute a cosmetic `articleNumber` (a full collection scan on every
      // single submission, cost growing with total article count forever).
      // That field wasn't displayed anywhere, so it's dropped instead of
      // fixed — ordering already comes from `timestamp`.
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.articleCollection)
          .add({
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isPublished': _publishImmediately,
        'createdAt': formattedDate,
      });

      if (!ctx.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_publishImmediately
              ? 'Article published successfully!'
              : 'Article saved as draft!'),
          backgroundColor: _publishImmediately ? Colors.green : Colors.orange,
        ),
      );

      Navigator.pop(ctx);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Could not save the article. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              onPressed: _isSubmitting ? null : _submitArticle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_publishImmediately
                      ? 'Publish Article'
                      : 'Save as Draft'),
            ),
          ],
        ),
      ),
    );
  }
}
