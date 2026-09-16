/// Đại diện cho một bài Note Markdown cùng các siêu dữ liệu liên kết.
/// Phụ trách: Member 2 (Markdown & Note Knowledge)
class Note {
  final String path;
  final String title;
  final String content;
  final List<String> outgoingLinks;
  final List<String> backlinks;
  final DateTime lastModified;

  Note({
    required this.path,
    required this.title,
    required this.content,
    List<String> outgoingLinks = const [],
    List<String> backlinks = const [],
    DateTime? lastModified,
  }) : outgoingLinks = List.unmodifiable(outgoingLinks),
       backlinks = List.unmodifiable(backlinks),
       lastModified = lastModified ?? DateTime.now();

  Note copyWith({
    String? path,
    String? title,
    String? content,
    List<String>? outgoingLinks,
    List<String>? backlinks,
    DateTime? lastModified,
  }) {
    return Note(
      path: path ?? this.path,
      title: title ?? this.title,
      content: content ?? this.content,
      outgoingLinks: outgoingLinks ?? this.outgoingLinks,
      backlinks: backlinks ?? this.backlinks,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
