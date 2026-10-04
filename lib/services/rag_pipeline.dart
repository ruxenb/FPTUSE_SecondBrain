import 'package:flutter/foundation.dart';

import '../contracts/ai_service.dart';
import '../core/constants/ai_runtime_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/fptu_glossary.dart';
import '../models/chat_message.dart';
import '../models/note_chunk.dart';
import 'vault_index_service.dart';

/// Kết quả trả về từ RAG pipeline.
class RagResponse {
  const RagResponse({
    required this.answer,
    this.citations = const [],
    this.retrievedChunks = const [],
  });

  /// Câu trả lời từ AI.
  final String answer;

  /// Danh sách trích dẫn nguồn (parsed từ structured output).
  final List<SourceCitation> citations;

  /// Các chunks đã dùng để trả lời (để hiển thị transparency).
  final List<NoteChunk> retrievedChunks;
}

/// Orchestrator layer cho RAG-augmented AI chat.
///
/// Flow khi sinh viên gửi câu hỏi:
/// 1. Glossary lookup → tìm thuật ngữ FPTU trong câu hỏi → inject definitions
/// 2. Semantic search → tìm top-k chunks liên quan nhất từ vault index
/// 3. Multi-note assembly → gom context từ nhiều notes + pinned notes
/// 4. Prompt construction → build augmented prompt
/// 5. Generation → gửi cho Gemini với structured output schema cho citations
/// 6. Parse response → tách answer + citations
class RagPipeline {
  RagPipeline({
    required this.aiService,
    required this.indexService,
    required this.config,
  });

  final AIService aiService;
  final VaultIndexService indexService;
  final AIRuntimeConfig config;

  /// Main entry point: RAG-augmented chat.
  ///
  /// [query] — câu hỏi của sinh viên
  /// [conversationHistory] — lịch sử chat
  /// [pinnedNotePaths] — paths các note được pin thủ công (Multi-note context)
  /// [currentNoteTitle] — title note đang mở (nếu có)
  /// [currentNoteContent] — content note đang mở (nếu có)
  Future<RagResponse> chat(
    String query,
    List<ChatMessage> conversationHistory, {
    List<String>? pinnedNotePaths,
    String? currentNoteTitle,
    String? currentNoteContent,
  }) async {
    if (!config.enableRag || !indexService.isIndexed) {
      // Fallback: gọi AI trực tiếp không RAG
      return _fallbackChat(
        query,
        conversationHistory,
        currentNoteTitle: currentNoteTitle,
        currentNoteContent: currentNoteContent,
      );
    }

    try {
      // Step 1: Glossary lookup
      final glossaryTerms = FptuGlossary.findMentionedTerms(query);
      final glossaryContext = FptuGlossary.buildContextString(glossaryTerms);

      // Step 2: Semantic search
      final retrievedChunks = await indexService.search(query);

      // Step 3: Build augmented prompt
      final augmentedPrompt = _buildAugmentedPrompt(
        query: query,
        glossaryContext: glossaryContext,
        retrievedChunks: retrievedChunks,
        currentNoteTitle: currentNoteTitle,
        currentNoteContent: currentNoteContent,
      );

      // Step 4: Send to AI
      final response = await aiService.sendChatMessage(
        augmentedPrompt,
        conversationHistory,
      );

      // Step 5: Parse citations từ response
      // Vì Gemini chat API không hỗ trợ structured output trực tiếp
      // qua startChat(), ta dùng convention markers trong prompt
      // và parse citations từ response text.
      final parsed = _parseCitationsFromResponse(response, retrievedChunks);

      return RagResponse(
        answer: parsed.answer,
        citations: parsed.citations,
        retrievedChunks: retrievedChunks,
      );
    } catch (e) {
      debugPrint('[RAG] Error in pipeline: $e');
      // Fallback nếu RAG pipeline lỗi
      return _fallbackChat(
        query,
        conversationHistory,
        currentNoteTitle: currentNoteTitle,
        currentNoteContent: currentNoteContent,
      );
    }
  }

  /// Tạo quiz với RAG context (multi-note).
  Future<RagResponse> summarizeWithRag(
    String noteTitle,
    String noteContent,
  ) async {
    // Summarize vẫn chỉ dùng note hiện tại — bổ sung glossary nếu có
    final glossaryTerms = FptuGlossary.findMentionedTerms(noteContent);
    final glossaryContext = FptuGlossary.buildContextString(glossaryTerms);
    final enrichedContent = glossaryContext.isNotEmpty
        ? '$glossaryContext\n\n$noteContent'
        : noteContent;

    final response = await aiService.summarizeNote(noteTitle, enrichedContent);
    return RagResponse(answer: response);
  }

  // ─── Prompt Construction ───

