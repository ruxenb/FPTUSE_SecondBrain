import 'package:flutter/foundation.dart';

import '../contracts/ai_service.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';

class AIProvider extends ChangeNotifier {
  AIProvider({required this.aiService});

  final AIService aiService;

  final List<ChatMessage> _messages = [];
  List<QuizQuestion> _quizQuestions = const [];
  bool _isLoading = false;
  String? _errorMessage;
  int _requestVersion = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<QuizQuestion> get quizQuestions => List.unmodifiable(_quizQuestions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasQuiz => _quizQuestions.isNotEmpty;

  Future<void> summarizeNote(String title, String content) async {
    if (!_canStartRequest()) {
      return;
    }
    if (content.trim().isEmpty) {
      _setError('Không thể tóm tắt vì ghi chú đang trống.');
      return;
    }

    final requestVersion = _beginRequest();
    try {
      final summary = await aiService.summarizeNote(title, content);
      if (!_isCurrentRequest(requestVersion)) {
        return;
      }
      _messages.add(
        ChatMessage(
          id: _newMessageId(),
          sender: MessageSender.ai,
          text: summary,
          kind: MessageKind.summary,
        ),
      );
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, requestVersion);
    } finally {
      _finishRequest(requestVersion);
    }
  }

  Future<void> generateQuiz(String title, String content) async {
    if (!_canStartRequest()) {
      return;
    }
    if (content.trim().isEmpty) {
      _setError('Không thể tạo quiz vì ghi chú đang trống.');
      return;
    }

    final requestVersion = _beginRequest();
    try {
      final questions = await aiService.generateQuiz(title, content);
      if (!_isCurrentRequest(requestVersion)) {
        return;
      }
      if (questions.length != 3) {
        throw const AIServiceException(
          'AI không trả về đúng 3 câu hỏi. Vui lòng thử lại.',
        );
      }
      _quizQuestions = List.unmodifiable(questions);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, requestVersion);
    } finally {
      _finishRequest(requestVersion);
    }
  }

  Future<void> sendMessage(
    String text, {
    String? noteTitle,
    String? noteContent,
  }) async {
    final prompt = text.trim();
    if (prompt.isEmpty || !_canStartRequest()) {
      return;
    }

    final history = List<ChatMessage>.from(_messages);
    _messages.add(
      ChatMessage(
        id: _newMessageId(),
        sender: MessageSender.user,
        text: prompt,
      ),
    );

    final contextualPrompt = _buildContextualPrompt(
      prompt,
      noteTitle: noteTitle,
      noteContent: noteContent,
    );

    final requestVersion = _beginRequest(notify: true);
    try {
      final response = await aiService.sendChatMessage(
        contextualPrompt,
        history,
      );
      if (!_isCurrentRequest(requestVersion)) {
        return;
      }
      _messages.add(
        ChatMessage(
          id: _newMessageId(),
          sender: MessageSender.ai,
          text: response,
        ),
      );
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, requestVersion);
    } finally {
      _finishRequest(requestVersion);
    }
  }

  void clearMessages() {
    _requestVersion++;
    _messages.clear();
    _quizQuestions = const [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  bool _canStartRequest() => !_isLoading;

  int _beginRequest({bool notify = true}) {
    final version = ++_requestVersion;
    _isLoading = true;
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
    return version;
  }

  void _finishRequest(int requestVersion) {
    if (!_isCurrentRequest(requestVersion)) {
      return;
    }
    _isLoading = false;
    notifyListeners();
  }

  bool _isCurrentRequest(int version) => version == _requestVersion;

  void _handleError(Object error, StackTrace stackTrace, int requestVersion) {
    if (!_isCurrentRequest(requestVersion)) {
      return;
    }
    _errorMessage = error is AIServiceException
        ? error.message
        : 'Không thể kết nối với trợ lý AI. Vui lòng thử lại.';
    debugPrintStack(label: 'AI request failed: $error', stackTrace: stackTrace);
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _buildContextualPrompt(
    String prompt, {
    String? noteTitle,
    String? noteContent,
  }) {
    final content = noteContent?.trim();
    if (content == null || content.isEmpty) {
      return prompt;
    }
    return '''
Ghi chú hiện tại: ${noteTitle?.trim().isNotEmpty == true ? noteTitle!.trim() : 'Không có tiêu đề'}

Nội dung ghi chú:
$content

Câu hỏi của sinh viên:
$prompt
'''
        .trim();
  }

  String _newMessageId() => DateTime.now().microsecondsSinceEpoch.toString();
}
