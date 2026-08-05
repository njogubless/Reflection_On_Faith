
import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isPublished;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isPublished,
  });

 
  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isPublished: map['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// NOTE: This file previously also defined `ArticleRemoteDatasource` /
// `FirebaseArticleDatasource`, a second, unused Firestore access path that
// read/wrote the collection name `'articles'` (plural) while every live
// screen uses `FirebaseConstants.articleCollection` (`'article'`, singular)
// via `article_provider.dart`. It was dead code — removed rather than fixed,
// since `article_provider.dart` + `ArticleModel` already cover this need.
