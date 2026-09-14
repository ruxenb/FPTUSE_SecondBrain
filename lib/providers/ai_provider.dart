import 'package:flutter/foundation.dart';
import '../contracts/ai_service.dart';
import '../models/chat_message.dart';

/// Quản lý trạng thái tương tác với AI: Chat, Tóm tắt Note, Tạo Quiz.
/// [MEMBER 3] sẽ hoàn thiện logic tại đây theo Task T3.3.
class AIProvider extends ChangeNotifier {
  final AIService aiService;

  AIProvider({required this.aiService});

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  // TODO: [Member 3] Hiện thực hàm summarizeNote(title, content)
  Future<void> summarizeNote(String title, String content) async {
    _isLoading = true;
    notifyListeners();

    try {
      final summary = await aiService.summarizeNote(title, content);
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.ai,
        text: summary,
      ));
    } catch (e) {
      debugPrint('Error summarizing note: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: [Member 3] Hiện thực hàm generateQuiz(title, content) và sendMessage(prompt)
}
