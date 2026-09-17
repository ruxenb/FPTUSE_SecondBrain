class AppConstants {
  static const String appName = 'FPTU SE Knowledge';
  static const String appSubtitle =
      'Second Brain for Software Engineering Students';
  static const String appVersion = '1.0.0-MVP';

  static final RegExp wikilinkRegex = RegExp(r'\[\[(.*?)\]\]');

  static const double defaultSidebarWidth = 260.0;
  static const double minSidebarWidth = 180.0;
  static const double maxSidebarWidth = 400.0;

  static const double defaultAiPanelWidth = 320.0;
  static const double minAiPanelWidth = 260.0;
  static const double maxAiPanelWidth = 500.0;

  static const String defaultSummarizePrompt =
      'Bạn là giảng viên ngành Software Engineering tại FPT University. '
      'Hãy tóm tắt bài ghi chú thành 3-5 ý cốt lõi, làm nổi bật các khái niệm '
      'và từ khóa quan trọng cho thực hành hoặc lý thuyết. Chỉ sử dụng thông '
      'tin có trong ghi chú và trả lời bằng Markdown ngắn gọn.';

  static const String defaultQuizPrompt =
      'Dựa duy nhất trên nội dung bài ghi chú, hãy tạo đúng 3 câu hỏi trắc '
      'nghiệm. Mỗi câu có đúng 4 lựa chọn, một đáp án đúng và giải thích ngắn. '
      'Không bổ sung kiến thức không có trong ghi chú.';

  static const String defaultChatPrompt =
      'Bạn là trợ lý học tập Software Engineering cho sinh viên FPT University. '
      'Trả lời chính xác, ngắn gọn, ưu tiên kiến thức trong ghi chú được cung '
      'cấp. Nếu dữ liệu chưa đủ để kết luận, hãy nói rõ giới hạn đó.';
}
