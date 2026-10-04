import '../models/note_chunk.dart';

enum MessageSender { user, ai, system }

enum MessageKind { chat, summary }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.kind = MessageKind.chat,
    this.citations = const [],
    this.retrievedNotes = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final MessageSender sender;
  final String text;
  final MessageKind kind;
  final DateTime timestamp;

  /// Trích dẫn nguồn từ RAG pipeline (chỉ có ở AI messages).
  final List<SourceCitation> citations;

  /// Tên các notes đã dùng để trả lời (transparency).
  final List<String> retrievedNotes;
}

