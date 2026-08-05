import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devotion/core/constants/firebase_constants.dart';
import 'package:devotion/core/providers/firebase_providers.dart';
import 'package:devotion/features/articles/data/models/article_model.dart';

/// Cap on how many documents a single list screen pulls in one go. None of
/// these collections have pagination UI (yet), so this just keeps a single
/// listener from silently downloading an unbounded, ever-growing collection
/// as content accumulates.
const int kDefaultQueryLimit = 200;

/// Publicly-visible articles only (`isPublished == true`), newest first.
/// This is what every non-admin screen (`ArticlePage`, search) should watch.
/// Previously this had no `isPublished` filter at all, so drafts were
/// visible to every signed-in user before an admin published them.
final articleStreamProvider = StreamProvider<List<ArticleModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection(FirebaseConstants.articleCollection)
      .where('isPublished', isEqualTo: true)
      .orderBy('timestamp', descending: true)
      .limit(kDefaultQueryLimit)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ArticleModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  });
});

/// All articles regardless of publish state — for the admin management
/// screen only. Firestore rules restrict reads of unpublished articles to
/// admins, so this must never be watched from a non-admin screen.
final allArticlesStreamProvider = StreamProvider<List<ArticleModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection(FirebaseConstants.articleCollection)
      .orderBy('timestamp', descending: true)
      .limit(kDefaultQueryLimit)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ArticleModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  });
});
