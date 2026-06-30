import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/Q&A/data/repository/question_repository_impl.dart';
import 'package:devotion/features/Q&A/domain/entities/question.dart';
import 'package:devotion/features/Q&A/domain/usecases/answer_questions.dart';
import 'package:devotion/features/Q&A/domain/usecases/get_questions.dart';
import 'package:devotion/features/Q&A/domain/usecases/submit_question.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionNotifier extends Notifier<List<Question>> {
  @override
  List<Question> build() {
    // Kick off initial fetch after the first frame.
    Future.microtask(fetchQuestions);
    return [];
  }

  Future<void> submitQuestion(Question question) async {
    await ref.read(submitQuestionUseCaseProvider).execute(question);
    await fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    state = await ref.read(getQuestionsUseCaseProvider).execute();
  }

  Future<void> answerQuestion(String questionId, String answerText) async {
    await ref
        .read(answerQuestionUseCaseProvider)
        .execute(questionId, answerText);
    await fetchQuestions();
  }
}

final questionProvider = NotifierProvider<QuestionNotifier, List<Question>>(
  QuestionNotifier.new,
);

final questionRepositoryProvider = Provider<QuestionRepositoryImpl>((ref) {
  final firestore = FirebaseFirestore.instance;
  return QuestionRepositoryImpl(firestore);
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
