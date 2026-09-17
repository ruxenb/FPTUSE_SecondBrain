import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../contracts/ai_service.dart';
import '../core/constants/ai_runtime_config.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';
import 'ai_retry_policy.dart';

class GeminiAIService implements AIService {
  GeminiAIService({
    required this.config,
    AIRetryPolicy? retryPolicy,
    Random? random,
  }) : retryPolicy = retryPolicy ?? AIRetryPolicy(config),
       _random = random ?? Random() {
    config.validate();
  }

  final AIRuntimeConfig config;
  final AIRetryPolicy retryPolicy;
  final Random _random;

  @override
  Future<String> summarizeNote(String noteTitle, String noteContent) async {
    final prompt =
        '''
${AppConstants.defaultSummarizePrompt}

${AppConstants.untrustedNoteStart}
Tiêu đề: $noteTitle

$noteContent
${AppConstants.untrustedNoteEnd}
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

Yêu cầu đầu ra:
- Đúng ${AppConstants.quizQuestionCount} câu hỏi.
- Mỗi câu có đúng ${AppConstants.quizOptionCount} lựa chọn.
- correctIndex là số nguyên chỉ vị trí đáp án đúng.

${AppConstants.untrustedNoteStart}
Tiêu đề: $noteTitle

$noteContent
${AppConstants.untrustedNoteEnd}
'''
            .trim();

    final raw = await _generateText(
      prompt,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _quizSchema,
      ),
    );
    return _parseQuiz(raw);
  }

  @override
  Future<String> sendChatMessage(
    String prompt,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      final eligibleHistory = conversationHistory
          .where(
            (message) =>
                message.sender != MessageSender.system &&
                message.kind == MessageKind.chat,
          )
          .toList();
      final startIndex = max(
        0,
        eligibleHistory.length - config.maxHistoryMessages,
      );
      final boundedHistory = eligibleHistory.sublist(startIndex);
      final history = boundedHistory
          .map(
            (message) => message.sender == MessageSender.user
                ? Content.text(message.text)
                : Content.model([TextPart(message.text)]),
          )
          .toList();

      final response = await _runWithRetry(() async {
        final chat = _createModel().startChat(history: history);
        return chat.sendMessage(
          Content.text('${AppConstants.defaultChatPrompt}\n\n$prompt'),
        );
      });
      return _requireText(response.text);
    } catch (error) {
      if (error is AIServiceException) {
        rethrow;
      }
      throw AIServiceException(_friendlyError(error));
    }
  }

  Future<String> _generateText(
    String prompt, {
    GenerationConfig? generationConfig,
  }) async {
    try {
      final response = await _runWithRetry(
        () =>
            _createModel(generationConfig: generationConfig)
                .generateContent([Content.text(prompt)]),
      );
      return _requireText(response.text);
    } catch (error) {
      if (error is AIServiceException) {
        rethrow;
      }
      throw AIServiceException(_friendlyError(error));
    }
  }

  GenerativeModel _createModel({GenerationConfig? generationConfig}) {
    _requireApiKey();
    return GenerativeModel(
      model: config.modelName,
      apiKey: config.apiKey,
      systemInstruction: Content.system(AppConstants.aiSystemInstruction),
      generationConfig: generationConfig,
    );
  }

  Future<T> _runWithRetry<T>(Future<T> Function() operation) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0; attempt < config.maxRetryAttempts; attempt++) {
      try {
        return await operation().timeout(config.requestTimeout);
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        final hasAnotherAttempt = attempt + 1 < config.maxRetryAttempts;
        if (!hasAnotherAttempt || !retryPolicy.shouldRetry(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }

        final jitter = config.retryJitterMs == 0
            ? 0
            : _random.nextInt(config.retryJitterMs + 1);
        await Future<void>.delayed(
          retryPolicy.delayForRetry(attempt, jitterMs: jitter),
        );
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
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

      if (questions.length != AppConstants.quizQuestionCount) {
        throw const FormatException(
          'Quiz response contains an invalid number of questions.',
        );
      }
      return questions;
    } catch (_) {
      throw const AIServiceException(
        'Không thể đọc dữ liệu quiz từ Gemini. Vui lòng thử tạo lại.',
      );
    }
  }

  void _requireApiKey() {
    if (config.apiKey.trim().isEmpty) {
      throw const AIServiceException(
        'Thiếu GEMINI_API_KEY. Hãy cấu hình API key trước khi dùng Gemini.',
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
    if (error is TimeoutException) {
      return 'Gemini phản hồi quá lâu. Vui lòng thử lại.';
    }
    if (error is InvalidApiKey) {
      return 'Gemini API key không hợp lệ hoặc đã hết hiệu lực.';
    }

    final message = error.toString().toLowerCase();

    if (message.contains('429') ||
        message.contains('resource_exhausted') ||
        message.contains('rate limit')) {
      return 'Gemini đang giới hạn số lượng yêu cầu. Vui lòng thử lại sau.';
    }
    if (message.contains('model_not_found') ||
        message.contains('model not found') ||
        message.contains('404')) {
      return 'Không tìm thấy Gemini model đã cấu hình.';
    }
    if (message.contains('api key') ||
        message.contains('permission') ||
        message.contains('401') ||
        message.contains('403')) {
      return 'Gemini API key không hợp lệ hoặc không có quyền truy cập.';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('503') ||
        message.contains('unavailable')) {
      return 'Không thể kết nối Gemini. Hãy kiểm tra mạng và thử lại.';
    }
    return 'Gemini gặp lỗi khi xử lý yêu cầu. Vui lòng thử lại.';
  }

  Schema get _quizSchema => Schema.array(
    items: Schema.object(
      properties: {
        'question': Schema.string(
          description: 'Câu hỏi chỉ dựa trên nội dung ghi chú.',
        ),
        'options': Schema.array(
          items: Schema.string(description: 'Một lựa chọn trả lời.'),
          description: 'Các lựa chọn trả lời.',
        ),
        'correctIndex': Schema.integer(
          description: 'Vị trí đáp án đúng, bắt đầu từ 0.',
        ),
        'explanation': Schema.string(
          description: 'Giải thích ngắn dựa trên ghi chú.',
        ),
      },
      requiredProperties: const [
        'question',
        'options',
        'correctIndex',
        'explanation',
      ],
    ),
    description: 'Danh sách câu hỏi quiz.',
  );
}
