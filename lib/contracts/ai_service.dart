import '../models/chat_message.dart';
import '../models/quiz_question.dart';

abstract class AIService {
  Future<String> summarizeNote(String noteTitle, String noteContent);

  Future<List<QuizQuestion>> generateQuiz(String noteTitle, String noteContent);

  Future<String> sendChatMessage(
    String prompt,
    List<ChatMessage> conversationHistory,
  );
}

class AIServiceException implements Exception {
  const AIServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
