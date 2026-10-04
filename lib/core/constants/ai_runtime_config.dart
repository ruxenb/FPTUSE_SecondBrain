import 'dart:io';

class AIRuntimeConfig {
  const AIRuntimeConfig({
    required this.useMock,
    required this.apiKey,
    required this.modelName,
    required this.requestTimeoutMs,
    required this.maxRetryAttempts,
    required this.initialBackoffMs,
    required this.maxBackoffMs,
    required this.retryJitterMs,
    required this.maxHistoryMessages,
    required this.clearStateOnNoteChange,
    required this.mockDelayMs,
    this.embeddingModel = 'gemini-embedding-001',
    this.maxRagChunks = 5,
    this.chunkSizeChars = 500,
    this.chunkOverlapChars = 80,
    this.enableRag = true,
    this.enableKnowledgeExtraction = true,
    this.embeddingBatchSize = 10,
    this.knowledgeExtractionDebounceMs = 5000,
  });

  /// Reads configuration from a local `.env` file if present,
  /// falling back to compile-time [environment] variables.
  static AIRuntimeConfig load({String envFilePath = '.env'}) {
    final env = environment;
    try {
      final file = File(envFilePath);
      if (!file.existsSync()) {
        return env;
      }

      final lines = file.readAsLinesSync();
      final map = <String, String>{};
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final eqIndex = line.indexOf('=');
        if (eqIndex <= 0) continue;
        final key = line.substring(0, eqIndex).trim();
        var val = line.substring(eqIndex + 1).trim();
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          if (val.length >= 2) {
            val = val.substring(1, val.length - 1);
          }
        }
        map[key] = val;
      }

      final keyFromEnv = map['GEMINI_API_KEY']?.trim() ?? env.apiKey;
      final bool? explicitMock = map.containsKey('USE_MOCK_AI')
          ? (map['USE_MOCK_AI']?.trim().toLowerCase() == 'true')
          : null;

      // Automatically disable mock if a valid Gemini API key is provided
      final bool resolvedUseMock = explicitMock ??
          (keyFromEnv.isNotEmpty ? false : env.useMock);

