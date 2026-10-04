import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/constants/ai_runtime_config.dart';

/// Wrapper cho Gemini Embedding API.
///
/// Cung cấp:
/// - embedText: embed một đoạn text → vector
/// - embedBatch: embed nhiều đoạn text → list of vectors
/// - cosineSimilarity: tính cosine similarity giữa 2 vectors
class GeminiEmbeddingService {
  GeminiEmbeddingService({required this.config});

  final AIRuntimeConfig config;

  GenerativeModel? _model;
  String? _effectiveModelName;

  GenerativeModel _getModel(String modelName) {
    if (_model != null && _effectiveModelName == modelName) {
      return _model!;
    }
    _effectiveModelName = modelName;
    return _model = GenerativeModel(
      model: modelName,
      apiKey: config.apiKey,
    );
  }

  /// Embed một đoạn text thành vector.
  Future<List<double>> embedText(String text) async {
    if (text.trim().isEmpty || config.apiKey.trim().isEmpty) {
      return const [];
    }

    final targetModel = _effectiveModelName ?? config.embeddingModel;
    try {
      final result = await _getModel(targetModel).embedContent(
        Content.text(text),
      );
      return result.embedding.values;
    } catch (e) {
      // Nếu model hiện tại không tồn tại hoặc không hỗ trợ, tự động fallback sang gemini-embedding-001
      if (targetModel != 'gemini-embedding-001' &&
          (e.toString().contains('not found') ||
              e.toString().contains('not supported'))) {
        try {
          debugPrint(
            '[Embedding] Fallback from $targetModel to gemini-embedding-001',
          );
          final result = await _getModel('gemini-embedding-001').embedContent(
            Content.text(text),
          );
          return result.embedding.values;
        } catch (fallbackError) {
          debugPrint('[Embedding] Fallback error: $fallbackError');
        }
      }
      debugPrint('[Embedding] Error embedding text: $e');
      return const [];
    }
  }

  /// Embed nhiều đoạn text thành list of vectors.
  ///
  /// Gọi tuần tự (Gemini Embedding API chưa hỗ trợ batch endpoint
  /// trong `google_generative_ai` package), nhưng được throttle
  /// bởi VaultIndexService theo batch.
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    if (texts.isEmpty || config.apiKey.trim().isEmpty) {
      return const [];
    }

    final results = <List<double>>[];
    for (final text in texts) {
      final embedding = await embedText(text);
      results.add(embedding);
    }
    return results;
  }

  /// Cosine similarity giữa 2 vectors.
  ///
  /// Trả về giá trị trong khoảng [-1, 1].
  /// 1 = hoàn toàn giống, 0 = không liên quan, -1 = hoàn toàn ngược.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;

    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = math.sqrt(normA) * math.sqrt(normB);
    if (denominator == 0.0) return 0.0;
    return dotProduct / denominator;
  }
}
