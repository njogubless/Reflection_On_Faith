import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/Q&A/data/models/question_model.dart';
import 'package:devotion/features/Q&A/domain/entities/question.dart';
import 'package:devotion/features/Q&A/domain/repository/question_repository.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final FirebaseFirestore firestore;

  QuestionRepositoryImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> get _questions =>
      firestore.collection('questions');

  @override
  Future<void> submitQuestion(Question question) async {
    final questionModel = QuestionModel(
      id: question.id,
      userId: question.userId,
      question: question.questionText,
      askedAt: question.askedAt,
      answer: question.answer,
      answeredAt: question.answeredAt,
      questionTitle: question.questionTitle,
    );
    await _questions.doc(question.id).set(questionModel.toMap());
  }

  @override
  Future<List<Question>> getQuestions({String? userId}) async {
    QuerySnapshot<Map<String, dynamic>> query;
    if (userId != null) {
      query = await _questions
          .where('userId', isEqualTo: userId)
          .orderBy('askedAt', descending: true)
          .get();
    } else {
      query = await _questions
          .orderBy('askedAt', descending: true)
          .limit(200)
          .get();
    }

    return query.docs
        .map((doc) => QuestionModel.fromMap(doc.data()).toEntity())
        .toList();
  }

  /// Live stream of the most recent questions, newest first. Used instead of
  /// [getQuestions] anywhere the UI needs to reflect answers/new questions
  /// from other users without a manual refresh.
  Stream<List<Question>> watchQuestions({int limit = 200}) {
    return _questions
        .orderBy('askedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromMap(doc.data()).toEntity())
            .toList());
  }

  @override
  Future<void> answerQuestion(String questionId, String answer) async {
    // Stored as an ISO-8601 string (not a bare DateTime) so it round-trips
    // through QuestionModel.fromMap's DateTime.parse the same way askedAt
    // does — passing a raw DateTime here previously wrote a Firestore
    // Timestamp that fromMap could not parse back (crash on next read).
    await _questions.doc(questionId).update({
      'answer': answer,
      'answeredAt': DateTime.now().toIso8601String(),
    });
  }
}