  String _buildAugmentedPrompt({
    required String query,
    required String glossaryContext,
    required List<NoteChunk> retrievedChunks,
    String? currentNoteTitle,
    String? currentNoteContent,
  }) {
    final buffer = StringBuffer();

    // Glossary context
    if (glossaryContext.isNotEmpty) {
      buffer.writeln(glossaryContext);
      buffer.writeln();
    }

    // Retrieved context từ vault
    if (retrievedChunks.isNotEmpty) {
      buffer.writeln('<retrieved_context>');
      buffer.writeln(
        'Dưới đây là các đoạn trích từ vault ghi chú liên quan đến câu hỏi. '
        'Hãy ưu tiên thông tin từ các đoạn này khi trả lời.',
      );
      for (var i = 0; i < retrievedChunks.length; i++) {
        final chunk = retrievedChunks[i];
        buffer.writeln();
        buffer.writeln(
          '--- Trích từ "${chunk.noteTitle}" '
          '(dòng ${chunk.startLine}-${chunk.endLine}) ---',
        );
        buffer.writeln(chunk.content);
      }
      buffer.writeln('</retrieved_context>');
      buffer.writeln();
    }

    // Current note context (nếu đang mở)
    final content = currentNoteContent?.trim();
    if (content != null && content.isNotEmpty) {
      buffer.writeln(AppConstants.untrustedNoteStart);
      buffer.writeln(
        'Tiêu đề: ${currentNoteTitle ?? "Không có tiêu đề"}',
      );
      buffer.writeln();
      buffer.writeln(content);
      buffer.writeln(AppConstants.untrustedNoteEnd);
      buffer.writeln();
    }

    // Citation instruction
    buffer.writeln(
      'QUAN TRỌNG: Sau câu trả lời, liệt kê các nguồn đã sử dụng theo format:',
    );
    buffer.writeln('📚 Nguồn:');
    buffer.writeln('- (note: tên-note, dòng X-Y)');
    buffer.writeln(
      'Nếu thông tin không có trong vault, ghi rõ: '
      '"⚠️ Thông tin này ngoài vault, cần kiểm chứng thêm."',
    );
    buffer.writeln();

    // User query
    buffer.writeln('Câu hỏi của sinh viên:');
    buffer.writeln(query);

    return buffer.toString();
  }

  // ─── Citation Parsing ───

  /// Parse citations từ AI response text.
  ///
  /// Tìm pattern `(note: tên-note, dòng X-Y)` trong response.
  _ParsedResponse _parseCitationsFromResponse(
    String response,
    List<NoteChunk> availableChunks,
  ) {
    final citations = <SourceCitation>[];
    final citationPattern = RegExp(
      r'\(note:\s*([^,)]+?)(?:,\s*dòng\s*(\d+)(?:\s*-\s*\d+)?)?\)',
      caseSensitive: false,
    );

    for (final match in citationPattern.allMatches(response)) {
      final noteTitle = match.group(1)?.trim() ?? '';
      final lineStr = match.group(2);
      final lineNumber = lineStr != null ? int.tryParse(lineStr) : null;

      if (noteTitle.isNotEmpty) {
        // Tìm notePath từ available chunks
        final matchingChunk = availableChunks.firstWhere(
          (c) => c.noteTitle.toLowerCase() == noteTitle.toLowerCase(),
          orElse: () => NoteChunk(
            noteTitle: noteTitle,
            notePath: '',
            content: '',
            startLine: 0,
            endLine: 0,
            indexedAt: DateTime.now(),
          ),
        );

        citations.add(SourceCitation(
          noteTitle: noteTitle,
          notePath: matchingChunk.notePath,
          lineNumber: lineNumber,
        ));
      }
    }

    // Deduplicate citations
    final seen = <String>{};
    final uniqueCitations = <SourceCitation>[];
    for (final citation in citations) {
      final key = '${citation.noteTitle}:${citation.lineNumber}';
      if (seen.add(key)) {
        uniqueCitations.add(citation);
      }
    }

    return _ParsedResponse(
      answer: response,
      citations: uniqueCitations,
    );
  }

  // ─── Fallback (no RAG) ───

  Future<RagResponse> _fallbackChat(
    String query,
    List<ChatMessage> conversationHistory, {
    String? currentNoteTitle,
    String? currentNoteContent,
  }) async {
    // Vẫn inject glossary ngay cả khi không có RAG
    final glossaryTerms = FptuGlossary.findMentionedTerms(query);
    final glossaryContext = FptuGlossary.buildContextString(glossaryTerms);

    final buffer = StringBuffer();
    if (glossaryContext.isNotEmpty) {
      buffer.writeln(glossaryContext);
      buffer.writeln();
    }

    final content = currentNoteContent?.trim();
    if (content != null && content.isNotEmpty) {
      buffer.writeln(AppConstants.untrustedNoteStart);
      buffer.writeln(
        'Tiêu đề: ${currentNoteTitle ?? "Không có tiêu đề"}',
      );
      buffer.writeln();
      buffer.writeln(content);
      buffer.writeln(AppConstants.untrustedNoteEnd);
      buffer.writeln();
    }

    buffer.writeln('Câu hỏi của sinh viên:');
    buffer.writeln(query);

    final response = await aiService.sendChatMessage(
      buffer.toString(),
      conversationHistory,
    );

    return RagResponse(answer: response);
  }
}

class _ParsedResponse {
  final String answer;
  final List<SourceCitation> citations;
  const _ParsedResponse({required this.answer, required this.citations});
}
