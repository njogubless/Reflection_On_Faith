import 'package:devotion/features/Q&A/domain/entities/question.dart';
import 'package:devotion/features/Q&A/presentation/providers/question_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminQuestionScreen extends ConsumerWidget {
  const AdminQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Questions')),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('No questions yet'));
          }
          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final isAnswered =
                  question.answer != null && question.answer!.isNotEmpty;

              return ListTile(
                title: Text(
                  question.questionText,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(isAnswered ? 'Answered' : 'Awaiting answer'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: isAnswered ? Colors.green : Colors.orange,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnswerScreen(question: question),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load questions: $error')),
      ),
    );
  }
}

class AnswerScreen extends ConsumerStatefulWidget {
  final Question question;

  const AnswerScreen({super.key, required this.question});

  @override
  ConsumerState<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends ConsumerState<AnswerScreen> {
  late final TextEditingController _answerController =
      TextEditingController(text: widget.question.answer ?? '');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  bool get _isAnswered =>
      widget.question.answer != null && widget.question.answer!.isNotEmpty;

  Future<void> _submitAnswer() async {
    final ctx = context;
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);
    final answerText = _answerController.text.trim();
    if (answerText.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please provide an answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(answerQuestionUseCaseProvider)
          .execute(widget.question.id, answerText);

      if (!ctx.mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Answer submitted successfully!')),
      );
      Navigator.pop(ctx);
    } catch (e) {
      if (!ctx.mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Could not submit the answer. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answer Question')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(widget.question.questionText, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (_isAnswered) ...[
              Text(
                'Current answer:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                hintText: 'Enter your answer here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnswer,
              child: Text(_isAnswered ? 'Update Answer' : 'Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }
}
