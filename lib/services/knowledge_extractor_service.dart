import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path/path.dart' as path;

import '../core/constants/ai_runtime_config.dart';
import '../models/knowledge_entity.dart';

/// Service trích xuất structured knowledge entities từ notes bằng Gemini.
///
/// Flow:
/// 1. Khi NoteProvider save note thành công → trigger extraction (debounced)
/// 2. Gửi note content cho Gemini với structured JSON output schema
/// 3. Parse response → `List<KnowledgeEntity>`
/// 4. Lưu vào {vault}/.secondbrain/knowledge.json
/// 5. GraphProvider đọc knowledge store để bổ sung edges
class KnowledgeExtractorService {
  KnowledgeExtractorService({required this.config});

  final AIRuntimeConfig config;

  /// Debounce timer: tránh gọi extraction liên tục khi auto-save.
  Timer? _debounceTimer;

  /// Pending extraction path (để cancel nếu note đổi).
  String? _pendingPath;

  /// Write queue để serialize ghi file.
  Future<void>? _pendingWrite;

  /// In-memory store (loaded from disk).
  final Map<String, List<KnowledgeEntity>> _store = {};

  // ─── Public API ───

  /// Lấy tất cả entities đã trích xuất.
  List<KnowledgeEntity> get allEntities =>
      _store.values.expand((e) => e).toList();

  /// Lấy entities theo note path.
  List<KnowledgeEntity> entitiesForNote(String notePath) =>
      _store[notePath] ?? const [];

  /// Trigger extraction với debounce.
  ///
  /// Nếu gọi liên tục (auto-save), chỉ lần cuối cùng mới thực sự chạy.
  void scheduleExtraction({
    required String noteTitle,
    required String noteContent,
    required String notePath,
    required String vaultRootPath,
  }) {
    _debounceTimer?.cancel();
    _pendingPath = notePath;

    _debounceTimer = Timer(config.knowledgeExtractionDebounce, () {
      // Chỉ chạy nếu path chưa bị thay đổi
      if (_pendingPath == notePath) {
        _extractAndStore(
          noteTitle: noteTitle,
          noteContent: noteContent,
          notePath: notePath,
          vaultRootPath: vaultRootPath,
        );
      }
    });
  }

