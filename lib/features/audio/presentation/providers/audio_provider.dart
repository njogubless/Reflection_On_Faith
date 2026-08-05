import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/core/constants/firebase_constants.dart';
import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single, canonical list of publicly-visible sermons: admin
/// bulk-uploaded audio (`Sermons`, always visible) merged with self-recorded
/// sermons that have cleared admin review (`Devotion`, `approvalStatus ==
/// 'approved'` only).
///
/// This used to be two disconnected implementations — `AudioScreen`'s
/// `audioProvider` read only `Sermons` (via a repository with a confusing
/// Sermons → audioFiles → raw-Storage-listing fallback chain), while a
/// separate `DevotionPage` merged `Devotion` + `Sermons` correctly. A sermon
/// recorded and approved in-app would appear on one tab but not the other.
/// Both screens now watch this one stream.
final audioProvider = StreamProvider<List<AudioFile>>((ref) {
  final firestore = FirebaseFirestore.instance;

  final devotionStream = firestore
      .collection(FirebaseConstants.devotionCollection)
      .where('approvalStatus', isEqualTo: 'approved')
      .limit(kAudioQueryLimit)
      .snapshots();
  final sermonsStream = firestore
      .collection(FirebaseConstants.sermonCollection)
      .limit(kAudioQueryLimit)
      .snapshots();

  return _combineSnapshots(devotionStream, sermonsStream).map((pair) {
    final allFiles = [
      ...pair.$1.docs.map(AudioFile.fromSnapshot),
      ...pair.$2.docs.map(AudioFile.fromSnapshot),
    ];
    allFiles.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return allFiles;
  });
});

/// See kDefaultQueryLimit in article_provider.dart for the same reasoning.
const int kAudioQueryLimit = 200;

/// The signed-in user's own recorded sermons, **regardless of
/// approvalStatus** — unlike [audioProvider] (approved-only, for the public
/// sermon list), this is for the Profile screen's "My Sermons" tab, where a
/// user needs to see their pending/rejected submissions too, not just the
/// ones that made it through review.
final myRecordingsProvider = StreamProvider<List<AudioFile>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection(FirebaseConstants.devotionCollection)
      .where('uploaderId', isEqualTo: uid)
      .limit(kAudioQueryLimit)
      .snapshots()
      .map((snapshot) {
    final files = snapshot.docs.map(AudioFile.fromSnapshot).toList();
    files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return files;
  });
});

Stream<(QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>)>
    _combineSnapshots(
  Stream<QuerySnapshot<Map<String, dynamic>>> streamA,
  Stream<QuerySnapshot<Map<String, dynamic>>> streamB,
) {
  final controller = StreamController<
      (QuerySnapshot<Map<String, dynamic>>, QuerySnapshot<Map<String, dynamic>>)>.broadcast();
  QuerySnapshot<Map<String, dynamic>>? latestA;
  QuerySnapshot<Map<String, dynamic>>? latestB;
  void tryEmit() {
    if (latestA != null && latestB != null) controller.add((latestA!, latestB!));
  }

  final subA = streamA.listen((snap) {
    latestA = snap;
    tryEmit();
  }, onError: controller.addError);
  final subB = streamB.listen((snap) {
    latestB = snap;
    tryEmit();
  }, onError: controller.addError);

  controller.onCancel = () {
    subA.cancel();
    subB.cancel();
  };
  return controller.stream;
}
