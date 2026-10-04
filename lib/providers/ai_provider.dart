import 'package:flutter/foundation.dart';

import '../contracts/ai_service.dart';
import '../core/constants/ai_runtime_config.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/note_chunk.dart';
import '../models/quiz_question.dart';
import '../services/rag_pipeline.dart';

class AIProvider extends ChangeNotifier {
  AIProvider({
    required this.aiService,
    this.ragPipeline,
    int? maxHistoryMessages,
    bool? clearStateOnNoteChange,
  }) : _maxHistoryMessages =
           maxHistoryMessages ?? AIRuntimeConfig.environment.maxHistoryMessages,
       _clearStateOnNoteChange =
           clearStateOnNoteChange ??
           AIRuntimeConfig.environment.clearStateOnNoteChange;

  final AIService aiService;

  /// RAG pipeline (null nếu RAG chưa sẵn sàng, fallback về AI trực tiếp).
  final RagPipeline? ragPipeline;

  final int _maxHistoryMessages;
  final bool _clearStateOnNoteChange;

  final List<ChatMessage> _messages = [];
  List<QuizQuestion> _quizQuestions = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeNotePath;
  int _requestVersion = 0;

  // ─── Pinned Notes (Multi-note context B4) ───
  final List<String> _pinnedNotePaths = [];

  // ─── Last RAG citations (for UI display) ───
  List<SourceCitation> _lastCitations = const [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<QuizQuestion> get quizQuestions => List.unmodifiable(_quizQuestions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasQuiz => _quizQuestions.isNotEmpty;
  String? get activeNotePath => _activeNotePath;
  List<String> get pinnedNotePaths => List.unmodifiable(_pinnedNotePaths);
  List<SourceCitation> get lastCitations => List.unmodifiable(_lastCitations);

  // ─── Pinned Notes Management ───

  void pinNote(String notePath) {
    if (!_pinnedNotePaths.contains(notePath)) {
      _pinnedNotePaths.add(notePath);
      notifyListeners();
    }
  }

  void unpinNote(String notePath) {
    if (_pinnedNotePaths.remove(notePath)) {
      notifyListeners();
    }
  }

  void clearPinnedNotes() {
    if (_pinnedNotePaths.isNotEmpty) {
      _pinnedNotePaths.clear();
      notifyListeners();
    }
  }

  // ─── AI Operations ───

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
      if (questions.length != AppConstants.quizQuestionCount) {
        throw AIServiceException(
          'AI không trả về đúng ${AppConstants.quizQuestionCount} câu hỏi. '
          'Vui lòng thử lại.',
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

    final history = _boundedChatHistory();
    _messages.add(
      ChatMessage(
        id: _newMessageId(),
        sender: MessageSender.user,
        text: prompt,
      ),
    );

    final requestVersion = _beginRequest(notify: true);
    try {
      // RAG path: dùng RagPipeline nếu có
      if (ragPipeline != null) {
        final ragResponse = await ragPipeline!.chat(
          prompt,
          history,
          pinnedNotePaths: _pinnedNotePaths.isNotEmpty ? _pinnedNotePaths : null,
          currentNoteTitle: noteTitle,
          currentNoteContent: noteContent,
        );
        if (!_isCurrentRequest(requestVersion)) {
          return;
        }

        _lastCitations = ragResponse.citations;

        final retrievedNoteNames = ragResponse.retrievedChunks
            .map((c) => c.noteTitle)
            .toSet()
            .toList();

        _messages.add(
          ChatMessage(
            id: _newMessageId(),
            sender: MessageSender.ai,
            text: ragResponse.answer,
            citations: ragResponse.citations,
            retrievedNotes: retrievedNoteNames,
          ),
        );
      } else {
        // Fallback: gọi AI trực tiếp (flow cũ)
        final contextualPrompt = _buildContextualPrompt(
          prompt,
          noteTitle: noteTitle,
          noteContent: noteContent,
        );
        final response = await aiService.sendChatMessage(
          contextualPrompt,
          history,
        );
        if (!_isCurrentRequest(requestVersion)) {
          return;
        }
        _lastCitations = const [];
        _messages.add(
          ChatMessage(
            id: _newMessageId(),
            sender: MessageSender.ai,
            text: response,
          ),
        );
      }
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, requestVersion);
    } finally {
      _finishRequest(requestVersion);
    }
  }

  void setActiveNote(String? notePath) {
    final normalizedPath = notePath?.trim();
    final nextPath = normalizedPath == null || normalizedPath.isEmpty
        ? null
        : normalizedPath;
    if (_activeNotePath == nextPath) {
      return;
    }

    _activeNotePath = nextPath;
    _requestVersion++;
    _isLoading = false;
    _errorMessage = null;
    _quizQuestions = const [];
    _lastCitations = const [];
    if (_clearStateOnNoteChange) {
      _messages.clear();
    }
    notifyListeners();
  }

  void clearMessages() {
    _requestVersion++;
    _messages.clear();
    _quizQuestions = const [];
    _isLoading = false;
    _errorMessage = null;
    _lastCitations = const [];
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

  List<ChatMessage> _boundedChatHistory() {
    final chatMessages = _messages
        .where(
          (message) =>
              message.kind == MessageKind.chat &&
              message.sender != MessageSender.system,
        )
        .toList();
    if (chatMessages.length <= _maxHistoryMessages) {
      return chatMessages;
    }
    return chatMessages.sublist(chatMessages.length - _maxHistoryMessages);
  }

  /// Fallback prompt builder (khi không có RAG).
  String _buildContextualPrompt(
    String prompt, {
    String? noteTitle,
    String? noteContent,
  }) {
    final content = noteContent?.trim();
    if (content == null || content.isEmpty) {
      return prompt;
    }

    final title = noteTitle?.trim();
    return '''
${AppConstants.untrustedNoteStart}
Tiêu đề: ${title == null || title.isEmpty ? 'Không có tiêu đề' : title}

$content
${AppConstants.untrustedNoteEnd}

Câu hỏi của sinh viên:
$prompt
'''
        .trim();
  }

  String _newMessageId() => DateTime.now().microsecondsSinceEpoch.toString();
}
