import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/core/constants/ai_runtime_config.dart';
import 'package:fptu_se_second_brain/services/gemini_embedding_service.dart';
import 'package:fptu_se_second_brain/services/local_note_repository.dart';
import 'package:fptu_se_second_brain/services/vault_index_service.dart';

class _MockGeminiEmbeddingService extends GeminiEmbeddingService {
  _MockGeminiEmbeddingService() : super(config: AIRuntimeConfig.environment);

  @override
  Future<List<double>> embedText(String text) async {
    return List.filled(3072, 0.05);
  }

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    return List.generate(texts.length, (_) => List.filled(3072, 0.05));
  }
}

void main() {
  group('VaultIndexService Index Path & Loading Tests', () {
    test('loads comprehensive index from wiki/.secondbrain/index.json', () async {
      final config = AIRuntimeConfig.load();
      final noteRepository = LocalNoteRepository();
      final embeddingService = _MockGeminiEmbeddingService();

      final indexService = VaultIndexService(
        noteRepository: noteRepository,
        embeddingService: embeddingService,
        config: config,
      );

      // Build index with default sample_vault path
      await indexService.buildIndex('sample_vault');

      expect(indexService.isIndexed, isTrue);
      // Contains the large database chunks (at least 3347)
      expect(indexService.indexedChunkCount, greaterThanOrEqualTo(3347));

      // Test searching for PE of PRO
      final results = await indexService.search('thi pe của pro');
      expect(results, isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
