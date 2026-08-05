import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/Q&A/data/repository/question_repository_impl.dart';
import 'package:devotion/features/Q&A/domain/entities/question.dart';
import 'package:devotion/features/Q&A/domain/usecases/answer_questions.dart';
import 'package:devotion/features/Q&A/domain/usecases/get_questions.dart';
import 'package:devotion/features/Q&A/domain/usecases/submit_question.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final questionRepositoryProvider = Provider<QuestionRepositoryImpl>((ref) {
  final firestore = FirebaseFirestore.instance;
  return QuestionRepositoryImpl(firestore);
});

/// Live-updating question list (newest first), used by both the public Q&A
/// screen and the admin answer queue so answers/new questions from other
/// sessions show up without a manual refresh.
final questionsStreamProvider = StreamProvider<List<Question>>((ref) {
  return ref.watch(questionRepositoryProvider).watchQuestions();
});

final submitQuestionUseCaseProvider = Provider<SubmitQuestionUseCase>(
  (ref) {
    final repository = ref.watch(questionRepositoryProvider);
    return SubmitQuestionUseCase(repository);
  },
);

final getQuestionsUseCaseProvider = Provider<GetQuestionsUseCase>(
  (ref) {
    final repository = ref.watch(questionRepositoryProvider);
    return GetQuestionsUseCase(repository);
  },
);

final answerQuestionUseCaseProvider = Provider<AnswerQuestionUseCase>(
  (ref) {
    final repository = ref.watch(questionRepositoryProvider);
    return AnswerQuestionUseCase(repository);
  },
);
