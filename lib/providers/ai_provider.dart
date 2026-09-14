import 'package:flutter/foundation.dart';
import '../contracts/ai_service.dart';
import '../models/chat_message.dart';

/// Quản lý trạng thái tương tác với AI: Chat, Tóm tắt Note, Tạo Quiz.
/// Phụ trách: Member 3
class AIProvider extends ChangeNotifier {
  final AIService aiService;

  AIProvider({required this.aiService});

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tóm tắt note đang mở
  Future<void> summarizeNote(String title, String content) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final summary = await aiService.summarizeNote(title, content);
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.ai,
        text: summary,
      ));
    } catch (e) {
      _errorMessage = 'Lỗi tóm tắt note: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sinh 3 câu hỏi trắc nghiệm ôn thi
  Future<void> generateQuiz(String title, String content) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final quiz = await aiService.generateQuiz(title, content);
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.ai,
        text: quiz,
        isQuiz: true,
      ));
    } catch (e) {
      _errorMessage = 'Lỗi tạo câu hỏi ôn tập: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gửi tin nhắn chat tự do
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: text.trim(),
    );
    _messages.add(userMsg);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await aiService.sendChatMessage(userMsg.text, _messages);
      _messages.add(ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        sender: MessageSender.ai,
        text: reply,
      ));
    } catch (e) {
      _errorMessage = 'Lỗi gửi tin nhắn: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa lịch sử chat
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
