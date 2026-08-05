// Regression test for a bug found in QuestionRepositoryImpl.answerQuestion:
// it used to write `'answeredAt': DateTime.now()` directly, which
// cloud_firestore silently stores as a Timestamp — but QuestionModel.fromMap
// parses `answeredAt` with DateTime.parse(), which throws on anything that
// isn't a String. Any question that had ever been answered would crash the
// Q&A screen the next time its list was fetched. The fix stores an
// ISO-8601 string instead, matching what askedAt already did.

import 'package:devotion/features/Q&A/data/models/question_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionModel.toMap / fromMap round-trip', () {
    test('askedAt and answeredAt survive as ISO-8601 strings', () {
      final askedAt = DateTime.utc(2026, 1, 1, 12);
      final answeredAt = DateTime.utc(2026, 1, 2, 9, 30);

      final model = QuestionModel(
        id: 'q1',
        userId: 'uid_1',
        question: 'What is grace?',
        questionTitle: 'What is grace?',
        answer: 'Unmerited favor.',
        askedAt: askedAt,
        answeredAt: answeredAt,
      );

      // This is what actually gets sent to Firestore.
      final map = model.toMap();
      expect(map['askedAt'], isA<String>());
      expect(map['answeredAt'], isA<String>());

      // This is what actually gets read back from a snapshot — must not
      // throw, and must reproduce the original values.
      final restored = QuestionModel.fromMap(map);
      expect(restored.askedAt, askedAt);
      expect(restored.answeredAt, answeredAt);
      expect(restored.answer, 'Unmerited favor.');
    });

    test('an unanswered question has a null answer and answeredAt', () {
      final model = QuestionModel(
        id: 'q2',
        userId: 'uid_2',
        question: 'Why do we pray?',
        questionTitle: 'Why do we pray?',
        askedAt: DateTime.utc(2026, 1, 1),
      );

      final restored = QuestionModel.fromMap(model.toMap());
      expect(restored.answer, isNull);
      expect(restored.answeredAt, isNull);
    });

    test(
        'fromMap does not throw when answeredAt is an ISO string produced '
        'by the fixed QuestionRepositoryImpl.answerQuestion', () {
      // Mirrors exactly what the repository writes today.
      final map = {
        'id': 'q3',
        'userId': 'uid_3',
        'question': 'Q',
        'questionTitle': 'Q',
        'askedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'answer': 'A',
        'answeredAt': DateTime.now().toIso8601String(),
      };

      expect(() => QuestionModel.fromMap(map), returnsNormally);
    });
  });
}
