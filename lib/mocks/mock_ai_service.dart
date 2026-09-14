import '../contracts/ai_service.dart';
import '../models/chat_message.dart';

/// Triển khai giả lập phản hồi của Gemini AI để kiểm tra UI ngay Day 2 mà không cần API Key.
/// Phụ trách: Member 3
class MockAIService implements AIService {
  @override
  Future<String> summarizeNote(String noteTitle, String noteContent) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Giả lập độ trễ AI
    return '''### ⚡ Tóm Tắt Trọng Tâm Note: `$noteTitle`
* **Kiến trúc cốt lõi:** Phân định rõ 3 tầng (UI, Provider, Services). Không gọi trực tiếp File I/O trong Widget.
* **State Management:** Khuyến nghị dùng Provider để tối ưu vòng đời widget.
* **Liên kết tri thức:** Sử dụng cú pháp `[[WikiLinks]]` để định hình mạng lưới Second Brain.
* **Lưu ý thi Lab:** Đảm bảo mock implementations hoạt động ổn định trước khi cắm real API.''';
  }

  @override
  Future<String> sendChatMessage(String prompt, List<ChatMessage> conversationHistory) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Chào bạn sinh viên FPTU! Mình đã nhận được câu hỏi: "$prompt". Trong mô hình Second Brain, các bài học của bạn đang được liên kết rất chặt chẽ!';
  }
}
