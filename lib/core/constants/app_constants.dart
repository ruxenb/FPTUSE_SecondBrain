/// Các hằng số ứng dụng FPTU SE Knowledge
class AppConstants {
  static const String appName = 'FPTU SE Knowledge';
  static const String appSubtitle = 'Second Brain for Software Engineering Students';
  static const String appVersion = '1.0.0-MVP';

  // Biểu thức Regex bắt liên kết dạng [[Tên Note]]
  static final RegExp wikilinkRegex = RegExp(r'\[\[(.*?)\]\]');

  // Kích thước các cột giao diện Desktop mặc định
  static const double defaultSidebarWidth = 260.0;
  static const double minSidebarWidth = 180.0;
  static const double maxSidebarWidth = 400.0;

  static const double defaultAiPanelWidth = 320.0;
  static const double minAiPanelWidth = 260.0;
  static const double maxAiPanelWidth = 500.0;

  // Prompt Gemini mặc định
  static const String defaultSummarizePrompt =
      'Bạn là giảng viên ngành SE tại FPT University. Hãy tóm tắt các ý cốt lõi '
      'và từ khóa thi thực hành/lý thuyết của bài ghi chép sau thành 3-5 gạch đầu dòng:';

  static const String defaultQuizPrompt =
      'Dựa trên nội dung bài học, hãy tạo đúng 3 câu hỏi trắc nghiệm (mỗi câu 4 lựa chọn A, B, C, D) '
      'kèm đáp án đúng và giải thích ngắn gọn để sinh viên ôn thi:';
}
