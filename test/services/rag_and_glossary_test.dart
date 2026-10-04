import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/core/constants/fptu_glossary.dart';
import 'package:fptu_se_second_brain/models/chat_message.dart';
import 'package:fptu_se_second_brain/models/knowledge_entity.dart';
import 'package:fptu_se_second_brain/models/note_chunk.dart';
import 'package:fptu_se_second_brain/services/gemini_embedding_service.dart';

void main() {
  group('FptuGlossary Tests', () {
    test('lookup finds known FPTU terms and aliases', () {
      final slot = FptuGlossary.lookup('slot');
      expect(slot, isNotNull);
      expect(slot!.term, equals('Slot'));
      expect(slot.category, equals('academic'));

      final ojt = FptuGlossary.lookup('OJT');
      expect(ojt, isNotNull);
      expect(ojt!.term, equals('OJT'));

      final flm = FptuGlossary.lookup('FLM');
      expect(flm, isNotNull);

      final capstone = FptuGlossary.lookup('capstone');
      expect(capstone, isNotNull);
    });

    test('findMentionedTerms detects terms in questions', () {
      const question =
          'Thầy ơi cho em hỏi slot 3 ngày mai thi PE môn SWD392 ở phòng nào?';
      final terms = FptuGlossary.findMentionedTerms(question);

      final termNames = terms.map((t) => t.term.toLowerCase()).toList();
      expect(termNames.contains('slot'), isTrue);
      expect(termNames.contains('pe'), isTrue);
      expect(termNames.contains('swd392'), isTrue);
    });

    test('buildContextString formats glossary entries correctly', () {
      final entries = [
        FptuGlossary.lookup('Slot')!,
        FptuGlossary.lookup('PE')!,
      ];
      final context = FptuGlossary.buildContextString(entries);
      expect(context.contains('<fptu_glossary>'), isTrue);
      expect(context.contains('**Slot**'), isTrue);
      expect(context.contains('**PE**'), isTrue);
      expect(context.contains('</fptu_glossary>'), isTrue);
    });
  });

  group('Cosine Similarity Tests', () {
    test('identical vectors return 1.0', () {
      final a = [1.0, 2.0, 3.0];
      final b = [1.0, 2.0, 3.0];
      expect(
        GeminiEmbeddingService.cosineSimilarity(a, b),
        closeTo(1.0, 0.0001),
      );
    });

    test('orthogonal vectors return 0.0', () {
      final a = [1.0, 0.0];
      final b = [0.0, 1.0];
      expect(
        GeminiEmbeddingService.cosineSimilarity(a, b),
        closeTo(0.0, 0.0001),
      );
    });

    test('opposite vectors return -1.0', () {
      final a = [1.0, 0.0];
      final b = [-1.0, 0.0];
      expect(
        GeminiEmbeddingService.cosineSimilarity(a, b),
        closeTo(-1.0, 0.0001),
      );
    });

    test('empty or mismatched vectors return 0.0', () {
      expect(GeminiEmbeddingService.cosineSimilarity([], []), equals(0.0));
      expect(
        GeminiEmbeddingService.cosineSimilarity([1.0], [1.0, 2.0]),
        equals(0.0),
      );
    });
  });

  group('Data Models Serialization Tests', () {
    test('NoteChunk toJson and fromJson roundtrip', () {
      final chunk = NoteChunk(
        noteTitle: 'Clean Architecture',
        notePath: 'vault/clean_arch.md',
        content: 'Entities and Use Cases are inner layers.',
        startLine: 10,
        endLine: 25,
        embedding: [0.1, 0.2, 0.3],
        indexedAt: DateTime(2026, 9, 24),
      );

      final json = chunk.toJson();
      final restored = NoteChunk.fromJson(json);

      expect(restored.noteTitle, equals('Clean Architecture'));
      expect(restored.notePath, equals('vault/clean_arch.md'));
      expect(restored.content, equals('Entities and Use Cases are inner layers.'));
      expect(restored.startLine, equals(10));
      expect(restored.endLine, equals(25));
      expect(restored.embedding, equals([0.1, 0.2, 0.3]));
    });

    test('KnowledgeEntity toJson and fromJson roundtrip', () {
      final entity = KnowledgeEntity(
        id: 'clean_arch:domain_layer',
        noteTitle: 'Clean Architecture',
        notePath: 'vault/clean_arch.md',
        type: EntityType.concept,
        name: 'Domain Layer',
        content: 'Chứa enterprise business rules độc lập với frameworks.',
        relatedEntities: ['Use Cases', 'Entities'],
        extractedAt: DateTime(2026, 9, 24),
      );

      final json = entity.toJson();
      final restored = KnowledgeEntity.fromJson(json);

      expect(restored.id, equals('clean_arch:domain_layer'));
      expect(restored.name, equals('Domain Layer'));
      expect(restored.type, equals(EntityType.concept));
      expect(restored.relatedEntities, equals(['Use Cases', 'Entities']));
    });

    test('SourceCitation formatting and parsing', () {
      const citation = SourceCitation(
        noteTitle: 'Software Architecture',
        notePath: 'notes/arch.md',
        lineNumber: 42,
      );

      expect(
        citation.toString(),
        equals('(note: Software Architecture, dòng 42)'),
      );

      final json = citation.toJson();
      final restored = SourceCitation.fromJson(json);
      expect(restored.noteTitle, equals('Software Architecture'));
      expect(restored.lineNumber, equals(42));
    });

    test('ChatMessage includes citations and retrieved notes', () {
      final message = ChatMessage(
        id: 'msg-1',
        sender: MessageSender.ai,
        text: 'Clean Architecture tách biệt business logic.',
        citations: const [
          SourceCitation(
            noteTitle: 'Clean Architecture',
            notePath: 'notes/clean.md',
            lineNumber: 5,
          ),
        ],
        retrievedNotes: const ['Clean Architecture', 'SOLID Principles'],
      );

      expect(message.citations.length, equals(1));
      expect(message.citations.first.noteTitle, equals('Clean Architecture'));
      expect(message.retrievedNotes.length, equals(2));
      expect(message.retrievedNotes, contains('SOLID Principles'));
    });
  });
}
