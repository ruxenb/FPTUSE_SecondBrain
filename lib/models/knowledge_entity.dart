/// Loại entity trích xuất từ note bởi AI.
enum EntityType {
  concept,
  definition,
  formula,
  codeSnippet,
  keyTerm,
  relationship,
}

/// Một entity tri thức được AI trích xuất từ note.
///
/// Dùng để xây dựng knowledge graph chính xác hơn wikilink regex,
/// và hỗ trợ structured search.
class KnowledgeEntity {
  const KnowledgeEntity({
    required this.id,
    required this.noteTitle,
    required this.notePath,
    required this.type,
    required this.name,
    required this.content,
    this.relatedEntities = const [],
    required this.extractedAt,
  });

  /// Unique ID, thường là `noteTitle:name` lowercase.
  final String id;

  /// Tên note chứa entity này.
  final String noteTitle;

  /// Đường dẫn file note chứa entity này.
  final String notePath;

  /// Loại entity.
  final EntityType type;

  /// Tên entity (VD: "Dependency Injection", "O(n log n)").
  final String name;

  /// Nội dung mô tả hoặc definition đầy đủ.
  final String content;

  /// Danh sách tên các entities liên quan (cross-reference).
  final List<String> relatedEntities;

  /// Thời điểm trích xuất.
  final DateTime extractedAt;

  factory KnowledgeEntity.fromJson(Map<String, dynamic> json) {
    return KnowledgeEntity(
      id: (json['id'] as String?)?.trim() ?? '',
      noteTitle: (json['noteTitle'] as String?)?.trim() ?? '',
      notePath: (json['notePath'] as String?)?.trim() ?? '',
      type: _parseEntityType(json['type']),
      name: (json['name'] as String?)?.trim() ?? '',
      content: (json['content'] as String?)?.trim() ?? '',
      relatedEntities: (json['relatedEntities'] as List<dynamic>?)
              ?.map((e) => (e as String).trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      extractedAt: json['extractedAt'] != null
          ? DateTime.tryParse(json['extractedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteTitle': noteTitle,
        'notePath': notePath,
        'type': type.name,
        'name': name,
        'content': content,
        'relatedEntities': relatedEntities,
        'extractedAt': extractedAt.toIso8601String(),
      };

  static EntityType _parseEntityType(Object? value) {
    if (value is String) {
      for (final t in EntityType.values) {
        if (t.name == value) return t;
      }
    }
    return EntityType.concept;
  }
}
