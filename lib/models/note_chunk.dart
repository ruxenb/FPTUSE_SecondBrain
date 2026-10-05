/// Một đoạn text (chunk) từ note, dùng cho RAG retrieval.
///
/// Mỗi note được chia thành nhiều chunks (~500 ký tự, overlap ~80 ký tự).
/// Mỗi chunk có embedding vector để tìm kiếm semantic similarity.
class NoteChunk {
  const NoteChunk({
    required this.noteTitle,
    required this.notePath,
    required this.content,
    required this.startLine,
    required this.endLine,
    this.embedding,
    required this.indexedAt,
  });

  /// Tên note chứa chunk này.
  final String noteTitle;

  /// Đường dẫn file note chứa chunk này.
  final String notePath;

  /// Nội dung text của chunk.
  final String content;

  /// Dòng bắt đầu trong note gốc (1-indexed).
  final int startLine;

  /// Dòng kết thúc trong note gốc (1-indexed).
  final int endLine;

  /// Embedding vector từ Gemini (null nếu chưa embed).
  final List<double>? embedding;

  /// Thời điểm index chunk này.
  final DateTime indexedAt;

  factory NoteChunk.fromJson(Map<String, dynamic> json) {
    return NoteChunk(
      noteTitle: (json['noteTitle'] as String?)?.trim() ?? '',
      notePath: (json['notePath'] as String?)?.trim() ?? '',
      content: (json['content'] as String?)?.trim() ?? '',
      startLine: (json['startLine'] as int?) ?? 1,
      endLine: (json['endLine'] as int?) ?? 1,
      embedding: (json['embedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      indexedAt: json['indexedAt'] != null
          ? DateTime.tryParse(json['indexedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'noteTitle': noteTitle,
        'notePath': notePath,
        'content': content,
        'startLine': startLine,
        'endLine': endLine,
        if (embedding != null) 'embedding': embedding,
        'indexedAt': indexedAt.toIso8601String(),
      };

  NoteChunk copyWith({
    String? noteTitle,
    String? notePath,
    String? content,
    int? startLine,
    int? endLine,
    List<double>? embedding,
    DateTime? indexedAt,
  }) {
    return NoteChunk(
      noteTitle: noteTitle ?? this.noteTitle,
      notePath: notePath ?? this.notePath,
      content: content ?? this.content,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      embedding: embedding ?? this.embedding,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }
}

/// Kết quả trích dẫn nguồn, dùng cho citation trong AI response.
class SourceCitation {
  const SourceCitation({
    required this.noteTitle,
    required this.notePath,
    this.lineNumber,
  });

  final String noteTitle;
  final String notePath;
  final int? lineNumber;

  factory SourceCitation.fromJson(Map<String, dynamic> json) {
    return SourceCitation(
      noteTitle: (json['noteTitle'] as String?)?.trim() ?? '',
      notePath: (json['notePath'] as String?)?.trim() ?? '',
      lineNumber: json['lineNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'noteTitle': noteTitle,
        'notePath': notePath,
        if (lineNumber != null) 'lineNumber': lineNumber,
      };

  @override
  String toString() {
    final line = lineNumber != null ? ', dòng $lineNumber' : '';
    return '(note: $noteTitle$line)';
  }
}