  /// Load store từ disk.
  Future<void> loadStore(String vaultRootPath) async {
    try {
      final file = File(_storePath(vaultRootPath));
      if (!await file.exists()) return;

      final content = await file.readAsString(encoding: utf8);
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      _store.clear();
      for (final entry in decoded.entries) {
        final entities = (entry.value as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(KnowledgeEntity.fromJson)
                .toList() ??
            const [];
        if (entities.isNotEmpty) {
          _store[entry.key] = entities;
        }
      }

      debugPrint(
        '[KnowledgeExtractor] Loaded store: '
        '${_store.length} notes, ${allEntities.length} entities',
      );
    } catch (e) {
      debugPrint('[KnowledgeExtractor] Error loading store: $e');
    }
  }

  /// Xoá entities của note đã bị xoá.
  Future<void> removeNote(String notePath, String vaultRootPath) async {
    if (_store.containsKey(notePath)) {
      _store.remove(notePath);
      await _saveStore(vaultRootPath);
    }
  }

  /// Huỷ pending extraction.
  void cancelPending() {
    _debounceTimer?.cancel();
    _pendingPath = null;
  }

  // ─── Extraction Logic ───

  Future<void> _extractAndStore({
    required String noteTitle,
    required String noteContent,
    required String notePath,
    required String vaultRootPath,
  }) async {
    if (!config.enableKnowledgeExtraction) return;
    if (config.apiKey.trim().isEmpty || config.useMock) return;
    if (noteContent.trim().length < 50) return; // Note quá ngắn

    try {
      final entities = await _callGeminiExtraction(noteTitle, noteContent, notePath);
      if (entities.isNotEmpty) {
        _store[notePath] = entities;
        await _saveStore(vaultRootPath);
        debugPrint(
          '[KnowledgeExtractor] Extracted ${entities.length} entities '
          'from "$noteTitle"',
        );
      }
    } catch (e) {
      debugPrint('[KnowledgeExtractor] Extraction failed for "$noteTitle": $e');
    }
  }

  Future<List<KnowledgeEntity>> _callGeminiExtraction(
    String noteTitle,
    String noteContent,
    String notePath,
  ) async {
    final model = GenerativeModel(
      model: config.modelName,
      apiKey: config.apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _extractionSchema,
      ),
    );

    final prompt = '''
Phân tích bài ghi chú sau và trích xuất các thực thể tri thức (knowledge entities).

Với mỗi entity, xác định:
- name: tên khái niệm/thuật ngữ/công thức
- type: một trong [concept, definition, formula, codeSnippet, keyTerm, relationship]
- content: mô tả ngắn gọn hoặc nội dung đầy đủ
- relatedEntities: danh sách tên các entities liên quan trong bài

Chỉ trích xuất từ nội dung bài ghi chú, không bổ sung kiến thức ngoài.
Trả về tối đa 15 entities quan trọng nhất.

Bài ghi chú:
Tiêu đề: $noteTitle

$noteContent
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) return const [];

    try {
      final cleaned = text
          .replaceFirst(RegExp(r'^\s*```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```\s*$'), '')
          .trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return const [];

      final now = DateTime.now();
      return decoded.whereType<Map<String, dynamic>>().map((json) {
        final name = (json['name'] as String?)?.trim() ?? '';
        return KnowledgeEntity(
          id: '${noteTitle.toLowerCase()}:${name.toLowerCase()}',
          noteTitle: noteTitle,
          notePath: notePath,
          type: _parseType(json['type'] as String?),
          name: name,
          content: (json['content'] as String?)?.trim() ?? '',
          relatedEntities: (json['relatedEntities'] as List<dynamic>?)
                  ?.map((e) => (e as String).trim())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const [],
          extractedAt: now,
        );
      }).where((e) => e.name.isNotEmpty && e.content.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  EntityType _parseType(String? value) {
    if (value == null) return EntityType.concept;
    for (final t in EntityType.values) {
      if (t.name == value) return t;
    }
    return EntityType.concept;
  }

  // ─── Persistence ───

  String _storePath(String vaultRootPath) =>
      path.join(vaultRootPath, '.secondbrain', 'knowledge.json');

  Future<void> _saveStore(String vaultRootPath) async {
    while (_pendingWrite != null) {
      await _pendingWrite;
    }
    _pendingWrite = _performSave(vaultRootPath);
    try {
      await _pendingWrite;
    } finally {
      _pendingWrite = null;
    }
  }

  Future<void> _performSave(String vaultRootPath) async {
    try {
      final dir = Directory(path.join(vaultRootPath, '.secondbrain'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final data = <String, dynamic>{};
      for (final entry in _store.entries) {
        data[entry.key] = entry.value.map((e) => e.toJson()).toList();
      }

      final filePath = _storePath(vaultRootPath);
      final tempPath = '$filePath.tmp';
      final tempFile = File(tempPath);
      await tempFile.writeAsString(
        jsonEncode(data),
        encoding: utf8,
        flush: true,
      );
      await tempFile.rename(filePath);
    } catch (e) {
      debugPrint('[KnowledgeExtractor] Error saving store: $e');
    }
  }

  // ─── Extraction Schema ───

  Schema get _extractionSchema => Schema.array(
        items: Schema.object(
          properties: {
            'name': Schema.string(
              description: 'Tên khái niệm, thuật ngữ hoặc công thức.',
            ),
            'type': Schema.enumString(
              enumValues: EntityType.values.map((e) => e.name).toList(),
              description: 'Loại entity.',
            ),
            'content': Schema.string(
              description: 'Mô tả ngắn gọn hoặc nội dung.',
            ),
            'relatedEntities': Schema.array(
              items: Schema.string(description: 'Tên entity liên quan.'),
              description: 'Các entities liên quan trong bài.',
            ),
          },
          requiredProperties: const ['name', 'type', 'content'],
        ),
        description: 'Danh sách knowledge entities trích xuất từ ghi chú.',
      );
}
