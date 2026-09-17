import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/models/quiz_question.dart';

void main() {
  group('QuizQuestion validation', () {
    test('accepts valid quiz question', () {
      final question = QuizQuestion(
        question: 'What is Provider used for?',
        options: const ['State', 'Build', 'Git', 'Database'],
        correctIndex: 0,
        explanation: 'Provider manages application state.',
      );

      expect(question.options, hasLength(4));
    });

    test('rejects empty question', () {
      expect(
        () => QuizQuestion(
          question: '   ',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Explanation',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty option', () {
      expect(
        () => QuizQuestion(
          question: 'Question',
          options: const ['A', '', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Explanation',
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate options case-insensitively', () {
      expect(
        () => QuizQuestion(
          question: 'Question',
          options: const ['Provider', 'provider', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Explanation',
        ),
        throwsArgumentError,
      );
    });

    test('rejects out-of-range answer index', () {
      expect(
        () => QuizQuestion(
          question: 'Question',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 9,
          explanation: 'Explanation',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty explanation', () {
      expect(
        () => QuizQuestion(
          question: 'Question',
          options: const ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('fromJson rejects non-string option payload', () {
      expect(
        () => QuizQuestion.fromJson({
          'question': 'Question',
          'options': ['A', 'B', 3, 'D'],
          'correctIndex': 0,
          'explanation': 'Explanation',
        }),
        throwsFormatException,
      );
    });
  });
}
