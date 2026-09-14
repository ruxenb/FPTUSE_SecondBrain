import 'package:google_generative_ai/google_generative_ai.dart';
import '../contracts/ai_service.dart';
import '../models/chat_message.dart';

/// Triển khai thực tế kết nối Google Gemini API qua package 'google_generative_ai'.
/// Phụ trách triển khai vào Tuần 2: Member 3
class GeminiAIService implements AIService {
  final String apiKey;
  final String modelName;

  GeminiAIService({
    required this.apiKey,
    this.modelName = 'gemini-1.5-flash',
  });

  GenerativeModel get _model => GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

  @override
  Future<String> summarizeNote(String noteTitle, String noteContent) async {
    final prompt = 'Bạn là trợ lý học tập môn Software Engineering tại FPT University. '
        'Hãy đọc và tóm tắt bài note "$noteTitle" thành 3-5 gạch đầu dòng cốt lõi ôn thi:\n\n$noteContent';
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Không nhận được phản hồi từ AI.';
  }

  @override
  Future<String> generateQuiz(String noteTitle, String noteContent) async {
    final prompt = 'Dựa trên bài học "$noteTitle", hãy tạo 3 câu hỏi trắc nghiệm (A, B, C, D) '
        'kèm đáp án đúng và giải thích ngắn gọn để sinh viên ôn thi:\n\n$noteContent';
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Không tạo được Quiz.';
  }

  @override
  Future<String> sendChatMessage(String prompt, List<ChatMessage> conversationHistory) async {
    // Chuyển đổi lịch sử chat
    final historyContents = conversationHistory.map((m) {
      if (m.sender == MessageSender.user) {
        return Content.text(m.text);
      } else {
        return Content.model([TextPart(m.text)]);
      }
    }).toList();

    final chat = _model.startChat(history: historyContents);
    final response = await chat.sendMessage(Content.text(prompt));
    return response.text ?? 'Không nhận được câu trả lời từ AI.';
  }
}
