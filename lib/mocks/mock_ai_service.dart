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
  Future<String> generateQuiz(String noteTitle, String noteContent) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return '''### 📝 Bộ 3 Câu Hỏi Ôn Tập: `$noteTitle`

**Câu 1:** Trong kiến trúc Clean Lean của ứng dụng, Widget UI được phép gọi trực tiếp package nào?
- A. `dart:io`
- B. `google_generative_ai`
- C. `Provider` (hoặc ChangeNotifier)  ✅ *(Chính xác: Giúp bảo đảm tính lỏng lẻo của mã nguồn)*
- D. Không được gọi bất kỳ package nào

---
**Câu 2:** Mục đích chính của việc sử dụng cú pháp `[[...]]` trong ứng dụng là gì?
- A. Định dạng in đậm văn bản
- B. Tạo liên kết nội bộ 2 chiều giữa các bài ghi chép  ✅
- C. Chèn ảnh từ ổ cứng
- D. Gửi dữ liệu lên máy chủ đám mây

---
**Câu 3:** Tại sao nhóm sinh viên cần tạo lớp `MockService` ngay từ Day 2?
- A. Để hoàn thành chỉ tiêu code dòng lệnh
- B. Để có thể phát triển giao diện UI song song mà không phụ thuộc API thật  ✅
- C. Vì Flutter bắt buộc phải có Mock
- D. Để tăng dung lượng file nộp bài''';
  }

  @override
  Future<String> sendChatMessage(String prompt, List<ChatMessage> conversationHistory) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Chào bạn sinh viên FPTU! Mình đã nhận được câu hỏi: "$prompt". Trong mô hình Second Brain, các bài học của bạn đang được liên kết rất chặt chẽ!';
  }
}
