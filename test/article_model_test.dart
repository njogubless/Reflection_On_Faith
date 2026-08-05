// ArticleModel parsing — including the isPublished default, which matters
// now that articleStreamProvider filters public reads on it (previously
// unfiltered, so drafts were visible to every signed-in user).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/articles/data/models/article_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArticleModel.fromMap', () {
    test('parses a fully-populated published article', () {
      final timestamp = Timestamp.fromDate(DateTime.utc(2026, 3, 1));
      final article = ArticleModel.fromMap({
        'id': 'a1',
        'title': 'On Grace',
        'content': 'Grace is...',
        'timestamp': timestamp,
        'isPublished': true,
      });

      expect(article.id, 'a1');
      expect(article.title, 'On Grace');
      expect(article.isPublished, isTrue);
      expect(article.createdAt, timestamp.toDate());
    });

    test('defaults isPublished to false when absent (drafts are not public)', () {
      final article = ArticleModel.fromMap({
        'id': 'a2',
        'title': 'Draft',
        'content': 'wip',
      });
      expect(article.isPublished, isFalse);
    });

    test('defaults missing fields to empty strings rather than throwing', () {
      final article = ArticleModel.fromMap(const {});
      expect(article.id, '');
      expect(article.title, '');
      expect(article.content, '');
      expect(article.isPublished, isFalse);
    });
  });
}
