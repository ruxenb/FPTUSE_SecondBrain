import '../models/chat_message.dart';

/// Interface cung cấp năng lực AI hỗ trợ học tập (Gemini API).
/// Phụ trách: Member 3
abstract class AIService {
  /// Tóm tắt nội dung bài note thành 3-5 gạch đầu dòng cốt lõi
  Future<String> summarizeNote(String noteTitle, String noteContent);

  /// Trò chuyện tự do với AI theo ngữ cảnh bài học
  Future<String> sendChatMessage(String prompt, List<ChatMessage> conversationHistory);
}
