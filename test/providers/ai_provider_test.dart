import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/contracts/ai_service.dart';
import 'package:fptu_se_second_brain/models/chat_message.dart';
import 'package:fptu_se_second_brain/models/quiz_question.dart';
import 'package:fptu_se_second_brain/providers/ai_provider.dart';

class _FakeAIService implements AIService {
  List<ChatMessage>? receivedHistory;

  @override
  Future<List<QuizQuestion>> generateQuiz(
    String noteTitle,
    String noteContent,
  ) async {
    return List.generate(
      3,
      (index) => QuizQuestion(
        question: 'Question $index',
        options: const ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        explanation: 'Explanation $index',
      ),
    );
  }

  @override
  Future<String> sendChatMessage(
    String prompt,
    List<ChatMessage> conversationHistory,
  ) async {
    receivedHistory = List.of(conversationHistory);
    return 'AI response';
  }

  @override
  Future<String> summarizeNote(String noteTitle, String noteContent) async {
    return 'Summary';
  }
}

void main() {
  group('AIProvider', () {
    test('summarizeNote adds an AI summary message', () async {
      final provider = AIProvider(aiService: _FakeAIService());

      await provider.summarizeNote('Title', 'Content');

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.sender, MessageSender.ai);
      expect(provider.messages.single.kind, MessageKind.summary);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('generateQuiz stores exactly three questions', () async {
      final provider = AIProvider(aiService: _FakeAIService());

      await provider.generateQuiz('Title', 'Content');

      expect(provider.quizQuestions, hasLength(3));
      expect(provider.hasQuiz, isTrue);
    });

    test('sendMessage does not duplicate current prompt in history', () async {
      final service = _FakeAIService();
      final provider = AIProvider(aiService: service);

      await provider.sendMessage('First question');
      await provider.sendMessage('Second question');
      expect(service.receivedHistory, hasLength(2));
      expect(
        service.receivedHistory!.where(
          (message) => message.text == 'Second question',
        ),
        isEmpty,
      );
      expect(provider.messages, hasLength(4));
    });

    test('empty summary content is rejected before calling service', () async {
      final provider = AIProvider(aiService: _FakeAIService());

      await provider.summarizeNote('Title', '   ');

      expect(provider.messages, isEmpty);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('clearMessages clears chat and quiz state', () async {
      final provider = AIProvider(aiService: _FakeAIService());

      await provider.sendMessage('Question');
      await provider.generateQuiz('Title', 'Content');
      provider.clearMessages();

      expect(provider.messages, isEmpty);
      expect(provider.quizQuestions, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });
  });
}
