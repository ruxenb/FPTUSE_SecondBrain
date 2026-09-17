import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/models/quiz_question.dart';
import 'package:fptu_se_second_brain/screens/ai/ai_quiz_card.dart';

void main() {
  testWidgets('quiz card allows selecting and revealing an answer', (
    WidgetTester tester,
  ) async {
    final questions = [
      QuizQuestion(
        question: 'Provider dùng để làm gì?',
        options: ['Quản lý state', 'Build native', 'Lưu Git', 'Vẽ icon'],
        correctIndex: 0,
        explanation: 'Provider chịu trách nhiệm quản lý state.',
      ),
      QuizQuestion(
        question: 'UI nên gọi lớp nào?',
        options: ['AIService', 'Provider', 'dart:io', 'Git'],
        correctIndex: 1,
        explanation: 'UI gọi Provider để giữ đúng phân tầng.',
      ),
      QuizQuestion(
        question: 'Quiz cần bao nhiêu lựa chọn?',
        options: ['1', '2', '3', '4'],
        correctIndex: 3,
        explanation: 'Mỗi câu có bốn lựa chọn A, B, C, D.',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: AIQuizCard(questions: questions),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Câu 1.'), findsOneWidget);
    expect(find.textContaining('Câu 2.'), findsOneWidget);
    expect(find.textContaining('Câu 3.'), findsOneWidget);

    await tester.tap(find.text('A. Quản lý state'));
    await tester.pump();
    await tester.tap(find.text('Xem đáp án').first);
    await tester.pump();

    expect(find.text('Bạn đã chọn đúng.'), findsOneWidget);
    expect(
      find.text('Provider chịu trách nhiệm quản lý state.'),
      findsOneWidget,
    );
  });
}
