import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../contracts/ai_service.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';

class GeminiAIService implements AIService {
  GeminiAIService({required this.apiKey, this.modelName = 'gemini-2.5-flash'});

  final String apiKey;
  final String modelName;

  GenerativeModel get _model {
    if (apiKey.trim().isEmpty) {
      throw const AIServiceException(
        'Thiếu GEMINI_API_KEY. Hãy cấu hình API key trước khi dùng Gemini.',
      );
    }
    return GenerativeModel(model: modelName, apiKey: apiKey);
  }

  @override
  Future<String> summarizeNote(String noteTitle, String noteContent) async {
    final prompt =
        '''
${AppConstants.defaultSummarizePrompt}

Tiêu đề: $noteTitle

Nội dung:
$noteContent
'''
            .trim();

    return _generateText(prompt);
  }

  @override
  Future<List<QuizQuestion>> generateQuiz(
    String noteTitle,
    String noteContent,
  ) async {
    final prompt =
        '''
${AppConstants.defaultQuizPrompt}

Tiêu đề: $noteTitle

Nội dung:
$noteContent

Chỉ trả về JSON hợp lệ theo cấu trúc:
[
  {
    "question": "Nội dung câu hỏi",
    "options": ["A", "B", "C", "D"],
    "correctIndex": 0,
    "explanation": "Giải thích ngắn"
  }
]
correctIndex dùng giá trị từ 0 đến 3.
'''
            .trim();

    final raw = await _generateText(prompt);
    return _parseQuiz(raw);
  }

  @override
  Future<String> sendChatMessage(
    String prompt,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      final history = conversationHistory
          .where((message) => message.sender != MessageSender.system)
          .map(
            (message) => message.sender == MessageSender.user
                ? Content.text(message.text)
                : Content.model([TextPart(message.text)]),
          )
          .toList();

      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(
        Content.text('${AppConstants.defaultChatPrompt}\n\n$prompt'),
      );
      return _requireText(response.text);
    } catch (error) {
      throw AIServiceException(_friendlyError(error));
    }
  }

  Future<String> _generateText(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return _requireText(response.text);
    } catch (error) {
      if (error is AIServiceException) {
        rethrow;
      }
      throw AIServiceException(_friendlyError(error));
    }
  }

  List<QuizQuestion> _parseQuiz(String raw) {
    try {
      final cleaned = raw
          .replaceFirst(RegExp(r'^\s*```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```\s*$'), '')
          .trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) {
        throw const FormatException('Quiz response must be a JSON array.');
      }

      final questions = decoded
          .map(
            (item) =>
                QuizQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      if (questions.length != 3) {
        throw const FormatException('Quiz must contain exactly 3 questions.');
      }
      return questions;
    } catch (error) {
      throw const AIServiceException(
        'Không thể đọc dữ liệu quiz từ Gemini. Vui lòng thử tạo lại.',
      );
    }
  }

  String _requireText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      throw const AIServiceException(
        'Gemini không trả về nội dung. Vui lòng thử lại.',
      );
    }
    return text;
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('api key') ||
        message.contains('permission') ||
        message.contains('401') ||
        message.contains('403')) {
      return 'Gemini API key không hợp lệ hoặc không có quyền truy cập.';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Không thể kết nối Gemini. Hãy kiểm tra mạng và thử lại.';
    }
    return 'Gemini gặp lỗi khi xử lý yêu cầu. Vui lòng thử lại.';
  }
}