      return AIRuntimeConfig(
        useMock: resolvedUseMock,
        apiKey: keyFromEnv,
        modelName: map['GEMINI_MODEL'] ?? env.modelName,
        requestTimeoutMs: int.tryParse(map['AI_REQUEST_TIMEOUT_MS'] ?? '') ??
            env.requestTimeoutMs,
        maxRetryAttempts: int.tryParse(map['AI_MAX_RETRY_ATTEMPTS'] ?? '') ??
            env.maxRetryAttempts,
        initialBackoffMs: int.tryParse(map['AI_INITIAL_BACKOFF_MS'] ?? '') ??
            env.initialBackoffMs,
        maxBackoffMs: int.tryParse(map['AI_MAX_BACKOFF_MS'] ?? '') ??
            env.maxBackoffMs,
        retryJitterMs: int.tryParse(map['AI_RETRY_JITTER_MS'] ?? '') ??
            env.retryJitterMs,
        maxHistoryMessages: int.tryParse(map['AI_MAX_HISTORY_MESSAGES'] ?? '') ??
            env.maxHistoryMessages,
        clearStateOnNoteChange: map.containsKey('AI_CLEAR_STATE_ON_NOTE_CHANGE')
            ? (map['AI_CLEAR_STATE_ON_NOTE_CHANGE']?.trim().toLowerCase() ==
                'true')
            : env.clearStateOnNoteChange,
        mockDelayMs: int.tryParse(map['AI_MOCK_DELAY_MS'] ?? '') ??
            env.mockDelayMs,
        embeddingModel: map['EMBEDDING_MODEL'] ?? env.embeddingModel,
        maxRagChunks: int.tryParse(map['MAX_RAG_CHUNKS'] ?? '') ??
            env.maxRagChunks,
        chunkSizeChars: int.tryParse(map['CHUNK_SIZE_CHARS'] ?? '') ??
            env.chunkSizeChars,
        chunkOverlapChars: int.tryParse(map['CHUNK_OVERLAP_CHARS'] ?? '') ??
            env.chunkOverlapChars,
        enableRag: map.containsKey('ENABLE_RAG')
            ? (map['ENABLE_RAG']?.trim().toLowerCase() != 'false')
            : env.enableRag,
        enableKnowledgeExtraction:
            map.containsKey('ENABLE_KNOWLEDGE_EXTRACTION')
                ? (map['ENABLE_KNOWLEDGE_EXTRACTION']?.trim().toLowerCase() !=
                    'false')
                : env.enableKnowledgeExtraction,
        embeddingBatchSize:
            int.tryParse(map['EMBEDDING_BATCH_SIZE'] ?? '') ??
                env.embeddingBatchSize,
        knowledgeExtractionDebounceMs:
            int.tryParse(map['KNOWLEDGE_EXTRACTION_DEBOUNCE_MS'] ?? '') ??
                env.knowledgeExtractionDebounceMs,
      );
    } catch (_) {
      return env;
    }
  }

  static const environment = AIRuntimeConfig(
    useMock: bool.fromEnvironment('USE_MOCK_AI', defaultValue: true),
    apiKey: String.fromEnvironment('GEMINI_API_KEY'),
    modelName: String.fromEnvironment(
      'GEMINI_MODEL',
      defaultValue: 'gemini-3.6-flash',
    ),
    requestTimeoutMs: int.fromEnvironment(
      'AI_REQUEST_TIMEOUT_MS',
      defaultValue: 30000,
    ),
    maxRetryAttempts: int.fromEnvironment(
      'AI_MAX_RETRY_ATTEMPTS',
      defaultValue: 3,
    ),
    initialBackoffMs: int.fromEnvironment(
      'AI_INITIAL_BACKOFF_MS',
      defaultValue: 1000,
    ),
    maxBackoffMs: int.fromEnvironment('AI_MAX_BACKOFF_MS', defaultValue: 8000),
    retryJitterMs: int.fromEnvironment('AI_RETRY_JITTER_MS', defaultValue: 250),
    maxHistoryMessages: int.fromEnvironment(
      'AI_MAX_HISTORY_MESSAGES',
      defaultValue: 12,
    ),
    clearStateOnNoteChange: bool.fromEnvironment(
      'AI_CLEAR_STATE_ON_NOTE_CHANGE',
      defaultValue: true,
    ),
    mockDelayMs: int.fromEnvironment('AI_MOCK_DELAY_MS', defaultValue: 800),
    embeddingModel: 'gemini-embedding-001',
    maxRagChunks: 5,
    chunkSizeChars: 500,
    chunkOverlapChars: 80,
    enableRag: true,
    enableKnowledgeExtraction: true,
    embeddingBatchSize: 10,
    knowledgeExtractionDebounceMs: 5000,
  );

  // ─── Original fields ───
  final bool useMock;
  final String apiKey;
  final String modelName;
  final int requestTimeoutMs;
  final int maxRetryAttempts;
  final int initialBackoffMs;
  final int maxBackoffMs;
  final int retryJitterMs;
  final int maxHistoryMessages;
  final bool clearStateOnNoteChange;
  final int mockDelayMs;

  // ─── RAG / Embedding fields ───

  /// Gemini embedding model (default: gemini-embedding-001).
  final String embeddingModel;

  /// Số lượng chunks tối đa trả về khi RAG search (default: 5).
  final int maxRagChunks;

  /// Kích thước mỗi chunk tính theo ký tự (default: 500).
  final int chunkSizeChars;

  /// Overlap giữa các chunks liền kề (default: 80 ký tự).
  final int chunkOverlapChars;

  /// Bật/tắt RAG pipeline (default: true).
  final bool enableRag;

  /// Bật/tắt knowledge extraction khi save note (default: true).
  final bool enableKnowledgeExtraction;

  /// Số requests embedding gửi trong 1 batch (throttle rate limit).
  final int embeddingBatchSize;

  /// Debounce cho knowledge extraction sau save note (ms).
  /// Tránh gọi API extraction liên tục khi auto-save.
  final int knowledgeExtractionDebounceMs;

  // ─── Derived getters ───
  Duration get requestTimeout => Duration(milliseconds: requestTimeoutMs);
  Duration get initialBackoff => Duration(milliseconds: initialBackoffMs);
  Duration get maxBackoff => Duration(milliseconds: maxBackoffMs);
  Duration get mockDelay => Duration(milliseconds: mockDelayMs);
  Duration get knowledgeExtractionDebounce =>
      Duration(milliseconds: knowledgeExtractionDebounceMs);

  void validate() {
    if (modelName.trim().isEmpty) {
      throw StateError('GEMINI_MODEL must not be empty.');
    }
    if (requestTimeoutMs <= 0) {
      throw StateError('AI_REQUEST_TIMEOUT_MS must be greater than zero.');
    }
    if (maxRetryAttempts <= 0) {
      throw StateError('AI_MAX_RETRY_ATTEMPTS must be greater than zero.');
    }
    if (initialBackoffMs < 0) {
      throw StateError('AI_INITIAL_BACKOFF_MS must not be negative.');
    }
    if (maxBackoffMs < initialBackoffMs) {
      throw StateError(
        'AI_MAX_BACKOFF_MS must be greater than or equal to AI_INITIAL_BACKOFF_MS.',
      );
    }
    if (retryJitterMs < 0) {
      throw StateError('AI_RETRY_JITTER_MS must not be negative.');
    }
    if (maxHistoryMessages <= 0) {
      throw StateError('AI_MAX_HISTORY_MESSAGES must be greater than zero.');
    }
    if (mockDelayMs < 0) {
      throw StateError('AI_MOCK_DELAY_MS must not be negative.');
    }
    if (maxRagChunks <= 0) {
      throw StateError('MAX_RAG_CHUNKS must be greater than zero.');
    }
    if (chunkSizeChars <= 0) {
      throw StateError('CHUNK_SIZE_CHARS must be greater than zero.');
    }
    if (chunkOverlapChars < 0 || chunkOverlapChars >= chunkSizeChars) {
      throw StateError(
        'CHUNK_OVERLAP_CHARS must be >= 0 and < CHUNK_SIZE_CHARS.',
      );
    }
    if (embeddingBatchSize <= 0) {
      throw StateError('EMBEDDING_BATCH_SIZE must be greater than zero.');
    }
  }
}

