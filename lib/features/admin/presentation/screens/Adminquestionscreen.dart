import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:devotion/core/constants/firebase_constants.dart';

class AdminQuestionScreen extends StatefulWidget {
  const AdminQuestionScreen({super.key});

  @override
  State<AdminQuestionScreen> createState() => _AdminQuestionScreenState();
}

class _AdminQuestionScreenState extends State<AdminQuestionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Questions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.questionsCollection)
            .orderBy('askedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final questionId = question.id;
              final questionText = question['question'];
              final isAnswered = question['isAnswered'] ?? false;

              return ListTile(
                title: Text(
                  questionText,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: isAnswered ? Colors.green : Colors.orange,
                ),
                onTap: () => _navigateToAnswerScreen(
                    context, questionId, questionText, isAnswered),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToAnswerScreen(BuildContext context, String questionId,
      String questionText, bool isAnswered) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnswerScreen(
          questionId: questionId,
          questionText: questionText,
          isAnswered: isAnswered,
        ),
      ),
    );
  }
}

class AnswerScreen extends StatefulWidget {
  final String questionId;
  final String questionText;
  final bool isAnswered;

  const AnswerScreen({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.isAnswered,
  });

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  final TextEditingController _answerController = TextEditingController();

  Future<void> _submitAnswer() async {
    final ctx = context;
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);
    final answerText = _answerController.text.trim();
    if (answerText.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection(FirebaseConstants.answersCollection)
            .add({
          'questionId': widget.questionId,
          'answer': answerText,
          'answeredAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection(FirebaseConstants.questionsCollection)
            .doc(widget.questionId)
            .update({
          'isAnswered': true,
        });

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Answer submitted successfully!')),
        );
        if (!ctx.mounted) return;
        Navigator.pop(ctx);
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error submitting answer: $e')),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please provide an answer')),
      );
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
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 5),
            Text(
              widget.questionText,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (widget.isAnswered)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection(FirebaseConstants.answersCollection)
                    .where('questionId', isEqualTo: widget.questionId)
                    .get(),
                builder: (context, answerSnapshot) {
                  if (!answerSnapshot.hasData ||
                      answerSnapshot.data!.docs.isEmpty) {
                    return const Text("No answer found");
                  }
                  final answer = answerSnapshot.data!.docs.first['answer'];
                  return Text(
                    'Answer: $answer',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  );
                },
              ),
            if (!widget.isAnswered) ...[
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                    hintText: 'Enter your answer here...'),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitAnswer,
                child: const Text('Submit Answer'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
