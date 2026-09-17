import '../contracts/ai_service.dart';
import '../core/constants/ai_runtime_config.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';

class MockAIService implements AIService {
  MockAIService({AIRuntimeConfig? config})
    : _config = config ?? AIRuntimeConfig.environment;

  final AIRuntimeConfig _config;

  @override
  Future<String> summarizeNote(String noteTitle, String noteContent) async {
    await Future.delayed(_config.mockDelay);
    return '''
### Tóm tắt: $noteTitle

- Xác định các khái niệm và mục tiêu chính của bài học.
- Ghi nhớ luồng xử lý và trách nhiệm của từng thành phần.
- Liên hệ ví dụ thực hành với lý thuyết trong ghi chú.
- Ưu tiên các từ khóa và quy tắc có thể xuất hiện trong bài kiểm tra.
'''
        .trim();
  }

  @override
  Future<List<QuizQuestion>> generateQuiz(
    String noteTitle,
    String noteContent,
  ) async {
    await Future.delayed(_config.mockDelay);
    return [
      QuizQuestion(
        question: 'Mục tiêu chính của kiến trúc phân tầng là gì?',
        options: const [
          'Tăng phụ thuộc giữa các tầng',
          'Tách trách nhiệm giữa các thành phần',
          'Đưa toàn bộ logic vào UI',
          'Loại bỏ state management',
        ],
        correctIndex: 1,
        explanation:
            'Tách trách nhiệm giúp hệ thống dễ bảo trì, kiểm thử và mở rộng.',
      ),
      QuizQuestion(
        question:
            'Provider trong ứng dụng chịu trách nhiệm chính cho phần nào?',
        options: const [
          'Quản lý state và điều phối logic',
          'Đọc file trực tiếp trong Widget',
          'Biên dịch mã nguồn',
          'Vẽ giao diện hệ điều hành',
        ],
        correctIndex: 0,
        explanation: 'Provider quản lý trạng thái và gọi service thay vì để Widget làm trực tiếp.',
      ),
      QuizQuestion(
        question: 'Widget nên giao tiếp với AI theo luồng nào?',
        options: const [
          'Widget gọi Gemini trực tiếp',
          'Widget gọi dart:io rồi gọi Gemini',
          'Widget gọi Provider, Provider gọi AIService',
          'Widget ghi dữ liệu trực tiếp vào Git',
        ],
        correctIndex: 2,
        explanation:
            'Luồng UI -> Provider -> AIService giữ đúng phân tầng của dự án.',
      ),
    ];
  }

  @override
  Future<String> sendChatMessage(
    String prompt,
    List<ChatMessage> conversationHistory,
  ) async {
    await Future.delayed(_config.mockDelay);
    return 'Mock AI đã nhận câu hỏi: "$prompt". '
        'Hãy chuyển sang Gemini service khi cần kiểm thử API thực tế.';
  }
}
