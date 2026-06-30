import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devotion/core/constants/firebase_constants.dart';
import 'package:devotion/core/providers/firebase_providers.dart';
import 'package:devotion/features/articles/data/models/article_model.dart';

final articleStreamProvider = StreamProvider<List<ArticleModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection(FirebaseConstants.articleCollection)
      .orderBy('timestamp', descending: true)
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

final articleListProvider = FutureProvider<List<ArticleModel>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final snapshot = await firestore
      .collection(FirebaseConstants.articleCollection)
      .orderBy('timestamp', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    return ArticleModel.fromMap({
      ...doc.data(),
      'id': doc.id,
    });
  }).toList();
});
